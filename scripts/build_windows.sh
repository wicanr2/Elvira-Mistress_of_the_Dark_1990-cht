#!/bin/bash
# Windows 交叉編(mingw-w64)+ 打包:patched scummvm.exe(含 MT-32/munt)+ DLL + ScummVM 資料 + 繁中字型。
# 產物:
#   dist-all/古堡禁地-CHT-FULL-windows-x64.zip   完整版(含遊戲原檔 + MT-32 ROM, 本機保留, 不可散佈)
#   dist-all/古堡禁地-CHT-windows-x64.zip        引擎版(patch-only, 可公開)
#
# 註:先前 mt32emu 在 mingw 下連結失敗(libmt32.a 的 mt32emu_* 符號拉不進來), 根因是
# 直接在 build/scummvm-src 就地編 —— 原生 Linux build 留下的 ELF .o/.a 沒清乾淨,
# mingw ld 視為 incompatible 而跳過, 但 nm 讀 ELF 正常故看起來「明明有定義」。
# 改成「複製一份源碼樹 + 清掉所有 .o/.a」後 mt32emu 正常連結(同 elvira_2_cht 的作法)。
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
docker run --rm -v "$PROJ:/w" -w /w debian:bookworm-slim bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq g++-mingw-w64-x86-64 mingw-w64-tools g++ make wget tar xz-utils zip unzip \
      libz-mingw-w64-dev ca-certificates file >/dev/null 2>&1
  HOST=x86_64-w64-mingw32
  cd /opt
  wget -q https://github.com/libsdl-org/SDL/releases/download/release-2.30.9/SDL2-devel-2.30.9-mingw.tar.gz
  tar xzf SDL2-devel-2.30.9-mingw.tar.gz
  SDLP=/opt/SDL2-2.30.9/$HOST
  export PATH="$SDLP/bin:$PATH"

  # [關鍵] 用乾淨副本編, 避免 Linux build 的 ELF .o/.a 混入 → mt32emu 連結失敗
  rm -rf /win && cp -r /w/build/scummvm-src /win
  cd /win
  find . -name "*.o" -delete; find . -name "*.a" -delete
  rm -f scummvm scummvm.exe config.mk config.log config.h 2>/dev/null || true

  echo "=== configure (mingw, AGOS only, 含 mt32emu) ==="
  ./configure --host=$HOST --disable-all-engines --enable-engine=agos --enable-release \
    --with-sdl-prefix="$SDLP" \
    --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth \
    --disable-mpeg2 --disable-theoradec --disable-faad --disable-libcurl --disable-timidity 2>&1 | tail -8
  grep -q "^ENABLE_AGOS" config.mk || { echo "!! FATAL: agos 未啟用"; exit 1; }
  grep -q "USE_MT32EMU" config.h    || { echo "!! FATAL: mt32emu 未啟用"; exit 1; }
  echo "  ✓ $(grep "^ENABLE_AGOS" config.mk) / $(grep USE_MT32EMU config.h)"

  echo "=== make ==="; make -j$(nproc) 2>&1 | tail -5
  ls -lh scummvm.exe

  # ── 打包(先做完整版底稿, 再剝成引擎版)──
  OUT=/tmp/古堡禁地-CHT-win64; rm -rf "$OUT"; mkdir -p "$OUT/data" "$OUT/game" "$OUT/saves"
  cp scummvm.exe "$OUT/"
  cp "$SDLP/bin/SDL2.dll" "$OUT/"
  cp "$SDLP/bin/SDL2_net.dll" "$OUT/" 2>/dev/null || true
  for dll in libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll; do
    f=$(find /usr/lib/gcc/$HOST /usr/$HOST -name "$dll" 2>/dev/null | head -1)
    [ -n "$f" ] && cp "$f" "$OUT/" && echo "  + $dll" || echo "  ⚠ 缺 $dll"
  done
  zdll=$(find /usr/$HOST -iname "zlib1.dll" -o -iname "libz-1.dll" 2>/dev/null | head -1)
  [ -n "$zdll" ] && cp "$zdll" "$OUT/" || true

  echo "=== exe DLL 依賴複檢 ==="
  $HOST-objdump -p scummvm.exe | grep "DLL Name" | awk "{print \$3}" | sort -u | while read d; do
    case "$d" in
      KERNEL32*|USER32*|GDI32*|WINMM*|ADVAPI32*|SHELL32*|ole32*|OLEAUT32*|IMM32*|VERSION*|WS2_32*|msvcrt*|SETUPAPI*|RPCRT4*|dwmapi*|WINSPOOL*|COMDLG32*|d3d9*|dxgi*|d3d11*|HID*|CFGMGR32*|comctl32*) ;;
      *) [ -f "$OUT/$d" ] && echo "  ✓ $d" || echo "  ✗ 缺 $d !!" ;;
    esac
  done

  for f in scummmodern.zip scummclassic.zip scummremastered.zip gui-icons.dat shaders.dat translations.dat; do
    cp gui/themes/$f "$OUT/data/" 2>/dev/null || true
  done
  cp dists/engine-data/fonts.dat dists/engine-data/fonts-cjk.dat "$OUT/data/" 2>/dev/null || true

  # 繁中字型 + 譯表
  cp /w/fonts/elvira1_zh16b.dcjk /w/fonts/elvira1_zh16.dcjk /w/fonts/elvira1_zh24.dcjk \
     /w/translations/elvira1_zh.tab "$OUT/game/"

  printf "@echo off\r\ncd /d %%~dp0\r\nif not exist saves mkdir saves\r\nscummvm.exe -p game --themepath=data --extrapath=game --savepath=saves --music-driver=mt32 --scaler=normal --scale-factor=3 --no-aspect-ratio --auto-detect %%*\r\npause\r\n" > "$OUT/play-elvira.bat"

  # ── 引擎版(patch-only, 可公開): 只有引擎 + 字型 ──
  # 註: 沒有 MT-32 ROM 時, ScummVM 會跳「MT 32 emulator cannot be used」對話框要玩家按 OK,
  # 所以公開版預設走 AdLib/OPL, 另附一支 MT-32 啟動器給有 ROM 的玩家。
  ENG=/tmp/古堡禁地-CHT-windows-x64; rm -rf "$ENG"; cp -r "$OUT" "$ENG"
  printf "@echo off\r\ncd /d %%~dp0\r\nif not exist saves mkdir saves\r\nscummvm.exe -p game --themepath=data --extrapath=game --savepath=saves --music-driver=adlib --scaler=normal --scale-factor=3 --no-aspect-ratio --auto-detect %%*\r\npause\r\n" > "$ENG/play-elvira.bat"
  printf "@echo off\r\ncd /d %%~dp0\r\nif not exist saves mkdir saves\r\nscummvm.exe -p game --themepath=data --extrapath=game --savepath=saves --music-driver=mt32 --scaler=normal --scale-factor=3 --no-aspect-ratio --auto-detect %%*\r\npause\r\n" > "$ENG/play-elvira-mt32.bat"
  printf "\xEF\xBB\xBF古堡禁地 (Elvira 1, 1990) 繁體中文版 Windows\r\n\r\n1. 把合法擁有的 Elvira Floppy/DOS 全部檔案複製進 game\\\\ 資料夾。\r\n2. 雙擊 play-elvira.bat 遊玩(AdLib/OPL 配樂)。\r\n3. 想要原版 MT-32 配樂: 把 MT32_CONTROL.ROM / MT32_PCM.ROM 放進 game\\\\,\r\n   改用 play-elvira-mt32.bat 啟動。\r\n\r\n熱鍵: F7 無敵, TAB 地圖; 存檔 Alt+數字, 讀檔 Ctrl+數字。\r\n" > "$ENG/README.txt"
  ( cd /tmp && rm -f /w/dist-all/古堡禁地-CHT-windows-x64.zip && zip -qr /w/dist-all/古堡禁地-CHT-windows-x64.zip "古堡禁地-CHT-windows-x64" )

  # ── 完整版(本機保留): 加遊戲原檔 + MT-32 ROM ──
  cp -rL /w/run_game/* "$OUT/game/" 2>/dev/null || true
  printf "\xEF\xBB\xBF古堡禁地 (Elvira 1, 1990) 繁體中文版 Windows 完整版\r\n\r\n雙擊 play-elvira.bat 即可遊玩(已含遊戲檔與 MT-32 ROM)。\r\n本包含版權素材, 僅供自己保留, 請勿散佈。\r\n\r\n熱鍵: F7 無敵, TAB 地圖; 存檔 Alt+數字, 讀檔 Ctrl+數字。\r\n" > "$OUT/README.txt"
  ( cd /tmp && mv "古堡禁地-CHT-win64" "古堡禁地-CHT-FULL-win64" \
    && rm -f /w/dist-all/古堡禁地-CHT-FULL-windows-x64.zip \
    && zip -qr /w/dist-all/古堡禁地-CHT-FULL-windows-x64.zip "古堡禁地-CHT-FULL-win64" )

  chown -R '"$(id -u):$(id -g)"' /w/dist-all 2>/dev/null || true
  echo "=== 產物 ==="; ls -lh /w/dist-all/*windows*.zip
'
