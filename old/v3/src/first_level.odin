package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

@(private="file")
InitFirstLevel :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    level.state = .Visited

    g_ctx.camera.zoom = 4

    LoadLevelData(g_ctx)
    
    CreatePlayer(g_ctx)
    player := GetPlayer(g_ctx)
    player.pos = level.player_starting_pos
    player.visible = true

    LoadFirstEntryEvents(g_ctx)
}

@(private="file")
FirstLevelLogic :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    player := GetPlayer(g_ctx)

    if len(level.current_events) > 0 {
        for &event, i in level.current_events {
            if RunEvent(g_ctx, &event) {
                ordered_remove(&level.current_events, i)
            }
        }
    } else {
        camera_width, camera_height := f32(rl.GetScreenWidth()) / g_ctx.camera.zoom, f32(rl.GetScreenHeight()) / g_ctx.camera.zoom
        g_ctx.camera.target = CenterVector2(player.pos, camera_width, camera_height)
    }

    RunPlayerLogic(g_ctx, player)
}

@(private="file")
RunFirstLevel :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    switch level.state {
        case .NeverVisited: {
            InitFirstLevel(g_ctx)
            FirstLevelLogic(g_ctx)
        }
        case .JustVisted: {
            level.state = .Visited
            FirstLevelLogic(g_ctx)
        }
        case .Visited: {
            FirstLevelLogic(g_ctx)
        }
    }
}

GetFirstLevel :: proc() -> ^Level {
    level := new(Level)
    level^ = Level {
        id = .FIRST_LEVEL,
        name = "FirstLevel",
        state = .NeverVisited,
        tiles = {},
        run_level = RunFirstLevel,
    }

    return level
}

GetFirstLevelFloor :: proc() -> ^Level {
    level := new(Level)
    level^ = Level {
        id = .FIRST_LEVEL_FLOOR,
        name = "FirstLevelFloor",
        state = .NeverVisited,
        tiles = {},
        run_level = RunFirstLevel,
    }
    return level
}