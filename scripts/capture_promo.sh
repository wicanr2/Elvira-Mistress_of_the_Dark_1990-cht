#!/bin/bash
# 推廣片實機 A/V 擷取:MT-32 原版配樂 + 繁中畫面(片頭古堡禁地→面板→對白→地圖→無敵)。
# 全 docker(agos-capture)。輸出 raw_promo.mp4(gitignore,作 Release 素材)。
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
docker run --rm -v "$PROJ:/work" -w /work agos-capture bash -c '
  export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p /tmp/xdg
  pulseaudio -D --exit-idle-time=-1 2>/dev/null; sleep 1
  pactl load-module module-null-sink sink_name=v >/dev/null
  export SDL_AUDIODRIVER=pulseaudio PULSE_SINK=v
  Xvfb :99 -screen 0 640x400x16 &>/dev/null & sleep 2
  export DISPLAY=:99
  /work/build/scummvm-src/scummvm -p /work/run_game --auto-detect \
     --music-driver=mt32 --extrapath=/work/run_game --no-aspect-ratio &>/tmp/s.log &
  SPID=$!
  sleep 1
  # 同步錄影 68 秒(x11grab 畫面 + pulse 音訊)
  ffmpeg -y -video_size 640x400 -framerate 25 -f x11grab -i :99 \
         -f pulse -i v.monitor -t 68 \
         -c:v libx264 -pix_fmt yuv420p -preset veryfast -crf 20 \
         -c:a aac -b:a 192k /work/dist-all/raw_promo.mp4 &>/tmp/ff.log &
  FFPID=$!
  # ── 動作時間軸(相對錄影起點)──
  sleep 22                                   # 片頭 ACCOLADE→HORROR SOFT→ELVIRA 古堡禁地(有樂)
  xdotool mousemove 320 200 click 1; sleep 3 # 進遊戲
  xdotool mousemove 320 240 click 1; sleep 1 # 走向前
  xdotool mousemove 62 150 click 1; sleep 4  # forward → 房間敘述對白
  xdotool mousemove 320 240 click 1; sleep 1
  xdotool mousemove 62 150 click 1; sleep 5  # 再前進 → NPC 對白
  xdotool key Tab; sleep 4                    # 地圖
  xdotool key Tab; sleep 1                    # 關地圖
  xdotool key F7; sleep 4                     # 無敵模式
  xdotool mousemove 320 240 click 1; sleep 1
  xdotool mousemove 62 150 click 1; sleep 6   # 更多對白
  wait $FFPID
  kill $SPID 2>/dev/null || true
  echo "=== 錄影完成 ==="; ls -la /work/dist-all/raw_promo.mp4
  chown -R '"$(id -u):$(id -g)"' /work/dist-all 2>/dev/null || true
' 2>&1 | tail -4
