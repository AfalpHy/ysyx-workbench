#include "common.h"
#include "verilated_dpi.h"
#include <string.h>

word_t *regs = nullptr;
paddr_t *pc = nullptr;

extern "C" int regs_num = REGS_NUM;

const char *regs_name[] = {"$0", "ra", "sp",  "gp",  "tp", "t0", "t1", "t2",
                           "s0", "s1", "a0",  "a1",  "a2", "a3", "a4", "a5",
                           "a6", "a7", "s2",  "s3",  "s4", "s5", "s6", "s7",
                           "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

extern "C" void set_pc(const svOpenArrayHandle r) {
  pc = (paddr_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

extern "C" void set_regs_ptr(const svOpenArrayHandle r) {
  regs = (word_t *)(((VerilatedDpiOpenVar *)r)->datap());
}

word_t isa_reg_str2val(const char *s) {
  if (strcmp(s, "pc") == 0) {
    return *pc;
  }
  for (int i = 0; i < regs_num; i++) {
    if (strcmp(regs_name[i], s) == 0) {
      return regs[i];
    }
  }
  return 0;
}

void isa_reg_display() {
  for (int i = 0; i < regs_num; i++) {
    printf("%d\t%s\t" FMT_WORD_D "\t" FMT_WORD "\n", i, regs_name[i], regs[i],
           regs[i]);
  }
}
