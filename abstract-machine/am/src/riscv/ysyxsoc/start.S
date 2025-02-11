.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, _stack_pointer
  la a2, _total_size
  la a1, _text_start
  li a0, 0xf000000
  call memcpy
  call _trm_init
