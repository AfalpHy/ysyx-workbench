/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "sdb.h"

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  char expr[256];
  word_t val;
  bool used;
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].used = false;
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */

WP *new_wp() {
  if (free_ == NULL) {
    Assert(0, "There are no free watchpoints");
  }

  WP *result = free_;
  free_ = free_->next;
  result->next = NULL;
  result->used = true;
  if (head == NULL) {
    head = result;
  } else {
    WP *tmp = head;
    while (tmp->next != NULL) {
      tmp = tmp->next;
    }

    tmp->next = result;
  }

  return result;
}

void free_wp(uint64_t order) {
  if (order >= NR_WP) {
    printf("Can not free wp %ld\n", order);
  }
  WP *wp = &wp_pool[order];
  if (!wp->used) {
    printf("The watchpoint needn't to free\n");
    return;
  }
  wp->next = NULL;
  wp->used = false;
  if (wp == head) {
    head = head->next;
  } else {
    for (WP *pre = head, *tmp = head->next; tmp != NULL;
         pre = pre->next, tmp = tmp->next) {
      if (tmp == wp) {
        pre->next = tmp->next;
        break;
      }
    }
  }
  if (free_ == NULL) {
    free_ = wp;
  } else {
    WP *tmp = free_;
    while (tmp->next != NULL) {
      tmp = tmp->next;
    }
    tmp->next = wp;
  }
}

bool check_wp() {
  if (head == NULL) {
    return false;
  }
  bool change = false;
  for (WP *wp = head; wp != NULL; wp = wp->next) {
    bool success = true;
    word_t result = expr(wp->expr, &success);
    Assert(success, "eval failed when checking wp");
    if (result != wp->val) {
      change = true;
      printf("{%s} old value = %lu, new value = %lu\n", wp->expr, wp->val,
             result);
      wp->val = result;
    }
  }
  return change;
}

void print_wp() {
  for (WP *wp = head; wp != NULL; wp = wp->next) {
    printf("watchpoint's index:\t%d\n", wp->NO);
    printf("watchpoint's expr:\t%s\n", wp->expr);
    printf("watchpoint's current value:\t%lu\n", wp->val);
  }
}