package game

import rl "vendor:raylib"
import str "core:strings"
import "core:log"

ChangeLevelInfo :: struct {
    new_player_pos: Point2,
    level_name: string,
}

LevelState :: enum {
    StartState,
    RunningState,
    EndingState
}

Level :: struct {
    name: string,
    state: LevelState,
    
    tiles: [3][dynamic]Tile,
    walls: [dynamic]Wall,

    entities: [dynamic]^Entity,
    triggers: [dynamic]TriggerArea,
    events: [dynamic]Event,
    
    dimensions: Vector2, // Width and height in pixels
    run_level: proc(^GameContext, ^Level),
    data: any,
}

// Keep in mind, that info about new level must me set 
// in game context struct before calling this procedure
ChangeLevel :: proc(g_ctx: ^GameContext) {
    info := &g_ctx.change_level_info
    for l in g_ctx.levels {
        if str.compare(l.name, info.level_name) == 0 {
            g_ctx.current_level = l
            return
        }
    }
    log.error("Could not find the level: ", info.level_name, " !")
}

BindLevelData :: proc(level: ^Level) {
    switch level.name {
        case FirstLevelName: {
            level.run_level = RunFirstLevel
        }
        case SecondLevelName: {
            level.run_level = RunSecondLevel
        }
        case ThirdLevelName: {
            level.run_level = RunThirdLevel
        }
    }
}