#!/bin/bash
# Instrumented build of one tree, plus the (only) reproducer.
#
#   build-san.sh --tree vuln  --san address    # 漏洞存在的节点 (13ffeab, 2018-01-16)
#   build-san.sh --tree fixed --san memory     # 全部修复的节点 (8239e79, 2018-03-20)
#   build-san.sh --tree vuln  --san all        # 三个 profile 各编一次
#
# Both `vuln` and `fixed` are tags on real upstream commits; the commit is
# resolved from the ref (`git rev-parse <tree>`) and echoed with every build —
# no SHA is hardcoded here.
#
# It produces one thing:
#   /out/hand-<profile>-<tree>/repro
#     hand_repro.cc linked against /work/<profile>-<tree>, instrumented with the
#     same profile.  No fuzz target (encoder_<coder>_fuzzer) and no libFuzzer
#     runtime is built: the driver carries the harness contract itself — forced
#     format, Blob read + write back, swallowed Magick::Exception, utils.cc
#     limits, and -DHARNESS_FIXED_LIMITS (width/height 2048) on the fixed tree.
#
# Options: --tree vuln|fixed  --san address|undefined|memory|all  --force
#          --dry-run  --out DIR   (build into DIR/repro, install prefix
#                                  /work/prefix-<basename>)
# Profiles: address | undefined | memory   (one build each, never merged)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/lib.sh"

TREE=""; SAN=""; FORCE=0; DRY=0; OUTDIR=""; EXTRA=()
while [ $# -gt 0 ]; do
  case "$1" in
    --tree)    TREE=${2:?}; shift 2 ;;
    --san)     SAN=${2:?}; shift 2 ;;
    --force)   FORCE=1; EXTRA+=(--force); shift ;;
    --dry-run) DRY=1; EXTRA+=(--dry-run); shift ;;
    --out)     OUTDIR=${2:?}; EXTRA+=(--out "$2"); shift 2 ;;
    -h|--help) sed -n '2,23p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[ -n "$TREE" ] && [ -n "$SAN" ] ||
  die "usage: build-san.sh --tree vuln|fixed --san address|undefined|memory|all"

case "$TREE" in vuln|fixed) ;; *) die "tree must be vuln or fixed" ;; esac
if [ "$SAN" = "all" ]; then
  for p in address undefined memory; do
    "$here/build-san.sh" --tree "$TREE" --san "$p" ${EXTRA[@]+"${EXTRA[@]}"} || exit 1
  done
  exit 0
fi
profile=$(san_profile "$SAN")

BASE="-O1 -gline-tables-only -fno-omit-frame-pointer -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
CXXSTD="-stdlib=libc++"
SANFLAGS=$(san_flags "$profile")
LINK_EXTRA=$(san_link_extra "$profile")
CFLAGS="$BASE $SANFLAGS"
CXXFLAGS="$CFLAGS $CXXSTD"

checkout_tree "$TREE"
# Resolved from the ref, never hardcoded; echoed below and stored in BUILD_INFO.
commit=$(git -C "$REPO" rev-parse "${TREE}^{commit}")
prefix="/work/$profile-$TREE"
hand_bin=$(hand_repro_bin "$TREE" "$profile")
if [ -n "$OUTDIR" ]; then
  prefix="/work/prefix-$(basename "$OUTDIR")"
  hand_bin="$OUTDIR/repro"
fi
hand_dir=$(dirname "$hand_bin")
info="$hand_dir/BUILD_INFO"

