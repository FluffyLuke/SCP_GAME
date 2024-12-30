package game

import "core:log"
import "core:encoding/json"
import str "core:strings"

import rl "vendor:raylib"
import "core:math"


DoorNotConnected :: struct {}
DoorConnected :: struct {
    puzzles: [10]^Puzzle
}

DoorState :: union {
    DoorNotConnected,
    DoorConnected,
}

Door :: struct {
    is_open: bool,
    new_player_pos: Point2,
    level_name: string,
    state: DoorState,

    closed_anim: AnimatedTexture,
    open_anim: AnimatedTexture,
}

ParseRawDoor :: proc(g_ctx: ^GameContext, d: ^EntityRaw) -> EntityInstance(Door) {
    level_name := d.fieldInstances[0].(json.Object)["__value"].(json.String)
    x := f32(d.fieldInstances[1].(json.Object)["__value"].(json.Integer))
    y := f32(d.fieldInstances[2].(json.Object)["__value"].(json.Integer))

    door := new(Entity)
    door^ = Entity {
        pos = GetPoint(d),
        visible = true,
        collider = GetColliderRetarded(d),
        use_item = UseItemEmpty,
        update = UpdateDoor,
        render = RenderDoor,
        render_ui = RenderEmpty,
        variant = Door {
            is_open = true,
            level_name = str.clone(level_name),
            new_player_pos = {x, y},

            closed_anim = NewAnimatedTexture(
                g_ctx, 
                "./assets/door/placeholders/door_closed.png",
                {16,32},
                {16,32},
                1,
                1,
            ),
            open_anim = NewAnimatedTexture(
                g_ctx, 
                "./assets/door/placeholders/door_open.png",
                {32,32},
                {16,32},
                2,
                3,
            ),
            state = DoorNotConnected {}
        }
    }
    return GetEntityInstance(door, &door.variant.(Door))
}

@(private="file")
UpdateDoor :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    door: EntityInstance(Door) = GetEntityInstance(entity, &entity.variant.(Door))

    switch &s in door.state {
        case DoorNotConnected: ConnectPuzzles(g_ctx, door)
        case DoorConnected: CheckPuzzles(g_ctx, door)
    }
}

@(private="file")
CheckPuzzles :: proc(g_ctx: ^GameContext, door: EntityInstance(Door)) {
    should_open := true
    for p in door.state.(DoorConnected).puzzles {
        if p == nil do continue
        if !p.finished {
            should_open = false
            break
        }
    }

    door.is_open = should_open
}

@(private="file")
ConnectPuzzles :: proc(g_ctx: ^GameContext, door: EntityInstance(Door)) {
    new_state := DoorConnected {}
    for &e, i in g_ctx.current_level.entities {
        if p, ok := &e.variant.(Puzzle); ok {
            new_state.puzzles[i] = p
        }
    }
    door.state = new_state
}

GoThruDoor :: proc(g_ctx: ^GameContext, door: EntityInstance(Door)) {
    if !door.is_open do return 

    g_ctx.current_level.state = .EndingState
    g_ctx.change_level_info = {
        level_name = door.level_name,
        new_player_pos = door.new_player_pos,
    }
}

RenderDoor :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    door: EntityInstance(Door) = GetEntityInstance(entity, &entity.variant.(Door))

    door.current_animation = door.is_open ? &door.open_anim : &door.closed_anim
    anim := door.current_animation

    UpdateAnimatedTexture(anim)
    RenderTextureDefault(anim, door.pos)
}