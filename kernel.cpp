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

// VGA text mode buffer
static volatile uint16_t* vga_text = (volatile uint16_t*)0xB8000;

static inline void out8(uint16_t port, uint8_t value) {
    __asm__ volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t in8(uint16_t port) {
    uint8_t value;
    __asm__ volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

// Write character to VGA text mode
static void vga_write_char(char c, uint8_t color, int x, int y) {
    vga_text[y * 80 + x] = (color << 8) | c;
}

static void vga_write_string(const char* str, uint8_t color, int x, int y) {
    int i = 0;
    while (str[i]) {
        vga_write_char(str[i], color, x + i, y);
        i++;
    }
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
    // First, write to VGA text mode to confirm kernel is running
    vga_write_string("KERNEL RUNNING", 0x0E, 0, 0);
    vga_write_string("FB=", 0x0A, 0, 1);
    
    // Convert framebuffer address to hex string
    char hex[] = "0x00000000";
    uint32_t addr = framebuffer_base;
    for (int i = 9; i >= 2; i--) {
        int digit = addr & 0xF;
        hex[i] = (digit < 10) ? ('0' + digit) : ('A' + digit - 10);
        addr >>= 4;
    }
    vga_write_string(hex, 0x0A, 3, 1);
    
    vga_write_string("W=", 0x0A, 0, 2);
    vga_write_string("H=", 0x0A, 10, 2);
    vga_write_string("BPP=", 0x0A, 20, 2);
    
    // Store parameters
    vram8 = reinterpret_cast<volatile uint8_t*>(framebuffer_base);
    screen_width = width;
    screen_height = height;
    screen_pitch = pitch;
    screen_bpp = bpp;
    
    // Fill screen with blue color
    uint32_t blue_color = 0x0000AA;
    for (uint32_t y = 0; y < screen_height; ++y) {
        for (uint32_t x = 0; x < screen_width; ++x) {
            write_pixel(x, y, blue_color);
        }
    }
    
    vga_write_string("DONE", 0x0C, 0, 3);
    
    for (;;) {
        __asm__ volatile("hlt");
    }
}