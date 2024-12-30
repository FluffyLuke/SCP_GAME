package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:os"

window_width :: 1280
window_height :: 720

Vector2 :: rl.Vector2

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    rl.InitWindow(window_width, window_height, "SCP Escape")
    rl.SetWindowPosition(200, 200)
    rl.SetWindowState({.WINDOW_RESIZABLE})
    // FIX for some reason code commented below does not work?
    // rl.SetExitKey(.DELETE)
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

    g_ctx: GameContext
    g_ctx.grid_size = 16 // TODO check this value automatically
    if file, success := os.read_entire_file_from_filename("./levels/levels.ldtk"); success == true {
        g_ctx = GameContext {
            debug = false,
            // current_level = ,
        
            camera = rl.Camera2D {
                zoom = 1,
                offset = {0, 0},
                target = {0, 0}
            },
            transition_layer = {
                opacity = 0
            },

            levels_file = file,
            levels = {
                GetMainMenu(),
                GetFirstLevel(),
                GetFirstLevelFloor(),
            }
        }
    } else {
        fmt.printfln("Cannot read file containing levels!")
        return
    }

    LoadTilesets(&g_ctx.tilesets)

    g_ctx.current_level = g_ctx.levels[0]
    g_ctx.current_level.state = .NeverVisited
    g_ctx.next_level = .MAIN_MENU

    defer {
        for l in g_ctx.levels {
            free(l)
        }
        delete(g_ctx.tilesets)
        delete(g_ctx.levels_file)
        delete(g_ctx.levels)
    }

    logic: for !rl.WindowShouldClose() {
        if g_ctx.next_level == .EXIT {
            break;
        }

        if g_ctx.current_level.id != g_ctx.next_level {
            for l in g_ctx.levels {
                if l.id == g_ctx.next_level {
                    fmt.printfln("Found new level: %s", g_ctx.next_level)
                    // If place was visited previosly (state not set to "never visited")
                    // Mark it that player just entered the area
                    if l.state == .Visited {
                        l.state = .JustVisted
                    }
                    g_ctx.current_level = l
                    break
                }
            }

            // No new level found
            if g_ctx.current_level.id != g_ctx.next_level {
                fmt.printfln("Cannot find new level: %s", g_ctx.next_level)
                break
            }
            fmt.printfln("Checking new level id: %d", g_ctx.current_level.id)
            // Check for new position of a player
            if g_ctx.next_exit_point_id >= 0 {
                g_ctx.next_exit_point_id = -1

                exit_point: ExitPoint
                found: bool
                fmt.printfln("Checking new epi: %d", g_ctx.current_level.exit_points)
                for ep in g_ctx.current_level.exit_points {
                    fmt.printfln("Checking new level id in ep: %d", ep.id)
                    if ep.id == g_ctx.next_exit_point_id {
                        found = true
                        g_ctx.player.pos = ep.pos
                    }
                }

                if !found {
                    fmt.printfln("Couldn't find an exit point!")
                    break logic
                }
            }
        }

        if rl.IsKeyDown(.F7) {
            g_ctx.debug = true
        }
        if rl.IsKeyDown(.F8) {
            g_ctx.debug = false
        }

        g_ctx.current_level.run_level(&g_ctx)
        CheckCamera(&g_ctx)
        rl.BeginDrawing()
        // Pink color for easier debugging
        rl.ClearBackground(rl.BLACK)
        rl.BeginMode2D(g_ctx.camera)

        Render(&g_ctx)
        clear(&g_ctx.current_level.temp_entities)

        rl.EndMode2D()
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    // Clean levels
    for l in g_ctx.levels {
        CleanEvents(l)

        if(l.state == .NeverVisited) {
            continue
        }

        delete(l.tiles)
        delete(l.events)
        delete(l.current_events)
        delete(l.entities)
        delete(l.temp_entities)
    }

    rl.CloseWindow()
}

CheckCamera :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    camera := &g_ctx.camera
    max_x := level.dimensions.x - f32(rl.GetScreenWidth())/camera.zoom
    max_y := level.dimensions.y - f32(rl.GetScreenHeight())/camera.zoom


    if camera.target.x < 0 {
        camera.target.x = 0
    } else if camera.target.x > max_x {
        camera.target.x = max_x
    }

    if camera.target.y < 0 {
        camera.target.y = 0
    } else if camera.target.y > max_y {
        camera.target.y = max_y
    }
}

Render :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    camera_dim := GetCameraDimensions(g_ctx)
    camera_pos := GetCameraPosition(g_ctx)

    layers: [LAYER_NUMBER][dynamic]^Entity
    for index, layer in RenderLayer {
        layers[index] = {}
    }

    // TODO this is temporaly fix
    // Need to add proper way of checking if player has been initialized
    if g_ctx.player.visible {
        append(&layers[RenderLayer.Player], &g_ctx.player)
    }

    t := Entity {
        pos = camera_pos,
        visible = true,
        variant = g_ctx.transition_layer
    }
    append(&layers[RenderLayer.Transition], &t)

    for &entity in level.entities {
        append(&layers[entity.layer], &entity)
    } 
    for &entity in level.temp_entities {
        append(&layers[entity.layer], &entity)
    } 

    for &tile in g_ctx.current_level.tiles {
        DrawTile(&tile)
    }

    // Layers 0-5 (entities)
    for layer, idx in layers {
        for entity in layer {

            if(!entity.visible) {
                continue
            }

            switch &v in entity.variant {
                case Player: {
                    RenderPlayer(GetEntityInstance(entity, &v))
                    if(g_ctx.debug) {
                        rl.DrawRectangle(i32(v.collider.x), i32(v.collider.y), i32(v.collider.width), i32(v.collider.height), {255, 255, 0, 100})
                    }
                }
                case StaticObject: {
                    RenderStaticObject(GetEntityInstance(entity, &v))
                    if(g_ctx.debug) {
                        rl.DrawRectangle(i32(v.collider.x), i32(v.collider.y), i32(v.collider.width), i32(v.collider.height), {255, 255, 0, 100})
                    }
                }
                case StaticCollider: {
                    // Nothing
                }
                case Transition: {
                    opacity := u8(g_ctx.transition_layer.opacity*255)
                    transition_rec := rl.Rectangle {
                        g_ctx.camera.target.x,
                        g_ctx.camera.target.y,
                        camera_dim.x,
                        camera_dim.y
                    }
                    rl.DrawRectanglePro(transition_rec, {0,0}, 0, {0,0,0, opacity})
                }
                case Door: {
                    RednerDoor(g_ctx, GetEntityInstance(entity, &v))
                }
                case IntroText: {
                    RenderIntroText(g_ctx, GetEntityInstance(entity, &v))
                }
            }
        }
    }
    
    if(g_ctx.debug) {
        rl.DrawTextPro(rl.GetFontDefault(), "Debug", g_ctx.camera.target, {-10,-10}, 0, 10, 5, rl.RED)
        camera_dim := GetCameraDimensions(g_ctx)/2
        rec_pos := Vector2 {g_ctx.camera.target.x + camera_dim.x, g_ctx.camera.target.y + camera_dim.y}
        rec := rl.Rectangle {rec_pos.x-8, rec_pos.y-8, 16, 16}
        rl.DrawRectanglePro(rec, {0,0}, 0, {255, 0, 0, 150})
    }

    for index, layer in RenderLayer {
        delete(layers[index])
    }
}