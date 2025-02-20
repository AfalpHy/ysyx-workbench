#ifndef FTRACH_H
#define FTRACE_H

#include "common.h"
#include <vector>

void init_elf(const std::vector<std::string> &elf_files);
char *get_fun_name(word_t addr);
void ftrace(word_t pc, word_t addr, uint32_t inst);
paddr_t get_function_addr(char *fun_name);
bool add_break_point(char *fun_name);
bool check_break_point(paddr_t function_addr);
#endif