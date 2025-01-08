#ifndef DEVICE_H
#define DEVICE_H

#include "common.h"
#include <SDL2/SDL.h>

extern void *vmem;
extern uint32_t *vgactl_port_base;

void vga_update_screen();
void init_vga();

#endif