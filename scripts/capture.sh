#!/bin/bash
# headless 截圖驗證。用法: capture.sh <boot_param> <秒數> <輸出前綴> [每2秒執行的按鍵指令]
# [HARD] Xvfb x16(x8 會炸 render driver)+ SDL_AUDIODRIVER=dummy。
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
BOOT="${1:-0}"; SECS="${2:-8}"; OUT="${3:-shot}"
mkdir -p "$PROJ/screenshots"
docker run --rm -v "$PROJ:/work" -w /work agos-build bash -c "
  export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p /tmp/xdg
  export SDL_AUDIODRIVER=dummy
  Xvfb :99 -screen 0 640x400x16 &>/dev/null & sleep 2
  export DISPLAY=:99
  cd /work/run_game
  /work/build/scummvm-src/scummvm -p /work/run_game --auto-detect -d1 \
     --scaler=normal --scale-factor=2 --no-aspect-ratio -e null --boot-param=$BOOT &>/work/screenshots/${OUT}.log &
  SPID=\$!
  sleep $SECS
  for i in 1 2 3 4 5 6 7 8; do
    import -window root /work/screenshots/${OUT}_\$i.png 2>/dev/null || xwd -root -silent | convert xwd:- /work/screenshots/${OUT}_\$i.png 2>/dev/null || true
    ${4:-true}
    sleep 2
  done
  kill \$SPID 2>/dev/null || true
  chown -R $(id -u):$(id -g) /work/screenshots 2>/dev/null || true
"
echo '=== CHTMISS / CHT log 摘要 ==='
grep -iE 'CHT|CHTMISS|繁中' "$PROJ/screenshots/${OUT}.log" 2>/dev/null | head -20 || true
