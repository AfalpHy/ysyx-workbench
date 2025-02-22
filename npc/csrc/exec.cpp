#include "VysyxSoCFull.h"
#include "difftest.h"
#include "disasm.h"
#include "ftrace.h"
#include "isa.h"
#include "pmem.h"
#include "string.h"
#include "watchpoint.h"
#include <nvboard.h>
#include <verilated_vcd_c.h>

extern TOP_NAME top;
extern int status;
extern bool diff_test_on;
extern bool interrupt;

uint64_t total_insts_num = 0;
bool skip_ref_inst = false;
uint32_t inst;
bool print_itrace = false;
bool halt = false;
uint64_t total_cycles = 0;
uint64_t calc_type = 0, ls_type = 0, csr_type = 0;

extern "C" void set_skip_ref_inst() { skip_ref_inst = true; }
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

extern "C" void trace(int inst, int npc) {
#ifdef ITRACE
  int iringbuf_index = total_insts_num % MAX_IRINGBUF_LEN;
  iringbuf[iringbuf_index].pc = *pc;
  iringbuf[iringbuf_index].inst = inst;
  disassemble(iringbuf[iringbuf_index].str, sizeof(DisasmInst::str),
              iringbuf[iringbuf_index].inst, (uint8_t *)&inst, 4);
  auto str = one_inst_str(&iringbuf[iringbuf_index]);
  if (print_itrace) {
    printf("%s", str);
  }
  if (total_insts_num < 10000) // avoid trace file too big
    fprintf(log_fp, "%s", str);
#endif

#ifdef FTRACE
  ftrace(*pc, npc, inst);
#endif

  halt = inst == 0b00000000000100000000000001110011;
}

extern "C" void count_inst_type(bool calc, bool ls, bool csr) {
  calc_type += calc;
  ls_type += ls;
  csr_type += csr;
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
  print_total_insts_num();
}

static int check_regs() {
  word_t ref_reg[REGS_NUM];
  paddr_t ref_pc;
  ref_difftest_regcpy((void *)ref_reg, &ref_pc, DIFFTEST_TO_DUT);
  if (*pc != ref_pc) {
    std::cerr << std::hex << " ref pc:" << ref_pc << " npc:" << *pc
              << std::endl;
    return -1;
  }
  for (int i = 0; i < REGS_NUM; i++) {
    if ((ref_reg[i] != regs[i]) || (*pc != ref_pc)) {
      std::cerr << "reg index:" << i << " " << regs_name[i]
                << " ref:" << std::hex << ref_reg[i] << " npc:" << regs[i]
                << std::endl;
      return -1;
    }
  }
  return 0;
}

void single_cycle() {
  nvboard_update();
  extern VerilatedVcdC *tfp;
  top.clock = 1;
  top.eval();

#ifdef TRACE_WAVE
  Verilated::timeInc(1);
  tfp->dump(Verilated::time());
#endif

  top.clock = 0;
  top.eval();

#ifdef TRACE_WAVE
  Verilated::timeInc(1);
  tfp->dump(Verilated::time());
#endif

  total_cycles++;
}

void reset() {
  top.reset = 1;
  for (int i = 0; i < 10; i++) {
    single_cycle();
  }
  top.reset = 0;
}

void cpu_exec(uint32_t num) {
  if (halt) {
    printf("Program execution has ended\n");
    return;
  }
  print_itrace = num <= 10;
  while (num-- > 0) {
#ifdef MTRACE
    // only print inst memory access
    print_mtrace = true;
#endif

    while (!(*write_back) && !interrupt)
      single_cycle();
    single_cycle(); // write back

#ifdef MTRACE
    // only print inst memory access
    print_mtrace = false;
#endif

    total_insts_num++;

#if defined(ITRACE) || defined(MTRACE)
    if (total_insts_num <= 10000) // avoid trace file too big
      fprintf(log_fp, "%ld instructions have been executed\n\n",
              total_insts_num); // make trace more clear
#endif

    if (diff_test_on) {
      if (skip_ref_inst) {
        ref_difftest_regcpy(regs, pc, DIFFTEST_TO_REF);
        skip_ref_inst = false;
      } else {
        ref_difftest_exec(1);
        if (check_regs() != 0) {
          print_message_of_npc();
          status = -1;
          return;
        }
      }
    }
    if (halt | interrupt) {
      print_message_of_npc();
      return;
    } else if (check_wp()) {
      return;
    } else if (check_breakpoint(*pc)) {
      return;
    }
  }
}