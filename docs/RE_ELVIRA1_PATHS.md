# Elvira 1 (GType_ELVIRA1) 引擎路徑逆向報告（patch 對位依據）

> 對 ScummVM v2.9.1 `engines/agos/` 的靜態追蹤。patch 以此為 oracle。

## 1. 文字顯示路徑
- 主路徑：`showMessageFormat`(charset.cpp:100) → `justifyOutPut`(143, word-wrap 對 Elvira1 生效) → `doOutput`(64) → `sendWindow`(window.cpp:274) → **`AGOSEngine::windowPutChar`(charset.cpp:220, 基底版)** → `windowDrawChar`。
- 主敘述文字視窗 = `_windowArray[0]`（`openTextWindow` 開 `openWindow(8,144,24,6,1,0,15)`）。
- **無 `printText` 函式**（等價入口是 showMessageFormat）。
- `printScroll`(script_e1.cpp:1159)：用 window 3，畫存讀檔卷軸底圖，非正常對白視窗。
- **`getBoxSize`/`printBox`/`_boxBuffer` 全是 `AGOSEngine_Waxworks::` 專屬，Elvira 1 完全不碰** → Waxworks patch 那段略過。

## 2. verb / 動作 UI
- ~~verb 字串來自 MENU 資料檔（`_menuBase`），逐字 `windowPutChar` 畫出，資料驅動。~~
  **更正（2026-07-31 實測）：這條對 floppy DOS 版不成立。** `loadMenuFile` 只在
  `getFileName(GAME_MENUFILE) != nullptr` 時才被呼叫（`agos.cpp:1086`），而這個版本的遊戲檔裡
  **沒有 MENU 檔**（`run_game/` 只有 gamepc／tables／*.vga／*.snd），`_menuBase` 是 null，
  `drawMenuStrip` 走不到。畫面右側的 OPEN／CLOSE／EXAMINE… **是烘進 VGA 的美術字**——
  字體與遊戲文字字型明顯不同（同狀態列 STR／RES 那種裝飾字），改字串表無效。
  → 中文化只能疊層覆蓋，且**必須是 hi-res 疊層**：原生 320×200 下每個動詞的判定框只有
  37×7 px、行距 8px，中文縮到 7px 高會糊成一團（不是可讀性打折，是完全不可讀）。
  「直接改一份中文美術圖替換」因此行不通；且對白／物品名／選單是執行期動態文字，
  本來就烘不進美術，疊層機制無論如何要保留。
- Elvira 1 **不觸及** `english_verb_names`（那是 Simon 專屬）；`setVerbText`/`clearName`/`displayName` 對 ELVIRA1 提早 return。
- `menuFor_ww`/`menuFor_e2`/`doMenuStrip` 非 Elvira 1。

## 3. 硬編碼 UI 字串（需源碼 ZH 分支，多有 JA case 可仿照）
| 位置 | 內容 |
|---|---|
| saveload.cpp:243 confirmOverWrite | File already exists / Overwrite / Yes No |
| saveload.cpp:313 userGame | Insert savegame data disk & enter filename |
| saveload.cpp:960 fileError（1021 有 `GType_ELVIRA1` printScroll 分支） | Load failed / File not found 等 |
| script_e1.cpp:955 quit | Are you sure? / Yes No |
| script_e1.cpp:532 oe1_score | "Your score is %d." |
| script_e1.cpp:548/550/554 oe1_look | "In the %s", "Carried by %s" |
| script_e1.cpp:561/1045/1047/1054/1057 lobjFunc | "You can see ", ", ", " and ", ".", "nothing" |
| verb.cpp:399 handleVerbClicked | "I don't understand" |
| rooms.cpp:251-257 | "%s is closed.", "%s is locked.", "You can't go that way." |
| window.cpp:295 waitWindow | "[ OK ]" |
- `printStats`(script_e1.cpp:1171)：只 `writeChar` 印數值；力量/敏捷等**標籤是烘在狀態列底圖**（美術層，非字串）。

## 4. 防拷
- **Elvira 1 引擎內無防拷檢查點**；`_copyProtection` 只在 script.cpp:431（GType_WW o_process id==71）與 Simon 用。
- **設 `_copyProtection=false` 對 Elvira 1 無效**。若 floppy 有手冊防拷 → script/資料層，playtest 時處理。

## 5. hi-res 雙層畫布（Elvira 1 原生 PC98，OR `_chtHires`）
要 OR `_chtHires` 的點：
- agos.cpp:651 `_backBuf`/`_scaleBuf` 建立
- gfx.cpp:1037 getBackendSurface、gfx.cpp:1041 updateBackendSurface（`v1?v1:v0` 合成）
- cursor.cpp:791 initMouse、cursor.cpp:876 drawMousePointer 2x
- charset.cpp:379 windowScroll scaleBuf、window.cpp:72 textMaxLength、window.cpp:111 clearWindow→clearHiResTextLayer
- **`AGOSEngine_Elvira1::windowDrawChar`(charset-fontdata.cpp:3028)**：JA 用 `_sjisFont->drawChar(_scaleBuf)`；CHT 改走 base windowPutChar 攔截(chtDrawBig5OnSurface)，不動此覆寫。

**[HARD] 保持 PC98-only，不可 OR `_chtHires`**：
- **res.cpp:950**：`%.2d.GR2`（PC98 hi-res 圖），OR 會去找不存在的 GR2。
- **vga.cpp:693 convertPC98Image**：PC98 圖解碼。

## 對位摘要
- **A 直接沿用（OR `_chtHires`）**：hi-res 基礎設施（gfx/cursor/agos/charset/window）。
- **B 略過**：getBoxSize/printBox/_boxBuffer（Waxworks 專屬）。
- **C 不適用**：script.cpp:431 防拷改 GType（Elvira 1 無此點）。
- **D verb**：drawMenuStrip 攔截 `_menuBase` 英文→Big5（源碼層映射，不改遊戲檔）。
- **E 硬編碼字串**：saveload/script_e1/verb/rooms/window 加 ZH（多仿 JA）。
