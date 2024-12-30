package game

import rl "vendor:raylib"
import "core:math"

StaticCollider :: struct {
    collider: Collider
}

StaticObject :: struct {
    collider: Collider,
    animation: AnimatedTexture,
}

RenderStaticObject :: proc(object: EntityInstance(StaticObject)) {
    anim := object.animation
    UpdateAnimatedTexture(&anim)
    
    // origin := Vector2 {
    //     anim.texture_dest.width / 2,
    //     anim.texture_dest.height / 2,
    // }

    frame_size := anim.texture_source[0]/f32(anim.frames) 
    // Source
    src := rl.Rectangle {
        x = math.floor(anim.current_frame)*frame_size,
        y = 0,
        width = frame_size,
        height = anim.texture_source[0]
    }

    dest := rl.Rectangle {
        object.pos.x,
        object.pos.y,
        anim.texture_dimensions[0],
        anim.texture_dimensions[0]
    }

    if anim.flip {
        src.width = -src.width
    }

    rl.DrawTexturePro(anim.texture_image, src, dest, 0, 0, rl.WHITE)
}