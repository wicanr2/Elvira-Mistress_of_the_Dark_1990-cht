#!/bin/bash
# 編譯 patched ScummVM(只留 AGOS 引擎 + 繁中 patch)。docker-first。
set -euo pipefail
SRC="/home/anr2/scummvm/elvira_cht/workplace/build/scummvm-src"
docker run --rm -v "$SRC:/src" -w /src agos-build bash -c "
  set -e
  [ -f config.mk ] || ./configure --disable-all-engines --enable-engine=agos --enable-release \
     --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth \
     --disable-mpeg2 --disable-theoradec --disable-faad --disable-libcurl 2>&1 | tail -6
  make -j\$(nproc) 2>&1 | tail -15
  chown $(id -u):$(id -g) scummvm 2>/dev/null || true
  ls -lh scummvm
"
