typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;
typedef signed int int32_t;
typedef signed char int8_t;

static volatile uint32_t* vram;
static void pixel(uint32_t x, uint32_t y, uint8_t color);

#include "logo_data.h"
#include "load_data.h"

static const uint32_t screen_width = 1920;
static const uint32_t screen_height = 1080;
static const uint32_t logical_width = 320;
static const uint32_t logical_height = 180;
static const uint32_t scale = 6;

static const uint32_t colors[16] = {
    0x000000, 0x0000AA, 0x00AA00, 0x00AAAA,
    0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA,
    0x555555, 0x5555FF, 0x55FF55, 0x55FFFF,
    0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF
};

static inline void out8(uint16_t port, uint8_t value) {
    __asm__ volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t in8(uint16_t port) {
    uint8_t value;
    __asm__ volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void fill(uint8_t color);
static void rectangle(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint8_t color);
static void character(uint32_t x, uint32_t y, char value, uint8_t color, uint8_t scale);
static void text(uint32_t x, uint32_t y, const char* value, uint8_t color, uint8_t scale);
static void progress(uint8_t percent);
static void loading_status(const char* message, uint8_t percent);
static void loading_pause();
static uint16_t pit_counter();
static void serial_initialize();
static void serial_write(const char* text);

extern "C" void login_screen();
extern "C" void desktop_screen();

extern "C" __attribute__((noreturn)) void kernel_main(uint32_t framebuffer_base) {
    vram = reinterpret_cast<volatile uint32_t*>(framebuffer_base);
    fill(1);
    draw_logo(120, 35);
    progress(0);

    serial_initialize();
    serial_write("Nova OS: kernel entered");

    progress(25);
    serial_write("Nova OS: kernel started");
    loading_pause();

    progress(50);
    serial_write("Nova OS: video ready");
    loading_pause();

    progress(75);
    serial_write("Nova OS: preparing login");
    loading_pause();

    progress(100);
    serial_write("Nova OS: loading complete");
    loading_pause();

    login_screen();
    desktop_screen();

    for (;;) {
        __asm__ volatile("hlt");
    }
}

static void fill(uint8_t color) {
    const uint32_t pixel_color = colors[color & 0x0Fu];
    for (uint32_t index = 0; index < screen_width * screen_height; ++index) {
        vram[index] = pixel_color;
    }
}

static void pixel(uint32_t x, uint32_t y, uint8_t color) {
    if (x >= logical_width || y >= logical_height) {
        return;
    }

    const uint32_t pixel_color = colors[color & 0x0Fu];
    const uint32_t base_x = x * scale;
    const uint32_t base_y = y * scale;
    for (uint32_t row = 0; row < scale; ++row) {
        const uint32_t offset = (base_y + row) * screen_width + base_x;
        for (uint32_t column = 0; column < scale; ++column) {
            vram[offset + column] = pixel_color;
        }
    }
}

static void rectangle(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint8_t color) {
    if (x >= logical_width || y >= logical_height) {
        return;
    }
    if (width > logical_width - x) {
        width = logical_width - x;
    }
    if (height > logical_height - y) {
        height = logical_height - y;
    }

    const uint32_t pixel_color = colors[color & 0x0Fu];
    const uint32_t pixel_width = width * scale;
    const uint32_t pixel_height = height * scale;
    const uint32_t base_x = x * scale;
    const uint32_t base_y = y * scale;
    for (uint32_t row = 0; row < pixel_height; ++row) {
        uint32_t offset = (base_y + row) * screen_width + base_x;
        for (uint32_t column = 0; column < pixel_width; ++column) {
            vram[offset + column] = pixel_color;
        }
    }
}

static void progress(uint8_t percent) {
    if (percent > 100u) {
        percent = 100u;
    }
    rectangle(55, 155, 210, 8, 8);
    rectangle(57, 157, 206, 4, 0);
    rectangle(57, 157, 206u * percent / 100u, 4, 14);
}

static const uint8_t* glyph(char value) {
    static const uint8_t blank[7] = {0, 0, 0, 0, 0, 0, 0};
    static const uint8_t letters[26][7] = {
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
        {17, 17, 10, 4, 4, 4, 4}, {31, 1, 2, 4, 8, 16, 31}
    };
    if (value >= 'A' && value <= 'Z') {
        return letters[value - 'A'];
    }
    if (value >= 'a' && value <= 'z') {
        return letters[value - 'a'];
    }
    if (value == ' ' || value == '\n' || value == '\r' || value == '\t') {
        return blank;
    }
    return blank;
}

static void character(uint32_t x, uint32_t y, char value, uint8_t color, uint8_t scale) {
    if (value == '\0' || scale == 0) {
        return;
    }

    const uint8_t* bitmap = glyph(value);
    for (uint8_t row = 0; row < 7; ++row) {
        for (uint8_t column = 0; column < 5; ++column) {
            if ((bitmap[row] & (1u << (4u - column))) != 0) {
                rectangle(x + static_cast<uint32_t>(column) * scale,
                          y + static_cast<uint32_t>(row) * scale,
                          scale, scale, color);
            }
        }
    }
}

static void text(uint32_t x, uint32_t y, const char* value, uint8_t color, uint8_t scale) {
    uint32_t cursor_x = x;
    uint32_t cursor_y = y;

    while (*value != '\0' && cursor_y < 200u) {
        if (*value == '\n') {
            cursor_x = x;
            cursor_y += 8u * scale;
            ++value;
            continue;
        }
        if (*value == '\r') {
            cursor_x = x;
            ++value;
            continue;
        }

        character(cursor_x, cursor_y, *value++, color, scale);
        cursor_x += 6u * scale;
    }
}

static void loading_pause() {
    uint16_t previous = pit_counter();
    uint8_t ticks = 0;

    while (ticks < 18u) {
        const uint16_t current = pit_counter();
        if (current > previous) {
            ++ticks;
        }
        previous = current;
    }
}

static uint16_t pit_counter() {
    out8(0x43, 0x00);
    const uint8_t low = in8(0x40);
    const uint8_t high = in8(0x40);
    return static_cast<uint16_t>(low | (static_cast<uint16_t>(high) << 8));
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
        uint32_t timeout = 1000000u;
        while ((in8(0x3FD) & 0x20) == 0 && timeout != 0) {
            --timeout;
        }
        if (timeout != 0) {
            out8(0x3F8, static_cast<uint8_t>(*text_value));
        }
        ++text_value;
    }
    uint32_t timeout = 1000000u;
    while ((in8(0x3FD) & 0x20) == 0 && timeout != 0) {
        --timeout;
    }
    if (timeout != 0) {
        out8(0x3F8, '\r');
        out8(0x3F8, '\n');
    }
}