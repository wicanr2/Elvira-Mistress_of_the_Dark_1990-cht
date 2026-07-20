#!/bin/bash
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
docker run --rm -v "$PROJ:/work" -w /work agos-build-vg bash -c '
  export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p /tmp/xdg; export SDL_AUDIODRIVER=dummy
  Xvfb :99 -screen 0 640x400x16 &>/dev/null & sleep 2
  export DISPLAY=:99
  # valgrind 慢 ~30x:等久一點進場,然後持續密集點(相對變快的遊戲更易觸發 re-entrant)
  ( sleep 420; xdotool mousemove 320 200 click 1; sleep 30
    for r in $(seq 1 40); do for vy in 40 70 100 130 160; do
      xdotool mousemove 600 $vy click 1; sleep 0.4
      xdotool mousemove 448 168 click 1; sleep 0.4; done; done ) &
  cd /work/run_game
  valgrind --error-exitcode=42 --tool=memcheck --track-origins=no \
    /work/build/scummvm-src/scummvm -p /work/run_game --auto-detect --no-aspect-ratio -e null \
    > /work/screenshots/vg.txt 2>&1
  echo "VG_EXIT=$?"
'
