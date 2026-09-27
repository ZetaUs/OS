typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;
typedef signed int int32_t;
typedef signed char int8_t;

typedef volatile uint8_t* vram_ptr;
static vram_ptr const vram = reinterpret_cast<vram_ptr>(0xA0000);

#include "logo_data.h"
#include "load_data.h"
#include "HZK X Python/hzk_mini12.h"
#include "mouse_data.h"

static inline void out8(uint16_t port, uint8_t value) {
    __asm__ volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t in8(uint16_t port) {
    uint8_t value;
    __asm__ volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void serial_initialize();
static void serial_write(const char* text);
static void fill(uint8_t color);
static void rectangle(uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t color);
static void character(uint16_t x, uint16_t y, char value, uint8_t color, uint8_t scale);
static void text(uint16_t x, uint16_t y, const char* value, uint8_t color, uint8_t scale);
static void progress(uint8_t percent);
static void login_screen();
static void desktop_screen();
static void chinese_char(uint16_t x, uint16_t y, uint16_t gb, uint8_t color);
static void mouse_init();
static void mouse_update();
static void draw_mouse_cursor(uint16_t x, uint16_t y, uint8_t color);

extern "C" __attribute__((noreturn)) void kernel_main() {
    serial_initialize();
    serial_write("Nova OS: C++ kernel started");
    serial_write("Dev-C++ MinGW, 32-bit protected mode");

    fill(1);
    rectangle(24, 20, 272, 160, 8);
    rectangle(28, 24, 264, 152, 1);
    
    draw_logo((320 - logo_width) / 2, 40);
    
    rectangle(58, 145, 204, 12, 8);
    rectangle(62, 149, 196, 4, 3);

    for (uint8_t percent = 0; percent <= 100; percent += 10) {
        progress(percent);
        for (volatile uint32_t delay = 0; delay < 5000000; ++delay) {
        }
    }

    serial_write("Nova OS loading screen ready");

    login_screen();

    for (;;) {
        __asm__ volatile("hlt");
    }
}

static void login_screen() {
    fill(1);
    rectangle(80, 40, 160, 120, 8);
    rectangle(82, 42, 156, 116, 0);
    
    rectangle(110, 90, 100, 16, 14);
    chinese_char(148, 93, 0xB5C7, 0);
    chinese_char(160, 93, 0xC2BC, 0);
    
    mouse_init();
    
    uint16_t mouse_x = 160;
    uint16_t mouse_y = 100;
    uint16_t prev_mouse_x = mouse_x;
    uint16_t prev_mouse_y = mouse_y;
    
    draw_mouse_cursor(mouse_x, mouse_y, 15);
    
    for (;;) {
        uint8_t scancode;
        int got_key = 0;
        int got_click = 0;
        
        __asm__ volatile(
            "inb $0x64, %%al\n"
            "testb $0x01, %%al\n"
            "jz 2f\n"
            "inb $0x60, %%al\n"
            "movb %%al, %0\n"
            "movb $1, %1\n"
            "jmp 3f\n"
            "2:\n"
            "movb $0, %1\n"
            "3:\n"
            : "=m"(scancode), "=m"(got_key)
            :
            : "al"
        );
        
        if (got_key && scancode == 0x1C) {
            break;
        }
        
        mouse_update();
        
        if (mouse_x != prev_mouse_x || mouse_y != prev_mouse_y) {
            draw_mouse_cursor(prev_mouse_x, prev_mouse_y, 1);
            draw_mouse_cursor(mouse_x, mouse_y, 15);
            prev_mouse_x = mouse_x;
            prev_mouse_y = mouse_y;
        }
        
        if (mouse_x >= 110 && mouse_x <= 210 && mouse_y >= 90 && mouse_y <= 106) {
            got_click = 1;
        }
        
        if (got_click) {
            break;
        }
        
        __asm__ volatile("hlt");
    }
    
    desktop_screen();
}

static void chinese_char(uint16_t x, uint16_t y, uint16_t gb, uint8_t color) {
    const unsigned char* glyph = 0;
    uint8_t gb_high = (gb >> 8) & 0xFF;
    uint8_t gb_low = gb & 0xFF;
    
    for (int i = 0; i < HZK12_MAP_COUNT; i++) {
        if (hzk12_mapping[i].gb_high == gb_high && hzk12_mapping[i].gb_low == gb_low) {
            glyph = &kernel_hzk12_mini[hzk12_mapping[i].idx * HZK12_PER_GLYPH];
            break;
        }
    }
    
    if (!glyph) return;
    
    for (int row = 0; row < HZK12_HEIGHT; row++) {
        unsigned char byte1 = glyph[row * 2];
        unsigned char byte2 = glyph[row * 2 + 1];
        for (int col = 0; col < HZK12_WIDTH; col++) {
            unsigned char bit = (col < 8) ? (byte1 >> (7 - col)) : (byte2 >> (15 - col));
            if (bit & 1) {
                vram[(y + row) * 320u + x + col] = color;
            }
        }
    }
}

static void desktop_screen() {
    fill(1);
    text(10, 10, "Nova OS Desktop", 15, 1);
    
    for (;;) {
        __asm__ volatile("hlt");
    }
}

static uint16_t g_mouse_x = 160;
static uint16_t g_mouse_y = 100;

static void mouse_init() {
    __asm__ volatile(
        "mov $0xA8, %%al\n"
        "outb %%al, $0x64\n"
        "mov $0x20, %%al\n"
        "outb %%al, $0x64\n"
        "inb $0x60, %%al\n"
        "orb $0x02, %%al\n"
        "mov $0x60, %%al\n"
        "outb %%al, $0x64\n"
        "inb $0x60, %%al\n"
        "mov %%al, %%bl\n"
        "mov $0xD4, %%al\n"
        "outb %%al, $0x64\n"
        "mov $0xF4, %%al\n"
        "outb %%al, $0x60\n"
        "inb $0x60, %%al\n"
        :
        :
        : "al", "bl"
    );
}

static void mouse_update() {
    static int phase = 0;
    static int8_t mx = 0, my = 0;
    uint8_t b;
    int has_data = 0;
    
    __asm__ volatile(
        "inb $0x64, %%al\n"
        "testb $0x01, %%al\n"
        "jz 2f\n"
        "inb $0x60, %%al\n"
        "movb %%al, %0\n"
        "movb $1, %1\n"
        "jmp 3f\n"
        "2:\n"
        "movb $0, %1\n"
        "3:\n"
        : "=m"(b), "=m"(has_data)
        :
        : "al"
    );
    
    if (!has_data) return;
    
    if (phase == 0) {
        if (b & 0x08) {
            phase = 1;
        }
    } else if (phase == 1) {
        mx = (int8_t)b;
        phase = 2;
    } else if (phase == 2) {
        my = (int8_t)b;
        phase = 0;
        
        g_mouse_x += mx;
        g_mouse_y -= my;
        
        if (g_mouse_x > 307) g_mouse_x = 307;
        if (g_mouse_y > 184) g_mouse_y = 184;
    }
}

static void draw_mouse_cursor(uint16_t x, uint16_t y, uint8_t color) {
    for (uint16_t row = 0; row < mouse_height; ++row) {
        for (uint16_t col = 0; col < mouse_width; ++col) {
            uint8_t pixel = mouse_data[row * mouse_width + col];
            if (pixel == 14) {
                vram[(y + row) * 320u + x + col] = color;
            }
        }
    }
}

static void fill(uint8_t color) {
    for (uint32_t index = 0; index < 320u * 200u; ++index) {
        vram[index] = color;
    }
}

static void rectangle(uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t color) {
    for (uint16_t row = 0; row < height; ++row) {
        for (uint16_t column = 0; column < width; ++column) {
            vram[(y + row) * 320u + x + column] = color;
        }
    }
}

static void progress(uint8_t percent) {
    rectangle(62, 149, 196, 4, 3);
    rectangle(62, 149, static_cast<uint16_t>(196u * percent / 100u), 4, 10);
}

static const uint8_t* glyph(char value) {
    static const uint8_t blank[7] = {0, 0, 0, 0, 0, 0, 0};
    static const uint8_t letters[27][7] = {
        {14, 17, 17, 31, 17, 17, 17}, {30, 17, 17, 30, 17, 17, 30},
        {14, 17, 16, 16, 16, 17, 14}, {30, 17, 17, 17, 17, 17, 30},
        {31, 16, 16, 30, 16, 16, 31}, {31, 16, 16, 30, 16, 16, 16},
        {14, 17, 16, 23, 17, 17, 15}, {17, 17, 17, 31, 17, 17, 17},
        {14, 4, 4, 4, 4, 4, 14}, {7, 2, 2, 2, 18, 18, 12},
        {17, 18, 20, 24, 20, 18, 17}, {16, 16, 16, 16, 16, 16, 31},
        {17, 27, 21, 21, 17, 17, 17}, {17, 25, 21, 19, 17, 17, 17},
        {14, 17, 17, 17, 17, 17, 14}, {30, 17, 17, 30, 16, 16, 16},
        {14, 17, 17, 17, 21, 18, 13}, {30, 17, 17, 30, 20, 18, 17},
        {15, 16, 16, 14, 1, 1, 30}, {31, 4, 4, 4, 4, 4, 4},
        {17, 17, 17, 17, 17, 17, 14}, {17, 17, 17, 17, 17, 10, 4},
        {17, 17, 17, 21, 21, 27, 17}, {17, 17, 10, 4, 10, 17, 17},
        {17, 17, 10, 4, 4, 4, 4}, {31, 1, 2, 4, 8, 16, 31},
        {0, 0, 0, 0, 0, 0, 0}
    };
    if (value >= 'A' && value <= 'Z') {
        return letters[value - 'A'];
    }
    if (value == ' ') {
        return blank;
    }
    return blank;
}

static void character(uint16_t x, uint16_t y, char value, uint8_t color, uint8_t scale) {
    const uint8_t* bitmap = glyph(value);
    for (uint8_t row = 0; row < 7; ++row) {
        for (uint8_t column = 0; column < 5; ++column) {
            if ((bitmap[row] & (1u << (4u - column))) != 0) {
                rectangle(x + column * scale, y + row * scale, scale, scale, color);
            }
        }
    }
}

static void text(uint16_t x, uint16_t y, const char* value, uint8_t color, uint8_t scale) {
    while (*value != '\0') {
        character(x, y, *value++, color, scale);
        x += static_cast<uint16_t>(6u * scale);
    }
}

static void serial_initialize() {
    out8(0x3F9, 0x00);
    out8(0x3FB, 0x80);
    out8(0x3F8, 0x01);
    out8(0x3F9, 0x00);
    out8(0x3FB, 0x03);
    out8(0x3FA, 0xC7);
    out8(0x3FC, 0x0B);
}

static void serial_write(const char* text_value) {
    while (*text_value != '\0') {
        while ((in8(0x3FD) & 0x20) == 0) {
        }
        out8(0x3F8, static_cast<uint8_t>(*text_value++));
    }
    out8(0x3F8, '\r');
    out8(0x3F8, '\n');
}