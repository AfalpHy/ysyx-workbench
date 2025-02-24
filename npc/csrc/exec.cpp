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

uint64_t total_insts_num = 0;

bool print_itrace = false;
bool halt = false;
bool finish_one_inst = false;

// counter
uint64_t total_cycles = 0;
uint64_t get_inst = 0;
uint64_t get_data = 0;
uint64_t exu_done = 0;
int inst_type = 0;
uint64_t calc_inst = 0, ls_inst = 0, csr_inst = 0;
uint64_t calc_inst_cycles = 0, ls_inst_cycles = 0, csr_inst_cycles = 0;
uint64_t ls_delay = 0;

// make mtrace message follows itrace message
char mtrace_buffer[256] = {};

bool skip_ref_inst = false;
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

extern "C" void ifu_record0() { get_inst++; }

extern "C" void ifu_record1(int inst, int npc) {
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

#ifdef MTRACE
  if (mtrace_buffer[0]) {
    fprintf(log_fp, "%s", mtrace_buffer);
  }
  mtrace_buffer[0] = 0;
#endif

#ifdef FTRACE
  ftrace(*pc, npc, inst);
#endif

  halt = inst == 0x00100073;
  finish_one_inst = true;

  if (halt) {
    total_cycles -= 20;
    return;
  }
  // cpu will be reset extra 10 cycles by soc, and the total reset cylce is 20.
  static uint64_t last_inst_end_cycles = 20;
  uint64_t spend_cycles = total_cycles - last_inst_end_cycles;
  switch (inst_type) {
  case 1:
    calc_inst_cycles += spend_cycles;
    break;
  case 2:
    ls_inst_cycles += spend_cycles;
    break;
  case 4:
    csr_inst_cycles += spend_cycles;
    break;
  default:
    break;
  }
  last_inst_end_cycles = total_cycles;
}

extern "C" void idu_record(bool calc, bool ls, bool csr) {
  calc_inst += calc;
  ls_inst += ls;
  csr_inst += csr;
  inst_type = (csr << 2) | (ls << 1) | calc;
}

extern "C" void exu_record() { exu_done++; }

extern "C" void lsu_record0(paddr_t addr, word_t data, word_t delay) {
  get_data++;
  ls_delay += delay;
#ifdef MTRACE
  if (total_insts_num < 10000)
    sprintf(mtrace_buffer, "read addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\n",
            addr, data);
#endif
}

extern "C" void lsu_record1(paddr_t addr, word_t data, word_t mask,
                            word_t delay) {
  // ls_delay += delay;
#ifdef MTRACE
  if (total_insts_num < 10000)
    sprintf(mtrace_buffer,
            "write addr:\t" FMT_PADDR "\tdata:" FMT_WORD "\tmask:" FMT_WORD
            "\n",
            addr, data, mask);
#endif
}

void iringbuf_display() {
  for (auto i = 0; i < MAX_IRINGBUF_LEN; i++) {
    int iringbuf_index = (total_insts_num + i) % MAX_IRINGBUF_LEN;
    const auto &buf = iringbuf[iringbuf_index];
    if (strcmp(buf.str, "")) {
      printf("%s", one_inst_str(&buf));
    }
  }
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
  total_cycles++;

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
}

void reset() {
  top.reset = 1;
  for (int i = 0; i < 10; i++) {
    single_cycle();
  }
  top.reset = 0;
}

void cpu_exec(uint32_t num) {
  if (halt | status) {
    printf("Program execution has finished or has some error\n");
    return;
  }
  print_itrace = num <= 10;
  while (num-- > 0) {
    finish_one_inst = false;
    while (!finish_one_inst)
      single_cycle();

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
          status = -1;
          return;
        }
      }
    }
    if (halt) {
      print_performance_info();
      return;
    } else if (check_wp()) {
      return;
    } else if (check_breakpoint(*pc)) {
      return;
    }
  }
}