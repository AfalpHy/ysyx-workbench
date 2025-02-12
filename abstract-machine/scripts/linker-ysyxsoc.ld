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
  } > flash : text

  .ssbl : {
    *(SSBL)
  } > sram AT > flash : ssbl
  _SSBL_start = LOADADDR(.ssbl);
  _SSBL_size = SIZEOF(.ssbl);
  
  .text : {
    *(.text*)
  } > psram AT > flash : text
  _text_start = LOADADDR(.text);

  .rodata : {
    *(.rodata*)
  } > psram AT > flash
    . = ALIGN(8);

  .data : {
    *(.data*)
    *(.sdata*)
  } > psram AT > flash : data
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  _bss_end = ALIGN(8);
  } > psram
  _total_size =SIZEOF(.text)+SIZEOF(.data)+SIZEOF(.rodata);
  _end = _bss_end;
  _heap_start = _bss_end;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
