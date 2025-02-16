.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, _stack_pointer
_FSBL:
  la a2, _SSBL_size
  la a1, _SSBL_start
  la a0, _sram_start
_memcpy_FSBL:
  lbu a3, 0(a1)
  sb a3, 0(a0)
  addi a1, a1, 1
  addi a0, a0, 1
  addi a2, a2, -1
  bnez a2, _memcpy_FSBL 
  
  call _SSBL

.section SSBL, "ax"
.globl _SSBL
.type _SSBL, @function
_SSBL:
  la a2, _total_size
  la a1, _text_start
  la a0, _sdram_start
_memcpy_SSBL:
  lbu a3, 0(a1)
  sb a3, 0(a0)
  addi a1, a1, 1
  addi a0, a0, 1
  addi a2, a2, -1
  bnez a2, _memcpy_SSBL

  call _trm_init
.size _SSBL, . - _SSBL