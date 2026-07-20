#!/bin/bash
# Windows 交叉編(mingw-w64)+ 打包 zip:patched scummvm.exe + DLL + ScummVM 資料 + 繁中字型 + .bat。
# 產物: dist-all/古堡禁地-CHT-windows-x64.zip。玩家自備 Elvira 原檔放進 game/。
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
docker run --rm -v "$PROJ:/w" -w /w agos-mingw bash -c '
  set -e
  export PATH=/usr/x86_64-w64-mingw32/bin:$PATH
  cd build/scummvm-src
  echo "=== configure (mingw) ==="
  # 註:mingw 交叉編下 ScummVM 內建 munt(mt32emu)的 C interface 有連結問題(libmt32.a 的
  # mt32emu_* 符號 ld 不拉入, group/-u/ranlib 皆無效)→ Windows 版改用 AdLib/OPL(nuked-opl 內建,
  # 與 munt 無關, 仍是原版遊戲配樂)。Linux/macOS 版保留 MT-32。
  ./configure --host=x86_64-w64-mingw32 --disable-all-engines --enable-engine=agos --enable-release \
    --disable-mt32emu \
    --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth --disable-fluidlite \
    --disable-mpeg2 --disable-theoradec --disable-faad --disable-libcurl --disable-a52 \
    --disable-mikmod --disable-gif --disable-jpeg --disable-png --disable-freetype2 \
    --disable-zlib --disable-tts --disable-discord --disable-sndio --disable-timidity \
    --disable-sparkle --disable-retrowave --disable-readline --disable-libunity 2>&1 | tail -8
  echo "  (Windows 版用 AdLib/OPL, 不含 mt32emu)"
  echo "=== make ==="
  make -j$(nproc) 2>&1 | tail -6
  ls -lh scummvm.exe
  # ── 打包 ──
  OUT=/tmp/古堡禁地-CHT-windows-x64; rm -rf "$OUT"; mkdir -p "$OUT/data" "$OUT/game" "$OUT/saves"
  cp scummvm.exe "$OUT/"
  # 必要 DLL: SDL2 + SDL2_net + mingw runtime
  cp /usr/x86_64-w64-mingw32/bin/SDL2.dll "$OUT/"
  cp /usr/x86_64-w64-mingw32/bin/SDL2_net.dll "$OUT/" 2>/dev/null || true
  for dll in libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll; do
    f=$(find /usr/lib/gcc/x86_64-w64-mingw32 /usr/x86_64-w64-mingw32 -name "$dll" 2>/dev/null | head -1)
    [ -n "$f" ] && cp "$f" "$OUT/" && echo "  + $dll" || echo "  ⚠ 缺 $dll"
  done
  # 用 objdump 複檢 exe 依賴的 DLL 都在(排除系統 DLL)
  echo "=== exe DLL 依賴複檢 ==="
  x86_64-w64-mingw32-objdump -p scummvm.exe | grep "DLL Name" | awk "{print \$3}" | while read d; do
    case "$d" in
      KERNEL32*|USER32*|GDI32*|WINMM*|ADVAPI32*|SHELL32*|ole32*|OLEAUT32*|IMM32*|VERSION*|WS2_32*|msvcrt*|SETUPAPI*|RPCRT4*|dwmapi*|WINSPOOL*|COMDLG32*|d3d9*|dxgi*|d3d11*|HID*|CFGMGR32*|comctl32*) ;;
      *) [ -f "$OUT/$d" ] && echo "  ✓ $d" || echo "  ✗ 缺 $d !!" ;;
    esac
  done
  # ScummVM 執行期資料(themes/字型)
  for f in scummmodern.zip scummclassic.zip scummremastered.zip gui-icons.dat shaders.dat translations.dat; do
    cp gui/themes/$f "$OUT/data/" 2>/dev/null || true
  done
  cp dists/engine-data/fonts.dat dists/engine-data/fonts-cjk.dat "$OUT/data/" 2>/dev/null || true
  # 繁中字型 + 譯表
  cp /w/fonts/elvira1_zh14.dcjk /w/fonts/elvira1_zh16.dcjk /w/fonts/elvira1_zh24.dcjk /w/translations/elvira1_zh.tab "$OUT/game/"
  # .bat 啟動器(鎖 2x)
  printf "@echo off\r\ncd /d %%~dp0\r\nscummvm.exe -p game --themepath=data --extrapath=game --savepath=saves --music-driver=adlib --scaler=normal --scale-factor=2 --no-aspect-ratio --auto-detect %%*\r\npause\r\n" > "$OUT/play-elvira.bat"
  # README
  printf "\xEF\xBB\xBF古堡禁地 (Elvira 1, 1990) 繁體中文版 Windows\r\n1. 把合法擁有的 Elvira Floppy/DOS 全部檔案複製進 game\\\\ 資料夾。\r\n2. 雙擊 play-elvira.bat 遊玩。\r\n配樂: Windows 版用 AdLib/OPL(原版遊戲配樂)。想要 MT-32 配樂請用 Linux/macOS 版。\r\n熱鍵: F7 無敵, TAB 地圖; 存檔 Alt+數字, 讀檔 Ctrl+數字。\r\n" > "$OUT/README.txt"
  ( cd /tmp && zip -qr /w/dist-all/古堡禁地-CHT-windows-x64.zip "古堡禁地-CHT-windows-x64" )
  chown -R '"$(id -u):$(id -g)"' /w/dist-all 2>/dev/null || true
  echo "=== 產物 ==="; ls -lh /w/dist-all/古堡禁地-CHT-windows-x64.zip
'
