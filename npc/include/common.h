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
#define FMT_WORD_D "0x%010u"
#endif
#define FMT_PADDR FMT_WORD

#if defined(RV32IM) || defined(RV64IM)
#define REGS_NUM 32
#else
#define REGS_NUM 16
#endif

extern word_t *regs, *pmem;
extern word_t *pc;
extern bool* done;
extern const char *regs_name[];
extern FILE *log_fp;

#define Assert(cond, format, ...)                                              \
  if (!(cond)) {                                                               \
    extern void fflush_trace();                                                \
    fflush_trace();                                                            \
    extern void isa_reg_display();                                             \
    isa_reg_display();                                                         \
    extern void iringbuf_display();                                            \
    iringbuf_display();                                                        \
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