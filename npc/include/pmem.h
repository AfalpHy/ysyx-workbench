#ifndef MEMORY_H
#define MEMORY_H

#include "common.h"

extern word_t *pmem;
extern "C" word_t pmem_read(paddr_t addr);
extern "C" void flash_read(int32_t addr, int32_t *data);
extern "C" void mrom_read(int32_t addr, int32_t *data);
extern bool print_mtrace;
#endif