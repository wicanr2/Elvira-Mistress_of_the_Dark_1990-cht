# 古堡禁地 (Elvira 1) 繁中化 — 進度紀錄

> 更新 2026-07-20。核心中文化**已完成、穩定、可玩**。

## ✅ 已完成(核心)
- **P0 環境**:docker `agos-build`；ScummVM v2.9.1;workplace 骨架。
- **P1 抽字**:`tools/extract_elvira1_text.py`,gamepc string table 689 條(687 非空)。
- **P2 翻譯**:8 subagent 依官方手冊譯名表翻完 **687 條** → `translations/zh.tsv`(0 衝突、0 非 Big5)。愛梅達女爵、STR/RES/DEX/SKI/LIF/EXP、料理雙關法術。
- **P3 字型/譯表**:DCJK 16/24 沿用姊妹版(字模驗證);`elvira1_zh.tab`(687 STAB)。
- **P4 引擎 patch**:`patches/agos-cht.patch`(805 行,乾淨可套)。
- **P5 驗證**:CHTMISS oracle 歸零;實機截圖確認物品描述 + 3 行 NPC 對白中文渲染、語氣保留、穩定。
- **打包**:Linux `dist-all/古堡禁地-CHT-linux-x86_64.tar.gz`(patched scummvm + .so + 字型 + 啟動器)。
- **文件**:README(雜誌風+截圖)、DEV_SETUP、MANUAL_INDEX、RESEARCH、RE_ELVIRA1_PATHS、glossary。
- leak-scan 乾淨、gitignore 就緒(patch-only)。

## ★ 崩潰問題與最終解法(重要)
- **症狀**:Elvira 1 DOS 強套 PC98 640×400 dual-layer hi-res 後,**快速操作時 heap 損壞崩潰**。
- **本質**:佈局相依 **heisenbug**——pre-existing AGOS 繪圖越界(vanilla 也有,撞無害記憶體)+ hires 多配大 buffer 改變堆佈局 → 撞關鍵資料。**gdb/ASan/valgrind/segtrace/padding 全部隱藏或抓不到**(插樁改佈局)。
- **驗證**:vanilla/慢速真人點擊**不崩**,只有超人速連點在動畫中崩。
- **最終解(使用者拍板:放棄 PC98 原生,自建 CJK 路徑)**:遊戲維持**原生 320×200**(穩定),自建直繪:`windowPutChar` CJK 字=2 個 8px 欄(16px 寬)/行距 16px;`chtDrawBig5OnSurface` 直繪 16×16 Big5+描邊。`_chtHires` 保持 false(dual-layer hooks gated-false 保留為文件)。headless 截圖需 `--scaler=normal --scale-factor=2`。
- 詳見 `RE_ELVIRA1_PATHS.md` + 記憶 `agos-dos-hires-backbuf-overflow`。

## ★★ 後續突破:ScummVM overlay 層 hi-res(面板+對白清晰中文,繞過 crash)
放棄 dual-layer 後,原生 320×200 雖穩定但**動詞面板密度太高**(40px 欄、行距 8.5px)塞不下清晰中文。解法:用 **ScummVM `_system` 的 overlay 層**當獨立 hi-res compositor——**完全不碰遊戲渲染路徑**(繞過 crash 根因):
- 進遊戲後 `showOverlay(false)`;每幀在 `displayScreen` 末尾:把穩定的 320×200 遊戲畫面**升採 2x 進 640×400 overlay**(讀完 `lockScreen` 立即 `unlockScreen`),再於其上畫 **16px 動詞面板中文**(升採後行距 17px,清晰容納)+ **無敵指示器**。
- **對白/敘述**:建 overlay 持久文字層 `_chtTextLayer`+`_chtTextCov`,`chtDrawBig5OnSurface` 改畫 **14px 壓縮格**(小巧貼合對話框、不觸框);`clearWindow`/`windowScroll` 加 hook 同步清除/捲動(鏡像原 dual-layer 機制,搬到安全的 overlay 空間)。
- 驗證:面板 13 動詞 + ROOM/INV/WEAPONS 全中文、對白多行清晰、片頭「古堡禁地」;**30 次快速連點(原 crash 觸發模式)無崩潰**。詳見記憶 `agos-overlay-hires-cjk-compositor`。

## ✅ P6 現代友善化(完成)
- **片頭標題**:ELVIRA 遊戲名畫面(zone 27 cutscene, `_mouseHideCount` 閂鎖)下疊「古堡禁地」。
- **動詞面板 + ROOM/INV/WEAPONS 中文**:overlay 16px(見上)。
- **對白 14px 清晰**:overlay 文字層(見上)。
- **無敵(F7)**:每幀強制 Life(`_variableArray[5]`)=99 + overlay「無敵模式」指示器。RE:狀態變數 `[0]`STR`[1]`RES`[2]`DEX`[3]`SKI`[5]`Life`[6]`EXP(`printStats`)。
- **地圖(TAB)**:`me()`→`derefItem(parent)` 取當前房間,`getExitOf_e1(room,d)` BFS 走 N/E/S/W(`_chtVisited` 迷霧),overlay 畫房間框+連線+當前高亮+標題「地圖」。

