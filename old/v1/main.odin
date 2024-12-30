package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

GetLevels :: proc() -> [dynamic]^Level {
    levels: [dynamic]^Level = {
        GetMainMenu()
    }
    return levels
}

window_width :: 1280
window_height :: 720

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    rl.InitWindow(window_width, window_height, "SCP Escape")
    rl.SetWindowPosition(200, 200)
    //rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(60)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }

    game_ctx: GameContext
    game_ctx.levels = GetLevels()
    game_ctx.current_level = game_ctx.levels[0]
    game_ctx.font = rl.GetFontDefault();
    
    defer {
        for level in game_ctx.levels {
            free(level)
        }
        delete(game_ctx.levels)
    }

    for !rl.WindowShouldClose() {
        if game_ctx.current_level == nil {
            break
        }
        
        current_level := game_ctx.current_level

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        #partial switch current_level.state {
            case .Uninitialized: {
                current_level.init(&game_ctx, current_level)
            }
            case .Initialized: {
                // Run logic (parse input, calculate physics, etc.)
                current_level.run_logic(&game_ctx, current_level)
                // Render level
                RenderLevel(&game_ctx, current_level)
            }
        }
        
        if current_level.state == .ShouldClose {
            current_level.deinit(&game_ctx, current_level)
        }

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    rl.CloseWindow()
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