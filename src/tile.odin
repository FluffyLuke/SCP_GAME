package game

import "core:log"
import rl "vendor:raylib"

Tile :: struct {
    texture: ^rl.Texture2D,
    src: Rectangle,
    dest: Rectangle,
}

TileLayerMask :: enum {
    Room = 0,
    Background = 1,
    Decorations = 2,
    Foreground = 3,
}

ParseTiles :: proc(g_ctx: ^GameContext, level: ^Level, tile_layer: ^[]AutoLayerTile, tileset: ^rl.Texture2D, mask: TileLayerMask) {
    for t in tile_layer {
        tile := Tile {
            texture = tileset,
            src = { f32(t.src.x), f32(t.src.y), f32(g_ctx.default_tile_width), f32(g_ctx.default_tile_height) },
            dest = { f32(t.px.x), f32(t.px.y) , f32(g_ctx.default_tile_width), f32(g_ctx.default_tile_height) },
        }
        append(&level.tiles[mask], tile)
    }
}