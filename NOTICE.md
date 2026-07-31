# 授權與資產來源

本專案是 patch-only 的中文化：只散布引擎修改（`.patch`）與自製的繁中資產，
遊戲原檔與有版權的第三方資產一律不隨庫散布。

## 引擎

ScummVM 依 GPLv3 授權。`patches/agos-cht.patch` 是對 ScummVM v2.9.1 的修改，
同樣以 GPLv3 釋出；釋出修改過的 binary 時一併提供對應原始碼與修改說明。

## 遊戲原檔

《Elvira: Mistress of the Dark》(1990, Accolade / Horror Soft) 的遊戲檔案有版權，
**不隨本 repo 散布**，請自備你合法擁有的版本。

## 中文字型

repo 內的 `fonts/elvira1_zh*.dcjk` 由 **Noto Sans CJK**（SIL Open Font License 1.1）烘製，
可自由散布。

**倚天中文系統（ETEN 3.53）的點陣字模有版權，不隨本 repo 散布。**
`tools/build_eten_font.py` 只是格式解析與轉檔工具（Big5 分區索引 → DCJK），
需要自備原始字模檔。1990 年 DOS 中文的字形原貌就是倚天，想要那個味道的話：

```bash
# 自備 stdfont.15 / SPCFONT.15（16×15 漢字與全形標點）與 stdfont.24 / SPCFONT.24
# 放進 tools/assets/eten/（此目錄已 gitignore），然後：
python3 tools/build_eten_font.py --size 15 \
    --std tools/assets/eten/stdfont.15 --spc tools/assets/eten/SPCFONT.15 \
    --out fonts/elvira1_zh16.dcjk                       # 對白內文（細）
python3 tools/build_eten_font.py --size 15 --bold \
    --std tools/assets/eten/stdfont.15 --spc tools/assets/eten/SPCFONT.15 \
    --out fonts/elvira1_zh16b.dcjk                      # 動詞面板（加粗）
python3 tools/build_eten_font.py --size 24 \
    --std tools/assets/eten/stdfont.24 --spc tools/assets/eten/SPCFONT.24 \
    --out fonts/elvira1_zh24.dcjk                       # 標題與地圖
```

24 點字模在光碟上是 `STD.24M` 等 ETUNPACK 壓縮檔，解壓工具見姊妹專案
[space_quest4 的 `tools/etunpack.py`](https://github.com/wicanr2)。

烘好後把 `.dcjk` 複製到遊戲資料夾（與 `GAMEPC` 同層）即可，不必重編引擎。

### 為什麼特地支援倚天

TTF 縮到 15–24px 時筆劃比例不對、複雜字會糊成一團；倚天是為這些尺寸手工調過的點陣字，
與 1990 年玩家在 DOS 上看到的中文完全一致。15 點只有偏細的明體一種，所以動詞面板那份
用工具的 `--bold`（水平膨脹 1px）加粗，暗色面板上才有足夠對比；對白內文則維持細版，
否則「爵／籠／罩／鑰」這類筆劃多的字會黏成一塊。

## MT-32 ROM

`MT32_CONTROL.ROM` / `MT32_PCM.ROM` 有版權，不隨本 repo 散布。
沒有 ROM 時啟動器會自動退回 AdLib。
