#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <stdarg.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char buff[8192];

static int num2str(char *out, uint64_t num, bool is_sign, int width,
                   int radix) {
  char *tmp = out;
  if (is_sign && (int64_t)num < 0) {
    *out++ = '-';
    num = ~num + 1;
  }
  char num_buff[20];
  int index = 0;
  do {
    if (radix == 0) { // dec
      num_buff[index++] = num % 10 + '0';
      num /= 10;
    } else if (radix == 1) { // hex
      char c = num % 16;
      if (c >= 10) {
        c = c - 10 + 'a';
      } else {
        c += '0';
      }
      num_buff[index++] = c;
      num /= 16;
    }
  } while (num != 0);

  // fill 0
  while (width-- > index) {
    *out++ = '0';
  }
  putch(index-'0');
  while (index > 0) {
    *out++ = num_buff[--index];
  }
  return out - tmp;
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  char *tmp = buff;
  int len = vsprintf(buff, fmt, ap);
  va_end(ap);
  while (*tmp) {
    putch(*tmp++);
  }
  return len;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  char *tmp = out;
  bool after_zero = false;
  int width = 0;
  while (*fmt) {
    if (*fmt == '%' || after_zero) {
      switch (*++fmt) {
      case 'c':
        *out++ = (char)va_arg(ap, int);
        break;
      case 's': {
        char *s = va_arg(ap, char *);
        while (*s) {
          *out++ = *s++;
        }
        break;
      }
      case 'd': {
        int d = va_arg(ap, int);
        int len = num2str(out, d, true, width, 0);
        out += len;
        break;
      }
      case 'x': {
        uint32_t d = va_arg(ap, uint32_t);
        int len = num2str(out, d, false, width, 1);
        out += len;
        break;
      }
      case 'l': {
        char ch = *++fmt;
        if (ch == 'd') {
          int64_t ld = va_arg(ap, int64_t);
          int len = num2str(out, ld, true, width, 0);
          out += len;
        } else if (ch == 'x') {
          uint64_t lx = va_arg(ap, uint64_t);
          int len = num2str(out, lx, false, width, 1);
          out += len;
        } else {
          assert(0); //  unsupport
        }
        break;
      }
      case 'p': {
        uintptr_t p = (uintptr_t)va_arg(ap, void *);
        *out++ = '0';
        *out++ = 'x';
        int real_width =
            sizeof(uintptr_t) * 2 > width ? sizeof(uintptr_t) * 2 : width;
        int len = num2str(out, p, false, real_width, 1);
        out += len;
        break;
      }
      case '0': {
        char ch = *++fmt;
        while (ch >= '0' && ch <= '9') {
          width = width * 10 + ch - '0';
          ch = *++fmt;
        }
        fmt--;
        after_zero = true;
        // skip reset
        continue;
      }
      default:
        assert(0); // unsupport
      }
      fmt++;
      // reset
      after_zero = false;
      width = 0;
    } else {
      *out++ = *fmt++;
    }
  }
  *out = '\0';
  return out - tmp + 1;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int len = vsprintf(out, fmt, ap);
  va_end(ap);
  return len;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int len = vsnprintf(out, n, fmt, ap);
  va_end(ap);
  return len;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  int len = vsprintf(buff, fmt, ap);
  if (len <= n) {
    strcpy(out, buff);
    return len;
  }
  strncpy(out, buff, n);
  return n;
}

#endif
