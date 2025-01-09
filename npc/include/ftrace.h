#ifndef FTRACH_H
#define FTRACE_H

#include "common.h"
#include <vector>

void init_elf(const std::vector<std::string> &elf_files);
void ftrace(word_t pc, word_t addr, uint32_t inst, bool jalr);

#endif