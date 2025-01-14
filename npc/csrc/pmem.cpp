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

extern "C" void set_memory_ptr(const svOpenArrayHandle r) {
  pmem = (word_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

void check_bound(paddr_t addr) {}

extern "C" word_t pmem_read(paddr_t addr, int len) {
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
  } else if (addr == KBD_ADDR) {
    result = 0;
    skip_ref_inst = true;
  }
  // else if (addr == VGACTL_ADDR) {
  //   result = vgactl_port_base[0];
  // }
  else {
    uint8_t *pmem_addr = (uint8_t *)pmem;
    pmem_addr += (addr - 0x80000000);
    switch (len) {
    case 1:
      result = *pmem_addr;
      break;
    case 2:
      result = *(uint16_t *)pmem_addr;
      break;
    case 4:
      result = *(word_t *)pmem_addr;
      break;
    default:
      result = *(word_t *)pmem_addr;
    }
  }
#ifdef MTRACE
  extern uint64_t total_inst_num;
  if (print_mtrace && total_inst_num < 10000)
    fprintf(log_fp, "read addr:\t" FMT_PADDR "\tlen:%d\tdata:" FMT_WORD "\n",
            addr, len, result);
#endif
  return result;
}

extern "C" void pmem_write(word_t addr, word_t data, int len) {
#ifdef MTRACE
  extern uint64_t total_inst_num;
  if (print_mtrace && total_inst_num < 10000)
    fprintf(log_fp, "write addr:\t" FMT_PADDR "\tlen:%d\tdata:" FMT_WORD "\n",
            addr, len, data);
#endif
  if (addr == SERIAL_PORT) {
    skip_ref_inst = true;
    putc(data, stderr);
    return;
  }
  //  else if (addr >= FB_ADDR) {
  //   uint8_t *fb_addr = (uint8_t *)vmem;
  //   fb_addr += (addr - FB_ADDR);
  //   switch (len) {
  //   case 1:
  //     *fb_addr = data;
  //     return;
  //   case 2:
  //     *(uint16_t *)fb_addr = data;
  //     return;
  //   case 4:
  //     *(uint32_t *)fb_addr = data;
  //     return;
  //   default:
  //     *(word_t *)fb_addr = data;
  //     return;
  //   }
  // } else if (addr == SYNC_ADDR) {
  //   vgactl_port_base[1] = data;
  //   return;
  // }

  uint8_t *pmem_addr = (uint8_t *)pmem;
  pmem_addr += (addr - 0x80000000);
  switch (len) {
  case 1:
    *pmem_addr = data;
    break;
  case 2:
    *(uint16_t *)pmem_addr = data;
    break;
  case 4:
    *(uint32_t *)pmem_addr = data;
    break;
  default:
    *(word_t *)pmem_addr = data;
    break;
  }
}