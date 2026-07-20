# 開發環境設定 — 古堡禁地 (Elvira 1) 繁中化

只需 **docker + git**。遊戲原檔（版權）自備。

## 一鍵建置

```bash
bash scripts/dev_setup.sh          # 建 image → 取 ScummVM v2.9.1 → 套 patch → 編譯
bash scripts/dev_setup.sh --rebuild-only   # 只重編(已有 scummvm-src)
```

完成後把你合法擁有的 **Elvira - Mistress of the Dark (Floppy/DOS)** 全部檔案（`gamepc`、`tables01…`、`start`、`*.vga` 等）複製進 `run_game/`。繁中資產（`elvira1_zh16.dcjk`／`elvira1_zh.tab`）由 dev_setup 自動放入。

```bash
# 本機遊玩
build/scummvm-src/scummvm -p run_game --auto-detect --music-driver=mt32
```

## 目錄佈局

| 路徑 | 內容 |
|---|---|
| `patches/agos-cht.patch` | 引擎繁中 patch（全 `// 非上游` gate；`git diff` 產生）|
| `patches/cht_fusion.cpp/.h` | 繁中載入器（字型／譯表）|
| `tools/extract_elvira1_text.py` | 抽字（gamepc string table 689 條）|
| `tools/build_cjk_font.py` | 從 TTF 烘 DCJK Big5 點陣字型 |
| `tools/build_translation.py` | zh.tsv → STAB 二進位譯表 |
| `translations/glossary.md` | 權威譯名表（官方手冊為據）|
| `translations/zh.tsv` | 687 條完整譯文 |
| `fonts/elvira1_zh16/24.dcjk` | 16／24px Big5 點陣字型 atlas |
| `scripts/` | build／capture／打包腳本 |
| `docs/` | 研究筆記、RE 報告、進度 |

## 常見工作流

**改譯文 → 重烘 .tab**
```bash
# 編輯 translations/zh.tsv 後
python3 tools/build_translation.py translations/zh.tsv run_game/elvira1_zh.tab
```

**改引擎 → 重生 patch**
```bash
bash scripts/build_scummvm.sh                          # 重編
cd build/scummvm-src && git diff HEAD -- engines/agos/ > ../../patches/agos-cht.patch
```

**headless 截圖驗證**
```bash
bash scripts/capture.sh 0 18 shot     # [HARD] Xvfb x16 + SDL dummy + --scaler 2x(320x200 才填滿)
# 截圖在 screenshots/,用影像檢視
```

## 引擎架構要點

- **文字注入**：`string.cpp getStringPtrByID` 依 stringId 查 Big5 譯表（A/B/C 類文字共用 chokepoint）。CHTMISS oracle：`-d1` 時 log「請求了但譯表沒有」的英文 id，驗收應歸零。
- **自建 CJK 路徑（非 PC98 dual-layer）**：Elvira 1 DOS 強套 640×400 dual-layer 會觸發佈局相依 heisenbug 崩潰（見 `docs/RE_ELVIRA1_PATHS.md` / `PROGRESS.md`）。故改「遊戲維持原生 320×200 + 自建直繪」：`charset.cpp windowPutChar` 把 CJK 字排成 2 個 8px 欄（16px 寬）、行距 16px；`charset-fontdata.cpp chtDrawBig5OnSurface` 直繪 16×16 Big5 + 描邊到螢幕。ScummVM 顯示層放大後清晰。
- **硬編碼 UI ZH 分支**：`saveload.cpp`（存讀檔錯誤）、`verb.cpp`（我不懂）、`rooms.cpp`（開關鎖／方向）、`script_e1.cpp`（分數／查看／物品列表）。
- **verb 面板**（OPEN/EXAMINE…）是烘進 VGA 美術（`_menuBase` 為 null，無 MENU 檔）→ 若要中文需疊層覆蓋（未做，見待辦）。

## 延伸

- 三平台打包：見 `scripts/build_*.sh`（Linux 已驗；Windows/macOS 待補）。
- 現代友善化（地圖／無敵／標題中文）：需先 RE Elvira 1 變數（STR/RES/DEX/SKI/LIF/EXP，與 Elvira 2 不同）。
