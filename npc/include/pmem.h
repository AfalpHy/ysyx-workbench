#ifndef MEMORY_H
#define MEMORY_H

#include "common.h"

extern word_t *pmem;
extern "C" word_t pmem_read(paddr_t addr);
extern bool print_mtrace;
#endif