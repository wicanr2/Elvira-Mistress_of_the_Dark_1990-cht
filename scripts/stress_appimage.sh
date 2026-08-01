#!/bin/bash
# AppImage 壓力測試:長時間隨機操作,偵測崩潰/中止/凍結。
# $1 = 標籤  $2 = display  $3 = gfx 參數(空字串 = 預設 SurfaceSDL)  $4 = 操作輪數
set -u
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="$1"; DISP="$2"; GFX="${3:-}"; ROUNDS="${4:-400}"

docker run --rm -v "$PROJ:/w" -w /tmp agos-build bash -c '
set -u
export SDL_AUDIODRIVER=dummy XDG_RUNTIME_DIR=/tmp/x APPIMAGE_EXTRACT_AND_RUN=1 LIBGL_ALWAYS_SOFTWARE=1
mkdir -p /tmp/x /tmp/t/elvira1-game
cp /w/run_game/* /tmp/t/elvira1-game/ 2>/dev/null || true
rm -f /tmp/t/elvira1-game/*.dcjk /tmp/t/elvira1-game/*.tab /tmp/t/elvira1-game/DUMPVGA
cp "/w/dist-all/古堡禁地-CHT-x86_64.AppImage" /tmp/t/app.AppImage

Xvfb :'"$DISP"' -screen 0 1600x1100x24 &>/dev/null & sleep 3
export DISPLAY=:'"$DISP"'
cd /tmp/t
timeout 1500 ./app.AppImage '"$GFX"' > /tmp/stress.log 2>&1 &
APPPID=$!

W=""; for t in $(seq 1 60); do W=$(xdotool search --class scummvm 2>/dev/null | tail -1); [ -n "$W" ] && break; sleep 1; done
if [ -z "$W" ]; then echo "RESULT '"$TAG"': 視窗沒出現"; tail -5 /tmp/stress.log; exit 1; fi
sleep 12
eval $(xdotool getwindowgeometry --shell $W)
gx(){ echo $((X + $1 * WIDTH / 320)); }; gy(){ echo $((Y + $1 * HEIGHT / 200)); }

xdotool mousemove $(gx 160) $(gy 100) click 1; sleep 5

done_n=0
for i in $(seq 1 '"$ROUNDS"'); do
  pgrep -f app.AppImage >/dev/null || break
  case $((RANDOM % 12)) in
    0|1|2) xdotool mousemove $(gx 25) $(gy 100) click 1 ;;    # 前進
    3)     xdotool mousemove $(gx 12) $(gy 112) click 1 ;;    # 左
    4)     xdotool mousemove $(gx 38) $(gy 112) click 1 ;;    # 右
    5)     xdotool mousemove $(gx 25) $(gy 125) click 1 ;;    # 後
    6)     xdotool mousemove $(gx 25) $(gy 60)  click 1 ;;    # UP
    7)     xdotool mousemove $(gx 45) $(gy 60)  click 1 ;;    # DOWN
    8)     xdotool mousemove $(gx 290) $((Y + (20 + RANDOM % 90) * HEIGHT / 200)) click 1 ;;  # 右側動詞欄
    9)     xdotool mousemove $(gx 25) $(gy $((22 + RANDOM % 20))) click 1 ;;                   # 左側 房間/物品/武器
    10)    xdotool mousemove $((X + (110 + RANDOM % 160) * WIDTH / 320)) $((Y + (20 + RANDOM % 100) * HEIGHT / 200)) click 1 ;;  # 遊戲畫面內
    11)    xdotool key Tab ;;                                  # 地圖開/關
  esac
  done_n=$i
  sleep 0.9
done

sleep 3
if pgrep -f app.AppImage >/dev/null; then STATE="存活"; else STATE="已結束"; fi
echo "RESULT '"$TAG"': $STATE (完成 $done_n / '"$ROUNDS"' 次操作)"
echo "--- 錯誤/警告 ---"
grep -aiE "ERROR|Can.t load|assert|segmentation|abort|跳過此圖" /tmp/stress.log | sort | uniq -c | head -10
if ! grep -aqiE "ERROR|Can.t load|assert|segmentation|abort" /tmp/stress.log; then echo "  無"; fi
echo "--- log 尾端 ---"
tail -4 /tmp/stress.log
pkill -f app.AppImage 2>/dev/null
cp /tmp/stress.log "/w/screenshots/stress_'"$TAG"'.log" 2>/dev/null
chown 1000:1000 "/w/screenshots/stress_'"$TAG"'.log" 2>/dev/null
'
