#include "VNPC.h"
#include "verilated.h"
#include "verilated_dpi.h"
#include "verilated_vcd_c.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

static VNPC *top = nullptr;

uint32_t *pc = nullptr;
uint32_t *regs = nullptr;
uint32_t *pmem = nullptr;

extern "C" void set_pc(const svOpenArrayHandle r) {
  pc = (uint32_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" void set_regs_ptr(const svOpenArrayHandle r) {
  regs = (uint32_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" void set_memory_ptr(const svOpenArrayHandle r) {
  pmem = (uint32_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" uint32_t pmem_read(uint32_t addr, int len) {
  auto pmem_addr = addr - 0x80000000;
  switch (len) {
  case 1:
    return pmem[pmem_addr];
  case 2:
    return pmem[pmem_addr + 1] << 8 | pmem[pmem_addr];
  case 4:
    return pmem_read(addr + 2, 2) << 16 | pmem_read(addr, 2);
  default:
    assert(0);
    break;
  }
}

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new VNPC{contextp};
  while (!contextp->gotFinish()) {
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->eval();
    if (top->halt) {
      break;
    }
  }
  delete top;
  delete contextp;
  return 0;
}
