package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:math"

Transition :: struct {
    opacity: f32,
}

GameContext :: struct {
    debug: bool,
    player: Entity,

    grid_size: i64,

    tilesets: map[string]rl.Texture2D,

    levels_file: []byte,
    levels: [dynamic]^Level,
    current_level: ^Level,
    next_level: LevelID,
    next_exit_point_id: i32,

    transition_layer: Transition,

    camera: rl.Camera2D,
    // camera_speed: f32,
    // camera_follow_point: ^Vector2,
}

// Lerp :: proc(a: f32, b: f32, t: f32) -> f32 {
//     return f32(a + t * (b - a))

// }

// EaseOut :: proc(t: f32) -> f32{
//     new_t := math.min(t, 1.0);
//     return new_t * new_t * (3.0 - 2.0 * new_t);
// }

// UpdateCamera :: proc() {
//     // TODO find out why I need to set this every frame
//     g_ctx.camera.offset = {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)}

//     follow_point := g_ctx.camera_follow_point != nil ? g_ctx.camera_follow_point^ : g_ctx.camera.target

//     if g_ctx.camera_speed == 0 {
//         g_ctx.camera.target = g_ctx.camera_follow_point^
//     }

//     delta := rl.GetFrameTime()
//     dist := Distance(g_ctx.camera.target, g_ctx.camera_follow_point^)
//     t := math.min(dist / f32(100)+4, f32(4))

//     g_ctx.camera.target.x = Lerp(g_ctx.camera.target.x, follow_point.x, g_ctx.camera_speed*t*delta)
//     g_ctx.camera.target.y = Lerp(g_ctx.camera.target.y, follow_point.y, g_ctx.camera_speed*t*delta)
// }
