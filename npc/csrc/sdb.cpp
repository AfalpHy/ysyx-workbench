#include "device.h"
#include "difftest.h"
#include "disasm.h"
#include "expr.h"
#include "verilated_dpi.h"
#include "watchpoint.h"
#include <VNPC.h>
#include <iostream>
#include <readline/history.h>
#include <readline/readline.h>
#include <sys/time.h>
#include <unistd.h>

extern VNPC top;
extern int status;
extern bool diff_test_on;

static int is_batch_mode = false;
int total_inst_num = 0;
// npc因为是仿真，存在上升沿与下降沿的时序逻辑，上升沿检测到的跳过当前指令，下降沿检测到的跳过下一条指令
bool skip_current_ref = false;
bool skip_next_ref = false;

#define MAX_IRINGBUF_LEN 20
typedef struct {
  paddr_t pc;
  uint32_t inst;
  char str[128];
} DisasmInst;

static DisasmInst iringbuf[MAX_IRINGBUF_LEN];

static void display_one_inst(const DisasmInst *di) {
  printf(FMT_WORD ":%08x\t%s\n", di->pc, di->inst, di->str);
}

static void iringbuf_display() {
  for (auto i = 0; i < 10; i++) {
    int iringbuf_index = (total_inst_num + i) % MAX_IRINGBUF_LEN;
    const auto &buf = iringbuf[iringbuf_index];
    if (strcmp(buf.str, "")) {
      display_one_inst(&buf);
    }
  }
}

static int check_ref() {
  word_t ref_reg[32];
  paddr_t reg_pc;
  ref_difftest_regcpy((void *)ref_reg, &reg_pc, DIFFTEST_TO_DUT);
  for (int i = 0; i < 32; i++) {
    if (ref_reg[i] != regs[i]) {
      std::cerr << total_inst_num << " instrutions has been executed"
                << std::endl;
      std::cerr << regs_name[i] << " ref:" << std::hex << ref_reg[i]
                << " npc:" << regs[i] << std::endl;
      return -1;
    }
    if (*pc != reg_pc) {
      std::cerr << total_inst_num << " instrutions has been executed"
                << std::endl;
      std::cerr << std::hex << " ref's pc:" << reg_pc << " npc's pc:" << *pc
                << std::endl;
      return -1;
    }
  }
  return 0;
}

static char *rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static void cpu_exec(uint32_t num) {
  uint32_t print_num = num;
  while (num-- > 0) {
    uint32_t inst = pmem_read(*pc, 4);
    int iringbuf_index = total_inst_num % MAX_IRINGBUF_LEN;
    iringbuf[iringbuf_index].pc = *pc;
    iringbuf[iringbuf_index].inst = inst;
    disassemble(iringbuf[iringbuf_index].str, sizeof(DisasmInst::str), *pc,
                (uint8_t *)&inst, 4);
    if (print_num <= 10) {
      display_one_inst(&iringbuf[iringbuf_index]);
    }

    single_cycle();

    if (diff_test_on) {
      if (skip_current_ref) {
        ref_difftest_regcpy(regs, pc, DIFFTEST_TO_REF);
      } else {
        ref_difftest_exec(1);
        if (check_ref() != 0) {
          return;
        }
      }
    }
    total_inst_num++;
    if (top.halt) {
      return;
    }
    if (check_wp()) {
      printf("watch point has been triggered\n");
      return;
    }
  }
}
static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) { return -1; }

static int cmd_si(char *args) {
  if (args == NULL) {
    cpu_exec(1);
  } else {
    cpu_exec(strtol(args, NULL, 10));
  }
  return 0;
}

static int cmd_info(char *args) {
  if (args == NULL) {
    return 0;
  }
  if (strcmp(args, "r") == 0) {
    isa_reg_display();
  } else if (strcmp(args, "w") == 0) {
    print_wp();
  } else if (strcmp(args, "i") == 0) {
    iringbuf_display();
  }
  return 0;
}

static int cmd_x(char *args) {
  char *base = NULL;
  uint64_t size = strtoul(args, &base, 10);
  word_t addr = strtoul(base, NULL, 16);
  for (uint64_t i = 0; i < size; ++i) {
    printf("0x%08x\n", (uint32_t)pmem_read(addr + 4 * i, 4));
  }
  return 0;
}

static int cmd_p(char *args) {
  bool success = true;
  word_t result = expr(args, &success);
  if (!success) {
    printf("eval expr failed, please check the expr\n");
  } else {
    printf(FMT_WORD_D " or " FMT_WORD "\n", result, result);
  }
  return 0;
}

static int cmd_w(char *args) {
  if (args == NULL) {
    printf("w commond need args, add watchpoint failed\n");
    return 0;
  }
  bool success = true;
  word_t result = expr(args, &success);
  if (!success) {
    printf("eval expr failed, please check the expr\n");
  } else {
    WP *wp = new_wp();
    strcpy(wp->expr, args);
    wp->val = result;
    wp->used = true;
  }
  return 0;
}

static int cmd_d(char *args) {
  uint64_t order = strtoul(args, NULL, 10);
  free_wp(order);
  return 0;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit NEMU", cmd_q},
    /* TODO: Add more commands */
    {"si", "Step forward n instructions", cmd_si},
    {"info", "Printf reg value or watchpoint", cmd_info},
    {"x", "Printf memory message, example: x 10 0x80000000", cmd_x},
    {"p", "Eval the expr", cmd_p},
    {"w", "Set the watchpoint", cmd_w},
    {"d", "Delete the watchpoint", cmd_d}};

#define NR_CMD sizeof(cmd_table) / sizeof(cmd_table[0])

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  } else {
    for (i = 0; i < NR_CMD; i++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() { is_batch_mode = true; }

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL;) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) {
      continue;
    }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) {
          return;
        }
        break;
      }
    }

    if (i == NR_CMD) {
      printf("Unknown command '%s'\n", cmd);
    }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}