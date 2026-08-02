# 古堡禁地繁體中文版 v1.2.4

本版修正存檔／讀檔輸入名稱後，Return 或數字鍵盤 Enter 無法確認的問題。根因是
Enter 被 AGOS 全域鍵位映射提前轉成「跳過片頭」動作；現在只保留 Escape 與手把
按鍵跳過片頭，文字輸入介面可正確收到 Return、KP Enter 與 Backspace。

驗證摘要：

- 以真實 GUI 完成存檔與讀檔，Return、KP Enter 均通過。
- 從一般探索遇上藍甲守衛，完成 44 次攻防後回到探索畫面，程序與錯誤記錄正常。
- 重新編譯 Linux x86_64、Windows x64，以及 macOS `x86_64`／`arm64` universal app。
- Linux 與 Windows 實際出貨包已做啟動冒煙測試；macOS 雙架構建置、合併與封裝均由 GitHub Actions 驗證成功。
- Windows ZIP 明確設定 UTF-8 檔名旗標，避免內建解壓縮工具把中文目錄解成亂碼。

GitHub Release 只提供不含原始遊戲資料與 MT-32 ROM 的公開版。請將自己合法持有的
Elvira DOS／GOG 遊戲檔複製到套件的 `game` 目錄；詳細操作請讀各平台封包內說明。
