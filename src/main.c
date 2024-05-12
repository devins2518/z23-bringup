#include "hardware/clocks.h"
#include "incbin.h"
#include "pico/stdlib.h"
#include "rom.h"
#include <stdbool.h>
#include <stdio.h>

// INCBIN(ROM, "../meminit.bin");

#define DATA0_PIN 16
#define DATA1_PIN 17
#define DATA2_PIN 18
#define DATA3_PIN 19
#define DATA4_PIN 20
#define DATA5_PIN 21
#define DATA6_PIN 22
#define DATA7_PIN 26
#define DATA_MASK 0x047F0000

#define ADDR_MASK 0x0000FFFF

#define W_NR_PIN 27
#define W_NR_MASK 1 << W_NR_PIN

#define INIT_AND_SET_PIN(num, dir)                                                                 \
    {                                                                                              \
        gpio_init((num));                                                                          \
        gpio_set_dir((num), (dir));                                                                \
    }

void set_data_pins_in() {
    gpio_set_dir_in_masked(DATA_MASK);
}

void set_data_pins_out() {
    gpio_set_dir_out_masked(DATA_MASK);
}

uint16_t get_addr() {
    return gpio_get_all() & 0xFFFF;
}

uint8_t get_data() {
    uint32_t raw = gpio_get_all();
    raw = (((raw >> DATA7_PIN) & 0x1) << 7) | ((raw >> DATA0_PIN) & 0x7F);

    return raw;
}

uint8_t RAM[0x7FFF] = {0};

void __scratch_x("do_it_fast") drive_data_pins(uint8_t value) {
    uint32_t expanded = ((value >> 7) << DATA7_PIN) | ((value & 0x7F) << DATA0_PIN);
    gpio_put_masked(DATA_MASK, expanded);
}

void __scratch_x("do_it_fast") handle_write(uint16_t addr, uint8_t value) {
    if (addr <= 0x2000) {
        // ROM write, ignore
    } else if (addr <= 0x7FFF) {
        RAM[addr] = value;
    } else {
        // Unmapped
    }
}

void __scratch_x("do_it_fast") handle_read(uint16_t addr) {
    uint8_t value;
    if (addr <= 0x2000) {
        value = rom[addr];
    } else if (addr <= 0x7FFF) {
        value = RAM[addr];
    } else {
        // Unmapped
    }
    drive_data_pins(value);
}

void __scratch_x("do_it_fast") handle_bus() {
    while (true) {
        uint16_t addr = get_addr();
        bool write = addr > 0x2000;
        if (write) {
            set_data_pins_in();
            uint8_t value = get_data();
            addr = get_addr();
            // printf("got write! addr %x, data %x\n", addr, value);
            handle_write(addr, value);
        } else {
            set_data_pins_out();
            handle_read(addr);
        }
    }
}

#define PLL_SYS_KHZ (200 * 1000)

int __scratch_x("do_it_fast") main() {
    // Set clock to 200mhz
    set_sys_clock_khz(PLL_SYS_KHZ, true);

    stdio_init_all();
    gpio_init(25);
    gpio_set_dir(25, GPIO_OUT);
    gpio_put(25, 1);

    // Init pins
    gpio_init_mask(ADDR_MASK | DATA_MASK | W_NR_MASK);

    // Set up address pins
    gpio_set_dir_in_masked(ADDR_MASK);

    // Set up data pins
    set_data_pins_out();

    // Set up W/!R pin
    gpio_set_dir_in_masked(W_NR_MASK);

    handle_bus();
}
