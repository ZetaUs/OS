#include <stdint.h>
#include <stddef.h>

typedef uint64_t EFI_STATUS;
typedef uint64_t EFI_UINTN;
typedef void* EFI_HANDLE;

struct EFI_GUID {
    uint32_t data1;
    uint16_t data2;
    uint16_t data3;
    uint8_t data4[8];
};

struct EFI_TABLE_HEADER {
    uint64_t signature;
    uint32_t revision;
    uint32_t header_size;
    uint32_t crc32;
    uint32_t reserved;
};

struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    void* reset;
    EFI_STATUS (*output_string)(EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL*, const uint16_t*);
    void* test_string;
    void* query_mode;
    void* set_mode;
    void* set_attribute;
    void* clear_screen;
    void* set_cursor_position;
    void* enable_cursor;
    void* mode;
};

struct EFI_SYSTEM_TABLE;

struct EFI_BOOT_SERVICES {
    EFI_TABLE_HEADER header;
    void* raise_tpl;
    void* restore_tpl;
    EFI_STATUS (*allocate_pages)(uint32_t, uint32_t, EFI_UINTN, uint64_t*);
    void* free_pages;
    EFI_STATUS (*get_memory_map)(EFI_UINTN*, void*, uint64_t*, EFI_UINTN*, uint32_t*);
    EFI_STATUS (*allocate_pool)(uint32_t, EFI_UINTN, void**);
    EFI_STATUS (*free_pool)(void*);
    void* create_event;
    void* set_timer;
    void* wait_for_event;
    void* signal_event;
    void* close_event;
    void* check_event;
    void* install_protocol_interface;
    void* reinstall_protocol_interface;
    void* uninstall_protocol_interface;
    EFI_STATUS (*handle_protocol)(EFI_HANDLE, EFI_GUID*, void**);
    void* reserved;
    void* register_protocol_notify;
    void* locate_handle;
    void* locate_device_path;
    void* install_configuration_table;
    void* load_image;
    void* start_image;
    void* exit;
    void* unload_image;
    EFI_STATUS (*exit_boot_services)(EFI_HANDLE, uint64_t);
    void* get_next_monotonic_count;
    EFI_STATUS (*stall)(EFI_UINTN);
    EFI_STATUS (*set_watchdog_timer)(EFI_UINTN, uint64_t, EFI_UINTN, uint16_t*);
    void* connect_controller;
    void* disconnect_controller;
    void* open_protocol;
    void* close_protocol;
    void* open_protocol_information;
    void* protocols_per_handle;
    void* locate_handle_buffer;
    EFI_STATUS (*locate_protocol)(EFI_GUID*, void*, void**);
};

struct EFI_RUNTIME_SERVICES {
    EFI_TABLE_HEADER header;
    void* get_time;
    void* set_time;
    void* get_wakeup_time;
    void* set_wakeup_time;
    void* set_virtual_address_map;
    void* convert_pointer;
    void* get_variable;
    void* get_next_variable_name;
    void* set_variable;
    void* get_next_high_monotonic_count;
    void* reset_system;
};

struct EFI_SYSTEM_TABLE {
    EFI_TABLE_HEADER header;
    uint16_t* firmware_vendor;
    uint32_t firmware_revision;
    EFI_HANDLE console_in_handle;
    void* console_in;
    EFI_HANDLE console_out_handle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL* console_out;
    EFI_HANDLE standard_error_handle;
    void* standard_error;
    EFI_RUNTIME_SERVICES* runtime_services;
    EFI_BOOT_SERVICES* boot_services;
};

struct EFI_GRAPHICS_OUTPUT_MODE_INFORMATION {
    uint32_t version;
    uint32_t horizontal_resolution;
    uint32_t vertical_resolution;
    uint32_t pixel_format;
    uint32_t pixel_information[4];
    uint32_t pixels_per_scan_line;
};

struct EFI_GRAPHICS_OUTPUT_MODE {
    uint32_t max_mode;
    uint32_t mode;
    EFI_GRAPHICS_OUTPUT_MODE_INFORMATION* info;
    EFI_UINTN size_of_info;
    uint64_t framebuffer_base;
    EFI_UINTN framebuffer_size;
};

