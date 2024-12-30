package game

import "core:log"

FirstLevelName :: "FirstLevel"

@(private="file")
CameraStartingLocation := Point2 {-100, -100}

@(private="file")
StartState :: proc(g_ctx: ^GameContext, level: ^Level) {
    SpawnPlayer(g_ctx, g_ctx.player_starting_pos)

    event := Event {{}}
    AddSetPlayerStateEvent(&event, PlayerDisabledState {})
    AddMoveCameraStateEvent(&event, 0, &CameraStartingLocation)
    AddMoveCameraStateEvent(&event, 2, &g_ctx.player.pos)
    AddSetPlayerStateEvent(&event, PlayerStandingState {})
    append(&level.events, event)
    RunEventsDefault(g_ctx, &level.events)

    level.state = .RunningState
}

@(private="file")
RunningState :: proc(g_ctx: ^GameContext, level: ^Level) {
    RunEventsDefault(g_ctx, &level.events)
}

@(private="file")
EndingState :: proc(g_ctx: ^GameContext, level: ^Level) {
    DespawnPlayer(g_ctx)
    ChangeLevel(g_ctx)
}

RunFirstLevel :: proc(g_ctx: ^GameContext, level: ^Level) {
    switch level.state {
        case .StartState: StartState(g_ctx, level)
        case .RunningState: RunningState(g_ctx, level)
        case .EndingState: EndingState(g_ctx, level)
    }
}