## ✅ P7 三平台打包 + P8 交付
- **Linux** x86_64 `.tar.gz`:patched scummvm + 非系統 .so + 3 字型 + tab + `play-elvira.sh`(鎖 2x, MT-32)。**實測中文正常**。
- **Windows** x64 `.zip`:mingw 交叉編(`agos-mingw` image + SDL2 2.30.9 mingw)+ 全 DLL(SDL2/SDL2_net/libgcc/libstdc++/libwinpthread)+ ScummVM 資料 + `.bat`(鎖 2x)。**wine 實測中文面板正常**。⚠ munt(mt32emu)mingw 連結頑固(`mt32emu_*` C API 符號 ld 不拉,group/-u/ranlib 皆無效)→ Windows 用 **AdLib/OPL**(原版配樂, 非 MT-32)。
- **macOS** universal `.dmg`/`.tar.gz`:GitHub Actions(macos-14 + Rosetta + 自編 pinned SDL2 2.30.9 + lipo + install_name_tool + codesign, MT-32)。**CI 綠(6 輪迭代)**,主程式與 SDL2 皆 x86_64+arm64 雙弧。踩雷見記憶 `scummvm-macos-ci-lean-static-pitfalls`。
- **推廣片**:`古堡禁地-推廣片.mp4`(78s, MT-32 原版配樂 + 實機中文:片頭/面板/對白/地圖/無敵, Noto CJK 標題卡/尾卡)。
- **GitHub repo**(patch-only, 45 檔, leak-clean)已推 https://github.com/wicanr2/Elvira-Mistress_of_the_Dark_1990-cht
- **leak-scan**:遊戲原檔/ROM/影片/英文全文 dump/手冊掃描皆 gitignore + 打包產物複檢乾淨。

## ⏳ 剩餘 / 待辦

### ★ AGOS 疊層韌性強化(排定要做,優先度高)
玩家 issue #2 的當機是 `chtOverlayCompose` 讀出遊戲 surface 邊界(retina 下
`ow/gw` 整數除法讓取樣索引超出 320×200)。該顆已修,但**同類風險應該系統性掃一遍**,
而不是等玩家一顆一顆撞出來:

- [x] **ASan 全流程掃描**(進行中,已完成主要情境):x4 高倍率、OpenGL 後端(overlay 4 bytes/px)
      各跑一輪 45 回合密集互動(面板點擊 / 地圖開關 / 無敵 / 存檔選單 / 場景切換),
      **兩者皆乾淨**。修復前的對照組一跑就報 `heap-buffer-overflow @ chtOverlayCompose`,
      堆疊與玩家 crash log 完全一致 → 手法有效。
      唯一剩下的一顆在上游 `stretch200To240Nearest`(見下)。
- [x] **cht 程式碼逐點審查**:52 處記憶體操作全數過一遍。疊層繪製類(`chtOvlFill`/
      `chtOvlBlitGlyph`/`chtDrawMap`/`chtTextLayerPut`)都收斂到同一個有 clamp 的
      填色函式;`chtTextLayerClear/Scroll` 的矩形先算後 clamp、長度為負時不動作;
      直繪到遊戲 surface 的兩條路徑(`chtDrawBig5OnSurface`/`chtDrawTitle`)逐像素
      檢查 `screen->w/h`。找到並修掉兩處:**字型載入沒驗 header**(見下)、
      **dirty rect 只 clamp 了兩邊**。
- [x] **防禦性下限**:
      - 字型載入(三個函式)收斂成共用實作 + header 驗證:尺寸自洽、字數合理、
        乘法不溢位、檔案裝得下,任一不成立就略過並印 warning。
        實測餵截斷檔與壞 header 檔,遊戲不再崩潰、只是該字型不啟用。
      - 重複載入時 `free` 舊的緩衝區(原本會洩漏)。
      - `chtDrawTitle` / `chtDrawBig5OnSurface` 的 dirty rect 四邊都 clamp,
        並在空矩形時直接 return。
- [ ] **上游既有越界(待回報 ScummVM)**:ASan 掃到一顆在
      `stretch200To240Nearest`(`backends/graphics/surfacesdl`,做 4:3 比例校正的函式),
      `WRITE of size 1280` 越界。中文化 patch 沒碰這裡,且只在開啟 aspect ratio
      correction 時走到 —— 本專案啟動器預設關閉,不影響玩家。
      待辦:確認 vanilla ScummVM(無 patch)是否也重現,是的話回報上游。

### 其他(選配加值)
- Waxworks 對等的 F8 除霧 / F6 給物(目前有 F7 無敵 + TAB 地圖)。
- munt-mingw 連結若解出可讓 Windows 也上 MT-32(目前 Windows 用 AdLib)。
- ~~發 GitHub Release~~ ✅ 已發 v1.0-cht(三平台 + 推廣片)。
