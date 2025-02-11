ENTRY(_start)
PHDRS { text PT_LOAD ; }
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  _flash_start = ORIGIN(flash);
  _sram_start = ORIGIN(sram);
  .entry : {
    *(entry)
  } > flash AT> flash : text
  .text : {
    *(.text*)
  } > sram AT> flash : text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > sram
  .data : {
    *(.data)
  } > sram
  edata = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sram
  end = .;
  _end = .;
  _heap_start = .;
  _load_begin = LOADADDR(.entry);
  _total_size = _end - _load_begin;
  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
