typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;
typedef signed int int32_t;
typedef signed char int8_t;

static volatile uint8_t* vram8;
static uint32_t screen_width;
static uint32_t screen_height;
static uint32_t screen_pitch;
static uint32_t screen_bpp;

static inline void out8(uint16_t port, uint8_t value) {
    __asm__ volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t in8(uint16_t port) {
    uint8_t value;
    __asm__ volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

// Simple pixel write based on BPP
static inline void write_pixel(uint32_t x, uint32_t y, uint32_t color) {
    if (x >= screen_width || y >= screen_height) return;
    
    uint32_t offset = y * screen_pitch + x * (screen_bpp / 8);
    
    if (screen_bpp == 16) {
        uint16_t rgb565 = ((color >> 19) & 0x1F) << 11 |
                          ((color >> 10) & 0x3F) << 5 |
                          ((color >> 3) & 0x1F);
        vram8[offset] = rgb565 & 0xFF;
        vram8[offset + 1] = (rgb565 >> 8) & 0xFF;
    } else if (screen_bpp == 24) {
        vram8[offset] = color & 0xFF;
        vram8[offset + 1] = (color >> 8) & 0xFF;
        vram8[offset + 2] = (color >> 16) & 0xFF;
    } else if (screen_bpp == 32) {
        vram8[offset] = color & 0xFF;
        vram8[offset + 1] = (color >> 8) & 0xFF;
        vram8[offset + 2] = (color >> 16) & 0xFF;
        vram8[offset + 3] = 0xFF;
    }
}

extern "C" __attribute__((noreturn)) void kernel_main(uint32_t framebuffer_base, uint32_t width, uint32_t height, uint32_t pitch, uint32_t bpp) {
    vram8 = reinterpret_cast<volatile uint8_t*>(framebuffer_base);
    screen_width = width;
    screen_height = height;
    screen_pitch = pitch;
    screen_bpp = bpp;
    
    // Fill screen with blue color (0x0000AA in 24-bit = blue)
    uint32_t blue_color = 0x0000AA;
    for (uint32_t y = 0; y < screen_height; ++y) {
        for (uint32_t x = 0; x < screen_width; ++x) {
            write_pixel(x, y, blue_color);
        }
    }
    
    for (;;) {
        __asm__ volatile("hlt");
    }
}