#!/bin/bash
# ASan 掃描:每個情境獨立一輪(ASan 沒開 recover,一個 process 只報第一顆)。
# $1=標籤 $2=display $3=額外參數 $4=操作輪數
set -u
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASAN="${ASAN_SRC:-$PROJ/build/asan-src}"
TAG="$1"; DISP="$2"; ARGS="${3:-}"; ROUNDS="${4:-120}"
DEPTH=24

docker run --rm -v "$PROJ:/w" -v "$ASAN:/asan" -w /tmp agos-build bash -c '
set -u
export SDL_AUDIODRIVER=dummy XDG_RUNTIME_DIR=/tmp/x LIBGL_ALWAYS_SOFTWARE=1
export ASAN_OPTIONS="detect_leaks=0:halt_on_error=1:print_stacktrace=1"
mkdir -p /tmp/x /tmp/g
cp /w/run_game/* /tmp/g/ 2>/dev/null || true
rm -f /tmp/g/DUMPVGA /tmp/g/TESTZONE0

Xvfb :'"$DISP"' -screen 0 1600x1100x'"$DEPTH"' &>/dev/null & sleep 3
export DISPLAY=:'"$DISP"'
timeout 600 /asan/scummvm -d1 -p /tmp/g --auto-detect '"$ARGS"' -e null > /tmp/a.log 2>&1 &

W=""; for t in $(seq 1 90); do W=$(xdotool search --class scummvm 2>/dev/null | tail -1); [ -n "$W" ] && break; sleep 1; done
if [ -z "$W" ]; then echo "RESULT '"$TAG"': 視窗沒出現"; tail -5 /tmp/a.log; exit 1; fi
sleep 14
eval $(xdotool getwindowgeometry --shell $W)
gx(){ echo $((X + $1 * WIDTH / 320)); }; gy(){ echo $((Y + $1 * HEIGHT / 200)); }
xdotool mousemove $(gx 160) $(gy 100) click 1; sleep 6

n=0
for i in $(seq 1 '"$ROUNDS"'); do
  pgrep scummvm >/dev/null || break
  case $((RANDOM % 12)) in
    0|1|2) xdotool mousemove $(gx 25) $(gy 100) click 1 ;;
    3)     xdotool mousemove $(gx 12) $(gy 112) click 1 ;;
    4)     xdotool mousemove $(gx 38) $(gy 112) click 1 ;;
    5)     xdotool mousemove $(gx 25) $(gy 125) click 1 ;;
    6)     xdotool mousemove $(gx 25) $(gy 60)  click 1 ;;
    7)     xdotool mousemove $(gx 45) $(gy 60)  click 1 ;;
    8)     xdotool mousemove $(gx 290) $((Y + (20 + RANDOM % 90) * HEIGHT / 200)) click 1 ;;
    9)     xdotool mousemove $(gx 25) $(gy $((22 + RANDOM % 20))) click 1 ;;
    10)    xdotool mousemove $((X + (110 + RANDOM % 160) * WIDTH / 320)) $((Y + (20 + RANDOM % 100) * HEIGHT / 200)) click 1 ;;
    11)    xdotool key Tab ;;
  esac
  n=$i; sleep 0.8
done
sleep 3
pgrep scummvm >/dev/null && S="存活" || S="已結束"
echo "RESULT '"$TAG"': $S (完成 $n / '"$ROUNDS"')"
echo "CHTOVL: $(grep -a CHTOVL /tmp/a.log | head -1)"
if grep -aq "ERROR: AddressSanitizer" /tmp/a.log; then
  echo "*** ASan 命中 ***"
  grep -a -m1 -A12 "ERROR: AddressSanitizer" /tmp/a.log | sed "s/(BuildId:.*//"
else
  echo "ASan: 乾淨"
fi
grep -aiE "Can.t load|跳過此圖" /tmp/a.log | head -3
pkill scummvm 2>/dev/null
cp /tmp/a.log "/w/screenshots/asan_'"$TAG"'.log" 2>/dev/null
chown 1000:1000 "/w/screenshots/asan_'"$TAG"'.log" 2>/dev/null
'
