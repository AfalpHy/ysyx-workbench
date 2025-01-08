#include "common.h"
#include <elf.h>

typedef struct {
  char fun_name[256];
  word_t begin;
  word_t end;
} function_message;

static function_message funs[100000];
static int fun_num = 0;

FILE *ftrace_log = NULL;

void add_elf(const char *elf_file) {
  FILE *fp = fopen(elf_file, "r");
  Assert(fp, "open elf file failed");

  fseek(fp, 0, SEEK_END);
  long file_size = ftell(fp);
  char *buff = malloc(file_size);
  fseek(fp, 0, SEEK_SET);

  if (fread(buff, 1, file_size, fp)) {
    Elf64_Ehdr *elf_header = (Elf64_Ehdr *)buff;
    // section header offset
    Elf64_Off shoff = elf_header->e_shoff;
    // section header num
    Elf64_Half shnum = elf_header->e_shnum;
    // symbol table section header
    Elf64_Shdr *sym_section_hdr = NULL;
    // str table section header
    Elf64_Shdr *str_section_hdr = NULL;
    for (Elf64_Half i = 0; i < shnum; i++) {
      Elf64_Shdr *section_header =
          (Elf64_Shdr *)&buff[shoff + i * sizeof(Elf64_Shdr)];
      if (section_header->sh_type == SHT_SYMTAB) {
        sym_section_hdr = section_header;
      } else if (section_header->sh_type == SHT_STRTAB &&
                 i != elf_header->e_shstrndx) {
        str_section_hdr = section_header;
      }
    }
    Elf64_Off str_offset = str_section_hdr->sh_offset;
    Elf64_Off sym_offset = sym_section_hdr->sh_offset;
    Elf64_Xword sym_size = sym_section_hdr->sh_size;
    Elf64_Xword section_entry_size = sym_section_hdr->sh_entsize;
    // 遍历符号表
    for (Elf64_Xword begin = 0; begin < sym_size; begin += section_entry_size) {
      Elf64_Sym *symbol = (Elf64_Sym *)&buff[sym_offset + begin];
      if ((symbol->st_info & 0x0f) == SYMINFO_NUM) {
        Elf64_Word str_index = symbol->st_name;
        strcpy(funs[fun_num].fun_name, &buff[str_offset + str_index]);
        funs[fun_num].begin = symbol->st_value;
        funs[fun_num].end = symbol->st_value + symbol->st_size;
        fun_num++;
      }
    }
  }
  free(buff);
  fclose(fp);
}

void init_elf(const char *elf_file[], int num) {
  for (int i = 0; i < num; i++) {
    add_elf(elf_file[i]);
  }
}

bool has_message() { return fun_num != 0; }

char *get_fun_name(word_t addr) {
  for (int i = 0; i < fun_num; i++) {
    if (addr >= funs[i].begin && addr < funs[i].end) {
      return funs[i].fun_name;
    }
  }
  return NULL;
}

bool is_call(word_t addr) {
  for (int i = 0; i < fun_num; i++) {
    if (addr == funs[i].begin) {
      return true;
    }
  }
  return false;
}