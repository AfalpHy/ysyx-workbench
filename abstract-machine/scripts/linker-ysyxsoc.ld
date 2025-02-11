ENTRY(_start)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  . = ORIGIN(flash);
  _sram_start = ORIGIN(sram);
  _psram_start = ORIGIN(psram);

  .entry : {
    *(entry)
  } > flash
  _entry_end = .;

  .ssbl : {
    *(SSBL)
  } > sram AT > flash
  _SSBL_size = . - _sram_start;
  _SSBL_end = _entry_end + _SSBL_size;
  
  .text : {
  _text_start = .;
    *(.text*)
  _text_end = .;
  } > psram AT > flash
  _text_align = ALIGN(_text_end);

  .rodata : AT(_text_align) {
    *(.rodata*)
  } > psram

  .data : {
    *(.data)
  _data_end = .;
  } > psram AT > flash
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
