void _SSBL();
void __attribute__((section(".fsbl"))) _fsbl() {
  extern char _SSBL_size[], _SSBL_start[], _sram_start[];
  int loop = (int)_SSBL_size >> 2;
//   int remain = (int)_SSBL_size & 0x3;
  int *origin_addr = (int*)_SSBL_start;
  int *target_addr = (int*)_sram_start;

  while (loop--) {
    *target_addr = *origin_addr;
    target_addr++;
    origin_addr++;
  }

  _SSBL();
}