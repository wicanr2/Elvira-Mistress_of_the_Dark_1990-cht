# 古堡禁地（Elvira - Mistress of the Dark, 1990）研究筆記

> 用途：Elvira 1 繁中化的劇情/系統/來源總整理，供譯名表（`../translations/glossary.md`）、README 引用當年中文資料、翻譯 subagent 對照。
> 一句話總結：**艾薇拉繼承並整修祖傳古堡當恐怖景點，卻喚醒了曾曾祖母——邪惡女巫愛梅達——的怪物大軍；玩家受邀進堡，須集齊六把鑰匙開箱取「惡魔統治殘冊」，擊敗愛梅達、救出艾薇拉。**

---

## 1. 基本資料
- 原名：Elvira - Mistress of the Dark（1990）。開發 Horror Soft，發行 Accolade。引擎＝AGOS（ScummVM `engines/agos`，`GType_ELVIRA1`）。
- 台灣官方：**軟體世界 珍藏版 118**，中文名 **《古堡禁地》**（1991，智冠/軟體世界代理，高雄）。3 片 1.2M 磁片，EGA/VGA，IBM XT/AT，限制級「兒童不宜」。文字編輯：謝明奇；美工編輯：郭寶寶。
- 主角原型：Cassandra Peterson 飾演的 Elvira；接續 1988 同名電影。

## 2. 劇情梗概（官方手冊「我的日記」p1-6＋英文維基/攻略）
艾薇拉的曾曾祖母 **愛梅達女爵（Emelda）** 是住在英格蘭 **基爾伯蘭根（Killbragant）** 古堡的邪惡女巫。她與邪惡巫師 **貝蒙君主（Lord Beremond）** 為伴、統治此地、行邪術；貝蒙狩獵時被暗箭所傷身亡。愛梅達的丈夫 **艾力克公爵** 長年在印度經商，返家即被愛梅達吸血、以家傳寶劍刺心而死（後轉世成玩家的曾祖父）。愛梅達過世多年，撒旦給她長生不老的復活權；她把開啟「惡魔統治殘冊」的 **六把鑰匙** 交給忠心僕人（鬼魅），伺機復活。

現代，艾薇拉經邪惡舅舅 **艾摩（Elmo）** 遺贈得到古堡（英文維基另作 Uncle Vincent），整修為「愛梅達恐怖週末之旅」景點，卻喚醒沉睡的怪物大軍與鬼魅。艾薇拉被困堡中（躲在廚房），透過「魔鬼剋星」廣告雇來玩家。玩家須找齊六鑰、開六鎖木箱取「惡魔統治殘冊」，阻止愛梅達復活並救出艾薇拉。

## 3. 角色關係
- **艾薇拉** —（曾曾孫女／後代）— **愛梅達女爵**（大魔王）
- **愛梅達** —（伴侶）— 貝蒙君主；—（亡夫）— 艾力克公爵（→ 轉世玩家曾祖父）
- **艾薇拉** —（雇主）— 玩家（第一人稱勇士）
- 廚房：艾薇拉＋胖廚娘（後被愛梅達女傭趕走）
- 敵對陣營：愛梅達的鬼魅僕人＝花園迷宮的精靈、臥室鬼兵、地窖骷髏、僧侶/士兵/弓箭手/騎士/水怪/衛兵隊長、女吸血鬼、狼人、拷問者鬼魂等。

## 4. 系統說明
### 4.1 介面（手冊 p12-21）
主要視窗（探索/戰鬥/烹煮）、最下面視窗（訊息/對話盒/可拿物列表）、物品視窗（ROOM/INV/WEAPONS）、方向箭頭（UP/DOWN 及紅色可走方向）、狀態視窗、右側命令選單、離開命令（PAUSE/SAVE/RESTORE、QUIT/CONTINUE）。
命令 10 動詞：OPEN 打開、CLOSE 關閉、LOCK 關鎖、UNLOCK 開鎖、LOOK IN 細看、EXAMINE 檢視、MIX 混合、CONSUME 服用、USE 使用、THROW 丟棄。
拿物：選物→拖手掌至 INV/WEAPONS；丟物：拖至 ROOM。二次點選物品看說明。紅色「R」＝退出恐怖特寫回正常視野。

