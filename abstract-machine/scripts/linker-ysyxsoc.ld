ENTRY(_start)
MEMORY {
  flash (rx) : ORIGIN = 0x30000000, LENGTH = 16M
  sram (xrw) : ORIGIN = 0x0f000000, LENGTH = 8k
  psram (xrw) : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {

  _sram_start = ORIGIN(sram);
  _psram_start = ORIGIN(psram);

  .entry : {
    *(entry)
  } > flash
  _entry_end = .;

  .ssbl : {
    *(SSBL)
  } > sram
  _SSBL_size = . - _sram_start;
  _SSBL_end = _entry_end + _SSBL_size;
  
  .text : {
  _text_start = .;
    *(.text)
  } > psram

  .rodata : {
    *(.rodata*)
  } > psram

  .data : {
    *(.data)
  _data_end = .;
  } > psram
  _total_size = _data_end - _text_start;

  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > psram
  _end = .;
  _heap_start = .;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
