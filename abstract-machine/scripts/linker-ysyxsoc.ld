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

  .SSBL : {
    *(SSBL)
  } > sram AT > flash : text
  _SSBL_size = . - _sram_start;
  _SSBL_end = _entry_end + _SSBL_size;
  
  .text : {
  _text_start = .;
    *(.text*)
  } > psram AT > flash

  .rodata : {
    *(.rodata*)
  } > psram AT > flash

  .data : {
    *(.data)
  _data_end = .;
  } > psram AT > flash : data
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
