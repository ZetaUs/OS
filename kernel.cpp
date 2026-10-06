typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;

static void pixel(uint16_t x, uint16_t y, uint8_t color);

#include "logo_data.h"

extern "C" void login_screen();
extern "C" void desktop_screen();

static volatile uint32_t* loading_framebuffer;
static uint32_t loading_pitch;
static const uint32_t loading_palette[16] = {
    0x000000, 0x0000AA, 0x00AA00, 0x00AAAA,
    0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA,
    0x555555, 0x5555FF, 0x55FF55, 0x55FFFF,
    0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF
};

static uint8_t in8(uint16_t port) {
    uint8_t value;
    __asm__ volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void out8(uint16_t port, uint8_t value) {
    __asm__ volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static uint16_t pit_read_count() {
    out8(0x43, 0);
    uint16_t low = in8(0x40);
    uint16_t high = in8(0x40);
    return low | (high << 8);
}

static void pixel(uint16_t x, uint16_t y, uint8_t color_index) {
    const uint32_t scale = 6;
    const uint32_t color = loading_palette[color_index & 0x0F];

    for (uint32_t dy = 0; dy < scale; ++dy) {
        volatile uint32_t* row = reinterpret_cast<volatile uint32_t*>(
            reinterpret_cast<volatile uint8_t*>(loading_framebuffer) + (y * scale + dy) * loading_pitch
        );
        for (uint32_t dx = 0; dx < scale; ++dx) {
            row[x * scale + dx] = color;
        }
    }
}

static void draw_loading_rect(uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t color) {
    for (uint16_t row = 0; row < height; ++row) {
        for (uint16_t column = 0; column < width; ++column) {
            pixel(x + column, y + row, color);
        }
    }
}

static void show_loading(uint32_t framebuffer_base, uint32_t width, uint32_t height, uint32_t pitch) {
    volatile uint8_t* framebuffer = reinterpret_cast<volatile uint8_t*>(framebuffer_base);

    for (uint32_t y = 0; y < height; ++y) {
        volatile uint32_t* row = reinterpret_cast<volatile uint32_t*>(framebuffer + y * pitch);
        for (uint32_t x = 0; x < width; ++x) {
            row[x] = 0x00101A30;
        }
    }

    loading_framebuffer = reinterpret_cast<volatile uint32_t*>(framebuffer_base);
    loading_pitch = pitch;
    draw_logo(static_cast<uint16_t>((width / 6 - logo_width) / 2),
              static_cast<uint16_t>((height / 6 - logo_height) / 2));

    const uint16_t progress_x = static_cast<uint16_t>((width / 6 - 160) / 2);
    const uint16_t progress_y = static_cast<uint16_t>(height / 6 - 30);
    draw_loading_rect(progress_x, progress_y, 160, 8, 15);
    draw_loading_rect(progress_x + 1, progress_y + 1, 158, 6, 8);

    uint16_t previous = pit_read_count();
    uint32_t elapsed_ticks = 0;
    uint32_t filled_width = 0;
    while (elapsed_ticks < 55) {
        const uint16_t current = pit_read_count();
        if (current > previous) {
            ++elapsed_ticks;
            const uint32_t next_width = (158 * elapsed_ticks) / 55;
            if (next_width > filled_width) {
                draw_loading_rect(
                    static_cast<uint16_t>(progress_x + 1 + filled_width),
                    progress_y + 1,
                    static_cast<uint16_t>(next_width - filled_width),
                    6,
                    9
                );
                filled_width = next_width;
            }
        }
        previous = current;
    }
}

extern "C" __attribute__((noreturn)) void kernel_main(
    uint32_t framebuffer_base,
    uint32_t width,
    uint32_t height,
    uint32_t pitch,
    uint32_t bpp
) {
    volatile uint32_t* video_info = reinterpret_cast<volatile uint32_t*>(0x5000);
    video_info[0] = framebuffer_base;
    video_info[1] = width;
    video_info[2] = height;
    video_info[3] = pitch;
    video_info[4] = bpp;

    show_loading(framebuffer_base, width, height, pitch);
    login_screen();
    desktop_screen();

    for (;;) {
        __asm__ volatile("hlt");
    }
}
