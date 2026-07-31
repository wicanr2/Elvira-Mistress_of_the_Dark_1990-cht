#!/bin/bash
# 剪接推廣片:Noto CJK 標題卡 + 尾卡 + 正規化 MT-32 配樂 + 拼接。輸出 dist-all/古堡禁地-推廣片.mp4。
set -e
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
docker run --rm -v "$PROJ:/work" -w /work agos-capture bash -c '
  set -e
  F="/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc"
  cd /work/dist-all
  # ── 標題卡 ──
  convert -size 640x400 xc:"#0a0a12" \
    -font "$F" -gravity center \
    -fill "#c8342c" -pointsize 96 -annotate +0-70 "古堡禁地" \
    -fill "#e8e8e0" -pointsize 30 -annotate +0+30 "Elvira — Mistress of the Dark (1990)" \
    -fill "#8a8a95" -pointsize 22 -annotate +0+78 "繁體中文化 · ScummVM AGOS 引擎 patch" \
    titlecard.png
  # ── 尾卡 ──
  convert -size 640x400 xc:"#0a0a12" \
    -font "$F" -gravity center \
    -fill "#c8342c" -pointsize 56 -annotate +0-120 "古堡禁地 繁體中文化" \
    -fill "#e8e8e0" -pointsize 26 -annotate +0-40 "全畫面中文 · 片頭 · 面板 · 對白" \
    -fill "#e8c848" -pointsize 26 -annotate +0+16 "F7 無敵    TAB 探索地圖" \
    -fill "#8a8a95" -pointsize 22 -annotate +0+70 "存讀檔 Alt+數字 / Ctrl+數字" \
    -fill "#6fa8dc" -pointsize 20 -annotate +0+130 "github.com/wicanr2/Elvira-Mistress_of_the_Dark_1990-cht" \
    endcard.png
  echo "cards done"
  # 統一參數
  ENC="-c:v libx264 -pix_fmt yuv420p -preset veryfast -crf 20 -r 25 -c:a aac -b:a 192k -ar 44100 -ac 2"
  # ── 標題卡 5s(配片頭 ACCOLADE 音樂:取 raw 2..7s)──
  ffmpeg -y -loop 1 -t 5 -i titlecard.png \
    -ss 2 -t 5 -i raw_promo.mp4 \
    -filter_complex "[0:v]scale=640:400,fps=25,format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st=4.4:d=0.6[v];[1:a]afade=t=in:st=0:d=0.6[a]" \
    -map "[v]" -map "[a]" $ENC titlecard.mp4 &>/dev/null
  # ── 主體:正規化音量(loudnorm)──
  ffmpeg -y -i raw_promo.mp4 \
    -vf "scale=640:400,fps=25,format=yuv420p" -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
    $ENC body.mp4 &>/dev/null
  # ── 尾卡 5s(配 raw 30..35s 音樂 + 淡出)──
  ffmpeg -y -loop 1 -t 5 -i endcard.png \
    -ss 30 -t 5 -i raw_promo.mp4 \
    -filter_complex "[0:v]scale=640:400,fps=25,format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st=4.2:d=0.8[v];[1:a]afade=t=out:st=3.5:d=1.5[a]" \
    -map "[v]" -map "[a]" $ENC endcard.mp4 &>/dev/null
  # ── 拼接 ──
  printf "file titlecard.mp4\nfile body.mp4\nfile endcard.mp4\n" > concat.txt
  ffmpeg -y -f concat -safe 0 -i concat.txt -c copy "古堡禁地-推廣片.mp4" &>/dev/null
  rm -f titlecard.mp4 body.mp4 endcard.mp4 concat.txt
  echo "=== 完成 ==="; ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "古堡禁地-推廣片.mp4"
  ls -la "古堡禁地-推廣片.mp4"
  chown -R '"$(id -u):$(id -g)"' /work/dist-all 2>/dev/null || true
' 2>&1 | tail -6
