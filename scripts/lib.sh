#!/bin/bash
# Shared helpers for the ImageMagick ARVO delivery image.
#
# Layout inside the container:
#   /src/imagemagick              git repo, tags: vuln (漏洞存在, 13ffeab) /
#                                 fixed (全部修复, 8239e79) — both real upstream commits
#   /payload                      cases.tsv, pocs/, vulnerabilities.*
#   /out/hand-<profile>-<tree>/   repro, the one (instrumented) reproducer
#   /out/plain-<tree>/            repro, hand_repro.cc against a plain build
#   /work/<profile>-<tree>/       install prefix of that instrumented build
#   /work/plain-<tree>/           install prefix of the plain build
#
# There is exactly one reproduction entry: hand_repro.cc.  It is a hand-written
# driver, not a fuzz target — it replicates the harness contract (forced format,
# Blob read + write back, swallowed Magick::Exception, utils.cc limits, plus
# width/height(2048) on the fixed tree) and takes the coder as a run-time
# argument.  Nothing here builds or links libFuzzer.

set -uo pipefail

REPO=${REPO:-/src/imagemagick}
PAYLOAD=${PAYLOAD:-/payload}
OUTROOT=${OUTROOT:-/out}

die() { echo "error: $*" >&2; exit 1; }

# One build per sanitizer — never merged (ASan+UBSan cross-talk makes the fixed
# tree report unrelated UB).
san_profile() {
  case "$1" in
    address|asan)       echo "address" ;;
    undefined|ubsan)    echo "undefined" ;;
    memory|msan)        echo "memory" ;;
    *) die "unknown sanitizer '$1' (address|undefined|memory)" ;;
  esac
}

san_env() {
  case "$(san_profile "$1")" in
    address)
      echo "ASAN_OPTIONS=allocator_may_return_null=1:detect_leaks=0:detect_container_overflow=1:detect_odr_violation=0:detect_stack_use_after_return=1:fast_unwind_on_fatal=0:handle_abort=1:handle_segv=1:handle_sigill=1:print_scariness=1:quarantine_size_mb=10:strict_memcmp=1:symbolize=1:use_sigaltstack=1:dedup_token_length=3" ;;
    undefined)
      echo "UBSAN_OPTIONS=print_stacktrace=1:print_summary=1:symbolize=1:dedup_token_length=3" ;;
    memory)
      echo "MSAN_OPTIONS=print_stats=1:symbolize=1:dedup_token_length=3" ;;
  esac
}

# Compiler/linker instrumentation of a profile.  Shared by the tree build and
# the hand reproducer so both are instrumented identically.
san_flags() {
  case "$(san_profile "$1")" in
    address)   echo "-fsanitize=address -fsanitize-address-use-after-scope" ;;
    undefined) echo "${SANITIZER_FLAGS_undefined:--fsanitize=undefined -fno-sanitize-recover=undefined}" ;;
    memory)    echo "-fsanitize=memory -fsanitize-memory-track-origins" ;;
  esac
}

# MSan also needs the image's *instrumented* libc++: the copy in /usr/local/lib
# is not instrumented, the one in /usr/msan/lib is.
san_link_extra() {
  case "$(san_profile "$1")" in
    memory) echo "-L/usr/msan/lib" ;;
    *)      echo "" ;;
  esac
}

# hand-written, instrumented reproducer for <tree> <profile>
hand_repro_bin() { echo "$OUTROOT/hand-$2-$1/repro"; }

# hand-written, non-instrumented reproducer for <tree>
plain_repro_bin() { echo "$OUTROOT/plain-$1/repro"; }

# upstream version label of a commit, e.g. 7.0.7-21-82-g13ffeab.
# `--match '7.*'` keeps the two convenience tags (vuln, fixed) out of the
# answer — the image's git 2.7.4 has no `--exclude`.
describe_ref() {
  git -C "$REPO" describe --tags --match '7.*' "${1}^{commit}" 2>/dev/null ||
    echo "no-version-tag"
}

# checkout_tree <vuln|fixed>
#
# The two refs are tags on real upstream commits; the SHA is always resolved
# from the ref, never hardcoded.  Prints "<tree> = <full sha> (<version>)".
checkout_tree() {
  local tree=$1 sha desc
  git -C "$REPO" rev-parse -q --verify "${tree}^{commit}" >/dev/null ||
    die "ref '$tree' not found in $REPO (expected 'vuln' or 'fixed')"
  sha=$(git -C "$REPO" rev-parse "${tree}^{commit}")
  git -C "$REPO" checkout -q -f --detach "$tree"
  git -C "$REPO" clean -xffdq
  desc=$(describe_ref "$sha")
  echo "tree $tree = $sha ($desc)"
}

# run_hand <san> <binary> <coder> <poc> -> "SUMMARY<TAB>...|FRAME<TAB>..."
run_hand() {
  local san=$1 bin=$2 coder=$3 poc=$4 out summary frame
  local -a envpairs=()
  [ -x "$bin" ] || { echo "MISSING-BINARY $bin"; return 2; }
  [ -f "$poc" ] || { echo "MISSING-POC $poc"; return 2; }

  while IFS= read -r line; do envpairs+=("$line"); done < <(san_env "$san")
  # The coder and the PoC are plain run-time arguments; no fuzz runtime involved.
  if [ "$(san_profile "$san")" = "memory" ]; then
    out=$(setarch x86_64 -R env "${envpairs[@]}" "$bin" "$coder" "$poc" 2>&1)
  else
    out=$(env "${envpairs[@]}" "$bin" "$coder" "$poc" 2>&1)
  fi
  summary=$(printf '%s\n' "$out" | grep -m1 '^SUMMARY: ' || true)
  frame=$(printf '%s\n' "$out" | grep -m1 -oE '#0 0x[0-9a-f]+ in [^ ]+' | awk '{print $NF}' || true)
  printf 'SUMMARY\t%s\nFRAME\t%s\n' "$summary" "$frame"
}
