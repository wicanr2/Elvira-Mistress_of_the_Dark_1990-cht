# 防拷（Copy Protection）靜態分析

> 結論先行：**古堡禁地繁中版不會被防拷擋住。** ScummVM 的 AGOS 引擎對 Elvira 1 沒有任何防拷檢查點，遊戲資料本身也沒有防拷提問；繁中 patch 中的 `_copyProtection = false` 對 Elvira 1 實為 **no-op**（僅與 ScummVM 預設一致的防禦性寫法）。

本文從程式面（ScummVM v2.9.1 AGOS 引擎原始碼 + 遊戲資料）逐點查證，供未來維護與其他 AGOS 專案參考。

---

## 1. 背景：AGOS 的 `_copyProtection` 怎麼運作

ScummVM 對「原版有防拷的遊戲」預設**自動略過**防拷。控制旗標是 `_copyProtection`（`agos.h`）：

- `agos.cpp:709`：`_copyProtection = ConfMan.getBool("copy_protection")` — 從設定讀，**預設 false**（即預設 bypass）。
- `metaengine.cpp`：GUI 選項「Enable copy protection」說明為 *"Enable any copy protection that would otherwise be bypassed by default."* → 佐證「預設就是 bypass」。

但**「bypass」的實際動作是逐遊戲寫死的**——引擎要有對應的檢查點，`_copyProtection == false` 時才會去自動填答／跳過。

## 2. `_copyProtection` 在引擎中的全部用處（grep 實據）

```
$ grep -rn '_copyProtection' engines/agos
agos.cpp:266   _copyProtection = false;                       // 建構子預設
agos.cpp:709   _copyProtection = ConfMan.getBool(...)          // 讀設定
agos.cpp:1101  _copyProtection = false;                        // ← 繁中 patch 加的(見下)
script.cpp:431 if (!_copyProtection && getGameType()==GType_WW && id==71) ...
script.cpp:853 if (!_copyProtection && !(getFeatures()&GF_TALKIE) && _currentTable) ...
```

實際「做事」的只有兩處，且**都不是 Elvira 1**：

| 位置 | 條件 | 對象 |
|---|---|---|
| `script.cpp:431` | `!_copyProtection && GType_WW && id==71` | **Waxworks** 專屬 |
| `script.cpp:853`（`o_freezeZones`） | `!_copyProtection && !TALKIE` 且 `_currentTable->id==2924`(Simon1) 或 `==1322`(Simon2) | **Simon 1 / Simon 2** 專屬 |

`o_freezeZones` 的實作明確只處理 Simon：

```cpp
void AGOSEngine::o_freezeZones() {                       // opcode 138
    freezeBottom();
    if (!_copyProtection && !(getFeatures() & GF_TALKIE) && _currentTable) {
        if ((getGameType() == GType_SIMON1 && _currentTable->id == 2924) ||
            (getGameType() == GType_SIMON2 && _currentTable->id == 1322)) {
            _variableArray[134] = 3;  _variableArray[135] = 3;
            setBitFlag(135, 1);       setScriptCondition(0);
        }
    }
}
```

→ **Elvira 1（`GType_ELVIRA1`）沒有任何一條 bypass 邏輯接上。**

## 3. 繁中 patch 的那行是 no-op

`agos.cpp` 進入繁中模式時設 `_copyProtection = false`。因為上一節顯示引擎對 Elvira 1 **無檢查點**，這行對 Elvira 1 **不產生任何效果**，而且值本來就等於 ScummVM 預設。它只是與預設一致的防禦性寫法（若未來換到有防拷 bypass 的 subengine，語意才有意義）。patch 內註解已據此修正。

## 4. 遊戲資料本身也沒有防拷

- **gamepc 字串表（687 條）**：grep `manual / page N / type the word / passcode / paragraph / code number / look up` → **無命中**（"sword" 只是含 "word" 子字串的誤中）。文字型防拷（要你查手冊輸入某字）必然要有提示字串 → 不存在。
- **`script_e1.cpp`**：無防拷 opcode。
- **detection（`detection_tables.h`）**：所有 DOS Elvira 1 entry 均為 `ADGF_NO_FLAGS`；AGOS 的 `GF_*` 旗標集亦無「copy protection」旗標。

## 5. 實測佐證

所有啟動路徑（headless docker × 多次、wine 跑 Windows 版、三平台打包實測）都是：

```
ACCOLADE → HORROR SOFT → ELVIRA「Mistress of the Dark」標題 → 直接進遊戲（城堡大門）
```

全程**未出現任何防拷詢問**。

## 6. 結論與唯一理論缺口

- **繁中版對防拷的行為 = 原版 vanilla ScummVM Elvira 1 完全一致**（兩者 `_copyProtection` 都 false、都無 Elvira 1 CP 邏輯、跑同一份遊戲腳本）。vanilla ScummVM Elvira 1 是完整支援、可玩的遊戲 → **防拷不會擋玩家**。
- **唯一理論缺口**：若遊戲的 VGA script（bytecode）內藏一個**非文字**的防拷（如密碼盤），ScummVM 會忠實執行它。但：(a) 這類防拷通常在**開機時**觸發，而實測開機都直接進遊戲；(b) 字串表無任何對應提示文字。→ 實務上不存在，且原版 DOS Elvira 1 的防拷屬磁片層級（ScummVM 讀已萃取的遊戲檔，磁片防拷自然不適用）。

---

*方法論：靜態反追溯源（先確認引擎程式路徑，再查遊戲資料，最後以實測佐證），不憑記憶下結論。*
