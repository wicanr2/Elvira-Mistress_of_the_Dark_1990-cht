#!/bin/bash
# Linux AppImage 打包。產兩種:
#   dist-all/古堡禁地-CHT-x86_64.AppImage         公開版(patch-only): 引擎 + 繁中字型, 遊戲外掛
#   dist-all/古堡禁地-CHT-FULL-x86_64.AppImage    完整版: 內含遊戲 + MT-32 ROM, 開箱即玩(本機保留)
#
# 公開版 AppRun 啟動時把內建繁中字型/譯表冪等複製到玩家的遊戲夾(字型須與遊戲原檔同夾引擎才載得到),
# 遊戲夾優先序: AppImage 同目錄的 elvira1-game/ → ~/.local/share/elvira1-cht/game/。
# [HARD] cat > AppRun 前先 rm -f 斷 symlink(本腳本 AppDir 全新建, 無此風險, 仍保險處理)。
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
[ -f "$PROJ/build/scummvm-src/scummvm" ] || { echo "!! 先 build scummvm"; exit 1; }
[ -x "$PROJ/.toolcache/appimagetool" ] || { echo "!! 缺 .toolcache/appimagetool"; exit 1; }
mkdir -p "$PROJ/dist-all"

docker run --rm -v "$PROJ:/w" -w /w agos-build bash -c '
  set -e
  export APPIMAGE_EXTRACT_AND_RUN=1

  # ── 共用: 收 scummvm + 非系統 .so + ScummVM 資料 + 繁中字型 ──
  stage_common() {
    local APP="$1"
    rm -rf "$APP"
    mkdir -p "$APP/usr/bin" "$APP/usr/lib" "$APP/usr/share/scummvm" "$APP/usr/share/elvira1-cht"
    cp build/scummvm-src/scummvm "$APP/usr/bin/scummvm"
    ldd "$APP/usr/bin/scummvm" | awk "{print \$3}" | grep -E "^/" | while read lib; do
      case "$lib" in
        *ld-linux*|*libc.so*|*libm.so*|*libpthread*|*libdl.so*|*librt.so*|*libstdc++*|*libgcc_s*) ;;
        *) cp -L "$lib" "$APP/usr/lib/" 2>/dev/null || true ;;
      esac
    done
    for f in scummmodern.zip scummclassic.zip scummremastered.zip gui-icons.dat shaders.dat translations.dat; do
      cp build/scummvm-src/gui/themes/$f "$APP/usr/share/scummvm/" 2>/dev/null || true
    done
    cp build/scummvm-src/dists/engine-data/fonts.dat build/scummvm-src/dists/engine-data/fonts-cjk.dat \
       "$APP/usr/share/scummvm/" 2>/dev/null || true
    # 繁中字型 + 譯表(GPL 衍生, 可散佈)放共用資源夾, AppRun 會用到
    cp fonts/elvira1_zh14.dcjk fonts/elvira1_zh16.dcjk fonts/elvira1_zh24.dcjk \
       translations/elvira1_zh.tab "$APP/usr/share/elvira1-cht/"
    # icon
    convert -size 256x256 "radial-gradient:#4a1c1c-#0c0808" \
      -font /usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc \
      -gravity center -fill "#c9a227" -pointsize 60 -annotate +0-14 "古堡" \
      -fill "#f2ead2" -pointsize 44 -annotate +0+46 "禁地" "$APP/scummvm.png" 2>/dev/null \
      || convert -size 256x256 xc:black "$APP/scummvm.png"
    cat > "$APP/scummvm.desktop" <<"EOF"
[Desktop Entry]
Type=Application
Name=Elvira CHT
Exec=AppRun
Icon=scummvm
Categories=Game;
EOF
  }

  build_one() {  # $1=AppDir  $2=輸出檔名
    ARCH=x86_64 /w/.toolcache/appimagetool --appimage-extract-and-run "$1" "/w/dist-all/$2" 2>&1 | tail -2
  }

  # ══════════ 公開版(patch-only): 遊戲外掛 ══════════
  APP=/tmp/AppDir-pub
  stage_common "$APP"
  rm -f "$APP/AppRun"
  cat > "$APP/AppRun" <<"EOF"