### 4.2 屬性（手冊 p18；★與 Elvira 2 不同）
STR 力量值 / RES 忍受度 / DEX 反應力 / SKI 技巧 / LIF 生命值 / EXP 經驗值。無 Level、無 PSY。LIF 歸零＝遊戲結束。

### 4.3 戰鬥（手冊 p22-25）
即時戰鬥；游標在攻擊態＝劍、防禦態＝盾，電腦按前一回合命中與否自動切換。
攻擊：LUNGE 刺（選敵左）/ HACK 劈（選敵右）；防禦：BLOCK 抵擋（左）/ PARRY 迴避（右）；完全戰敗＝DEATH。
戰鬥窗上下數字＝受傷/造成傷害；左右眼睛＝魔法傷害值。弓箭是唯一可「練習」的武器（射靶練成 master bowman，strings 520）。可逃跑（受傷/負重過多逃不掉）。
怪物表（手冊 p25，技巧/反應力/力量/忍受度/生命）：僧侶、士兵、弓箭手、騎士（近身無敵）、骷髏、水怪、衛兵隊長（手冊誤植「船長」）。同種怪以戰袍顏色分強弱（藍＞綠）。

### 4.4 法術（手冊 p26-42）
材料城堡內外皆可採。單位：3 把(handful)=1 匙(saucepan)、4 把=1 籃(basketful)、6 罐(glass)=1 瓶(bottle)。
流程：帶魔法書進廚房交艾薇拉→選 MIX→把材料拖到魔法書左頁→選 Mix 圖示→成品進裝備欄（藥瓶/捲軸）→CONSUME/USE 施放。配錯艾薇拉會提示。
（法術/藥劑官方全名見譯名表；此處不重列。）

## 5. 攻略關鍵路線（六把鑰匙，供譯文情境判斷；來源見下）
1. 馬廄狼人：鐵匠鋪坩堝熔銀十字架＋弩箭＝銀頭弩箭，射殺變狼的男人；馬廄鐵環後藏第一把金鑰。
2. 廚房送菜升降機（dumb waiter）：調「掌燈/閃耀自尊」照亮通道→第二把鑰匙。
3. 死掉的獵鷹（dead falcon）身上→第三把鑰匙。
4. 刑房：移走地上鐵環露出骷髏與第四把鑰匙。
5. 守衛室：殺衛兵隊長，取告示（notice）後方第五把鑰匙。
6. 無敵騎士：用弩箭擊落城下，井下護城河底找屍體取第六把鑰匙。
開場艾薇拉給三寶＋一把匕首：木心（Woodenheart，恢復生命）、姆指燈（Fingerlight）、火球術（Thorny Splinter）。先取書房魔法書＋蜂蜜罐→交艾薇拉配「香草蜂蜜」。

## 6. 手冊關鍵頁摘要（供 README 引用當年中文原文）
- **封面（p1 jpg001）**：ELVIRA / ACCOLADE，限制級兒童不宜，3 片裝 1.2M NT$300，「只適用同時配有 1.2M 磁碟機、硬碟及 EGA/VGA 彩色顯示系統之電腦」。
- **封底（jpg002）**：官方文案（艾薇拉第一人稱）——
  > 「嗨！諸位勇士，我是 Elvira，全美最著名的靈異節目主持人，也是古堡的繼承者。瞧，我已經將陰森恐怖的古堡重新裝修，想趁好萊塢之夜大撈一筆。誰知道，我那死於百年前的曾曾祖母——愛梅達女爵——即將復活！請求勇士們，幫我收拾那些嚇人的怪物及討厭的衛士，並阻止愛梅達的復活。」
  > 賣點：超過 800 個場景、300 多個特殊物品、即時戰鬥模式、「媲美神農嘗百草，以各種花草為原料配製魔法」、「多種詭異、恐怖的怪物，讓你死的很『難看』」。
  > 版權：© 1990 Queen "B" Productions / Horror Soft Ltd. / Accolade。
