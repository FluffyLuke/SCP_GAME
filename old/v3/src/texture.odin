package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:os"
import str "core:strings"

AnimatedTexture :: struct {
    flip: bool,
    using texture: StaticTexture,

    frames: i32,
    current_frame: f32, // cutting of decimal point will give the frame index
    speed: f32,
}

NewAnimatedTexture :: proc(
    g_ctx: ^GameContext,
    path: string,
    src: rl.Vector2,
    dim: rl.Vector2,
    frames: i32,
    speed: f32,
) -> AnimatedTexture {
    texture := NewStaticTexture(g_ctx, path, src, dim)

    animation := AnimatedTexture {
        flip = false,
        texture = texture,
        
        speed = speed,
        current_frame = 0,
        frames = frames
    }

    return animation
}

UpdateAnimatedTexture :: proc(anim: ^AnimatedTexture) {
    delta := rl.GetFrameTime()

    anim.current_frame = anim.current_frame + anim.speed * 1 * delta
    if anim.current_frame >= f32(anim.frames) {
        anim.current_frame = 0
    }
}

StaticTexture :: struct {
    texture_image: rl.Texture2D, // Loaded texture
    texture_source: rl.Vector2, // Part of texture
    texture_dimensions: rl.Vector2, // Size of this part
}

NewStaticTexture :: proc(
    g_ctx: ^GameContext,
    path: string,
    source: rl.Vector2,
    dimensions: rl.Vector2,
) -> StaticTexture {

    cpath := str.clone_to_cstring(path)

    defer {
        delete(cpath)
    }

    // TODO load texture only once
    texture := rl.LoadTexture(cpath)

    return  StaticTexture {
        texture_image = texture,
        texture_source = source,
        texture_dimensions = dimensions,
    }
}

StaticTextureFromExistingTexture :: proc(
    texture: rl.Texture2D,
    source: rl.Vector2,
    dimensions: rl.Vector2,
) -> StaticTexture {
    return StaticTexture {
        texture_image = texture,
        texture_source = source,
        texture_dimensions = dimensions,
    }

}