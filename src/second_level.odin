package game

import "core:log"

SecondLevelName :: "SecondLevel"

@(private="file")
StartState :: proc(g_ctx: ^GameContext, level: ^Level) {
    SpawnPlayer(g_ctx, g_ctx.change_level_info.new_player_pos)
    level.state = .RunningState
}

@(private="file")
RunningState :: proc(g_ctx: ^GameContext, level: ^Level) {
    
}

@(private="file")
EndingState :: proc(g_ctx: ^GameContext, level: ^Level) {
    DespawnPlayer(g_ctx)
    ChangeLevel(g_ctx)
}

RunSecondLevel :: proc(g_ctx: ^GameContext, level: ^Level) {
    switch level.state {
        case .StartState: StartState(g_ctx, level)
        case .RunningState: RunningState(g_ctx, level)
        case .EndingState: EndingState(g_ctx, level)
    }
}