#+feature dynamic-literals

package game

import "core:mem"
import "core:encoding/json"
import "core:log"
import str "core:strings"

import rl "vendor:raylib"

// General data about game
GameContext :: struct {
    debug: bool, // whether the game is in debug mode or not
    font: rl.Font,
    player: EntityInstance(Player),

    camera: struct {
        using cam: rl.Camera2D,
        speed: f32,
        target_ref: ^Point2,
    },
    tilesets: map[Tilesets]^rl.Texture2D,

    change_level_info: ChangeLevelInfo,

    // --- Read using parser ---
    default_tile_width: i32,
    default_tile_height: i32,

    levels: [dynamic]^Level,
    dialogues: [dynamic]Dialogue,
    current_level: ^Level,

    player_starting_pos: Point2,
}

Item :: struct {
    id: string,
    destroyed: bool,
    default_animation: AnimatedTexture,
    data: any,
}


ItemParseData :: struct {
    default_texture_path: string,
    frames: i32,
    speed: f32,
    repeat: bool,

    source_dimensions: Vector2,
    source_dimensions_offset: Vector2,
    render_dimensions: Vector2,
} 

ParseRawItem :: proc(g_ctx: ^GameContext, p: ^EntityRaw) -> EntityInstance(Item) {
    
    item_data := map[string]ItemParseData {
        FuzeItemName = FuzeItemTexturePath,
    }

    id := p.fieldInstances[0].(json.Object)["__value"].(json.String)
    data, ok := item_data[id]
    if !ok {
        log.error("Cannot find texture for item of id: ", id, "!")
    }

    texture_path_c := str.clone_to_cstring(data.default_texture_path, context.temp_allocator)
    pos := RetartedVectorToPoint(p.px)
    item := new(Entity)
    item^ = Entity {
        pos = pos,
        visible = true,
        collider = GetCollider(p),
        update = UpdateEmpty,
        render = RenderEntityDefault,
        render_ui = RenderUIEmpty,
        variant = Item {
            id = str.clone(id),
            default_animation = NewAnimatedTexture(
                g_ctx,
                texture_path_c,
                data.source_dimensions,
                data.render_dimensions,
                {0,0},
                data.frames,
                data.speed,
                data.repeat,
            ),
        }
    }
    item_instance := GetEntityInstance(item, &item.variant.(Item))
    item_instance.current_animation = &item_instance.default_animation

    return item_instance
}

Tilesets :: enum {
    RoomTileset
}

GetTilesets :: proc(g_ctx: ^GameContext) {

    room_tileset_path: cstring = "./assets/tilesets/levels.png"

    door_tileset := new(rl.Texture2D)
    door_tileset^ = rl.LoadTexture(room_tileset_path)
    g_ctx.tilesets = {
        .RoomTileset = door_tileset
    }

    free_all(context.allocator)
}

GetCameraTarget :: proc(g_ctx: ^GameContext) -> Vector2 {
    return g_ctx.camera.target
} 