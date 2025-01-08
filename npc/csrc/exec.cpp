#include "VNPC.h"
#include "difftest.h"
#include "disasm.h"
#include "memory.h"
#include "string.h"
#include "watchpoint.h"

extern VNPC top;
extern int status;
extern bool diff_test_on;

int total_inst_num = 0;

typedef struct {
  paddr_t pc;
  uint32_t inst;
  char str[128];
} DisasmInst;

#define MAX_IRINGBUF_LEN 20
static DisasmInst iringbuf[MAX_IRINGBUF_LEN];

static void display_one_inst(const DisasmInst *di) {
  printf(FMT_WORD ":%08x\t%s\n", di->pc, di->inst, di->str);
}

void iringbuf_display() {
  for (auto i = 0; i < 10; i++) {
    int iringbuf_index = (total_inst_num + i) % MAX_IRINGBUF_LEN;
    const auto &buf = iringbuf[iringbuf_index];
    if (strcmp(buf.str, "")) {
      display_one_inst(&buf);
    }
  }
}

static int check_ref() {
  word_t ref_reg[32];
  paddr_t reg_pc;
  ref_difftest_regcpy((void *)ref_reg, &reg_pc, DIFFTEST_TO_DUT);
  for (int i = 0; i < 32; i++) {
    if (ref_reg[i] != regs[i]) {
      std::cerr << total_inst_num << " instrutions has been executed"
                << std::endl;
      std::cerr << regs_name[i] << " ref:" << std::hex << ref_reg[i]
                << " npc:" << regs[i] << std::endl;
      return -1;
    }
    if (*pc != reg_pc) {
      std::cerr << total_inst_num << " instrutions has been executed"
                << std::endl;
      std::cerr << std::hex << " ref's pc:" << reg_pc << " npc's pc:" << *pc
                << std::endl;
      return -1;
    }
  }
  return 0;
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

void cpu_exec(uint32_t num) {
  if (top.halt) {
    printf("Program execution has ended\n");
    return;
  }
  uint32_t print_num = num;
  while (num-- > 0) {
    uint32_t inst = pmem_read(*pc, 4);
    int iringbuf_index = total_inst_num % MAX_IRINGBUF_LEN;
    iringbuf[iringbuf_index].pc = *pc;
    iringbuf[iringbuf_index].inst = inst;
    disassemble(iringbuf[iringbuf_index].str, sizeof(DisasmInst::str), *pc,
                (uint8_t *)&inst, 4);
    if (print_num <= 10) {
      display_one_inst(&iringbuf[iringbuf_index]);
    }

    single_cycle();

    if (diff_test_on) {
      ref_difftest_exec(1);
      if (check_ref() != 0) {
        status = -1;
        return;
      }
    }
    total_inst_num++;
    if (top.halt) {
      return;
    }
    if (check_wp()) {
      printf("watch point has been triggered\n");
      return;
    }
  }
}