#include <am.h>
#include <nemu.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

static uint32_t sbuf_size;

void __am_audio_init() {
  sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  cfg->present = true;
  cfg->bufsize = sbuf_size;
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
  outl(AUDIO_FREQ_ADDR, ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR, ctrl->samples);
  outb(AUDIO_INIT_ADDR, 1);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  static int index = 0;
  uint32_t write_size = ctl->buf.end - ctl->buf.start;
  // keep waitting if exceed the buf size
  while (inl(AUDIO_COUNT_ADDR) + write_size > sbuf_size) {
  }
  // align to 4 byte
  int len2align = 4 - (index & 3);
  int append = len2align < write_size ? len2align : write_size;
  uint32_t write_addr = AUDIO_SBUF_ADDR + index;
  uint8_t *data = ctl->buf.start;
  switch (append) {
  case 1:
    outb(write_addr++, *data++);
    break;
  case 2:
    outb(write_addr++, *data++);
    outb(write_addr++, *data++);
    break;
  case 3:
    outb(write_addr++, *data++);
    outb(write_addr++, *data++);
    outb(write_addr++, *data++);
    break;
  default:
    break;
  }
  uint32_t sbuf_end = AUDIO_SBUF_ADDR + sbuf_size;
  if (write_addr == sbuf_end) {
    write_addr = AUDIO_SBUF_ADDR;
  }

  // remaining data size to write
  int need_wirte_size = write_size - append;
  while (need_wirte_size >= 4) {
    outw(write_addr, *(uint32_t *)data);
    write_addr += 4;
    data += 4;
    need_wirte_size -= 4;
    if (write_addr == sbuf_end) {
      write_addr = AUDIO_SBUF_ADDR;
    }
  }

  switch (need_wirte_size) {
  case 1:
    outb(write_addr++, *data++);
    break;
  case 2:
    outb(write_addr++, *data++);
    outb(write_addr++, *data++);
    break;
  case 3:
    outb(write_addr++, *data++);
    outb(write_addr++, *data++);
    outb(write_addr++, *data++);
    break;
  default:
    break;
  }

  index += write_size;
  // wraparound
  index &= (sbuf_size - 1);

  // for (uint8_t *data = ctl->buf.start; data < (uint8_t *)ctl->buf.end;
  // data++) {
  //   outb(AUDIO_SBUF_ADDR + index, *data);
  //   if (++index == sbuf_size)
  //     index = 0;
  // }
  outl(AUDIO_COUNT_ADDR, inl(AUDIO_COUNT_ADDR) + write_size);
}
