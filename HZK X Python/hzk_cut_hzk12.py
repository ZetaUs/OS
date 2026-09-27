def char_to_gb2312_code(c: str) -> int:
    gb = c.encode("gb2312")
    return (gb[0] << 8) | gb[1]

def get_hzk12_offset(gb_code: int) -> int:
    """GB2312 转标准HZK12文件偏移，单字24字节"""
    high = (gb_code >> 8) & 0xFF
    low = gb_code & 0xFF
    q = high - 0xA0
    w = low - 0xA0
    return ((q - 1) * 94 + (w - 1)) * 24

def main():
    # HZK12 配置区（和HZK16唯一区别在这里）
    HZK_SRC_PATH = "HZK12"        # 原始HZK12文件
    CHAR_LIST_PATH = "common.txt"
    OUT_BIN = "mini_hzk12.bin"
    OUT_H = "hzk_mini12.h"
    FONT_PER_CHAR = 24    # HZK12固定24字节/字
    FONT_W = 12
    FONT_H = 12

    # 读取汉字列表去重
    with open(CHAR_LIST_PATH, "r", encoding="utf-8") as f:
        char_lines = [line.strip() for line in f if line.strip()]
    char_set = list(dict.fromkeys(char_lines))
    char_count = len(char_set)
    print(f"待提取汉字总数：{char_count}")

    # 读取原始HZK12字模
    with open(HZK_SRC_PATH, "rb") as src_hzk:
        glyph_buffer = bytes()
        char_meta = []

        for ch in char_set:
            try:
                gb_code = char_to_gb2312_code(ch)
            except UnicodeEncodeError:
                print(f"警告：字符「{ch}」非GB2312，跳过")
                continue
            off = get_hzk12_offset(gb_code)
            src_hzk.seek(off)
            glyph = src_hzk.read(FONT_PER_CHAR)
            glyph_buffer += glyph
            char_meta.append((ch, gb_code))

    # 输出精简二进制（磁盘加载用，纯点阵无头部）
    with open(OUT_BIN, "wb") as fb:
        fb.write(glyph_buffer)
    print(f"生成磁盘字库 {OUT_BIN}，大小：{len(glyph_buffer)} 字节")

    # 生成内核嵌入C头文件
    h_content = f"""#ifndef __HZK_MINI12_H
#define __HZK_MINI12_H

#define HZK12_CHAR_COUNT     {len(char_meta)}
#define HZK12_PER_GLYPH      24
#define HZK12_WIDTH          {FONT_W}
#define HZK12_HEIGHT         {FONT_H}

static const unsigned char kernel_hzk12_mini[] = {{
"""
    hex_data = [f"0x{b:02X}" for b in glyph_buffer]
    for i in range(0, len(hex_data), 16):
        line = ", ".join(hex_data[i:i+16])
        h_content += f"    {line},\n"
    h_content += "};\n\n"

    # GB映射表，内核查表用
    h_content += "typedef struct {\n    uint8_t gb_high;\n    uint8_t gb_low;\n    uint16_t idx;\n} hzk12_map_t;\n\n"
    h_content += "static const hzk12_map_t hzk12_mapping[] = {\n"
    for idx, (ch, gb_code) in enumerate(char_meta):
        b1 = (gb_code >> 8) & 0xFF
        b2 = gb_code & 0xFF
        h_content += f"    {{0x{b1:02X}, 0x{b2:02X}, {idx}}}, // {ch}\n"
    h_content += "};\n#define HZK12_MAP_COUNT (sizeof(hzk12_mapping)/sizeof(hzk12_map_t))\n\n#endif\n"

    with open(OUT_H, "w", encoding="utf-8") as fh:
        fh.write(h_content)
    print(f"生成内核嵌入头文件 {OUT_H}")

if __name__ == "__main__":
    main()
