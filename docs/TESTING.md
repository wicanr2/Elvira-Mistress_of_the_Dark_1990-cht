# 怎麼測《古堡禁地》繁中版

這個專案的 bug 有個共通特性:**多半不會當場炸**。疊層越界讀到的是別人的記憶體,畫面照樣正常;游標被蓋掉時繪製函式照樣被呼叫、也沒有任何錯誤訊息;缺圖的中止要走到特定場景才會遇到。「跑跑看沒問題」在這裡幾乎不構成證據。

所以測法要挑對。以下是實際用過、驗證有效的作法,以及踩過的誤判——後者比前者更值錢,因為誤判會讓人以為自己驗過了。

---

## 環境

一律在 docker 裡跑,不污染 host。

```bash
docker run --rm -v "$PWD:/w" -w /w agos-build bash -c '...'
```

### Xvfb 的色深要選對

| 用途 | 參數 | 理由 |
|---|---|---|
| SurfaceSDL(預設後端) | `Xvfb :99 -screen 0 1600x1100x16` | x8 會讓 SDL 找不到 render driver,畫面全黑 |
| OpenGL 後端 | `Xvfb :99 -screen 0 1600x1100x24` + `LIBGL_ALWAYS_SOFTWARE=1` | 軟體 GL(llvmpipe)需要 24 位色深 |

兩者都要 `SDL_AUDIODRIVER=dummy` 與 `XDG_RUNTIME_DIR`(隨便指一個存在的目錄即可)。

**螢幕要開得比視窗大。** 若螢幕尺寸剛好等於視窗,截圖時右下角會被裁掉——`--scale-factor=2` 的視窗是 640×480,螢幕開 640×480 截出來只有 630×385。裁掉的比例會隨倍率變化,拿來做倍率間的比對就會得到假的「錯位」。

### 視窗要等,不能 sleep 固定秒數

啟動時間會隨機器負載變動。寫死 `sleep 16` 有時候剛好、有時候視窗還沒出來,後面所有 `xdotool` 都會打在空氣上,而測試看起來「跑完了」。

```bash
W=""
for t in $(seq 1 60); do
  W=$(xdotool search --class scummvm 2>/dev/null | tail -1)
  [ -n "$W" ] && break
  sleep 1
done
[ -z "$W" ] && { echo "視窗沒出現"; exit 1; }
sleep 12   # 視窗出來後還要等遊戲載入
```

---

## 讓遊戲動起來

### 座標換算

遊戲的邏輯解析度固定是 320×200,但視窗尺寸會隨倍率、比例校正而變。所有點擊位置用**遊戲座標**寫,執行時再換算:

```bash
eval $(xdotool getwindowgeometry --shell $W)
gx(){ echo $((X + $1 * WIDTH  / 320)); }
gy(){ echo $((Y + $1 * HEIGHT / 200)); }

xdotool mousemove $(gx 25) $(gy 100) click 1
```

寫死畫面座標的測試在換倍率、開比例校正之後全部失效,而且不會報錯,只會安靜地點錯地方。

### 面板熱點(遊戲座標)

| 位置 | 座標 | 說明 |
|---|---|---|
| 進遊戲 | (160, 100) | 片頭畫面點一下即可跳過 |
| 前進 | (25, 100) | 羅盤上方紅色箭頭 |
| 左 / 右 | (12, 112) / (38, 112) | 羅盤左右 |
| 後退 | (25, 125) | 羅盤下方 |
| UP / DOWN | (25, 60) / (45, 60) | 上下樓 |
| 房間 / 物品 / 武器 | (25, 22) / (25, 32) / (25, 42) | 左欄三個選單 |
| 動詞欄 | x≈290,y 20–110 | 右欄開啟／關閉／查看… |
| 遊戲畫面 | x 110–270,y 20–120 | 場景內的物件 |

熱鍵:`TAB` 地圖、`F7` 無敵、`Alt`+數字存檔、`Ctrl`+數字讀檔(AGOS 的存/讀是 Alt/Ctrl 分開,不要搞反)。

