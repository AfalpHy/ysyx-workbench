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

#ifdef (RV32IM || RV64IM)
#define REGS_NUM 32
#else
#define REGS_NUM 16
#endif

extern word_t *regs, *pmem;
extern word_t *pc;
extern const char *regs_name[];

#define Assert(cond, format, ...)                                              \
  if (!cond)                                                                   \
    printf(format "\n", ##__VA_ARGS__);                                        \
  assert(cond);

#endif