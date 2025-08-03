#include <klib.h>

void _SSBL();
void __attribute__((section(".entry"))) _fsbl() {
  extern char _SSBL_size[], _SSBL_start[], _sram_start[];
  uint32_t loop = (uint32_t)_SSBL_size >> 2;
  //   int remain = (int)_SSBL_size & 0x3;
  uint32_t *origin_addr = (uint32_t *)_SSBL_start;
  uint32_t *target_addr = (uint32_t *)_sram_start;

  while (loop--) {
    *target_addr = *origin_addr;
    target_addr++;
    origin_addr++;
  }

  _SSBL();
}