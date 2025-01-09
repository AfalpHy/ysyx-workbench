#include "device.h"
#include "isa.h"
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

extern "C" void set_memory_ptr(const svOpenArrayHandle r) {
  pmem = (word_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" word_t pmem_read(paddr_t addr, int len) {
  word_t result;
  if (addr == RTC_ADDR) { // 时钟
    struct timeval now;
    gettimeofday(&now, NULL);
    uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
    result = us - begin_us;
  } else if (addr == KBD_ADDR) {
    result = 0;
  } else if (addr == VGACTL_ADDR) {
    result = vgactl_port_base[0];
  } else if (addr == SYNC_ADDR) {
    result = vgactl_port_base[1];
  }

  uint8_t *pmem_addr = (uint8_t *)pmem + (addr - 0x80000000);
  switch (len) {
  case 1:
    result = *pmem_addr;
  case 2:
    result = *(uint16_t *)pmem_addr;
  case 4:
    result = *(word_t *)pmem_addr;
  default:
    result = *(word_t *)pmem_addr;
  }
#ifdef MTRACE
  if (print_mtrace)
    fprintf(log_fp,
            "current pc" FMT_PADDR " read addr:\t" FMT_PADDR
            "\tlen:%d\tdata:" FMT_WORD "\n",
            *pc, addr, len, result);
#endif
  return result;
}

extern "C" void pmem_write(word_t addr, word_t data, int len) {
  if (addr == SERIAL_PORT) {
    putchar(data);
    return;
  } else if (addr >= FB_ADDR) {
    uint8_t *fb_addr = (uint8_t *)vmem + (addr - FB_ADDR);
    switch (len) {
    case 1:
      *fb_addr = data;
      break;
    case 2:
      *(uint16_t *)fb_addr = data;
      break;
    case 4:
      *(uint32_t *)fb_addr = data;
      break;
    default:
      *(word_t *)fb_addr = data;
      break;
    }
    return;
  } else if (addr == SYNC_ADDR) {
    vgactl_port_base[1] = data;
    return;
  }

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

#ifdef MTRACE
  if (print_mtrace)
    fprintf(log_fp,
            "current pc" FMT_PADDR " write addr:\t" FMT_PADDR
            "\tlen:%d\tdata:" FMT_WORD "\n",
            *pc, addr, len, data);
#endif
}