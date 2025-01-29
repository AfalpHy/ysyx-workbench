#include <am.h>
#include <klib-macros.h>

int main(const char *args);

static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }

void putch(char ch) { outb(0x10000000, ch); }

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : : "r"(code));
  while (1);
}

extern char _data,_data_start,_end;

void _trm_init() {
  // copy data from mrom to sram
  int size = &_end - &_data_start;
  for (int i = 0; i < size; i++) {
    *(&_data_start + i) = *(&_data + i);
  }
  int ret = main(mainargs);
  halt(ret);
}