#!/bin/bash
# 古堡禁地 繁中版 AppImage(公開版)。玩家自備 Elvira 遊戲原檔。
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
DATA="${HERE}/usr/share/scummvm"
CHT="${HERE}/usr/share/elvira1-cht"
# 遊戲夾優先序: AppImage 同目錄 elvira1-game/ → ~/.local/share/elvira1-cht/game/
APPDIR_OUT="$(dirname "$(readlink -f "${APPIMAGE:-$0}")")"
if [ -f "${APPDIR_OUT}/elvira1-game/gamepc" ]; then
  GAME="${APPDIR_OUT}/elvira1-game"
else
  GAME="${XDG_DATA_HOME:-$HOME/.local/share}/elvira1-cht/game"
fi
mkdir -p "$GAME"
if [ ! -f "${GAME}/gamepc" ]; then
  echo "──────────────────────────────────────────────"
  echo " 古堡禁地 繁中版 — 尚未偵測到遊戲檔"
  echo " 請把你合法擁有的 Elvira (Floppy/DOS) 全部檔案"
  echo " (gamepc、tables01…、start、*.vga 等) 複製到:"
  echo "   ${GAME}"
  echo " 再重新執行本 AppImage。"
  echo "──────────────────────────────────────────────"
  command -v xmessage >/dev/null && xmessage -center "請把 Elvira 遊戲原檔放進:\n${GAME}\n再重新執行。" 2>/dev/null || true
  exit 1
fi
# 繁中字型/譯表須與遊戲原檔同夾(冪等複製, 不覆蓋玩家可能自備的版本)
for f in elvira1_zh14.dcjk elvira1_zh16.dcjk elvira1_zh24.dcjk elvira1_zh.tab; do
  [ -f "${GAME}/${f}" ] || cp "${CHT}/${f}" "${GAME}/"
done
SAVE="${XDG_DATA_HOME:-$HOME/.local/share}/elvira1-cht/saves"; mkdir -p "$SAVE"
# 無 MT-32 ROM 時 mt32 驅動會跳對話框 → 依 ROM 是否存在自動選 driver
if [ -f "${GAME}/MT32_CONTROL.ROM" ] || [ -f "${GAME}/CM32L_CONTROL.ROM" ]; then MUS=mt32; else MUS=adlib; fi
exec "${HERE}/usr/bin/scummvm" -p "$GAME" \
     --themepath="$DATA" --extrapath="$GAME" --savepath="$SAVE" \
     --music-driver="$MUS" --scaler=normal --scale-factor=2 --no-aspect-ratio --auto-detect "$@"
EOF
  chmod +x "$APP/AppRun"
  build_one "$APP" "古堡禁地-CHT-x86_64.AppImage"

  # ══════════ 完整版: 內含遊戲 + ROM(本機保留) ══════════
  APP=/tmp/AppDir-full
  stage_common "$APP"
  mkdir -p "$APP/usr/share/elvira1-game"
  cp -rL run_game/* "$APP/usr/share/elvira1-game/"
  rm -f "$APP/AppRun"
  cat > "$APP/AppRun" <<"EOF"
#!/bin/bash
# 古堡禁地 繁中版 AppImage(完整版, 已內含遊戲 + MT-32 ROM)。
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
DATA="${HERE}/usr/share/scummvm"
GAME="${HERE}/usr/share/elvira1-game"
SAVE="${XDG_DATA_HOME:-$HOME/.local/share}/elvira1-cht/saves"; mkdir -p "$SAVE"
exec "${HERE}/usr/bin/scummvm" -p "$GAME" \
     --themepath="$DATA" --extrapath="$GAME" --savepath="$SAVE" \
     --music-driver=mt32 --scaler=normal --scale-factor=2 --no-aspect-ratio --auto-detect "$@"
EOF
  chmod +x "$APP/AppRun"
  build_one "$APP" "古堡禁地-CHT-FULL-x86_64.AppImage"

  chown -R '"$(id -u):$(id -g)"' /w/dist-all 2>/dev/null || true
  echo "=== 產物 ==="; ls -lh /w/dist-all/*.AppImage
'
