ENTRY(_start)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}
SECTIONS {
  . = ORIGIN(flash);
  .text : {
    *(entry)
  } > flash

  .text : {
  _text_start = .;
    *(.text*)
  } > sram AT > flash

  .rodata : {
    *(.rodata*)
  } > sram AT > flash

  .data : {
    *(.data)
  _data_end = .;
  } > sram AT > flash
  _total_size = _data_end - _text_start;

  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sram
  _end = .;
  _heap_start = .;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