### 進到遊戲深處

片頭之後點一下進入城堡外,再往前幾次會進中庭。隨機走訪約 30–50 次操作就能走到艾薇拉本人的房間,足以測到對白、NPC 特寫、多行文字這些路徑。

---

## 判斷「畫出來了沒」

### A/B 差異法

要判斷某個東西(例如游標)有沒有真的被畫出來,最可靠的方式是**移到兩個位置各截一張,比對差異**:

```bash
xdotool mousemove $(gx 150) $(gy 75); sleep 2; import -window $W /tmp/A.png
xdotool mousemove $(gx 250) $(gy 75); sleep 2; import -window $W /tmp/B.png
compare -metric AE /tmp/A.png /tmp/B.png /tmp/diff.png
```

差異非 0 就代表那個東西存在且會動。這比人眼看截圖可靠——小游標在複雜背景上很容易看漏。

> **⚠ 背景要挑對。** 這招在這個專案上失手過一次:兩個位置都選在畫面下方的黑色文字框上,而測試的變因又剛好把游標畫成不透明黑色,結果黑疊黑,差異是 0——看起來像「游標沒畫出來」,其實畫了。挑一塊有紋理、對比明顯的區域(例如城堡石牆),不要挑純色區。

### 截圖要截視窗,不要截 root

```bash
import -window $W /w/screenshots/shot.png     # 對
import -window root /w/screenshots/shot.png   # 錯:會連桌面一起截,且位置會偏移
```

---

## 插樁(暫時性程式碼)

### 用旗標檔開關,不要用環境變數

ScummVM 的 `common/forbidden.h` 禁掉了 `getenv`,加了會編譯失敗。用檔案存在與否當開關:

```cpp
{ // TEMP-PROBE
    Common::File probe;
    if (probe.open("DUMPVGA")) {
        probe.close();
        dumpAllVgaScriptFiles();
        quitGame();
        return Common::kNoError;
    }
}
```

跑的時候 `touch run_game/DUMPVGA`,跑完刪掉。這樣同一份 binary 可以在「正常玩」與「dump」之間切換,不必重編。

### `debug()` 要加 `-d1` 才會印

`debug(0, ...)` 預設不會輸出,debuglevel 是 -1。執行時加 `-d1`。`warning()` 則一律會印。

### 取樣範圍會騙人

這是這次最貴的一個誤判。原本用這種寫法印探針:

```cpp
static int n = 0;
if (n < 40) warning("...", n++);
```

`n < 40` 只會印**最前面 40 幀**,全是遊戲剛啟動的畫面。當時要查的是「截圖那一刻游標為什麼不見」,而截圖發生在幾百幀之後——印出來的資料跟要查的時間點完全無關,卻讓人得出「游標位置卡住了」這種錯誤結論。

要看某個時間點的狀態,就用時間間隔限流(每秒印一次),或乾脆每幀都印再看尾端:

```cpp
static uint32 last = 0;
if (g_system->getMillis(false) - last > 1000) { last = g_system->getMillis(false); warning("..."); }
```

### 兩個獨立計數器排不出順序

同一個迴圈裡放兩個探針、各自用自己的計數器,log 讀起來像 `CUR, OVL, CUR, OVL`,但那可能是 `OVL(n) CUR(n) | OVL(n+1) CUR(n+1)` 的中段,分不出誰先誰後。

不過**計數本身仍是訊號**:當時 OVL 的計數比 CUR 多 2,代表有兩幀畫了疊層卻沒畫游標——那正是後來破案的線索(游標在更早的步驟被畫掉了),只是當下被當成雜訊略過。要排順序就用**同一個**計數器。

---

## 找記憶體越界:ASan

越界**讀**不會可靠地崩潰,它讀到什麼取決於當下的記憶體佈局。同一份程式在 A 機器上跑一整晚沒事,在 B 機器上五分鐘就掛。這種問題靠「多玩幾次」測不出來,要用 AddressSanitizer。

