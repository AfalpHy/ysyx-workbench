#include "VNPC.h"
#include "difftest.h"
#include "disasm.h"
#include "ftrace.h"
#include "pmem.h"
#include "string.h"
#include "watchpoint.h"

extern VNPC top;
extern int status;
extern bool diff_test_on;

uint64_t total_inst_num = 0;
bool skip_ref_inst = false;

typedef struct {
  paddr_t pc;
  uint32_t inst;
  char str[128];
} DisasmInst;

#define MAX_IRINGBUF_LEN 20
static DisasmInst iringbuf[MAX_IRINGBUF_LEN];

char *one_inst_str(const DisasmInst *di) {
  static char buff[256];
  sprintf(buff, FMT_WORD ":%08x\t\t%s\n", di->pc, di->inst, di->str);
  return buff;
}

static void display_one_inst(const DisasmInst *di) {
  printf("%s", one_inst_str(di));
}

void iringbuf_display() {
  for (auto i = 0; i < MAX_IRINGBUF_LEN; i++) {
    int iringbuf_index = (total_inst_num + i) % MAX_IRINGBUF_LEN;
    const auto &buf = iringbuf[iringbuf_index];
    if (strcmp(buf.str, "")) {
      display_one_inst(&buf);
    }
  }
}

static int check_regs() {
  word_t ref_reg[REGS_NUM];
  ref_difftest_regcpy((void *)ref_reg, pc, DIFFTEST_TO_DUT);
  for (int i = 0; i < REGS_NUM; i++) {
    if (ref_reg[i] != regs[i]) {
      std::cerr << total_inst_num << " instrutions has been executed"
                << std::endl;
      std::cerr << "reg index:" << i << " " << regs_name[i]
                << " ref:" << std::hex << ref_reg[i] << " npc:" << regs[i]
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
#ifdef ITRACE
    uint32_t inst = pmem_read(*pc, 4);
    int iringbuf_index = total_inst_num % MAX_IRINGBUF_LEN;
    iringbuf[iringbuf_index].pc = *pc;
    iringbuf[iringbuf_index].inst = inst;
    disassemble(iringbuf[iringbuf_index].str, sizeof(DisasmInst::str), *pc,
                (uint8_t *)&inst, 4);
    auto str = one_inst_str(&iringbuf[iringbuf_index]);
    if (print_num <= 10) {
      printf("%s", str);
    }
    fprintf(log_fp, "inst index:%ld\t%s", total_inst_num + 1, str);
#endif

#ifdef MTRACE
    // only print inst memory access
    print_mtrace = true;
    single_cycle();
    print_mtrace = false;
#else
    single_cycle();
#endif

#if defined(ITRACE) || defined(MTRACE)
    fprintf(log_fp, "\n"); // make trace more clear
#endif

#ifdef FTRACE
    ftrace(iringbuf[iringbuf_index].pc, *pc, inst);
#endif
    total_inst_num++;

    if (diff_test_on) {
      if (skip_ref_inst) {
        ref_difftest_regcpy(regs, pc, DIFFTEST_TO_REF);
        skip_ref_inst = false;
      } else {
        ref_difftest_exec(1);
        if (check_regs() != 0) {
          status = -1;
          return;
        }
      }
    }
    if (top.halt) {
      return;
    }
    if (check_wp()) {
      printf("watch point has been triggered\n");
      return;
    }
  }
}