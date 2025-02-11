ENTRY(_start)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  .text : {
    *(entry)
    *(.text*)
  } > sram
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > sram
  _data = .;
  .data : {
  _data_start = .;
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
  _total_size = _end - ORIGIN(sram);
  _heap_start = .;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
