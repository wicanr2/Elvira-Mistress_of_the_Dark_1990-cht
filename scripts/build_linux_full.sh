#!/bin/bash
# Linux 完整版(本機保留, 含遊戲原檔 + MT-32 ROM, 不可散佈): 從公開版加料。
# 需先跑 scripts/build_linux.sh。產物: dist-all/古堡禁地-CHT-FULL-linux-x86_64.tar.gz
set -e
PROJ="/home/anr2/scummvm/elvira_cht/workplace"
SRC="$PROJ/dist-all/古堡禁地-CHT-linux-x86_64.tar.gz"
[ -f "$SRC" ] || { echo "!! 先跑 scripts/build_linux.sh"; exit 1; }
docker run --rm -v "$PROJ:/w" -w /w agos-build bash -c '
  set -e
  T=/tmp/lf; rm -rf $T; mkdir -p $T; cd $T
  tar xzf "/w/dist-all/古堡禁地-CHT-linux-x86_64.tar.gz"
  mv 古堡禁地-CHT-linux-x86_64 古堡禁地-CHT-FULL-linux-x86_64
  D=古堡禁地-CHT-FULL-linux-x86_64
  cp -rL /w/run_game/* "$D/game/"        # 遊戲原檔 + MT-32/CM32L ROM
  # 完整版有 ROM → 預設就用 MT-32 原版配樂
  sed -i "s|\${ELVIRA_MUSIC:-adlib}|\${ELVIRA_MUSIC:-mt32}|" "$D/play-elvira.sh"
  cat > "$D/README.txt" <<"EOF"
古堡禁地 (Elvira - Mistress of the Dark, 1990) 繁體中文版 完整版
================================================================
執行 ./play-elvira.sh 即可遊玩(已含遊戲檔與 MT-32 ROM, 原版配樂)。
本包含版權素材, 僅供自己保留, 請勿散佈。

熱鍵: F7 無敵, TAB 地圖; 存檔 Alt+數字, 讀檔 Ctrl+數字。
EOF
  tar czf "/w/dist-all/古堡禁地-CHT-FULL-linux-x86_64.tar.gz" "$D"
  chown -R '"$(id -u):$(id -g)"' /w/dist-all
  echo "=== 產物 ==="; ls -lh "/w/dist-all/古堡禁地-CHT-FULL-linux-x86_64.tar.gz"
'
