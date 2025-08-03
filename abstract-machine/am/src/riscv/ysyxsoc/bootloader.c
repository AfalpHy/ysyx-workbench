#include <klib.h>
void _ssbl();
void _trm_init();

void __attribute__((section(".entry"))) _fsbl() {
  extern char _SSBL_size[], _SSBL_start[], _sram_start[];
  uint32_t loop = (uint32_t)_SSBL_size >> 2;
  uint32_t *origin_addr = (uint32_t *)_SSBL_start;
  uint32_t *target_addr = (uint32_t *)_sram_start;

  while (loop--) {
    *target_addr = *origin_addr;
    origin_addr++;
    target_addr++;
  }
  uint32_t remain = (uint32_t)_SSBL_size & 0x3;
  uint8_t *remain_origin_addr = (uint8_t *)origin_addr;
  uint8_t *remain_target_addr = (uint8_t *)target_addr;

  while (remain--) {
    *remain_target_addr = *remain_origin_addr;
    remain_origin_addr++;
    remain_target_addr++;
  }
  _ssbl();
}

void __attribute__((section(".ssbl"))) _ssbl() {
  extern char _total_size[], _text_start[], _sdram_start[];
  uint32_t loop = (uint32_t)_total_size >> 2;
  uint32_t *origin_addr = (uint32_t *)_text_start;
  uint32_t *target_addr = (uint32_t *)_sdram_start;

  while (loop--) {
    *target_addr = *origin_addr;
    origin_addr++;
    target_addr++;
  }
  uint32_t remain = (uint32_t)_total_size & 0x3;
  uint8_t *remain_origin_addr = (uint8_t *)origin_addr;
  uint8_t *remain_target_addr = (uint8_t *)target_addr;

  while (remain--) {
    *remain_target_addr = *remain_origin_addr;
    remain_origin_addr++;
    remain_target_addr++;
  }
  _trm_init();
}