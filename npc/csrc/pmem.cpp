#include "device.h"
#include "verilated_dpi.h"
#include <common.h>
#include <sys/time.h>

#define DEVICE_BASE 0xa0000000

#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#define RTC_ADDR (DEVICE_BASE + 0x0000048)

word_t pmem[0x10000000] = {};
bool print_mtrace = false;

extern uint64_t begin_us;

extern bool skip_ref_inst;

extern "C" void flash_read(int32_t addr, int32_t *data) {
  int tmp = pmem[addr / 4];
  *data = ((tmp >> 24) & 0xff) | (tmp << 24) | ((tmp & 0xff00) << 8) |
          ((tmp >> 8) & 0xff00);
}

extern "C" void mrom_read(int32_t addr, int32_t *data) {
  uint8_t *tmp = (uint8_t *)pmem;
  addr &= ~3;
  tmp += addr - 0x20000000;
  *data = *(int32_t *)tmp;
}

extern "C" word_t pmem_read(paddr_t addr) {
  word_t result;
  if (addr == RTC_ADDR || addr == RTC_ADDR + 4) {
    static uint64_t us;
    if (addr == RTC_ADDR + 4) {
      struct timeval now;
      gettimeofday(&now, NULL);
      us = now.tv_sec * 1000000 + now.tv_usec - begin_us;
      result = us >> 32;
    } else {
      result = us & 0xFFFFFFFF;
    }
    skip_ref_inst = true;
  } else {
    uint8_t *pmem_addr = (uint8_t *)pmem;
    pmem_addr += (addr - 0x80000000);
    result = *(word_t *)pmem_addr;
  }
#ifdef MTRACE
  extern uint64_t total_insts_num;
  if (print_mtrace && total_insts_num < 10000)
    fprintf(log_fp, "read addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\n", addr,
            result);
#endif
  return result;
}

extern "C" void pmem_write(word_t addr, word_t data, int mask) {
#ifdef MTRACE
  extern uint64_t total_insts_num;
  if (print_mtrace && total_insts_num < 10000)
    fprintf(log_fp, "write addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\n", addr,
            data);
#endif
  if (addr == SERIAL_PORT) {
    skip_ref_inst = true;
    putc(data, stderr);
    return;
  }

  uint8_t *pmem_addr = (uint8_t *)pmem;
  pmem_addr += (addr - 0x80000000);
  word_t origin_data = *(word_t *)pmem_addr;
  *(word_t *)pmem_addr = (origin_data & ~mask) | (data & mask);
}

extern "C" void psram_read(paddr_t addr, int *data) {
  word_t result;
  result = pmem[addr / 4];
#ifdef MTRACE
  extern uint64_t total_insts_num;
  if (print_mtrace && total_insts_num < 10000)
    fprintf(log_fp, "read addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\n", addr,
            result);
#endif
  *data = result;
  printf("---%d\n",*data);
}

extern "C" void psram_write(word_t addr, word_t data, int mask) {
#ifdef MTRACE
  extern uint64_t total_insts_num;
  if (print_mtrace && total_insts_num < 10000)
    fprintf(log_fp, "write addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\n", addr,
            data);
#endif
  uint8_t *pmem_addr = (uint8_t *)pmem;
  pmem_addr += addr;
  word_t origin_data = *(word_t *)pmem_addr;
  *(word_t *)pmem_addr = (origin_data & ~mask) | (data & mask);
}