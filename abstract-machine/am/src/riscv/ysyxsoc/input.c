#include <am.h>
#include <klib.h>
#define KBD_ADDR 0x10011000
#define KEYDOWN_MASK 0x8000

typedef enum {
  SCANCODE_UNKNOWN = 0,

  SCANCODE_A = 0x1c,
  SCANCODE_B = 0x32,
  SCANCODE_C = 0x21,
  SCANCODE_D = 0x23,
  SCANCODE_E = 0x24,
  SCANCODE_F = 0x2b,
  SCANCODE_G = 0x34,
  SCANCODE_H = 0x33,
  SCANCODE_I = 0x43,
  SCANCODE_J = 0x3b,
  SCANCODE_K = 0x42,
  SCANCODE_L = 0x4b,
  SCANCODE_M = 0x3a,
  SCANCODE_N = 0x31,
  SCANCODE_O = 0x44,
  SCANCODE_P = 0x4d,
  SCANCODE_Q = 0x15,
  SCANCODE_R = 0x2d,
  SCANCODE_S = 0x1b,
  SCANCODE_T = 0x2c,
  SCANCODE_U = 0x3c,
  SCANCODE_V = 0x2a,
  SCANCODE_W = 0x1d,
  SCANCODE_X = 0x22,
  SCANCODE_Y = 0x35,
  SCANCODE_Z = 0x1a,

  SCANCODE_1 = 0x16,
  SCANCODE_2 = 0x1e,
  SCANCODE_3 = 0x26,
  SCANCODE_4 = 0x25,
  SCANCODE_5 = 0x2e,
  SCANCODE_6 = 0x36,
  SCANCODE_7 = 0x3d,
  SCANCODE_8 = 0x3e,
  SCANCODE_9 = 0x46,
  SCANCODE_0 = 0x45,

  SCANCODE_RETURN = 0x5a,
  SCANCODE_ESCAPE = 0x76,
  SCANCODE_BACKSPACE = 0x66,
  SCANCODE_TAB = 0xd,
  SCANCODE_SPACE = 0x29,

  SCANCODE_MINUS = 0x4e,
  SCANCODE_EQUALS = 0x55,
  SCANCODE_LEFTBRACKET = 0x54,
  SCANCODE_RIGHTBRACKET = 0x5b,
  SCANCODE_BACKSLASH = 0x5d,
  SCANCODE_SEMICOLON = 0x4c,
  SCANCODE_APOSTROPHE = 52,
  SCANCODE_GRAVE = 0xe,
  SCANCODE_COMMA = 0x41,
  SCANCODE_PERIOD = 0x49,
  SCANCODE_SLASH = 0x4a,

  SCANCODE_CAPSLOCK = 0x58,

  SCANCODE_F1 = 0x5,
  SCANCODE_F2 = 0x6,
  SCANCODE_F3 = 0x4,
  SCANCODE_F4 = 0xc,
  SCANCODE_F5 = 0x3,
  SCANCODE_F6 = 0xb,
  SCANCODE_F7 = 0x83,
  SCANCODE_F8 = 0xa,
  SCANCODE_F9 = 0x1,
  SCANCODE_F10 = 0x9,
  SCANCODE_F11 = 0x78,
  SCANCODE_F12 = 0x07,

  SCANCODE_INSERT = 0xe0,
  SCANCODE_HOME = 0xe0,
  SCANCODE_PAGEUP = 0xe0,
  SCANCODE_DELETE = 0xe0,
  SCANCODE_END = 0xe0,
  SCANCODE_PAGEDOWN = 0xe0,
  SCANCODE_RIGHT = 0xe0,
  SCANCODE_LEFT = 0xe0,
  SCANCODE_DOWN = 0xe0,
  SCANCODE_UP = 0xe0,

  SCANCODE_APPLICATION = 0x65, /**< windows contextual menu, compose */

  SCANCODE_LCTRL = 0x14,
  SCANCODE_LSHIFT = 0x12,
  SCANCODE_LALT = 0x11, /**< alt, option */
  SCANCODE_RCTRL = 0xe0,
  SCANCODE_RSHIFT = 0x59,
  SCANCODE_RALT = 0xe0 /**< alt gr, option */

} Scancode;

typedef enum {
  EXTEND_SCANCODE_INSERT = 0x70,
  EXTEND_SCANCODE_HOME = 0x60,
  EXTEND_SCANCODE_PAGEUP = 0x7d,
  EXTEND_SCANCODE_DELETE = 0x71,
  EXTEND_SCANCODE_END = 0x69,
  EXTEND_SCANCODE_PAGEDOWN = 0x7a,
  EXTEND_SCANCODE_RIGHT = 0x74,
  EXTEND_SCANCODE_LEFT = 0x6b,
  EXTEND_SCANCODE_DOWN = 0x72,
  EXTEND_SCANCODE_UP = 0x75,
  EXTEND_SCANCODE_RCTRL = 0x14,
  EXTEND_SCANCODE_RSHIFT = 0x59,
  EXTEND_SCANCODE_RALT = 0x11 /**< alt gr, option */
} ExtendScancode;

#define XX(k) [SCANCODE_##k] = AM_KEY_##k,
#define EXTEND_XX(k) [EXTEND_SCANCODE_##k] = AM_KEY_##k
static int keymap[256] = {AM_KEYS(XX)};
static int extend_keymap[256] = {
    EXTEND_XX(INSERT),   EXTEND_XX(INSERT), EXTEND_XX(HOME),
    EXTEND_XX(PAGEUP),   EXTEND_XX(DELETE), EXTEND_XX(END),
    EXTEND_XX(PAGEDOWN), EXTEND_XX(RIGHT),  EXTEND_XX(LEFT),
    EXTEND_XX(DOWN),     EXTEND_XX(UP),     EXTEND_XX(RCTRL),
    EXTEND_XX(RSHIFT),   EXTEND_XX(RALT)};

static inline uint32_t inl(uintptr_t addr) {
  return *(volatile uint32_t *)addr;
}

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t keycode = inl(KBD_ADDR);
  if (keycode == 0xf0) {
    kbd->keydown = 0;
    keycode = inl(KBD_ADDR);
  } else {
    kbd->keydown = 1;
  }
  if (keycode == 0xe0) {
    kbd->keycode = extend_keymap[inl(KBD_ADDR)];
  } else {
    kbd->keycode = keymap[keycode];
  }
}
