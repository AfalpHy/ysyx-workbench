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

extern char _data,_end;

void _trm_init() {
  // copy data from mrom to sram
  for (char *addr = &_data; addr < &_end; addr++) {
    *(addr + 0xf000000) = *addr;
  }
  int ret = main(mainargs);
  halt(ret);
}
