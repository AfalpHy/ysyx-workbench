#include "device.h"
#include "difftest.h"
#include "disasm.h"
#include "expr.h"
#include "sdb.h"
#include "verilated_dpi.h"
#include "watchpoint.h"
#include <VNPC.h>
#include <assert.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <vector>

using namespace std;

#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR (DEVICE_BASE + 0x0000060)
#define RTC_ADDR (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR (DEVICE_BASE + 0x0000100)
#define FB_ADDR (MMIO_BASE + 0x1000000)
#define SYNC_ADDR (VGACTL_ADDR + 4)

VNPC top;

word_t *regs, *pmem;
paddr_t *pc;
const char *regs_name[] = {"$0", "ra", "sp",  "gp",  "tp", "t0", "t1", "t2",
                           "s0", "s1", "a0",  "a1",  "a2", "a3", "a4", "a5",
                           "a6", "a7", "s2",  "s3",  "s4", "s5", "s6", "s7",
                           "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

int status = 0;
bool diff_test_on = false;
uint64_t begin_us;
extern bool skip_current_ref, skip_next_ref;

extern "C" void set_pc(const svOpenArrayHandle r) {
  pc = (paddr_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" void set_regs_ptr(const svOpenArrayHandle r) {
  regs = (word_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" void set_memory_ptr(const svOpenArrayHandle r) {
  pmem = (word_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" word_t pmem_read(paddr_t addr, int len) {
  if (addr == RTC_ADDR) { // 时钟
    skip_next_ref = true;
    struct timeval now;
    gettimeofday(&now, NULL);
    uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
    return us - begin_us;
  } else if (addr == KBD_ADDR) {
    skip_next_ref = true;
    return 0;
  } else if (addr == VGACTL_ADDR) {
    skip_next_ref = true;
    return vgactl_port_base[0];
  } else if (addr == SYNC_ADDR) {
    skip_next_ref = true;
    return vgactl_port_base[1];
  }

  uint8_t *pmem_addr = (uint8_t *)pmem + (addr - 0x80000000);
  switch (len) {
  case 1:
    return *pmem_addr;
  case 2:
    return *(uint16_t *)pmem_addr;
  case 4:
    return *(word_t *)pmem_addr;
  default:
    return *(word_t *)pmem_addr;
  }
}

// extern "C" void pmem_write(word_t addr, word_t data, int len) {
//   if (addr == SERIAL_PORT) { //串口
//     skip_current_ref = true;
//     putchar(data);
//     return;
//   } else if (addr >= FB_ADDR) {
//     skip_current_ref = true;
//     uint8_t *fb_addr = (uint8_t *)vmem + (addr - FB_ADDR);
//     switch (wrtype) {
//     case 0:
//       *fb_addr = data;
//       break;
//     case 1:
//       *(uint16_t *)fb_addr = data;
//       break;
//     case 2:
//       *(uint32_t *)fb_addr = data;
//       break;
//     default:
//       *(word_t *)fb_addr = data;
//       break;
//     }
//     return;
//   } else if (addr == SYNC_ADDR) {
//     skip_current_ref = true;
//     vgactl_port_base[1] = data;
//     return;
//   }

//   uint8_t *pmem_addr = (uint8_t *)pmem + (addr - 0x80000000);
//   switch (len) {
//   case 1:
//     *pmem_addr = data;
//     break;
//   case 2:
//     *(uint16_t *)pmem_addr = data;
//     break;
//   case 4:
//     *(uint32_t *)pmem_addr = data;
//     break;
//   default:
//     *(word_t *)pmem_addr = data;
//     break;
//   }
// }

word_t isa_reg_str2val(const char *s) {
  if (strcmp(s, "pc") == 0) {
    return *pc;
  }
  for (int i = 0; i < 32; i++) {
    if (strcmp(regs_name[i], s) == 0) {
      return regs[i];
    }
  }
  return 0;
}

void isa_reg_display() {
  for (int i = 0; i < 32; i++) {
    printf("%d\t%s\t" FMT_WORD_D "\t" FMT_WORD "\n", i, regs_name[i], regs[i],
           regs[i]);
  }
}

void single_cycle() {
  top.clk = 1;
  top.eval();
  top.clk = 0;
  top.eval();
}

void reset() {
  top.rst = 1;
  top.clk = 1;
  top.eval();
  top.clk = 0;
  top.eval();
  top.rst = 0;
}

int load_img(const string &filepath) {
  ifstream file(filepath, ios::binary);
  assert(file.is_open());
  file.seekg(0, ios::end);
  size_t size = file.tellg();
  file.seekg(0, ios::beg);
  file.read((char *)pmem, size);
  file.close();
  return size;
}

int main(int argc, char **argv) {
  struct timeval now;
  gettimeofday(&now, NULL);
  begin_us = now.tv_sec * 1000000 + now.tv_usec;
  top.eval();
  string img;
  string ref_so;
  for (int i = 0; i < argc; i++) {
    string tmp = argv[i];
    string option;
    int pos = 0;
    if (tmp[pos] != '-') {
      continue;
    }
    for (pos++; pos < tmp.length() && tmp[pos] != '='; pos++) {
      option.push_back(tmp[pos]);
    }
    if (option == "img") {
      img = tmp.substr(pos + 1);
    } else if (option == "diff_so") {
      ref_so = tmp.substr(pos + 1);
    } else if (option == "b") {
      sdb_set_batch_mode();
    }
  }
  // expr
  init_regex();
  // disasm
  init_disasm("riscv64-pc-linux-gnu");
  // init watchpoint
  init_wp_pool();
  // init sdl
  init_vga();
  int size = load_img(img);
  reset();
  if (!ref_so.empty()) {
    init_difftest(ref_so.c_str(), size);
    diff_test_on = true;
  }
  sdb_mainloop();
  if (isa_reg_str2val("a0") != 0) {
    status = -1;
    cout << img << "\033[31m\tBAD TRAP\033[0m" << endl;
  } else {
    cout << img << "\033[32m\tGOOD TRAP\033[0m" << endl;
  }
  return status;
}