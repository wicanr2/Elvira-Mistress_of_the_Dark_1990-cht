#!/usr/bin/env python3
# 抽取 Elvira 1 (AGOS GType_ELVIRA1) 全文字。
# 引擎 oracle: AGOSEngine::allocGamePcVars + readGamePcText (engines/agos/res.cpp)
#   header(BE): [0:4]itemArraySize [4:8]version(=0x80) [8:12]itemArrayInited [12:16]stringTableNum
#               [16:20]textSize, 之後 textSize bytes 為 textMem
#   setupStringTable: textMem 依 \x00 切成 stringTableNum 條 → _stringTabPtr[id] (id<0x8000)
# Elvira 1 無 STRIPPED.TXT / TEXT 分頁檔,所有字串 id 皆 < 0x8000,全在 gamepc 表。
# 用法: python3 tools/extract_elvira1_text.py <game_dir> <out.tsv>
import sys, struct, os

def find_ci(directory, name):
    p = os.path.join(directory, name)
    if os.path.exists(p):
        return p
    low = name.lower()
    for f in os.listdir(directory):
        if f.lower() == low:
            return os.path.join(directory, f)
    return p

def read_string_table(gamepc):
    d = open(gamepc, 'rb').read()
    version = struct.unpack('>I', d[4:8])[0]
    assert version == 0x80, f"非 runtime database (version={version:#x})"
    string_tab_num = struct.unpack('>I', d[12:16])[0]
    text_size = struct.unpack('>I', d[16:20])[0]
    text_mem = d[20:20 + text_size]
    parts = text_mem.split(b'\x00')
    strings = parts[:string_tab_num]
    return string_tab_num, strings

def main():
    game_dir, out_tsv = sys.argv[1], sys.argv[2]
    gamepc = find_ci(game_dir, 'GAMEPC')
    n, strings = read_string_table(gamepc)
    nonempty = 0
    with open(out_tsv, 'w', encoding='utf-8') as f:
        f.write(f"# Elvira 1 字串表 id\\ttext  (共 {n} 條)\n")
        for i, s in enumerate(strings):
            t = s.decode('latin1')
            if t.strip():
                nonempty += 1
            # tsv: 換行/tab 轉義,保原文
            t = t.replace('\\', '\\\\').replace('\t', '\\t').replace('\n', '\\n')
            f.write(f"{i}\t{t}\n")
    print(f"字串表 {n} 條 (非空 {nonempty}) 寫入 {out_tsv}")

if __name__ == '__main__':
    main()