# -DHARNESS_FIXED_LIMITS mirrors the fixed tree's Magick++/fuzz/utils.cc, which
# adds ResourceLimits::width(2048)/height(2048) (commit e8be814f); without it a
# fixed-tree build still crashes on cases that only the limits tame.
build_hand() {
  local defs=""
  if [ "$TREE" = "fixed" ]; then defs="-DHARNESS_FIXED_LIMITS"; fi
  mkdir -p "$hand_dir"
  echo "hand reproducer -> $hand_bin"
  clang++ $CXXFLAGS $LINK_EXTRA -std=c++11 $defs \
    -I"$prefix/include/ImageMagick-7" "$here/hand_repro.cc" \
    -o "$hand_dir/repro.new" \
    -DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 \
    "$prefix/lib/libMagick++-7.Q16HDRI.a" \
    "$prefix/lib/libMagickWand-7.Q16HDRI.a" \
    "$prefix/lib/libMagickCore-7.Q16HDRI.a" -lpthread -lm ||
    die "hand reproducer build failed ($TREE/$profile)"
  mv -f "$hand_dir/repro.new" "$hand_bin"
}

echo "building $TREE/$profile at $commit ($(describe_ref "$commit"))"
if [ "$DRY" -eq 1 ]; then
  echo "dry-run: configure --prefix=$prefix"
  echo "dry-run: CFLAGS=$CFLAGS"
  if [ "$TREE" = "fixed" ]; then
    echo "dry-run: hand reproducer with -DHARNESS_FIXED_LIMITS"
  fi
  echo "dry-run: would produce $hand_bin"
  exit 0
fi

up2date=0
if [ "$FORCE" -eq 0 ] && [ -f "$info" ] && [ -d "$prefix/lib" ] &&
   [ "$(awk -F'\t' '$1=="commit"{print $2}' "$info" 2>/dev/null)" = "$commit" ]; then
  up2date=1
fi
if [ "$up2date" -eq 1 ] && [ -x "$hand_bin" ]; then
  echo "already built: $hand_bin — use --force to rebuild"
  exit 0
fi
if [ "$up2date" -eq 1 ]; then
  # The tree build is still valid; only the reproducer is missing, so compile
  # just that against the existing prefix.
  echo "tree build up to date: $prefix"
  build_hand
  exit 0
fi

start=$(date +%s)
cd "$REPO"
# configure is tracked in this tree; never regenerate it (autoconf-archive is
# not available in the base image and a regenerated configure is broken).
[ -f ./configure ] || die "configure missing after checkout of $TREE"
# Plain flags for configure: MSan-instrumented test programs cannot run during
# feature detection, so instrumentation is injected at make time.
export CC=clang CXX=clang++
PLAIN_C="-O1 -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
PLAIN_CXX="$PLAIN_C -stdlib=libc++"
if ! CFLAGS="$PLAIN_C" CXXFLAGS="$PLAIN_CXX" LDFLAGS="" \
     ./configure --prefix="$prefix" --disable-shared --disable-docs \
     --disable-openmp --without-perl > /tmp/conf.log 2>&1; then
  tail -n 6 /tmp/conf.log
  die "configure failed"
fi
make -j"$(nproc)" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$SANFLAGS" >/dev/null
make install CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$SANFLAGS" >/dev/null

rm -rf "$hand_dir"
build_hand

# Fail loudly if the instrumentation did not make it into the binary.
# (write to a file: `nm | grep -q` dies from SIGPIPE under pipefail)
nm "$hand_bin" > /tmp/dtrepro.syms 2>/dev/null || die "nm failed on $hand_bin"
case "$profile" in
  address)   grep -q "__asan_" /tmp/dtrepro.syms || die "$hand_bin is not ASan-instrumented" ;;
  memory)    grep -q "__msan_" /tmp/dtrepro.syms || die "$hand_bin is not MSan-instrumented" ;;
  undefined) grep -q "__ubsan_" /tmp/dtrepro.syms || die "$hand_bin is not UBSan-instrumented" ;;
esac

{
  printf 'tree\t%s\n' "$TREE"
  printf 'profile\t%s\n' "$profile"
  printf 'commit\t%s\n' "$commit"
  printf 'cflags\t%s\n' "$CFLAGS"
  printf 'hand\t%s\n' "$hand_bin"
  printf 'built\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'seconds\t%s\n' "$(( $(date +%s) - start ))"
} > "$info"

echo "done: $hand_bin ($(( $(date +%s) - start ))s) — tree $TREE = $commit"
