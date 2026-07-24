#!/bin/bash
# Linux 引擎包(patch-only 可公開散佈):patched ScummVM(AGOS+CHT) + 收非系統 .so + 繁中字型 + 啟動器。
# 玩家自備 Elvira 原檔放進 game/ 即可玩。產物: dist-all/古堡禁地-CHT-linux-x86_64.tar.gz
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
[ -f "$PROJ/build/scummvm-src/scummvm" ] || { echo "!! 先 build scummvm"; exit 1; }
mkdir -p "$PROJ/dist-all"
docker run --rm -v "$PROJ:/w" -w /w agos-build bash -c '
  set -e
  OUT=/tmp/古堡禁地-CHT-linux-x86_64; rm -rf "$OUT"
  mkdir -p "$OUT/bin" "$OUT/lib" "$OUT/data" "$OUT/game" "$OUT/saves"
  cp build/scummvm-src/scummvm "$OUT/bin/scummvm"
  # 收非系統 .so
  ldd "$OUT/bin/scummvm" | awk "{print \$3}" | grep -E "^/" | while read lib; do
    case "$lib" in
      *ld-linux*|*libc.so*|*libm.so*|*libpthread*|*libdl.so*|*librt.so*|*libstdc++*|*libgcc_s*) ;;
      *) cp -L "$lib" "$OUT/lib/" 2>/dev/null || true ;;
    esac
  done
  # ScummVM 執行期資料(主題/字型)
  for f in scummmodern.zip scummclassic.zip scummremastered.zip gui-icons.dat shaders.dat translations.dat; do
    cp build/scummvm-src/gui/themes/$f "$OUT/data/" 2>/dev/null || true
  done
  cp build/scummvm-src/dists/engine-data/fonts.dat build/scummvm-src/dists/engine-data/fonts-cjk.dat "$OUT/data/" 2>/dev/null || true
  # 繁中字型+譯表(GPL 衍生, 可散佈)。14px=對白 16px=面板 24px=標題/地圖
  cp fonts/elvira1_zh14.dcjk fonts/elvira1_zh16.dcjk fonts/elvira1_zh24.dcjk translations/elvira1_zh.tab "$OUT/game/"
  # 啟動器
  cat > "$OUT/play-elvira.sh" <<"EOF"
#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib:$LD_LIBRARY_PATH"
# [重要] 鎖 --scale-factor=2:繁中 overlay 疊層(面板/對白)座標為 640x400 設計, 需 2x 才對齊。
# 想放大用 ScummVM 全螢幕(它縮放最終 640x400 影像、疊層仍對齊)。
"$HERE/bin/scummvm" -p "$HERE/game" --themepath="$HERE/data" --extrapath="$HERE/game" \
  --savepath="$HERE/saves" --music-driver="${ELVIRA_MUSIC:-adlib}" --scaler=normal --scale-factor=2 \
  --no-aspect-ratio --auto-detect "$@"
EOF
  chmod +x "$OUT/play-elvira.sh"
  # MT-32 版啟動器(需自備 ROM)。沒有 ROM 時 ScummVM 會跳對話框要玩家按 OK, 故公開版預設 AdLib。
  cat > "$OUT/play-elvira-mt32.sh" <<"EOF"
#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
ELVIRA_MUSIC=mt32 exec "$HERE/play-elvira.sh" "$@"
EOF
  chmod +x "$OUT/play-elvira-mt32.sh"
  cat > "$OUT/README.txt" <<"EOF"
古堡禁地 (Elvira - Mistress of the Dark, 1990) 繁體中文版
========================================================
1. 把你合法擁有的 Elvira(Floppy/DOS) 全部檔案(gamepc、tables01…、start、*.vga 等)
   複製進 game/ 資料夾。
2. 執行 ./play-elvira.sh 即可遊玩(AdLib/OPL 配樂)。
3. 想要原版 MT-32 配樂: 把 MT32_CONTROL.ROM / MT32_PCM.ROM 放進 game/,
   改用 ./play-elvira-mt32.sh 啟動。
畫面偏小可在 ScummVM 設定調整縮放(Graphics → Scaler)。
EOF
  ( cd /tmp && tar czf /w/dist-all/古堡禁地-CHT-linux-x86_64.tar.gz "古堡禁地-CHT-linux-x86_64" )
  chown -R '"$(id -u):$(id -g)"' /w/dist-all 2>/dev/null || true
  echo "=== 產物 ==="; ls -lh /w/dist-all/古堡禁地-CHT-linux-x86_64.tar.gz
'
