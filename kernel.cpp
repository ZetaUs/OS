typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;

typedef volatile uint8_t* vram_ptr;
static vram_ptr const vram = reinterpret_cast<vram_ptr>(0xA0000);

#include "logo_data.h"
#include "load_data.h"

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

extern "C" void _login_screen();

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

    // Call login screen
    _login_screen();

    for (;;) {
        __asm__ volatile("hlt");
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