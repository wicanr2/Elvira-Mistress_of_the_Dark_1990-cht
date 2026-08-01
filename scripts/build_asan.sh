#!/bin/bash
# 用目前的原始碼樹編一份 ASan 版(獨立目錄,不動出貨用的 build 樹)。
set -e
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASAN="${ASAN_SRC:-$PROJ/build/asan-src}"

mkdir -p "$(dirname "$ASAN")"
docker run --rm -v "$PROJ:/w" -v "$(dirname "$ASAN"):/out" agos-build bash -c '
set -e
rm -rf /out/asan-src && mkdir -p /out/asan-src
cd /w/build/scummvm-src
# 只複製原始碼,不帶既有的 .o/.a(混到會出事,見 AGOS_PITFALLS 平台章節)
tar cf - --exclude="*.o" --exclude="*.a" --exclude=".git" --exclude="scummvm" . | tar xf - -C /out/asan-src
cd /out/asan-src
rm -f config.mk config.h
CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -g -O1" \
LDFLAGS="-fsanitize=address" \
./configure --disable-all-engines --enable-engine=agos \
   --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth \
   --disable-mpeg2 --disable-theoradec --disable-faad --disable-libcurl 2>&1 | tail -3
make -j$(nproc) 2>&1 | grep -iE " error|Error 1" | head -5
ls -lh scummvm
chown -R 1000:1000 /out/asan-src
'
