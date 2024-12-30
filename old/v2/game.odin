package game

import rl "vendor:raylib"
import "core:mem"
import "core:fmt"
import log "core:log"

GameContext :: struct {
    font: rl.Font,
    levels: [number_of_levels]^Level,
    current_level: ^Level,

    player: Player
}

Vector2 :: rl.Vector2


ClickAreaDisabled :: struct {}
ClickAreaEnabled :: struct {
    clicked: bool,
}

ClickAreaState :: union {
    ClickAreaDisabled,
    ClickAreaEnabled
}

ClickArea :: struct {
    rec: rl.Rectangle,
    message: cstring,
    state: ClickAreaState
}

CheckClickArea :: proc(rec: rl.Rectangle, area: ^ClickAreaEnabled){
    pos := rl.GetMousePosition()
    hold := rl.IsMouseButtonDown(.LEFT)

    if rl.CheckCollisionPointRec(pos, rec) && hold {
        area.clicked = true
    } else {
        area.clicked = false
    }
}

NewClickArea :: proc(
    rec: rl.Rectangle,
    enabled: bool,
) -> ClickArea {
    area: ClickArea
    area.rec = rec;
    if enabled {
        area.state = ClickAreaEnabled {}
    } else {
        area.state = ClickAreaDisabled {}
    }
    return area
}

Collider :: struct {
    rec: rl.Rectangle,
    enabled: bool,
}

NewCollider :: proc(rec: rl.Rectangle, enabled: bool) -> Collider {
    return {
        rec = rec,
        enabled = enabled,
    }
}


number_of_levels ::  2
LevelID :: enum {
    EXIT,
    MAIN_MENU,
    FIRST_LEVEL,
}

LevelState :: enum {
    Uninitialized,
    Initialized,
    ShouldClose,
}

Level :: struct {
    state: LevelState,
    id: LevelID,

    init: proc(ctx: ^GameContext, level: ^Level),
    run_logic: proc(ctx: ^GameContext, level: ^Level),
    deinit: proc(ctx: ^GameContext, level: ^Level),

    colliders: [dynamic]^Collider,
    drawables: [dynamic]^Drawable,
}

EventState :: enum {
    EventInit,
    EventRun,
}

Event :: struct {
    state: EventState,
    data: rawptr,
    event: proc(game_ctx: ^GameContext, data: rawptr) -> bool,
}

ChangeLevel :: proc(ctx: ^GameContext, current_level: ^Level, next_level: LevelID) {
    current_level.state = .ShouldClose

    ctx.current_level = nil

    if next_level == .EXIT {
        return
    }

    for level in ctx.levels {
        if level.id == next_level {
            ctx.current_level = level
        }
    }

    if ctx.current_level == nil {
        fmt.printf("Cannot find level %s!\n", next_level)
    }
}

Drawable :: struct {
    pos: Vector2,
    flip: bool,
    texture: rl.Texture2D,
    texture_source: rl.Rectangle, // Part of texture
    texture_dest: rl.Rectangle // Size of this part
}

Player :: struct {
    using Drawable
}

InitPlayer :: proc(pos: Vector2) -> Player {
    player: Player = {
        pos = pos,
        texture = rl.LoadTexture("./assets/player/model.gif"),
        texture_source = {0, 0, 1216, 1216},
        texture_dest = {pos.x, pos.y, 150, 150},
    }

    return player
}

UpdatePlayerPosition :: proc(player: ^Player, pos_add: Vector2, flip: bool) {
    player.pos += pos_add
    player.flip = flip;

    player.texture_dest.x = player.pos.x
    player.texture_dest.y = player.pos.y
}
