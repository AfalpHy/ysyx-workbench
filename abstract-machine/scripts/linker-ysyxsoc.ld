ENTRY(_start)
MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}
SECTIONS {
  . = ORIGIN(mrom);
  .text : {
    *(entry)
    *(.text*)
  } > mrom AT > mrom 
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > mrom AT > mrom
  _data = .;
  .data : {
  _data_start = .;
    *(.data)
  } > sram AT > mrom 
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
