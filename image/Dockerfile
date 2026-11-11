# ImageMagick ARVO baseline, 2018-01-16 — delivery image
#
# Base image supplies the 2018-era OSS-Fuzz toolchain (clang 6.0.0, libc++,
# MSan libc++, ImageMagick's build dependencies) plus the full upstream history.
#
# Build (context = the deliver/ directory):
#   docker build -f image/Dockerfile -t im-arvo:2018-01-16 deliver
#
# The image ships the git repo with two refs, and both are real upstream
# commits — nothing is constructed here, no patch files exist anywhere:
#   vuln  = 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a  (2018-01-16,
#           git describe = 7.0.7-21-82-g13ffeab)
#   fixed = 8239e79ee4c8cc34034838eefe4f34bab02c5fc7  (2018-03-20,
#           git describe = 7.0.7-27-24-g8239e79, 665 commits after vuln,
#           contains all 62 fix commits of the 68 ARVO cases)
# The two tags only give stable names to commits that already exist in the
# history, so `git log`, `git blame` and `git diff vuln fixed` all work against
# upstream.
FROM n132/arvo:42518038-vul@sha256:fce885bd28185e1f08512fad0085714b32526187f7041fb7941965e8fd8de124

COPY payload/ /payload/
COPY scripts/ /opt/imdt/

RUN set -eux; \
    cd /src/imagemagick; \
    git tag -f vuln  13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a; \
    git tag -f fixed 8239e79ee4c8cc34034838eefe4f34bab02c5fc7; \
    test "$(git rev-parse vuln)"  = 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a; \
    test "$(git rev-parse fixed)" = 8239e79ee4c8cc34034838eefe4f34bab02c5fc7; \
    git checkout -q --detach vuln; \
    git clean -xffdq; \
    rm -rf /out/* /work/*

RUN chmod +x /opt/imdt/*.sh /opt/imdt/imdt

# The single reproducer, built here for both trees and all three sanitizers:
#   /out/hand-address-vuln/repro   /out/hand-address-fixed/repro
#   /out/hand-undefined-vuln/repro /out/hand-undefined-fixed/repro
#   /out/hand-memory-vuln/repro    /out/hand-memory-fixed/repro
# hand_repro.cc is a hand-written driver (no fuzz target, no libFuzzer runtime):
# it replicates the harness contract — forced format, Blob read + write back,
# swallowed Magick::Exception, utils.cc limits, plus width/height(2048) on the
# fixed tree (commit e8be814f, in fixed's history) via -DHARNESS_FIXED_LIMITS;
# the vuln tree builds without it.
# /work is emptied afterwards (same layer) so the shipped image stays small and
# `imdt build-before|build-after` exercises the real build path from scratch.
# The reset to `vuln` is forced (-f): configure and PerlMagick's Makefile.PL
# rewrite tracked files (utilities/*.1, PerlMagick/quantum/quantum.pm), and the
# two real commits differ in those files, so a plain checkout refuses.
RUN set -eux; \
    for tree in vuln fixed; do \
      for san in address undefined memory; do \
        /opt/imdt/build-san.sh --tree "$tree" --san "$san" --force; \
      done; \
    done; \
    cd /src/imagemagick; \
    git checkout -q -f --detach vuln; \
    git clean -xffdq; \
    rm -rf /work/*

ENV REPO=/src/imagemagick \
    PAYLOAD=/payload \
    OUTROOT=/out \
    PATH=/opt/imdt:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/out
WORKDIR /opt/imdt

# Sanity check and final cleanup: the two refs resolve to the real upstream
# commits, the worktree is pristine and all six hand reproducers are present.
# Nothing here expects an encoder_*_fuzzer.  configure rewrites the tracked
# utilities/*.1 man pages, so the reset to `vuln` belongs in this layer (it also
# keeps the build layer above cacheable).
RUN set -eux; \
    cd /src/imagemagick; \
    test "$(git rev-parse --verify vuln^{commit})"  = 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a; \
    test "$(git rev-parse --verify fixed^{commit})" = 8239e79ee4c8cc34034838eefe4f34bab02c5fc7; \
    git merge-base --is-ancestor vuln fixed; \
    git reset -q --hard vuln; \
    git clean -xffdq; \
    test -z "$(git status --porcelain)"; \
    for t in vuln fixed; do \
      for s in address undefined memory; do \
        test -x "/out/hand-$s-$t/repro"; \
      done; \
    done; \
    test -z "$(ls -A /work)"

CMD ["/bin/bash"]
