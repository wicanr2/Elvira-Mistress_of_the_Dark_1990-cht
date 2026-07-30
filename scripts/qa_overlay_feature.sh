#!/usr/bin/env bash
# ============================================================================
# QA: 疊層的「其他中文路徑」在非 1:2 overlay 下是否也正確
# (動詞面板由 qa_overlay_scale.sh 顧, 這支顧對白文字層 / 地圖 / 選單)
#
# 這三條路徑各自有自己的座標算式(壓縮格排版、BFS 房間格、判定框中心直繪),
# 全部都寫在基準 640x400 空間, 高 DPI 下同樣要經映射才會落在對的位置。
#
# 用法: scripts/qa_overlay_feature.sh <tag> <scale> <W> <H>
# 產出: qa_<tag>_dlg.png(對白) / qa_<tag>_map.png(地圖) / qa_<tag>_menu.png(暫停選單)
# ============================================================================
set -u
cd "$(dirname "$0")/.." || exit 1
ROOT="$PWD"

TAG="${1:?tag}"; SCALE="${2:?scale}"; W="${3:?width}"; H="${4:?height}"
DISP=":8${SCALE}"
BIN="/work/build/scummvm-src/scummvm"
mkdir -p screenshots

# 遊戲座標(320x200) → 視窗座標
gx() { echo $(( $1 * W / 320 )); }
gy() { echo $(( $1 * H / 200 )); }

EXAMINE_X=$(gx 295); EXAMINE_Y=$(gy 52)    # 右欄「檢視」判定框中心
DOOR_X=$(gx 160);    DOOR_Y=$(gy 95)       # 城堡大門(畫面中央)
BAG_X=$(gx 85);      BAG_Y=$(gy 157)       # 物品欄裡的背包(檢視物品必定吐敘述文字)
PAUSE_X=$(gx 295);   PAUSE_Y=$(gy 102)     # 右欄「暫停」判定框中心

docker run --rm -v "$ROOT:/work" -w /work/run_game agos-build bash -c "
export SDL_AUDIODRIVER=dummy XDG_RUNTIME_DIR=/tmp/x
mkdir -p /tmp/x
Xvfb $DISP -screen 0 \$(( $W + 60 ))x\$(( $H + 60 ))x16 &>/dev/null &
sleep 2
export DISPLAY=$DISP
timeout 60 $BIN -p /work/run_game --auto-detect --no-aspect-ratio \
    --scale-factor=$SCALE -e null -d1 >/work/screenshots/qa_${TAG}_feat.log 2>&1 &
sleep 6
WID=\$(xdotool search --name 'Elvira' | tail -1)
shot() { import -window \$WID /work/screenshots/qa_${TAG}_\$1.png; }

# 0) 對白文字層最可靠的來源: 開場旁白(不需要任何互動, 一定有整段中文)
shot intro
sleep 7

# 開場最後一擊: 進遊戲後的第一次點擊會被拿去跳過/收尾開場, 先消耗掉再開始互動,
# 否則後面每個動作都少一拍(實測: 不做這步, 點動詞與點暫停全部沒反應)。
xdotool mousemove $DOOR_X $DOOR_Y click 1; sleep 3

# 1) 對白/敘述文字層: 點「檢視」→ 點物品欄的背包 → 敘述文字出現在下方對話框
xdotool mousemove $EXAMINE_X $EXAMINE_Y; sleep 1; xdotool click 1; sleep 2
xdotool mousemove $BAG_X $BAG_Y; sleep 1; xdotool click 1; sleep 4
shot dlg

# 2) 地圖疊層(TAB)
xdotool key Tab; sleep 2
shot map
xdotool key Tab; sleep 1

# 3) 模態選單(點「暫停」→ 遊戲暫停/繼續/結束)
# 先 hover 再點: hitarea 要靠滑鼠移動事件更新, mousemove+click 連發會漏掉
xdotool mousemove $DOOR_X $DOOR_Y; sleep 1
xdotool mousemove $PAUSE_X $PAUSE_Y; sleep 2; xdotool click 1; sleep 4
shot menu

pkill scummvm; sleep 1
chown 1000:1000 /work/screenshots/qa_${TAG}_*.png /work/screenshots/qa_${TAG}_feat.log 2>/dev/null
" >/dev/null 2>&1

for k in dlg map menu; do
	f="screenshots/qa_${TAG}_${k}.png"
	[ -f "$f" ] && echo "OK: $f" || echo "MISS: $f"
done
