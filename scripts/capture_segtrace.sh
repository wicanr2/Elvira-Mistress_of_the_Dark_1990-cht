#!/bin/bash
# 全速 LD_PRELOAD segtrace + verb 點擊,崩潰時印 backtrace(不改時序,能重現)。
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
OUT="${1:-seg}"
docker run --rm -v "$PROJ:/work" -w /work agos-build bash -c "
  export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p /tmp/xdg; export SDL_AUDIODRIVER=dummy
  Xvfb :99 -screen 0 640x400x16 &>/dev/null & sleep 2
  export DISPLAY=:99
  ( sleep 15; xdotool mousemove 320 200 click 1; sleep 4
    for vy in 40 55 70 85 100 115 130 145 160; do xdotool mousemove 600 \$vy click 1; sleep 1; xdotool mousemove 448 168 click 1; sleep 1; done
    xdotool mousemove 320 250 click 1; sleep 1 ) &
  cd /work/run_game
  LD_PRELOAD=/work/scripts/segtrace.so /work/build/scummvm-src/scummvm -p /work/run_game --auto-detect --no-aspect-ratio -e null 2>/work/screenshots/${OUT}.txt
  echo EXIT=\$?
"
echo "=== SEGTRACE backtrace ==="
grep -A40 'SEGTRACE' "$PROJ/screenshots/${OUT}.txt" 2>/dev/null | grep -vE 'JOY_|HardwareInput' | head -45
