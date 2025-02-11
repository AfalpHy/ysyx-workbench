ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  . = ORIGIN(flash);

  .entry : {
    *(entry)
  } > flash :text
  _entry_end = .;

  .text : {
    *(SSBL)
  } > sram AT > flash
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
  } > psram AT > flash :data
  _total_size = _data_end - _text_start;

  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > psram
  _end = .;
  _heap_start = .;

  _sram_start = ORIGIN(sram);
  _psram_start = ORIGIN(psram);
  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
