ENTRY(_start)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  . = ORIGIN(sram);
  .text : {
    *(entry)
    *(.text*)
  } > sram AT > flash
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > sram AT> flash
  _data = .;
  .data : {
  _data_start = .;
    *(.data)
  } > sram AT > flash
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

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
