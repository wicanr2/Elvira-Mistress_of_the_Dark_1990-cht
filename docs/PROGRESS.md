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

## ⏳ 剩餘
- **verb 面板中文**:✅ 已由 overlay 16px 解決(不需疊層覆蓋美術)。
- **P7 Windows/macOS 打包**:mingw 交叉編(Windows);macOS universal 走 macos-14+Rosetta+自編 SDL2 CI(kb `mac-app-cross-pack`)。
- **P8 推廣片**:原版 MT-32 配樂 + 實機畫面。
- **git push**:公開 repo patch-only(需使用者確認後執行)。