```bash
CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -g -O1" \
LDFLAGS="-fsanitize=address" \
./configure --disable-all-engines --enable-engine=agos …
make -j$(nproc)
```

跑的時候:

```bash
ASAN_OPTIONS="detect_leaks=0:halt_on_error=1:print_stacktrace=1" ./scummvm -p game …
```

ASan 沒開 recover,一個 process 只會報第一顆錯,所以**每個情境要各跑一輪**,不要指望一次跑完全部。刻意製造極端條件:

- 各種倍率,含非整數倍(`--scale-factor=3`)
- 兩種後端都要跑(SurfaceSDL 疊層是 2 bytes/px,OpenGL 是 4,程式走不同分支)
- 開/關比例校正(`--aspect-ratio`)
- 密集互動:地圖開關、存讀檔、場景切換、動詞面板

這個專案先後三顆崩潰類問題,全部是 ASan 抓到的,沒有一顆是「玩一玩發現」的。

### 標準掃描矩陣

每次動到疊層、字型或後端相關的程式碼之後,跑這一輪。每個情境都要獨立一個 process。

```bash
bash scripts/build_asan.sh                                        # 編一份 ASan 版

bash scripts/asan_sweep.sh x2       51 "--scale-factor=2"                    130
bash scripts/asan_sweep.sh x3       52 "--scale-factor=3"                    130
bash scripts/asan_sweep.sh x4       53 "--scale-factor=4"                    130
bash scripts/asan_sweep.sh gl       54 "--gfx-mode=opengl --scale-factor=3"  130
bash scripts/asan_sweep.sh aspect   55 "--aspect-ratio --scale-factor=2"     130
```

五個情境各自涵蓋不同的程式路徑,缺一不可:

| 情境 | 實際的疊層條件 | 涵蓋什麼 |
|---|---|---|
| x2 | 640×480,2 bytes/px,映射 1.00x / 1.20y | 基準 |
| x3 | 960×720,映射 1.50x / 1.80y | 非整數倍映射 |
| x4 | 1280×960,映射 2.00x / 2.40y | 等同 Retina 回報物理像素的條件 |
| OpenGL | 800×600,**4 bytes/px** | 另一條合成分支(SurfaceSDL 是 2) |
| 比例校正 | 640×480 + 200→240 拉伸 | 先前爆掉的組合 |

跑完看 `CHTOVL:` 那行確認條件真的生效——若倍率沒吃到,疊層尺寸不會變,那一輪等於白跑。

---

## 反組譯

ScummVM 內建兩套 dump:

| 函式 | 內容 |
|---|---|
| `dumpAllVgaScriptFiles()` | 各 zone 的動畫腳本 |
| `dumpAllSubroutines()` | GAMEPC 的遊戲邏輯子程式 |

> **⚠ `dumpAllSubroutines()` 只 dump 當下載入在記憶體裡的子程式。** Elvira 1 的腳本分散在 11 個 `TABLES*` 分頁,遊戲會依區域載入。直接呼叫只會拿到約 13 萬行;先跑一輪把所有分頁載進來,才會變成 17 萬行:
>
> ```cpp
> for (int sid = 0; sid < 3000; sid++)
>     if (getSubroutineByID(sid) == nullptr)
>         loadTablesIntoMem(sid);
> dumpAllSubroutines();
> ```
>
> 少了這步,dump 出來一樣看起來完整,不會有任何提示。`Can't load 002.VGA` 的關鍵證據就在後面那 4 萬行裡。

想看英文原文而不是中文,把 `.tab` 譯表暫時移出遊戲夾即可(`_chtActive` 會是 false)。

---

## 重現不出來的時候

「查了沒有」與「查詢本身壞掉」是兩回事,下「不存在」的結論前先做正對照。

這次踩到兩次:

