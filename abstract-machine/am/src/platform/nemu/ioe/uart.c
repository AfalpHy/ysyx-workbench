#include <am.h>
#include <klib.h>

void __am_uart_rx(AM_UART_RX_T *uart) { uart->data = 0xff; }
