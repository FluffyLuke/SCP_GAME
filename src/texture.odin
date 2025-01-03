package game

import "core:fmt"
import "core:mem"
import "core:math"
import "core:log"

import rl "vendor:raylib"

Tileset :: rl.Texture2D

AnimatedTexture :: struct  {
    flip: bool,
    repeat: bool,
    texture: rl.Texture2D,
    source_dimensions: Vector2,
    source_offset: Vector2,
    render_dimensions: Vector2,
    frames: i32, // number of frames
    current_frame: f32, // cutting of decimal point will give the frame index
    speed: f32, // 1 => one frame per second
}

NewAnimatedTexture :: proc(
    g_ctx: ^GameContext, 
    path: cstring,
    source_dimensions: Vector2,
    render_dimensions: Vector2,
    source_offset: Vector2 = {0, 0},
    frames: i32 = 1,
    speed: f32 = 1,
    repeat: bool = true,
) -> AnimatedTexture {
    texture := rl.LoadTexture(path)
    if texture.id <= 0 {
        log.errorf("Cannot find texture!")
    }

    return AnimatedTexture {
        flip = false,
        texture = texture,
        source_dimensions = source_dimensions,
        source_offset = source_offset,
        render_dimensions = render_dimensions,
        frames = frames,
        current_frame = 0,
        speed = speed,
        repeat = repeat,
    }
}

UpdateAnimatedTexture :: proc(anim: ^AnimatedTexture) {
    delta := rl.GetFrameTime()

    anim.current_frame = anim.current_frame + anim.speed * delta
    
    if anim.current_frame >= f32(anim.frames) && !anim.repeat {
        anim.current_frame = f32(anim.frames)
    } else if anim.current_frame >= f32(anim.frames) {
        anim.current_frame = 0
    }
}

RenderTextureDefault :: proc(anim: ^AnimatedTexture, pos: Point2) {
    origin := anim.render_dimensions / 2
    frame_size := anim.source_dimensions[0]/f32(anim.frames) 

    // Source
    src := rl.Rectangle {
        x = math.floor(anim.current_frame)*frame_size + anim.source_offset.x,
        y = anim.source_offset.y,
        width = frame_size,
        height = anim.source_dimensions[1]
    }

    // Use texture width and height, but player position
    dest := rl.Rectangle {
        pos.x,
        pos.y,
        anim.render_dimensions[0],
        anim.render_dimensions[1]
    }

    if anim.flip {
        src.width = -src.width
    }

    rl.DrawTexturePro(anim.texture, src, dest, origin, 0, rl.WHITE)
}

RenderTextureCustomDim :: proc(anim: ^AnimatedTexture, pos: Point2, render_dimensions: Vector2) {
    origin := render_dimensions / 2
    frame_size := anim.source_dimensions[0]/f32(anim.frames) 

    // Source
    src := rl.Rectangle {
        x = math.floor(anim.current_frame)*frame_size,
        y = 0,
        width = frame_size,
        height = anim.source_dimensions[1]
    }

    // Use texture width and height, but player position
    dest := rl.Rectangle {
        pos.x,
        pos.y,
        render_dimensions[0],
        render_dimensions[1]
    }

    if anim.flip {
        src.width = -src.width
    }

    rl.DrawTexturePro(anim.texture, src, dest, origin, 0, rl.WHITE)
}

RenderTextureScaled :: proc(anim: ^AnimatedTexture, pos: Point2, scale: f32) {
    origin := (anim.render_dimensions / 2) * scale
    frame_size := anim.source_dimensions[0]/f32(anim.frames) 

    // Source
    src := rl.Rectangle {
        x = math.floor(anim.current_frame)*frame_size,
        y = 0,
        width = frame_size,
        height = anim.source_dimensions[1]
    }

    // Use texture width and height, but player position
    dest := rl.Rectangle {
        pos.x,
        pos.y,
        anim.render_dimensions[0] * scale,
        anim.render_dimensions[1] * scale,
    }

    if anim.flip {
        src.width = -src.width
    }

    rl.DrawTexturePro(anim.texture, src, dest, origin, 0, rl.WHITE)
}