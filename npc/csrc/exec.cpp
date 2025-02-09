#include "VysyxSoCFull.h"
#include "difftest.h"
#include "disasm.h"
#include "ftrace.h"
#include "isa.h"
#include "pmem.h"
#include "string.h"
#include "watchpoint.h"
#include <verilated_vcd_c.h>

extern TOP_NAME top;
extern int status;
extern bool diff_test_on;
extern bool interrupt;

uint64_t total_insts_num = 0;
bool skip_ref_inst = false;
uint32_t inst;

extern "C" void set_skip_ref_inst() { skip_ref_inst = true; }
extern "C" void set_inst(int _inst) { inst = _inst; }
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
    int iringbuf_index = (total_insts_num + i) % MAX_IRINGBUF_LEN;
    const auto &buf = iringbuf[iringbuf_index];
    if (strcmp(buf.str, "")) {
      display_one_inst(&buf);
    }
  }
}

static int check_regs() {
  word_t ref_reg[REGS_NUM];
  paddr_t ref_pc;
  ref_difftest_regcpy((void *)ref_reg, &ref_pc, DIFFTEST_TO_DUT);
  if (*pc != ref_pc) {
    std::cerr << total_insts_num << " instrutions have been executed"
              << std::hex << " ref pc:" << ref_pc << " npc:" << *pc
              << std::endl;
    return -1;
  }
  for (int i = 0; i < REGS_NUM; i++) {
    if ((ref_reg[i] != regs[i]) || (*pc != ref_pc)) {
      std::cerr << total_insts_num << " instrutions have been executed"
                << std::endl;
      std::cerr << "reg index:" << i << " " << regs_name[i]
                << " ref:" << std::hex << ref_reg[i] << " npc:" << regs[i]
                << std::endl;
      return -1;
    }
  }
  return 0;
}

static inline bool halt() {
  extern VerilatedContext contextp;
  if (contextp.gotFinish()) {
    return true;
  }
  return false;
}

void single_cycle() {
  if (halt()) {
    return;
  }
  extern VerilatedContext contextp;
  contextp.timeInc(1);
  extern VerilatedVcdC *tfp;
  tfp->dump(contextp.time());
  top.clock = 1;
  top.eval();
  tfp->dumpvars(0, "");
  top.clock = 0;
  top.eval();
  tfp->dumpvars(0, "");
}

void reset() {
  top.reset = 1;
  for (int i = 0; i < 10; i++) {
    single_cycle();
  }
  top.reset = 0;
}

void cpu_exec(uint32_t num) {
  if (halt()) {
    printf("Program execution has ended\n");
    return;
  }
  uint32_t print_num = num;
  while (num-- > 0) {
#ifdef ITRACE
    int iringbuf_index = total_insts_num % MAX_IRINGBUF_LEN;
    iringbuf[iringbuf_index].pc = *pc;
#endif

#ifdef MTRACE
    // only print inst memory access
    print_mtrace = true;
#endif

    while (!(*write_back) && !interrupt && !halt())
      single_cycle();
    single_cycle(); // write back

#ifdef MTRACE
    // only print inst memory access
    print_mtrace = false;
#endif

#ifdef ITRACE
    iringbuf[iringbuf_index].inst = inst;
    disassemble(iringbuf[iringbuf_index].str, sizeof(DisasmInst::str),
                iringbuf[iringbuf_index].inst, (uint8_t *)&inst, 4);
    auto str = one_inst_str(&iringbuf[iringbuf_index]);
    if (print_num <= 10) {
      printf("%s", str);
    }
    if (total_insts_num < 10000) // avoid trace file too big
      fprintf(log_fp, "%s", str);
#endif

    total_insts_num++;

#if defined(ITRACE) || defined(MTRACE)
    if (total_insts_num <= 10000) // avoid trace file too big
      fprintf(log_fp, "%ld instructions have been executed\n\n",
              total_insts_num); // make trace more clear
#endif

#ifdef FTRACE
    ftrace(iringbuf[iringbuf_index].pc, *pc, inst);
#endif

    if (diff_test_on) {
      if (skip_ref_inst) {
        ref_difftest_regcpy(regs, pc, DIFFTEST_TO_REF);
        skip_ref_inst = false;
      } else {
        ref_difftest_exec(1);
        if (check_regs() != 0) {
          extern void isa_reg_display();
          isa_reg_display();
          iringbuf_display();
          status = -1;
          return;
        }
      }
    }
    if (halt() || interrupt) {
      printf("\n%ld instructions have been executed\n", total_insts_num);
      return;
    }
    if (check_wp()) {
      printf("watch point has been triggered\n");
      return;
    }
  }
}