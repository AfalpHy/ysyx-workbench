#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <stdarg.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char buff[8192];

static void get_num(char **out, uint64_t num, bool is_sign, int width,
                    int radix) {
  uint64_t tmp = num;
  if (is_sign) {
    if ((int64_t)tmp < 0) {
      *(*out)++ = '-';
      tmp = ~tmp + 1;
    }
  }
  char num_buff[20];
  int index = 0;
  do {
    if (radix == 0) { // 10进制
      num_buff[index++] = tmp % 10 + '0';
      tmp /= 10;
    } else if (radix == 1) { // 16进制
      char c = tmp % 16;
      if (c >= 10) {
        c = c - 10 + 'a';
      } else {
        c += '0';
      }
      num_buff[index++] = c;
      tmp /= 16;
    }
  } while (tmp != 0);
  if (radix == 1) {
    *(*out)++ = '0';
    *(*out)++ = 'x';
  }
  // 填充前置0
  while (width-- > index) {
    *(*out)++ = '0';
  }
  while (index > 0) {
    *(*out)++ = num_buff[--index];
  }
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
  char *result = out;
  int d;
  int64_t ld;
  char c;
  char *s;
  int width = 0;
  bool skip = false;
  while (*fmt) {
    if (*fmt != '%' && !skip) {
      *out++ = *fmt;
    } else {
      skip = false;
      switch (*++fmt) {
      case 's':
        s = va_arg(ap, char *);
        strcpy(out, s);
        out += strlen(s);
        break;
      case 'd':
        d = va_arg(ap, int);
        get_num(&out, d, true, width, 0);
        width = 0;
        break;
      case 'c':
        c = (char)va_arg(ap, int);
        *out++ = c;
        break;
      case 'p': {
        uintptr_t p = (uintptr_t)va_arg(ap, void *);
        get_num(&out, p, false, width, 1);
        width = 0;
        break;
      }
      case 'l': {
        char ch = *++fmt;
        if (ch == 'd') {
          ld = va_arg(ap, int64_t);
          get_num(&out, ld, true, width, 0);
          width = 0;
        }
        break;
      }
      case '0': {
        char ch = *++fmt;
        while (ch >= '0' && ch <= '9') {
          width = width * 10 + ch - '0';
          ch = *++fmt;
        }
        fmt -= 2;
        skip = true;
        break;
      }
      default:
        break;
      }
    }
    fmt++;
  }
  *out = '\0';
  return strlen(result) + 1;
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