struct EFI_GRAPHICS_OUTPUT_PROTOCOL {
    EFI_STATUS (*query_mode)(EFI_GRAPHICS_OUTPUT_PROTOCOL*, uint32_t, EFI_UINTN*,
                             EFI_GRAPHICS_OUTPUT_MODE_INFORMATION**);
    EFI_STATUS (*set_mode)(EFI_GRAPHICS_OUTPUT_PROTOCOL*, uint32_t);
    void* blt;
    EFI_GRAPHICS_OUTPUT_MODE* mode;
};

struct EFI_LOADED_IMAGE_PROTOCOL {
    uint32_t revision;
    EFI_HANDLE parent_handle;
    EFI_SYSTEM_TABLE* system_table;
    EFI_HANDLE device_handle;
    void* file_path;
    void* reserved;
    uint32_t load_options_size;
    void* load_options;
    void* image_base;
    uint64_t image_size;
    uint32_t image_code_type;
    uint32_t image_data_type;
    void* unload;
};

typedef EFI_STATUS (*EFI_RESET_SYSTEM)(uint32_t, EFI_STATUS, EFI_UINTN, void*);

static EFI_GUID gop_guid = {
    0x9042A9DE, 0x23DC, 0x4A38,
    {0x96, 0xFB, 0x7A, 0xDE, 0xD0, 0x80, 0x51, 0x6A}
};

static EFI_GUID loaded_image_guid = {
    0x5B1B31A1, 0x9562, 0x11D2,
    {0x8E, 0x3F, 0x00, 0xA0, 0xC9, 0x69, 0x72, 0x3B}
};

extern "C" const uint8_t uefi_kernel_image[];
extern "C" const uint8_t uefi_kernel_image_end[];
extern "C" [[noreturn]] void enter_kernel(uint32_t entry, uint32_t framebuffer);

static void show_error(EFI_SYSTEM_TABLE* system_table, const uint16_t* message) {
    if (system_table->console_out != 0 && system_table->console_out->output_string != 0) {
        system_table->console_out->output_string(system_table->console_out, message);
    }
    for (;;) {
        system_table->boot_services->stall(1000000);
    }
}

