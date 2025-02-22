#include "verilated_dpi.h"
#include <common.h>

word_t flash[0x10000000] = {};
word_t psram[0x100000] = {};

extern "C" void flash_read(int32_t addr, int32_t *data) {
  int tmp = flash[addr / 4];
  *data = ((tmp >> 24) & 0xff) | (tmp << 24) | ((tmp & 0xff00) << 8) |
          ((tmp >> 8) & 0xff00);
}

extern "C" void mrom_read(int32_t addr, int32_t *data) { assert(0); }

extern "C" word_t pmem_read(paddr_t addr) {
  // disable in soc
  return 0;
}

extern "C" void pmem_write(word_t addr, word_t data, int mask) { assert(0); }

extern "C" void psram_read(paddr_t addr, int *data) { *data = psram[addr / 4]; }

extern "C" void psram_write(word_t addr, word_t data, int mask) {
  uint8_t *psram_addr = (uint8_t *)psram;
  psram_addr += addr;
  word_t origin_data = *(word_t *)psram_addr;
  *(word_t *)psram_addr = (origin_data & ~mask) | (data & mask);
}