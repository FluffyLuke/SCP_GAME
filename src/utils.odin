package game

import rl "vendor:raylib"
import str "core:strings"
import "core:fmt"

Vector2 :: rl.Vector2
Rectangle :: rl.Rectangle

// Point2 represents a center of a thing.
// While most of things use upper left corner to mark their position (like colliders),
// things like "player" use their center to mark position
Point2 :: distinct rl.Vector2

// Upper left corner to center
VectorToPoint :: proc(v: Vector2, size: Vector2) -> Point2 {
    return Point2 {
        v.x + size.x/2,
        v.y + size.y/2,
    },
}

// Upper left corner to center
PointToVector :: proc(p: Point2, size: Vector2) -> Vector2 {
    return Vector2 {
        p.x - size.x/2,
        p.y - size.y/2,
    },
}

PointToRetardedVector :: proc(p: Point2) -> Vector2 {
    return Vector2 {
        p.x,
        p.y,
    },
}

RetartedVectorToPoint :: proc(v: Vector2) -> Point2 {
    return Point2 {
        v.x,
        v.y,
    },
}

Point2Distance :: proc(p1: Point2, p2: Point2) -> f32 {
    return rl.Vector2Distance(PointToRetardedVector(p1), PointToRetardedVector(p2))
}

CheckCollisionWithPoint :: proc(c: Collider, p: Point2) -> bool {
    return rl.CheckCollisionRecs(c, {p.x, p.y, 0.001, 0.001})
}

CheckCollisionWithVector2 :: proc(c: Collider, v: Vector2) -> bool {
    return rl.CheckCollisionRecs(c, {v.x, v.y, 0.001, 0.001})
}

CheckCollisionWithCollider  :: proc(c1: Collider, c2: Collider) -> bool {
    return rl.CheckCollisionRecs(c1, c2)
}

CheckCollision :: proc{
    CheckCollisionWithPoint,
    CheckCollisionWithVector2,
    CheckCollisionWithCollider,
}

CenterCollider :: proc(c: ^Collider, point: Point2) {
    vec := PointToVector(point, { c.width, c.height } )
    c^ = CreateCollider({ vec.x, vec.y, c.width, c.height })
}

RuneToString :: proc(r: rune) -> string {
    b := str.builder_make()
    str.write_rune(&b, r)
    num_str := str.to_string(b)
    return num_str
}

RunesToString :: proc(runes: []rune) -> string {
    b := str.builder_make()
    for r in runes {
        str.write_rune(&b, r)
    }
    num_str := str.to_string(b)
    return num_str
}

RunesToCString :: proc(runes: []rune) -> cstring {
    b := str.builder_make()
    for r in runes {
        str.write_rune(&b, r)
    }
    num_str := str.to_cstring(&b)
    str.builder_destroy(&b)
    return num_str
}

CompareLists :: proc(list1: []$T, list2: []T) -> bool {
    if len(list1) != len(list2) do return false
    for i in 0..<len(list1) {
        if list1[i] != list2[i] do return false
    }
    return true
}

GetCameraDimensions :: proc(g_ctx: ^GameContext) -> rl.Vector2 {
    camera_width, camera_height := f32(rl.GetScreenWidth()) / g_ctx.camera.zoom, f32(rl.GetScreenHeight()) / g_ctx.camera.zoom
    return {
        camera_width,
        camera_height
    }
}