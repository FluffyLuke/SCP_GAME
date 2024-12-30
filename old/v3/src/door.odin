package game

import rl "vendor:raylib"
import str "core:strings"
import fmt "core:fmt"

DoorType :: enum {
    Regular = 0
}

Door :: struct {
    type: DoorType,
    texture: StaticTexture,
    collider: Collider,

    level_id: i32,
    exit_point_id: i32,
}

ExitPoint :: struct {
    id: i32,
    pos: Vector2,
}

DoorTypeNames :: [DoorType]string {
    .Regular = "RegularDoor"
}

GetDoorType :: proc(type: string) -> (DoorType, bool) {
    for dt, i in DoorTypeNames {
        if str.compare(dt, type) == 0 {
            return i, true
        }
    }
    return .Regular, false
}

InitDoor :: proc(g_ctx: ^GameContext, type: DoorType, pos: Vector2, epi: i32) -> (door: Door) {
    door_texture_path: string

    door_collider: rl.Rectangle
    door_source: rl.Vector2
    door_dimensions: rl.Vector2

    switch type {
        case .Regular: {
            door_texture_path = "./assets/doors/regular_door.png"
            door_source = {16, 32}
            door_dimensions = {16, 32}
            door_collider = {
                x = 16,
                y = 32,
                width = pos.x,
                height = pos.y
            }
        }
        case: {
            door_texture_path = "./assets/doors/regular_door.png"
            door_source = {16, 32}
            door_dimensions = {16, 32} 
            door_collider = {
                x = 16,
                y = 32,
                width = pos.x,
                height = pos.y
            }
        }
    }

    fmt.printfln("Laduje drztwi")
    return Door {
        type = type,
        level_id = (epi / 10) * 10,
        exit_point_id = epi,


        collider = door_collider,
        texture = NewStaticTexture(g_ctx, door_texture_path, door_source, door_dimensions),
    }
}

GetDoorCenter :: proc(door: EntityInstance(Door)) -> (pos: rl.Vector2) {
    pos.x = door.pos.x 
    pos.y = door.pos.y
    return
}

RednerDoor :: proc(g_ctx: ^GameContext, door: EntityInstance(Door)) {
    src := rl.Rectangle {
        0,
        0,
        door.texture.texture_source.x,
        door.texture.texture_source.y,
    }

    dest := rl.Rectangle {
        door.pos.x,
        door.pos.y,
        door.texture.texture_dimensions.x,
        door.texture.texture_dimensions.y,
    }

    tint := rl.WHITE

    if door.in_players_reach {
        tint = {255, 0, 0, 255}
    }

    rl.DrawTexturePro(
        door.texture.texture_image,
        src,
        dest,
        {0,0},
        0,
        tint
    )
}