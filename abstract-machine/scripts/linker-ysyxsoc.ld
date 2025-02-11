ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
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
  } > flash : text
  _entry_end = .;

  .SSBL : AT(_entry_end) {
    *(SSBL)
  } > sram
  _SSBL_size = SIZEOF(.SSBL);
  _SSBL_end = _entry_end + _SSBL_size;
  
  .text : AT(_SSBL_end) {
  _text_start = .;
    *(.text*)
  } > psram
  _text_end = _SSBL_end + SIZEOF(.text);

  .rodata : AT(_text_end) {
    *(.rodata*)
  } > psram
  _rodata_end = _text_end + SIZEOF(.rodata);

  .data : AT(_rodata_end) {
    *(.data)
  _data_end = .;
  } > psram : data
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
