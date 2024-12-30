package game

import rl "vendor:raylib"
import "core:math"

// This function assumes that pivot is located in top left corner
CenterVector2 :: proc(vec: Vector2, width, height: f32) -> rl.Vector2 {
    return rl.Vector2 {
        vec.x - (width/2),
        vec.y - (height/2),
    }
}

GetCameraDimensions :: proc(g_ctx: ^GameContext) -> rl.Vector2 {
    camera_width, camera_height := f32(rl.GetScreenWidth()) / g_ctx.camera.zoom, f32(rl.GetScreenHeight()) / g_ctx.camera.zoom
    return {
        camera_width,
        camera_height
    }
}

GetCameraPosition :: proc(g_ctx: ^GameContext) -> rl.Vector2 {
    return g_ctx.camera.target
}