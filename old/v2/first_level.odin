package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import log "core:log"

@(private="file")
MainMenuData :: struct {
    player_ref: ^Player
}

@(private="file")
level_data: MainMenuData

@(private="file")
Init :: proc(ctx: ^GameContext, level: ^Level) { 
    level.state = .Initialized

    ctx.player = InitPlayer({200, 200})

    level_data = {
        player_ref = &ctx.player
    }

    level.colliders = {
        
    }

    level.drawables = {
        level_data.player_ref
    }

    level.state = .Initialized
}

@(private="file")
FirstLevelUI :: proc(ctx: ^GameContext, level: ^Level) {

}

@(private="file")
RunLogic :: proc(ctx: ^GameContext, level: ^Level) {
    FirstLevelUI(ctx, level)

    delta := rl.GetFrameTime()

    if rl.IsKeyDown(.LEFT) {
        UpdatePlayerPosition(level_data.player_ref, {-200*delta, 0}, true)
    } else if rl.IsKeyDown(.RIGHT) {
        UpdatePlayerPosition(level_data.player_ref, {200*delta, 0}, false)
    }

}

@(private="file")
Deinit :: proc(ctx: ^GameContext, level: ^Level) {
    delete(level.drawables)
    delete(level.colliders)

    level.state = .ShouldClose
}

GetFirstLevel :: proc() -> ^Level {
    level := new(Level)

    level.state = .Uninitialized
    level.id = .FIRST_LEVEL

    level.init = Init
    level.run_logic = RunLogic
    level.deinit = Deinit

    return level
}