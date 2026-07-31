#!/bin/bash
# 跑 N 次密集互動 + segtrace,任一次崩就印 backtrace(beat heisenbug 機率性)。
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for i in 1 2 3 4; do
  docker run --rm -v "$PROJ:/work" -w /work agos-build bash -c "
    export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p /tmp/xdg; export SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x400x16 &>/dev/null & sleep 2
    export DISPLAY=:99
    ( sleep 13; xdotool mousemove 320 200 click 1; sleep 3
      for r in 1 2 3; do for vy in 40 55 70 85 100 115 130 145 160; do
        xdotool mousemove 600 \$vy click 1; sleep 0.25
        xdotool mousemove 448 168 click 1; sleep 0.25
        xdotool mousemove 320 250 click 1; sleep 0.25; done; done
      sleep 2 ) &
    cd /work/run_game
    timeout 55 env LD_PRELOAD=/work/scripts/segtrace.so /work/build/scummvm-src/scummvm -p /work/run_game --auto-detect --no-aspect-ratio -e null 2>/work/screenshots/segm.txt
  " >/dev/null 2>&1
  if grep -q 'SEGTRACE' "$PROJ/screenshots/segm.txt" 2>/dev/null; then
    echo "=== 第 $i 次崩潰,backtrace: ==="
    grep -A40 'SEGTRACE' "$PROJ/screenshots/segm.txt" | grep -vE 'JOY_|HardwareInput'
    exit 0
  fi
  echo "第 $i 次未崩"
done
echo "4 次皆未在 segtrace 下重現(heisenbug 佈局)"
