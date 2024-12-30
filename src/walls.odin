package game

import "core:log"
import rl "vendor:raylib"

Wall :: struct {
    collider: Rectangle
}

ParseRawWall :: proc(w: ^EntityRaw) -> Wall {
    return Wall {
        collider = GetColliderRetarded(w)
    }
}