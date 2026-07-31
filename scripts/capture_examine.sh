#!/bin/bash
# 互動驗證:啟動→等 18s 進場→對數個場景物件做 EXAMINE(檢視)→截圖看 Big5 對白渲染。
set -e
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-exam}"
docker run --rm -v "$PROJ:/work" -w /work agos-build bash -c "
  export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p /tmp/xdg
  export SDL_AUDIODRIVER=dummy
  Xvfb :99 -screen 0 640x400x16 &>/dev/null & sleep 2
  export DISPLAY=:99
  cd /work/run_game
  /work/build/scummvm-src/scummvm -p /work/run_game --auto-detect -d1 \
     --no-aspect-ratio -e null &>/work/screenshots/${OUT}.log &
  SPID=\$!
  sleep 14
  # 點一下跳過標題進場
  xdotool mousemove 320 200 click 1; sleep 4
  import -window root /work/screenshots/${OUT}_0boot.png 2>/dev/null || true
  EXAMINE() { xdotool mousemove 600 110 click 1; sleep 1; xdotool mousemove \$1 \$2 click 1; sleep 2; }
  # EXAMINE 牆上告示牌
  EXAMINE 448 168; import -window root /work/screenshots/${OUT}_1sign.png 2>/dev/null || true
  # EXAMINE 大門
  EXAMINE 320 150; import -window root /work/screenshots/${OUT}_2door.png 2>/dev/null || true
  # EXAMINE 樹
  EXAMINE 505 130; import -window root /work/screenshots/${OUT}_3tree.png 2>/dev/null || true
  # EXAMINE 左側石頭
  EXAMINE 150 175; import -window root /work/screenshots/${OUT}_4rock.png 2>/dev/null || true
  kill \$SPID 2>/dev/null || true
  chown -R $(id -u):$(id -g) /work/screenshots 2>/dev/null || true
"
echo '=== CHT / CHTMISS 摘要 ==='
grep -iE 'CHTMISS|CHT:' "$PROJ/screenshots/${OUT}.log" 2>/dev/null | tail -6 || true
