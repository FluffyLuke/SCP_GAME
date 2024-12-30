package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

GetLevels :: proc() -> [number_of_levels]^Level {
    levels := [number_of_levels]^Level {
        GetMainMenu(),
        GetFirstLevel(),
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
        // delete(game_ctx.levels)
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

    // If window was closeb by "X", clean memory
    if game_ctx.current_level != nil {
        game_ctx.current_level.deinit(&game_ctx, game_ctx.current_level)
    }

    rl.CloseWindow()
}

RenderLevel :: proc(ctx: ^GameContext, level: ^Level) {
    // Render objects
    for d in ctx.current_level.drawables {
        source_copy := d.texture_source;
        if d.flip {
            source_copy.width = -source_copy.width
            rl.DrawTexturePro(d.texture, source_copy, d.texture_dest, 0, 0, rl.Color {255,255,255,255})
        } else {
            rl.DrawTexturePro(d.texture, source_copy, d.texture_dest, 0, 0, rl.Color {255,255,255,255})
        }
    }
}