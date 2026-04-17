export const TILE_SIZE = 32;
export const GRID_WIDTH = 26;
export const GRID_HEIGHT = 14;

export const SCENE_PADDING = 16;

export function gridToWorldX(x: number) {
  return SCENE_PADDING + x * TILE_SIZE;
}

export function gridToWorldY(y: number) {
  return SCENE_PADDING + y * TILE_SIZE;
}
