#include "device.h"
#include "verilated_dpi.h"
#include <common.h>
#include <sys/time.h>

#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR (DEVICE_BASE + 0x0000060)
#define RTC_ADDR (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR (DEVICE_BASE + 0x0000100)
#define FB_ADDR (MMIO_BASE + 0x1000000)
#define SYNC_ADDR (VGACTL_ADDR + 4)

word_t *pmem = nullptr;
bool print_mtrace = false;

extern uint64_t begin_us;

extern bool skip_ref_inst;

extern "C" void flash_read(int32_t addr, int32_t *data) { assert(0); }
extern "C" void mrom_read(int32_t addr, int32_t *data) {
  uint8_t *tmp = (uint8_t *)pmem;
  tmp += addr - 0x20000000;

  *data = *(int32_t *)tmp;
}

extern "C" void set_memory_ptr(const svOpenArrayHandle r) {
  pmem = (word_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

void check_bound(paddr_t addr) {}

extern "C" word_t pmem_read(paddr_t addr) {
  check_bound(addr);

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