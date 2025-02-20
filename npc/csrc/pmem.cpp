#include "device.h"
#include "verilated_dpi.h"
#include <common.h>
#include <sys/time.h>

#define DEVICE_BASE 0xa0000000

#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#define RTC_ADDR (DEVICE_BASE + 0x0000048)

word_t flash[0x10000000] = {};
word_t psram[0x100000] = {};
bool print_mtrace = false;

extern uint64_t begin_us;

extern bool skip_ref_inst;

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

extern "C" void psram_read(paddr_t addr, int *data) {
  word_t result;
  result = psram[addr / 4];
#ifdef MTRACE
  extern uint64_t total_insts_num;
  if (print_mtrace && total_insts_num < 10000)
    fprintf(log_fp, "read addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\n", addr,
            result);
#endif
  *data = result;
}

extern "C" void psram_write(word_t addr, word_t data, int mask) {
#ifdef MTRACE
  extern uint64_t total_insts_num;
  if (print_mtrace && total_insts_num < 10000)
    fprintf(log_fp,
            "write addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\tmask:" FMT_WORD
            "\n",
            addr, data, mask);
#endif
  uint8_t *psram_addr = (uint8_t *)psram;
  psram_addr += addr;
  word_t origin_data = *(word_t *)psram_addr;
  *(word_t *)psram_addr = (origin_data & ~mask) | (data & mask);
}