package game

import rl "vendor:raylib"
import "core:mem"
import "core:fmt"

GameContext :: struct {
    font: rl.Font,
    levels: [dynamic]^Level,
    current_level: ^Level,
}

Vector2 :: rl.Vector2

ClickArea :: struct {
    rec: rl.Rectangle,
    enabled: bool,
    data: rawptr,
    action: proc(game_ctx: ^GameContext, data: rawptr)
}

NewClickArea :: proc(
    rec: rl.Rectangle,
    enabled: bool,
    data: rawptr,
    action: proc(game_ctx: ^GameContext, data:  rawptr)
) -> ClickArea {
    return {
        rec = rec,
        enabled = enabled,
        data = data,
        action = action,
    }
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

    data: rawptr,
    clickables: [dynamic]^Collider,
    collaidables: [dynamic]^Collider,
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

CloseLevel :: proc(ctx: ^GameContext, data: rawptr) {
    level := cast(^Level)data
    level.state = .ShouldClose
    ctx.current_level = nil
}

RenderLevel :: proc(ctx: ^GameContext, level: ^Level) {
    // Render objects

    r: rl.Rectangle
    // Render widgets
    for &widget in level.widgets {
        switch &s in widget {
            case Label: {
                rl.DrawText(s.text, i32(s.pos[0]), i32(s.pos[1]), s.text_size, s.text_color)
            }
            case Button: {
                CheckButtonState(ctx, &s)
                RenderButton(ctx, &s)
            }
        }
    }
}

RenderButton :: proc(ctx: ^GameContext, button: ^Button) {
    font_spacing :: 5
    text_color: rl.Color
    text_size: f32

    switch button.state {
        case .BUTTON_DISABLED: {
            text_color = button.b_disabled.text_color
            text_size = button.b_disabled.text_size
        }
        case .BUTTON_NORMAL: {
            text_color = button.b_normal.text_color
            text_size = button.b_normal.text_size
        }
        case .BUTTON_HOVER: {
            text_color = button.b_hover.text_color
            text_size = button.b_hover.text_size
        }
        case .BUTTON_CLICKED: {
            text_color = button.b_clicked.text_color
            text_size = button.b_clicked.text_size
        }
    }

    rl.DrawRectangleV({button.rec.x, button.rec.y}, {button.rec.width, button.rec.height}, rl.GRAY)
    offset := rl.MeasureTextEx(ctx.font, button.text, text_size, font_spacing)

    offsex_x := button.rec.x+(button.rec.width/2)-(offset.x/2)
    offsex_y := button.rec.y+(button.rec.height/2)-(offset.y/2)

    rl.DrawTextEx(ctx.font, button.text, {offsex_x, offsex_y}, text_size, font_spacing, text_color)
}
