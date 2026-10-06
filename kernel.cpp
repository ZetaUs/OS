typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;

static void pixel(uint16_t x, uint16_t y, uint8_t shade);

#include "load_data.h"

extern "C" void login_screen();
extern "C" void desktop_screen();

static volatile uint32_t* loading_framebuffer;
static uint32_t loading_pitch;

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

static void pixel(uint16_t x, uint16_t y, uint8_t shade) {
    const uint32_t scale = 6;
    const uint8_t intensity = static_cast<uint8_t>((shade * 255) / 63);
    const uint32_t color = (intensity << 16) | (intensity << 8) | intensity;

    for (uint32_t dy = 0; dy < scale; ++dy) {
        volatile uint32_t* row = reinterpret_cast<volatile uint32_t*>(
            reinterpret_cast<volatile uint8_t*>(loading_framebuffer) + (y * scale + dy) * loading_pitch
        );
        for (uint32_t dx = 0; dx < scale; ++dx) {
            row[x * scale + dx] = color;
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
    draw_load(static_cast<uint16_t>((width / 6 - load_width) / 2),
              static_cast<uint16_t>((height / 6 - load_height) / 2));

    uint16_t previous = pit_read_count();
    uint32_t elapsed_ticks = 0;
    while (elapsed_ticks < 55) {
        const uint16_t current = pit_read_count();
        if (current > previous) {
            ++elapsed_ticks;
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