- 用 `gh search issues --repo scummvm/scummvm` 查上游有沒有回報過同樣的問題,回空。看起來像「上游沒人遇到」,實際上 ScummVM 的 GitHub issue 功能是關閉的(`has_issues: false`),那個管道根本查不到東西。改查 commit 才拿到真正的答案。
- 用隨機走訪 230 次沒重現玩家回報的中止,這**不能**推論「機率低」——隨機走訪不是對房間圖的均勻覆蓋。要講機率得先做系統性走訪。

---

## 驗出貨品,不要只驗工作樹

編出來的執行檔跟打包進 AppImage / zip / dmg 的執行檔可能不是同一個。確認方法很直接:

```bash
./app.AppImage --appimage-extract >/dev/null
md5sum squashfs-root/usr/bin/scummvm build/scummvm-src/scummvm
```

有一次 AppImage 的檔案大小跟上一版**一模一樣**(66370040 bytes),看起來像沒重新打包;md5 比對才確認裡面確實是新的執行檔,大小相同只是 squashfs 對齊的巧合。反過來說,大小不同也不代表內容對——一律比 md5。

公開版還要驗「玩家的實際情境」:只放遊戲原檔、不放字型,看啟動腳本會不會自動把字型補進遊戲夾。

---

## 壓力測試

長時間隨機操作,偵測崩潰、中止與凍結。測的是**出貨的 AppImage**,不是工作樹的執行檔:

```bash
bash scripts/stress_appimage.sh sdl 41 ""                   500
bash scripts/stress_appimage.sh gl  42 "--gfx-mode=opengl"  500
```

內容大致長這樣:

```bash
for i in $(seq 1 500); do
  pgrep -f app.AppImage >/dev/null || { echo "第 $i 次操作後結束"; break; }
  case $((RANDOM % 12)) in
    0|1|2) xdotool mousemove $(gx 25)  $(gy 100) click 1 ;;   # 前進
    3)     xdotool mousemove $(gx 12)  $(gy 112) click 1 ;;   # 左
    …
    11)    xdotool key Tab ;;                                  # 地圖
  esac
  sleep 0.9
done
```

判定要同時看三件事,只看一件會漏:

1. **程序還在不在**(`pgrep`)——抓崩潰與 `error()` 中止。
2. **log 裡有沒有 `ERROR` / `Can't load` / `assert`**——抓有訊息但沒死的情況。
3. **操作次數有沒有跑完**——中途 break 代表死在第幾次,可以回頭對 log。

**沉默不等於成功。** 如果過濾條件只 grep 成功訊息,程式在崩潰迴圈裡打轉跟一切正常看起來是一樣的。

---

## 主控端的操作坑

跟遊戲無關,但重複踩到:

- **shell 的工作目錄會延續。** 在某次指令裡 `cd build/scummvm-src` 之後,下一次指令的相對路徑會從那裡算起。曾經因此以為整棵原始碼樹不見了(其實是 `ls build/` 查到了 `build/scummvm-src/build/`)。長流程一律用絕對路徑。
- **`strings` 預設只抓 ASCII。** 想確認中文警告字串有沒有編進 binary,`strings | grep 中文` 永遠是 0。用 `grep -a` 直接對二進位抓。
- **build image 裡沒有 git。** 要在容器內驗證 patch 能不能套到乾淨的原始碼樹,用 `patch -p1 < xxx.patch`,不要用 `git apply`。
- **重生 patch 前要 `git add -N` 新檔案。** `git diff` 收不到 untracked 檔案,少了這步 patch 會缺檔;本機用現成的 build 樹看不出來,只有從乾淨樹套用的 CI 會爆。

---

## 相關文件

- [`AGOS_PITFALLS.md`](AGOS_PITFALLS.md) —— AGOS 引擎中文化踩過的坑,每條含根因與驗證方法
- [`BUG_002VGA_ZONE0.md`](BUG_002VGA_ZONE0.md) —— 一次完整追查的全紀錄,可當本文各項手法的實例
- [`DEV_SETUP.md`](DEV_SETUP.md) —— 環境建置、重烘字型、重生 patch、打包
