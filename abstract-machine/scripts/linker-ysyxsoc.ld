ENTRY(_start)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}
SECTIONS {
  . = ORIGIN(flash);
  .text : {
    *(entry)
    *(.text*)
  } > flash
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > flash
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
