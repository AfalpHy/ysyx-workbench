ENTRY(_start)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  sdram : ORIGIN = 0xa0000000, LENGTH = 64M
}

SECTIONS {
  . = ORIGIN(flash);
  _sram_start = ORIGIN(sram);
  _sdram_start = ORIGIN(sdram);

  .entry : {
    *(entry)
  } > flash

  .ssbl : {
    *(SSBL)
  } > sram AT > flash
  _SSBL_start = LOADADDR(.ssbl);
  _SSBL_size = SIZEOF(.ssbl);
  
  .text : {
    *(.text*)
    . = ALIGN(16);
  } > sdram AT > flash 
  _text_start = LOADADDR(.text);

  .rodata : {
    . = ALIGN(16);
    *(.rodata*)
    *(.srodata*)
    . = ALIGN(16);
  } > sdram AT > flash 

  .data : {
    . = ALIGN(16);
    *(.data*)
    *(.sdata*)
    . = ALIGN(16);
  } > sdram AT > flash

  .bss : {
    . = ALIGN(16);
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    . = ALIGN(16);
  } > sdram AT > flash 
  _total_size = LOADADDR(.bss) - _text_start;
  _heap_start = .;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
