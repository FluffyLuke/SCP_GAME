package game

import "core:mem"
import "core:fmt"
import "core:log"
import "core:math"
import str "core:strings"
import rl "vendor:raylib"

window_width :: 1280
window_height :: 720

main :: proc() {
    logger := log.create_console_logger()
	context.logger = logger
    defer log.destroy_console_logger(logger)

    // Configure allocator
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }

    rl.InitWindow(window_width, window_height, "SCP Escape")
    rl.SetWindowPosition(200, 200)
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(60)

    dim := rl.GetScreenHeight()

    g_ctx := GameContext {
        debug = false,
        // tile_size = 16, // Read using parser
        font = rl.GetFontDefault(),
        levels = {},
        camera = {
            rl.Camera2D {
                zoom = 4,
                offset = {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)},
                target = {0, 0}
            },
            10,
            nil
        }
    }

    // This should be called before parsing levels
    // since parsing references the player
    PreparePlayer(&g_ctx)
    g_ctx.camera.target_ref = &g_ctx.player.pos

    GetTilesets(&g_ctx)
    ParseLevels(&g_ctx, "./levels/levels.ldtk")
    defer free(g_ctx.player.entity)

    logic: for !rl.WindowShouldClose() {
        log.debug("new tick")
        // Set debug mode
        if rl.IsKeyDown(.F7) {
            g_ctx.debug = true
        }
        if rl.IsKeyDown(.F8) {
            g_ctx.debug = false
        }

        // Start drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        // Run logic
        RunPlayerLogic(&g_ctx, GetEntityInstance(&g_ctx.player, &g_ctx.player.variant.(Player)))
        for &e in g_ctx.current_level.entities {
            e.update(&g_ctx, e)
        }
        g_ctx.current_level.run_level(&g_ctx, g_ctx.current_level)

        // Move camera
        MoveCamera(&g_ctx)

        // Render everything
        rl.BeginMode2D(g_ctx.camera)
        Render(&g_ctx)
        rl.EndMode2D()

        RednerUI(&g_ctx)

        // Stop Drawing
        rl.EndDrawing()
    }
}

MoveCamera :: proc(g_ctx: ^GameContext) {
    camera := &g_ctx.camera
    new_target := PointToRetardedVector(camera.target_ref^)
    // log.warn("Target:", camera.target)
    // log.warn("Target ref:", camera.target_ref)

    logic: if camera.speed == 0 {
        camera.target = new_target
    } else {
        // Since camera is moving towards something, it is needed to check 
        // if camera will not go beyond the target
        // Get distance
        distance := rl.Vector2Distance(camera.target, new_target)

        // Remember kids, never divide by 0
        // Otherwise Odin will become Javascript and return "NaN" 💀
        if distance == 0 do break logic

        // Get direction vector
        direction := new_target - camera.target
        direction /= distance
        direction *= camera.speed*rl.GetFrameTime()*50

        // Check if the next move would place the camera beyond the target
        next_position := camera.target + direction
        next_distance := rl.Vector2Distance(next_position, new_target)


        if next_distance > distance {
            camera.target = Vector2(g_ctx.player.pos)
        } else {
            camera.target = next_position
        }
    }

    // TODO add this feature later
    // left := f32(rl.GetScreenWidth()/2)/camera.zoom
    // right := g_ctx.current_level.dimensions.x - f32(rl.GetScreenWidth()/2)/camera.zoom

    // if camera.target.x < left {
    //     camera.target.x = left
    // } else if camera.target.x > right {
    //     camera.target.x = right
    // }
}

Render :: proc(g_ctx: ^GameContext) {
    for t in g_ctx.current_level.tiles {
        rl.DrawTexturePro(t.texture^, t.src, t.dest, 0, 0, rl.WHITE)
    }

    for e in g_ctx.current_level.entities {
        if !e.visible {
            continue
        }
        e.render(g_ctx, e)
    }

    if g_ctx.player.visible {
        RenderPlayer(g_ctx)
    }

    if g_ctx.debug {
        rl.DrawRectanglePro(g_ctx.player.collider, 0, 0, {255, 0, 0, 100})
        rl.DrawCircleV(PointToRetardedVector(g_ctx.player.pos), 2, {0, 255, 0, 255})
        for e in g_ctx.current_level.entities {
            rl.DrawRectanglePro(e.collider, 0, 0, {255, 0, 0, 100})
            rl.DrawCircleV(PointToRetardedVector(e.pos), 2, {0, 255, 0, 255})
        }
        for w in g_ctx.current_level.walls {
            rl.DrawRectanglePro(w.collider, 0, 0, {255, 0, 0, 100})
        }
    }
}
RednerUI :: proc(g_ctx: ^GameContext) {
    for &e in g_ctx.current_level.entities {
        e.render_ui(g_ctx, e)
    }

    if g_ctx.debug {
        rl.DrawTextPro(g_ctx.font, "Debug", {5, 5}, 0, 0, 70, 5, rl.WHITE)

        b := str.builder_make()
        str.write_string(&b, "Player pos: ")
        str.write_f32(&b, g_ctx.player.pos.x, 'f')
        str.write_string(&b, "x, ")
        str.write_f32(&b, g_ctx.player.pos.y, 'f')
        str.write_string(&b, "y")
        ps := str.to_string(b)
        player_pos := str.clone_to_cstring(ps)

        b = str.builder_make()
        str.write_string(&b, "Camera pos: ")
        str.write_f32(&b, g_ctx.camera.target.x, 'f')
        str.write_string(&b, "x, ")
        str.write_f32(&b, g_ctx.camera.target.y, 'f')
        str.write_string(&b, "y")
        cs := str.to_string(b)
        camera_pos := str.clone_to_cstring(cs)

        defer {
            delete(ps)
            delete(cs)
            delete(player_pos)
            delete(camera_pos)
        }

        rl.DrawTextPro(g_ctx.font, player_pos, {5, 120}, 0, 0, 25, 5, rl.WHITE)
        rl.DrawTextPro(g_ctx.font, camera_pos, {5, 160}, 0, 0, 25, 5, rl.WHITE)
    }

    RenderUIPlayer(g_ctx)
}