#!/bin/bash
# 從 Noto Sans CJK 烘 16/24 DCJK Big5 點陣字型(字型與遊戲無關,可直接沿用)。
set -e
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
docker run --rm -v "$PROJ:/work" -w /work agos-build bash -c '
  FONT=$(find /usr/share/fonts -iname "*NotoSansCJK*Regular*" -o -iname "*NotoSansCJKtc*" 2>/dev/null | head -1)
  [ -z "$FONT" ] && FONT=$(find /usr/share/fonts -iname "*NotoSans*CJK*" | head -1)
  echo "font: $FONT"
  python3 tools/build_cjk_font.py --size 16 --font "$FONT" --out fonts/elvira1_zh16.dcjk
  python3 tools/build_cjk_font.py --size 24 --font "$FONT" --out fonts/elvira1_zh24.dcjk
  chown '"$(id -u):$(id -g)"' fonts/elvira1_zh16.dcjk fonts/elvira1_zh24.dcjk 2>/dev/null || true
'
