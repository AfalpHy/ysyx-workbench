#include <klib.h>

#define UART_ADDR 0x10000000
#define UART_REG_TR 0
#define UART_REG_LC 3
#define UART_REG_LS 5
#define UART_REG_DLL 0
#define UART_REG_DLH 1

int main(const char *args);

static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }

void putch(char ch) {
  // loop until transmitter is not empty
  while (!(inb(UART_ADDR + UART_REG_LS) & 0x40)) {
  }

  outb(UART_ADDR + UART_REG_TR, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : : "r"(code));
  while (1);
}

void bootload() {
  extern char _end[];
  // copy data from flash to sram
  int size = (int)&_end;
  size -= 0xf000000;
  for (int i = 0; i < size; i++) {
    *(char *)(0xf000000 + i) = *(char *)(0x30000000 + i);
  }
}

void init_uart() {
  outb(UART_ADDR + UART_REG_LC, 0x80); // set dlab(divisor latch access bit)
  outb(UART_ADDR + UART_REG_DLL, 12);
  outb(UART_ADDR + UART_REG_DLH, 0);
  outb(UART_ADDR + UART_REG_LC, 3); // recover
}

void printId() {
  uint32_t id = 0;
  asm volatile("csrr  %0, mvendorid" : "=r"(id));
  printf("ysyx ascii:%x\n", id);
  asm volatile("csrr %0, marchid" : "=r"(id));
  printf("student id:%x\n", id);
}

void _trm_init() {
  bootload();
  init_uart();
  printId();
  int ret = main(mainargs);
  halt(ret);
}
