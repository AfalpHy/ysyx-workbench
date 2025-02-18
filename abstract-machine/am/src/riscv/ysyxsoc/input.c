#include <am.h>
#include <klib.h>
#define KBD_ADDR 0x10011000
#define KEYDOWN_MASK 0x8000

typedef enum {
  SCANCODE_UNKNOWN = 0,

  /**
   *  \name Usage page 0x07
   *
   *  These values are from usage page 0x07 (USB keyboard page).
   */
  /* @{ */

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

  SCANCODE_1 = 30,
  SCANCODE_2 = 31,
  SCANCODE_3 = 32,
  SCANCODE_4 = 33,
  SCANCODE_5 = 34,
  SCANCODE_6 = 35,
  SCANCODE_7 = 36,
  SCANCODE_8 = 37,
  SCANCODE_9 = 38,
  SCANCODE_0 = 39,

  SCANCODE_RETURN = 40,
  SCANCODE_ESCAPE = 41,
  SCANCODE_BACKSPACE = 42,
  SCANCODE_TAB = 43,
  SCANCODE_SPACE = 44,

  SCANCODE_MINUS = 45,
  SCANCODE_EQUALS = 46,
  SCANCODE_LEFTBRACKET = 47,
  SCANCODE_RIGHTBRACKET = 48,
  SCANCODE_BACKSLASH = 49, /**< Located at the lower left of the return
                            *   key on ISO keyboards and at the right end
                            *   of the QWERTY row on ANSI keyboards.
                            *   Produces REVERSE SOLIDUS (backslash) and
                            *   VERTICAL LINE in a US layout, REVERSE
                            *   SOLIDUS and VERTICAL LINE in a UK Mac
                            *   layout, NUMBER SIGN and TILDE in a UK
                            *   Windows layout, DOLLAR SIGN and POUND SIGN
                            *   in a Swiss German layout, NUMBER SIGN and
                            *   APOSTROPHE in a German layout, GRAVE
                            *   ACCENT and POUND SIGN in a French Mac
                            *   layout, and ASTERISK and MICRO SIGN in a
                            *   French Windows layout.
                            */

  SCANCODE_SEMICOLON = 51,
  SCANCODE_APOSTROPHE = 52,
  SCANCODE_GRAVE = 53, /**< Located in the top left corner (on both ANSI
                        *   and ISO keyboards). Produces GRAVE ACCENT and
                        *   TILDE in a US Windows layout and in US and UK
                        *   Mac layouts on ANSI keyboards, GRAVE ACCENT
                        *   and NOT SIGN in a UK Windows layout, SECTION
                        *   SIGN and PLUS-MINUS SIGN in US and UK Mac
                        *   layouts on ISO keyboards, SECTION SIGN and
                        *   DEGREE SIGN in a Swiss German layout (Mac:
                        *   only on ISO keyboards), CIRCUMFLEX ACCENT and
                        *   DEGREE SIGN in a German layout (Mac: only on
                        *   ISO keyboards), SUPERSCRIPT TWO and TILDE in a
                        *   French Windows layout, COMMERCIAL AT and
                        *   NUMBER SIGN in a French Mac layout on ISO
                        *   keyboards, and LESS-THAN SIGN and GREATER-THAN
                        *   SIGN in a Swiss German, German, or French Mac
                        *   layout on ANSI keyboards.
                        */
  SCANCODE_COMMA = 54,
  SCANCODE_PERIOD = 55,
  SCANCODE_SLASH = 56,

  SCANCODE_CAPSLOCK = 57,

  SCANCODE_F1 = 58,
  SCANCODE_F2 = 59,
  SCANCODE_F3 = 60,
  SCANCODE_F4 = 61,
  SCANCODE_F5 = 62,
  SCANCODE_F6 = 63,
  SCANCODE_F7 = 64,
  SCANCODE_F8 = 65,
  SCANCODE_F9 = 66,
  SCANCODE_F10 = 67,
  SCANCODE_F11 = 68,
  SCANCODE_F12 = 69,

  SCANCODE_INSERT = 73, /**< insert on PC, help on some Mac keyboards (but
                                 does send code 73, not 117) */
  SCANCODE_HOME = 74,
  SCANCODE_PAGEUP = 75,
  SCANCODE_DELETE = 76,
  SCANCODE_END = 77,
  SCANCODE_PAGEDOWN = 78,
  SCANCODE_RIGHT = 79,
  SCANCODE_LEFT = 80,
  SCANCODE_DOWN = 81,
  SCANCODE_UP = 82,

  SCANCODE_APPLICATION = 101, /**< windows contextual menu, compose */

  SCANCODE_LCTRL = 224,
  SCANCODE_LSHIFT = 225,
  SCANCODE_LALT = 226, /**< alt, option */
  SCANCODE_LGUI = 227, /**< windows, command (apple), meta */
  SCANCODE_RCTRL = 228,
  SCANCODE_RSHIFT = 229,
  SCANCODE_RALT = 230 /**< alt gr, option */

} Scancode;

#define XX(k) [SCANCODE_##k] = AM_KEY_##k,
static int keymap[256] = {AM_KEYS(XX)};

static inline uint32_t inl(uintptr_t addr) {
  return *(volatile uint32_t *)addr;
}

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t keycode = inl(KBD_ADDR);
  if (keycode == 0xf0) {
    kbd->keydown = 0;
    kbd->keycode = keymap[inl(KBD_ADDR)];
  } else {
    kbd->keydown = 1;
    kbd->keycode = keymap[keycode];
  }

  if (keycode != 0)
    printf("%d %d %d\n", keycode, SCANCODE_A, AM_KEY_A);
}
