.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, _stack_pointer
  
  li a1, 0x30000000
  li a0, 0xf000000

  // copy data from flash to sram
  call memcpy
  call _trm_init
