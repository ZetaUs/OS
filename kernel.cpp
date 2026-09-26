typedef unsigned short uint16_t;
typedef unsigned char uint8_t;

static volatile uint16_t* const video_memory =
    reinterpret_cast<volatile uint16_t*>(0xB8000);
static uint16_t cursor = 0;

static inline void out8(uint16_t port, uint8_t value) {
    __asm__ volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t in8(uint16_t port) {
    uint8_t value;
    __asm__ volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
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

static void serial_write(const char* text) {
    while (*text != '\0') {
        while ((in8(0x3FD) & 0x20) == 0) {
        }
        out8(0x3F8, static_cast<uint8_t>(*text++));
    }
    out8(0x3F8, '\r');
    out8(0x3F8, '\n');
}

static void write_line(uint16_t row, const char* text, uint8_t color) {
    uint16_t column = 0;
    while (text[column] != '\0' && column < 80) {
        video_memory[row * 80 + column] =
            static_cast<uint16_t>((color << 8) | static_cast<uint8_t>(text[column]));
        ++column;
    }
}

extern "C" __attribute__((noreturn)) void kernel_main() {
    for (uint16_t cell = 0; cell < 80 * 25; ++cell) {
        video_memory[cell] = 0x0720;
    }

    serial_initialize();
    serial_write("Nova OS: C++ kernel started");
    serial_write("Dev-C++ MinGW, 32-bit protected mode");

    write_line(4, "NOVA OS", 0x0B);
    write_line(6, "C++ kernel is running in 32-bit protected mode.", 0x0F);
    write_line(8, "Built with the Dev-C++ MinGW toolchain.", 0x07);
    write_line(10, "BIOS loaded the kernel from disk.", 0x07);

    for (;;) {
        __asm__ volatile("hlt");
    }
}