- **目錄（jpg005/p4）**：一、我的日記；二、基本配備；三、備份磁片/載入硬碟；四、設定配備；五、啟動遊戲；六、控制方法；七、遊戲玩法；八、戰鬥；九、施法；十、愛梅達的魔法書；附錄一、法術說明；附錄二、提示。
- **我的日記（jpg006-008/p1-6）**：愛梅達身世、貝蒙、艾力克公爵、艾摩、六鑰、惡魔統治殘冊來歷；文風＝冷面吐槽（可作對白語氣範本，如「一個大兩個頭…不…一個頭兩個大」）。提及好萊塢恐怖片梗（血腥瑪麗、法蘭克史坦、Freddy「夜半鬼上床」、Gomer Pyle 碰上 Marquis de Sade）。
- **法術說明附錄（jpg024-025/p40-42）**：18 個法術官方譯名＋效果（見譯名表）。
- **提示附錄（jpg025/p42）**：三寶、魔法書交艾薇拉、廚房被愛梅達女傭佔據等。

## 7. 遊戲字串（翻譯真實分母）
- `../strings/elvira1_text.tsv`：689 條（含空/佔位）。含物品描述（A/B 類）、對白（NPC 損人台詞）、房間名（`the xxx`）、法術/藥劑名、系統訊息（YES/NO、Are you sure、DONE、Do you want to play again）。
- 專名以 `the + 名詞` 形式反覆出現（房間/NPC），法術以名詞短語出現（palmlight/fingerlight spell 等）。翻譯時房間名對照譯名表「地點」、NPC 對照「人物/怪物」、法術對照「法術系統」。

## 8. 參考來源（網址）
- 英文維基（劇情/系統權威）：https://en.wikipedia.org/wiki/Elvira:_Mistress_of_the_Dark_(video_game)
- GameFAQs 攻略（Lightside, PC）：https://gamefaqs.gamespot.com/pc/564814-elvira/faqs/19583
- Walkthrough King：https://www.walkthroughking.com/text/elvira.aspx
- Nemmelheim Horrorsoft 專站（攻略/魔法書）：https://www.nemmelheim.de/horrorsoft/elvira/elvira_walktrough.htm ；魔法書 https://www.nemmelheim.de/horrorsoft/elvira/files/spellbook/Spellbook.htm
- Lemon Amiga 解法：https://www.lemonamiga.com/doc/elvira-mistress-of-the-dark/552
- The Spoiler 解法：https://the-spoiler.com/RPG/Accolade/elvira.mistress.1.html
- CRPG Addict 評析：http://crpgaddict.blogspot.com/2014/01/game-131-elvira-mistress-of-dark-1990.html
- Abandonware DOS 解法：https://www.abandonwaredos.com/docawd.php?sf=elviradarksolution.txt&st=walkthrough&sg=Elvira:+Mistress+of+the+Dark&idg=1646
- **官方中文手冊掃描（最高權威台灣譯名來源）**：`../manual/珍118-古堡禁地/doc20110220152304_001..029.jpg`（29 張，含封面/封底/目錄/日記/操作/戰鬥/施法/魔法書/附錄）。
- 手冊掃描出處（骨灰集散地「軟體世界說明書補完計畫」）：http://boneash.oldgame.tw ；http://www.gamebase.com.tw/forum/30032

## 9. 待辦/注意
- Emelda 譯名 Elvira 1（愛梅達，手冊）vs Elvira 2 譯名表（艾梅達）——README/跨作對照時標明系列內差異，本作字串一律用「愛梅達」。
- 手冊怪物表「Captain＝船長」為誤植，字串一律譯「衛兵隊長」。
- Elvira 1 屬性列＝STR/RES/DEX/SKI/LIF/EXP，勿套 Elvira 2 的 Level/PSY/HP。
- 手冊個別頁有錯字（「愛海達」「Elrira」），以正確「愛梅達／艾薇拉」為準。
