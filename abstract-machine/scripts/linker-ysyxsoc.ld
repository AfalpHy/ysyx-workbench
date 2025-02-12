ENTRY(_start)
PHDRS { entry PT_LOAD; ssbl PT_LOAD; text PT_LOAD; data PT_LOAD; }
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
  } > flash : entry

  .ssbl : {
    *(SSBL)
  } > sram AT > flash : ssbl
  _SSBL_start = LOADADDR(.ssbl);
  _SSBL_size = SIZEOF(.ssbl);
  
  .text : {
    *(.text*)
    . = ALIGN(8);
  } > psram AT > flash : text
  _text_start = LOADADDR(.text);

  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > psram AT > flash : data

  .data : {
    *(.data*)
    *(.sdata*)
  } > psram AT > flash

  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > psram
  _total_size = LOADADDR(.bss) - _text_start;
  
  _end = LOADADDR(.bss) + SIZEOF(.bss);
  _heap_start = _end;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
