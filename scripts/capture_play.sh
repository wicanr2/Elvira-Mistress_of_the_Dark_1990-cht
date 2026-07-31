#!/bin/bash
# 長 playthrough:進場後大量點擊(動詞+物件+導航)觸發 getStringPtrByID,收集 CHTMISS oracle + 截圖。
set -e
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-play}"
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
  xdotool mousemove 320 200 click 1; sleep 3   # 跳過標題
  shot(){ import -window root /work/screenshots/${OUT}_\$1.png 2>/dev/null || true; }
  V(){ xdotool mousemove \$1 \$2 click 1; sleep 1; }   # 點動詞
  # 逐個動詞 × 物件,盡量觸發描述文字
  for vy in 40 55 70 85 100 115 130 145 160; do   # 右側動詞各列
    V 600 \$vy
    V 448 168        # 牆上告示
    shot v\$vy
    V 600 \$vy
    V 505 130        # 樹
    shot t\$vy
  done
  # INV 檢視攜帶物
  V 60 68; shot inv
  # 導航前進幾步再 look
  V 320 250; sleep 1; V 320 250; sleep 1; shot nav
  kill \$SPID 2>/dev/null || true
  chown -R $(id -u):$(id -g) /work/screenshots 2>/dev/null || true
"
echo '=== CHTMISS 去重(完整性 oracle,應接近歸零)==='
grep -oiE 'CHTMISS id=[0-9]+: .*' "$PROJ/screenshots/${OUT}.log" 2>/dev/null | sort -u | head -40
echo "--- CHTMISS 總筆數(去重) ---"
grep -oiE 'CHTMISS id=[0-9]+' "$PROJ/screenshots/${OUT}.log" 2>/dev/null | sort -u | wc -l
