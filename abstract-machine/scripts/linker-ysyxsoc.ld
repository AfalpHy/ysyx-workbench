ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}
SECTIONS {
  . = ORIGIN(mrom);
  .text : {
    *(entry)
    *(.text*)
  } > mrom AT > mrom : text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > mrom AT > mrom
  _data = .;
  .data : {
    *(.data)
  } > sram AT > mrom : data
  edata = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sram AT > mrom
  end = .;
  _end = .;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
  _heap_start = ORIGIN(sram) + _end - _data;
}
