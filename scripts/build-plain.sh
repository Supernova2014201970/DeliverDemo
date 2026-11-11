#!/bin/bash
# Non-instrumented build of one tree, plus the hand-written reproducer.
#
#   build-plain.sh --tree vuln  [--force]
#   build-plain.sh --tree fixed [--force]
#
# /work/plain-<tree>        install prefix (no sanitizer runtime involved)
# /out/plain-<tree>/repro    hand_repro.cc linked against it
#
# Same configure line and make as build-san.sh, minus every sanitizer flag: this
# is the build a reviewer can run by hand — /out/plain-vuln/repro MVG poc —
# without any sanitizer environment.  Only the run-time coder selection and the
# HARNESS_FIXED_LIMITS switch distinguish it from the instrumented reproducer.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/lib.sh"

TREE=""; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tree)    TREE=${2:?}; shift 2 ;;
    --force)   FORCE=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[ -n "$TREE" ] || die "usage: build-plain.sh --tree vuln|fixed [--force]"
case "$TREE" in vuln|fixed) ;; *) die "tree must be vuln or fixed" ;; esac

prefix="/work/plain-$TREE"
bin=$(plain_repro_bin "$TREE")
dir=$(dirname "$bin")
# -O1 -g (not -gline-tables-only): this binary is meant to be read in a debugger.
PLAIN_C="-O1 -g -fno-omit-frame-pointer -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
PLAIN_CXX="$PLAIN_C -stdlib=libc++"

checkout_tree "$TREE"
want=$(git -C "$REPO" rev-parse "${TREE}^{commit}")

if [ "$FORCE" -eq 0 ] && [ -x "$bin" ] && [ -f "$dir/BUILD_INFO" ] &&
   [ "$(awk -F'\t' '$1=="commit"{print $2}' "$dir/BUILD_INFO" 2>/dev/null)" = "$want" ]; then
  echo "already built: $bin — use --force to rebuild"
else
  start=$(date +%s)
  cd "$REPO"
  [ -f ./configure ] || die "configure missing after checkout of $TREE"
  export CC=clang CXX=clang++
  echo "configuring plain $TREE -> $prefix"
  if ! CFLAGS="$PLAIN_C" CXXFLAGS="$PLAIN_CXX" LDFLAGS="" \
       ./configure --prefix="$prefix" --disable-shared --disable-docs \
       --disable-openmp --without-perl > /tmp/conf-plain.log 2>&1; then
    tail -n 6 /tmp/conf-plain.log
    die "configure failed"
  fi
  # configure already recorded these flags, including the -pthread that a
  # sanitizer build gets back from the sanitizer runtime and a plain build does
  # not; overriding CFLAGS at make time (as build-san.sh must, to inject
  # instrumentation) would drop it and fail to link utilities/magick.
  make -j"$(nproc)" >/dev/null
  make install >/dev/null

  # fixed's Magick++/fuzz/utils.cc sets ResourceLimits::width/height (e8be814f),
  # so a reproducer linked against that tree must do the same to stay faithful.
  defs=""
  if [ "$TREE" = "fixed" ]; then defs="-DHARNESS_FIXED_LIMITS"; fi
  mkdir -p "$dir"
  clang++ $PLAIN_CXX -std=c++11 $defs \
    -I"$prefix/include/ImageMagick-7" "$here/hand_repro.cc" \
    -o "$dir/repro.new" \
    -DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 \
    "$prefix/lib/libMagick++-7.Q16HDRI.a" \
    "$prefix/lib/libMagickWand-7.Q16HDRI.a" \
    "$prefix/lib/libMagickCore-7.Q16HDRI.a" -lpthread -lm ||
    die "hand reproducer build failed (plain $TREE)"
  mv -f "$dir/repro.new" "$bin"

  {
    printf 'tree\t%s\n' "$TREE"
    printf 'commit\t%s\n' "$want"
    printf 'cflags\t%s\n' "$PLAIN_C"
    printf 'hand\t%s\n' "$bin"
    printf 'built\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'seconds\t%s\n' "$(( $(date +%s) - start ))"
  } > "$dir/BUILD_INFO"
  echo "done: $bin ($(( $(date +%s) - start ))s)"
fi

# Both refs, always.  They are tags on two real upstream commits: `fixed` is
# 665 commits after `vuln` and contains all 62 fix commits of the 68 cases.
v_commit=$(git -C "$REPO" rev-parse "vuln^{commit}")
f_commit=$(git -C "$REPO" rev-parse "fixed^{commit}")
echo
echo "vuln  $v_commit  $(describe_ref "$v_commit")  $(git -C "$REPO" log -1 --format=%cd --date=short "$v_commit")"
echo "fixed $f_commit  $(describe_ref "$f_commit")  $(git -C "$REPO" log -1 --format=%cd --date=short "$f_commit")"
if [ "$v_commit" = "$f_commit" ]; then
  echo "vuln and fixed are the SAME commit ($v_commit) — this image is broken, the two trees must differ"
  exit 1
fi
echo "vuln and fixed are different upstream commits: fixed is $(git -C "$REPO" rev-list --count "$v_commit..$f_commit") commits after vuln"
