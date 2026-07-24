#!/bin/bash
# macOS 完整版(含遊戲 + MT-32 ROM, 本機保留、不公開): 把 run_game 的遊戲原檔 + 字型 +
# ROM 注入 CI 產的乾淨 macOS 引擎包(ScummVM.app)。.dmg 需 macOS host, 本機只產 .tar.gz。
# 需先把 CI artifact 的引擎 tar.gz 放進 dist-macos-artifact/(gh run download)。
# 產物: dist-all/古堡禁地-CHT-FULL-macos-universal.tar.gz
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
ENG=$(find "$PROJ/dist-macos-artifact" -name "古堡禁地-CHT-macos-universal.tar.gz" 2>/dev/null | head -1)
[ -n "$ENG" ] || { echo "!! 缺 macOS 引擎 tar.gz(先 gh run download 到 dist-macos-artifact/)"; exit 1; }
echo "使用引擎包: $ENG"

T=/tmp/mac-full; rm -rf "$T"; mkdir -p "$T"
# 本專案 CI tar 是散檔(ScummVM.app / 繁中字型 / 使用說明.txt 直接在根)→ 自建外層資料夾
OUT="$T/古堡禁地-CHT-FULL-macos-universal"; mkdir -p "$OUT/game"
tar xzf "$ENG" -C "$T/"
cp -R "$T/ScummVM.app" "$OUT/"

# 注入完整遊戲原檔 + 字型 + 譯表 + MT-32/CM32L ROM(run_game 已備齊)
cp -rL "$PROJ"/run_game/* "$OUT/game/"

cat > "$OUT/README.txt" <<'EOF'
古堡禁地 (Elvira 1, 1990) 繁體中文版 — macOS 完整版(universal)
================================================================
本包已含遊戲原檔、繁中字型、譯表與 MT-32 ROM, 開箱即玩。
含版權素材, 僅供自己保留, 請勿散佈。

安裝:
1. 對 ScummVM.app 按右鍵 → 打開(首次繞過 Gatekeeper)。
2. 開 ScummVM.app → Add Game → 指向同層的 game/ 資料夾。
3. Graphics 設 Scaler=Normal、Scale=2x(繁中疊層為 640x400 設計;放大用全螢幕)。
4. Audio 設 Music Device = MT-32 Emulator 可得原版配樂(ROM 已在 game/)。
熱鍵: F7 無敵, TAB 地圖; 存檔 Alt+數字, 讀檔 Ctrl+數字。
EOF

( cd "$T" && tar czf "$PROJ/dist-all/古堡禁地-CHT-FULL-macos-universal.tar.gz" "古堡禁地-CHT-FULL-macos-universal" )
rm -rf "$T"
echo "=== 產物(本機保留, 不發佈) ==="; ls -lh "$PROJ/dist-all/古堡禁地-CHT-FULL-macos-universal.tar.gz"
echo "=== 確認含遊戲 + ROM ==="; tar tzf "$PROJ/dist-all/古堡禁地-CHT-FULL-macos-universal.tar.gz" | grep -iE "gamepc|MT32_CONTROL.ROM|elvira1_zh.tab" | head
