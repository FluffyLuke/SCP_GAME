package game

import rl "vendor:raylib"

Collider :: rl.Rectangle

GetCenteredRec :: proc(pos: Vector2, width: f32, height: f32) -> rl.Rectangle {
    return {pos.x-(width/2), pos.y-(height/2), width, height}
}

GetCenterRec :: proc(rec: rl.Rectangle) -> Vector2 {
    return {
        rec.x + (rec.width/2),
        rec.y + (rec.height/2)
    }
}

RenderLayer :: enum {
    FarBackground = 0,
    CloseBackground = 1,
    Props = 2,
    Player = 3,
    CloseForeground = 4,
    FarForeground = 5,
    Transition = 6,
    Text = 7,
}
LAYER_NUMBER :: 8

Entity :: struct {
    using pos: Vector2,
    layer: RenderLayer,
    visible: bool,
    in_players_reach: bool,

    variant: union {
        Player,
        StaticCollider,
        StaticObject,
        IntroText,
        Transition,
        Door
    }
}

// https://www.youtube.com/watch?v=UidiNCZVPKw
EntityInstance :: struct($T: typeid) {
    using entity: ^Entity,
    using var: ^T,
}

GetEntityInstance :: proc(e: ^Entity, var: ^$T) -> EntityInstance(T) {
    return EntityInstance(T) { e, var }
}