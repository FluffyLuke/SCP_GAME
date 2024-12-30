package game

import rl "vendor:raylib"
import "core:strconv"
import "core:strings"
import "core:fmt"
import "core:mem"
import "core:encoding/json"
import "core:os"

LoadTilesets :: proc(tileset: ^map[string]rl.Texture2D) {
    tilesets := map[string]string {
        "outside-tileset.png" = "./assets/tilesets/outside-tileset.png",
    }

    for key, value in tilesets {
        cvalue := strings.clone_to_cstring(value)
        texture := rl.LoadTexture(cvalue)
        tileset[key] = texture
        delete(cvalue)
    }

    delete(tilesets)
}

GetTileset :: proc(g_ctx: ^GameContext, tileset: string) -> (rl.Texture2D, bool) {
    return g_ctx.tilesets[tileset]
}

LoadTiles :: proc(
    g_ctx: ^GameContext,
    lvl: ^Level,
    tiles: []json.Value,
    tileset_path: string,
    grid_size: f64,
) -> (
    worked: bool
) {
    for t in tiles {
        tile_json := t.(json.Object) or_return
        dest := tile_json["px"].(json.Array) or_return
        src := tile_json["src"].(json.Array) or_return

        if len(dest) < 2 || len(src) < 2 {
            return
        }

        dest_x := dest[0].(json.Float)
        dest_y := dest[1].(json.Float)
        src_x := src[0].(json.Float)
        src_y := src[1].(json.Float)
        
        texture := GetTileset(g_ctx, tileset_path) or_return

        new_tile := Tile {
            texture = texture,
            src = rl.Rectangle {
                x = f32(src_x),
                y = f32(src_y),
                width = f32(grid_size),
                height = f32(grid_size),
            },
            dest = rl.Rectangle {
                x = f32(dest_x),
                y = f32(dest_y),
                width = f32(grid_size),
                height = f32(grid_size),
            },
        }
        append(&lvl.tiles, new_tile)
    }
    return true;
}

Tile :: struct {
    texture: rl.Texture2D,
    src: rl.Rectangle,
    dest: rl.Rectangle,
}

DrawTile :: proc(tile: ^Tile) {
    rl.DrawTexturePro(tile.texture, tile.src, tile.dest, {0,0}, 0, rl.WHITE)
}