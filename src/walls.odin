package game

import "core:log"
import rl "vendor:raylib"

Wall :: struct {
    collider: Collider
}

ParseRawWall :: proc(w: ^EntityRaw) -> Wall {
    return Wall {
        collider = GetColliderRetarded(w)
    }
}