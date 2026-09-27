def char_to_gb2312_code(c: str) -> int:
    """汉字转GB2312内码，返回2字节整数"""
    gb = c.encode("gb2312")
    return (gb[0] << 8) | gb[1]

def get_hzk_offset(gb_code: int) -> int:
    """GB2312内码转HZK16文件偏移，单字32字节"""
    high = (gb_code >> 8) & 0xFF
    low = gb_code & 0xFF
    q = high - 0xA0
    w = low - 0xA0
    return ((q - 1) * 94 + (w - 1)) * 32

def main():
    # 配置区
    HZK_SRC_PATH = "HZK16"       # 原始完整HZK16路径
    CHAR_LIST_PATH = "common.txt"# 常用汉字列表
    OUT_BIN = "mini_hzk16.bin"   # 输出精简HZK二进制（磁盘加载用）
    OUT_H = "hzk_mini.h"         # 输出C数组头文件（嵌入kernel用）
    FONT_PER_CHAR = 32           # HZK16单字占用字节

    # 1. 读取需要保留的汉字，去重
    with open(CHAR_LIST_PATH, "r", encoding="utf-8") as f:
        char_lines = [line.strip() for line in f if line.strip()]
    char_set = list(dict.fromkeys(char_lines))
    char_count = len(char_set)
    print(f"待提取汉字总数：{char_count}")

    # 2. 打开原始HZK读取字模
    with open(HZK_SRC_PATH, "rb") as src_hzk:
        glyph_buffer = bytes()
        char_meta = []  # 存储(汉字, GB内码, 原始偏移)

        for ch in char_set:
            try:
                gb_code = char_to_gb2312_code(ch)
            except UnicodeEncodeError:
                print(f"警告：字符「{ch}」不支持GB2312，跳过")
                continue
            off = get_hzk_offset(gb_code)
            src_hzk.seek(off)
            glyph = src_hzk.read(FONT_PER_CHAR)
            glyph_buffer += glyph
            char_meta.append((ch, gb_code))

    # 3. 输出精简HZK二进制文件（标准无头部HZK格式）
    with open(OUT_BIN, "wb") as fb:
        fb.write(glyph_buffer)
    print(f"已生成磁盘版字库 {OUT_BIN}，大小：{len(glyph_buffer)} 字节")

    # 4. 生成可嵌入内核的C头文件
    h_content = f"""#ifndef __HZK_MINI_H
#define __HZK_MINI_H

#define HZK_MINI_CHAR_COUNT    {len(char_meta)}
#define HZK_16_PER_GLYPH       32
#define HZK_WIDTH              16
#define HZK_HEIGHT             16

// 精简HZK16点阵数据，可直接编译进内核
static const unsigned char kernel_hzk_mini[] = {{
"""
    # 二进制转十六进制数组，每行16字节
    hex_data = [f"0x{b:02X}" for b in glyph_buffer]
    for i in range(0, len(hex_data), 16):
        line = ", ".join(hex_data[i:i+16])
        h_content += f"    {line},\n"
    h_content += "};\n\n"

    # 可选：汉字-索引映射表（内核查表用，通过汉字找字模偏移）
    h_content += "// 汉字对应字库下标映射\n"
    h_content += "typedef struct {\n    char gb[2];\n    uint16_t idx;\n} hzk_char_map_t;\n\n"
    h_content += "static const hzk_char_map_t hzk_mapping[] = {\n"
    for idx, (ch, gb_code) in enumerate(char_meta):
        b1 = (gb_code >> 8) & 0xFF
        b2 = gb_code & 0xFF
        h_content += f"    {{0x{b1:02X}, 0x{b2:02X}, {idx}}}, // {ch}\n"
    h_content += "};\n\n#define HZK_MAP_COUNT (sizeof(hzk_mapping)/sizeof(hzk_char_map_t))\n\n#endif\n"

    with open(OUT_H, "w", encoding="utf-8") as fh:
        fh.write(h_content)
    print(f"已生成内核嵌入头文件 {OUT_H}")

if __name__ == "__main__":
    main()
