package game

import rl "vendor:raylib"
import "core:mem"
import "core:fmt"
import log "core:log"

GameContext :: struct {
    font: rl.Font,
    levels: [dynamic]^Level,
    current_level: ^Level,
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

Drawable  :: struct {
    pos: Vector2,
    rotation: f32,
    texture: rl.Texture2D,
    text_source: rl.Rectangle, // Part of texture
    text_dest: rl.Rectangle // Size of this part
}

LevelState :: enum {
    Uninitialized,
    Initialized,
    ShouldClose,
}

Level :: struct {
    state: LevelState,

    init: proc(ctx: ^GameContext, level: ^Level),
    run_logic: proc(ctx: ^GameContext, level: ^Level),
    deinit: proc(ctx: ^GameContext, level: ^Level),

    click_areas: [dynamic]^ClickArea,
    colliders: [dynamic]^Collider,
    drawables: [dynamic]^Drawable,
    widgets: [dynamic]^Widget,
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

ChangeLevel :: proc(ctx: ^GameContext, current_level: ^Level, next_level: ^Level) {
    current_level.state = .ShouldClose
    ctx.current_level = next_level
}
