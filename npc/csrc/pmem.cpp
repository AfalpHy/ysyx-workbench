#include "verilated_dpi.h"
#include <common.h>

word_t flash[0x10000000] = {};
word_t psram[0x100000] = {};

#define CONFIG_FLASH_BASE 0x30000000
#define CONFIG_FLASH_SIZE 0x1000000

#define CONFIG_PSRAM_BASE 0x80000000
#define CONFIG_PSRAM_SIZE 0x400000

#define CONFIG_SRAM_SIZE 0x2000
#define CONFIG_SRAM_BASE 0xf000000

#define CONFIG_SDRAM_SIZE 0x4000000
#define CONFIG_SDRAM_BASE 0xa0000000

static uint8_t sram[CONFIG_SRAM_SIZE] = {};
static uint8_t sdram[CONFIG_SDRAM_SIZE] = {};

uint8_t *sram2host(paddr_t paddr) { return sram + paddr - CONFIG_SRAM_BASE; }
uint8_t *sdram2host(paddr_t paddr) { return sdram + paddr - CONFIG_SDRAM_BASE; }

static bool in_sram(paddr_t addr) {
  return addr - CONFIG_SRAM_BASE < CONFIG_SRAM_SIZE;
}

static bool in_flash(paddr_t addr) {
  return addr - CONFIG_FLASH_BASE < CONFIG_FLASH_SIZE;
}

static bool in_psram(paddr_t addr) {
  return addr - CONFIG_PSRAM_BASE < CONFIG_PSRAM_SIZE;
}

static bool in_sdram(paddr_t addr) {
  return addr - CONFIG_SDRAM_BASE < CONFIG_SDRAM_SIZE;
}

extern "C" void flash_read(int32_t addr, int32_t *data) {
  int tmp = flash[addr / 4];
  *data = ((tmp >> 24) & 0xff) | (tmp << 24) | ((tmp & 0xff00) << 8) |
          ((tmp >> 8) & 0xff00);
}

extern "C" void mrom_read(int32_t addr, int32_t *data) { assert(0); }

extern "C" void psram_read(paddr_t addr, int *data) { *data = psram[addr / 4]; }

extern "C" void psram_write(word_t addr, word_t data, int mask) {
  uint8_t *psram_addr = (uint8_t *)psram;
  psram_addr += addr;
  word_t origin_data = *(word_t *)psram_addr;
  *(word_t *)psram_addr = (origin_data & ~mask) | (data & mask);
}
word_t pmem_read(paddr_t addr) {
  // disable in soc
  return 0;
}

void pmem_write(word_t addr, word_t data, int mask) { assert(0); }
