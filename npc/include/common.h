#ifndef COMMON_H
#define COMMON_H

#include <iostream>
#include <stdint.h>

#ifdef CONFIG_ISA64
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

extern word_t *regs, *pmem;
extern word_t *pc;
extern const char *regs_name[];

word_t isa_reg_str2val(const char *reg_name);
extern "C" word_t pmem_read(paddr_t addr, int len);
void isa_reg_display();
void single_cycle();

#define Assert(cond, format, ...)                                              \
  printf(format, ##__VA_ARGS__);                                               \
  assert(cond);

#endif