extern "C" EFI_STATUS efi_main(EFI_HANDLE image_handle, EFI_SYSTEM_TABLE* system_table) {
    EFI_BOOT_SERVICES* boot = system_table->boot_services;
    EFI_GRAPHICS_OUTPUT_PROTOCOL* graphics = 0;
    EFI_STATUS status = boot->set_watchdog_timer(0, 0, 0, 0);
    if (status != 0) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','c','a','n','n','o','t',' ','d','i','s','a','b','l','e',' ','U','E','F','I',' ','w','a','t','c','h','d','o','g','.',13,10,0};
        show_error(system_table, message);
    }

    status = boot->locate_protocol(&gop_guid, 0, reinterpret_cast<void**>(&graphics));
    if (status != 0 || graphics == 0 || graphics->mode == 0) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','G','O','P',' ','g','r','a','p','h','i','c','s',' ','n','o','t',' ','a','v','a','i','l','a','b','l','e','.',13,10,0};
        show_error(system_table, message);
    }

    bool selected_mode = false;
    for (uint32_t mode = 0; mode < graphics->mode->max_mode; ++mode) {
        EFI_UINTN info_size = 0;
        EFI_GRAPHICS_OUTPUT_MODE_INFORMATION* info = 0;
        status = graphics->query_mode(graphics, mode, &info_size, &info);
        if (status != 0 || info == 0) {
            continue;
        }

        const bool supported = info->horizontal_resolution == 1920 &&
                               info->vertical_resolution == 1080 &&
                               info->pixel_format == 1 &&
                               info->pixels_per_scan_line == 1920;
        boot->free_pool(info);
        if (supported && graphics->set_mode(graphics, mode) == 0) {
            selected_mode = true;
            break;
        }
    }

    if (!selected_mode || graphics->mode == 0 ||
        graphics->mode->framebuffer_base > 0xFFFFFFFFu ||
        graphics->mode->framebuffer_size < 1920u * 1080u * 4u) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','r','e','q','u','i','r','e','s',' ','1','9','2','0','x','1','0','8','0',' ','G','O','P',' ','B','G','R','X',' ','m','o','d','e',' ','b','e','l','o','w',' ','4',' ','G','B','.',13,10,0};
        show_error(system_table, message);
    }

    void* image_protocol_pointer = 0;
    status = boot->handle_protocol(image_handle, &loaded_image_guid, &image_protocol_pointer);
    if (status != 0 || image_protocol_pointer == 0) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','c','a','n','n','o','t',' ','r','e','a','d',' ','U','E','F','I',' ','i','m','a','g','e',' ','i','n','f','o','.',13,10,0};
        show_error(system_table, message);
    }

    EFI_LOADED_IMAGE_PROTOCOL* loaded_image =
        static_cast<EFI_LOADED_IMAGE_PROTOCOL*>(image_protocol_pointer);
    const uint64_t image_base = reinterpret_cast<uint64_t>(loaded_image->image_base);
    if (image_base > 0xFFFFFFFFu || loaded_image->image_size > 0xFFFFFFFFu - image_base) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','U','E','F','I',' ','l','o','a','d','e','r',' ','m','u','s','t',' ','r','e','s','i','d','e',' ','b','e','l','o','w',' ','4',' ','G','B','.',13,10,0};
        show_error(system_table, message);
    }

    const size_t kernel_size = static_cast<size_t>(uefi_kernel_image_end - uefi_kernel_image);
    if (kernel_size == 0 || kernel_size > 32768) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','b','u','i','l','t','-','i','n',' ','k','e','r','n','e','l',' ','i','s',' ','t','o','o',' ','l','a','r','g','e','.',13,10,0};
        show_error(system_table, message);
    }

    uint64_t kernel_address = 0x200000;
    status = boot->allocate_pages(2, 2, 32, &kernel_address);
    if (status != 0 || kernel_address != 0x200000) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','c','o','u','l','d',' ','n','o','t',' ','r','e','s','e','r','v','e',' ','k','e','r','n','e','l',' ','m','e','m','o','r','y','.',13,10,0};
        show_error(system_table, message);
    }

    volatile uint8_t* kernel_destination = reinterpret_cast<volatile uint8_t*>(kernel_address);
    for (size_t index = 0; index < 32u * 4096u; ++index) {
        kernel_destination[index] = 0;
    }
    for (size_t index = 0; index < kernel_size; ++index) {
        kernel_destination[index] = uefi_kernel_image[index];
    }

    static const uint16_t loading_message[] = {'N','o','v','a',' ','O','S',' ','U','E','F','I',':',' ','s','t','a','r','t','i','n','g',' ','k','e','r','n','e','l','.',13,10,0};
    if (system_table->console_out != 0 && system_table->console_out->output_string != 0) {
        system_table->console_out->output_string(system_table->console_out, loading_message);
    }

    void* memory_map = 0;
    status = boot->allocate_pool(2, 65536, &memory_map);
    if (status != 0 || memory_map == 0) {
        static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','c','o','u','l','d',' ','n','o','t',' ','a','l','l','o','c','a','t','e',' ','U','E','F','I',' ','m','e','m','o','r','y',' ','m','a','p','.',13,10,0};
        show_error(system_table, message);
    }

    EFI_UINTN map_size = 65536;
    EFI_UINTN descriptor_size = 0;
    uint32_t descriptor_version = 0;
    uint64_t map_key = 0;
    for (uint32_t attempt = 0; attempt < 4; ++attempt) {
        map_size = 65536;
        status = boot->get_memory_map(&map_size, memory_map, &map_key,
                                      &descriptor_size, &descriptor_version);
        if (status != 0) {
            static const uint16_t message[] = {'N','o','v','a',' ','O','S',':',' ','U','E','F','I',' ','m','e','m','o','r','y',' ','m','a','p',' ','r','e','a','d',' ','f','a','i','l','e','d','.',13,10,0};
            show_error(system_table, message);
        }

        status = boot->exit_boot_services(image_handle, map_key);
        if (status == 0) {
            enter_kernel(0x200000, static_cast<uint32_t>(graphics->mode->framebuffer_base));
        }
    }

    static const uint16_t exit_message[] = {'N','o','v','a',' ','O','S',':',' ','c','o','u','l','d',' ','n','o','t',' ','e','x','i','t',' ','U','E','F','I',' ','b','o','o','t',' ','s','e','r','v','i','c','e','s','.',13,10,0};
    show_error(system_table, exit_message);
}
