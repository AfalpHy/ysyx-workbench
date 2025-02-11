.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, _stack_pointer
  la a2, _total_size
  la a1, _entry_end
  la a0, _store_start
_bootload:
  lb a3, 0(a1)
  sb a3, 0(a0)
  addi a1, a1, 1
  addi a0, a0, 1
  addi a2, a2, -1
  bnez a2, _bootload
  
  call _trm_init
