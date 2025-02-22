#ifndef COMMON_H
#define COMMON_H

#include <assert.h>
#include <iostream>
#include <stdint.h>

#ifdef RV64IM
typedef uint64_t word_t;
typedef int64_t sword_t;
typedef uint64_t paddr_t;
#define FMT_WORD "0x%016lx"
#define FMT_WORD_D "0x%020lu"
#else
typedef uint32_t word_t;
typedef int32_t sword_t;
typedef uint32_t paddr_t;
#define FMT_WORD "0x%08x"
#define FMT_WORD_D "%010u"
#endif
#define FMT_PADDR FMT_WORD

#if defined(RV32IM) || defined(RV64IM)
#define REGS_NUM 32
#else
#define REGS_NUM 16
#endif

extern FILE *log_fp;
extern uint64_t total_insts_num;

void fflush_trace();

static inline void print_total_insts_num() {
  printf("\n%ld instructions have been executed\n", total_insts_num);
}

static inline void print_debug_info() {
  extern void isa_reg_display();
  extern void iringbuf_display();
  isa_reg_display();
  iringbuf_display();
}

static inline void print_performance_info() {
  extern uint64_t total_cycles, calc_type, ls_type, csr_type;
  extern uint64_t calc_type_cycles, ls_type_cycles, csr_type_cycles;
  printf("%*scalc_type%*sls_type%*scsr_type\n", 27, "", 13, "", 12, "");
  printf("counter:        %20ld%20ld%20ld\n", calc_type, ls_type, csr_type);
  printf("average cycles: %20lf%20lf%20lf\n",
         (double)calc_type_cycles / calc_type, (double)ls_type_cycles / ls_type,
         (double)csr_type_cycles / csr_type);
  printf("total cycles:%ld\n", total_cycles);

  printf("\n%ld instructions have been executed. ipc:%lf\n", total_insts_num,
         (double)total_insts_num / (double)total_cycles);
}

#define ASSERT(cond, format, ...)                                              \
  if (!(cond)) {                                                               \
    printf(format "\n", ##__VA_ARGS__);                                        \
  }                                                                            \
  assert(cond);

#define ASSERT_IN_RUNTIME(cond, format, ...)                                   \
  if (!(cond)) {                                                               \
    fflush_trace();                                                            \
    print_debug_info();                                                        \
    print_performance_info();                                                  \
    printf(format "\n", ##__VA_ARGS__);                                        \
  }                                                                            \
  assert(cond);

#define CHOOSE2nd(a, b, ...) b
#define MUX_WITH_COMMA(contain_comma, a, b) CHOOSE2nd(contain_comma a, b)
#define MUX_MACRO_PROPERTY(p, macro, a, b)                                     \
  MUX_WITH_COMMA(concat(p, macro), a, b)
// define placeholders for some property
#define __P_DEF_0 X,
#define __P_DEF_1 X,
// define some selection functions based on the properties of BOOLEAN macro
#define MUXDEF(macro, X, Y) MUX_MACRO_PROPERTY(__P_DEF_, macro, X, Y)
#define BITMASK(bits) ((1ull << (bits)) - 1)
#define BITS(x, hi, lo)                                                        \
  (((x) >> (lo)) & BITMASK((hi) - (lo) + 1)) // similar to x[hi:lo] in verilog

#endif