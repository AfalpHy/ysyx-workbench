#include "common.h"
#define SCREEN_W 400
#define SCREEN_H 300

static uint32_t screen_size() { return SCREEN_W * SCREEN_H * sizeof(uint32_t); }

#include <SDL2/SDL.h>

void *vmem = nullptr;
uint32_t *vgactl_port_base = nullptr;

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

static void init_screen() {
  SDL_Window *window = NULL;
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(SCREEN_W * 2, SCREEN_H * 2, 0, &window,
                              &renderer);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                              SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
}

static inline void update_screen() {
  SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}

void vga_update_screen() {
  if (vgactl_port_base[1] != 0) {
    update_screen();
    vgactl_port_base[1] = 0;
  }
}

void init_vga() {
  vgactl_port_base = (uint32_t *)malloc(8);
  vgactl_port_base[0] = (SCREEN_W << 16) | SCREEN_H;
  init_screen();
  vmem = malloc(screen_size());
  memset(vmem, 0, screen_size());
}
