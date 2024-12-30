package game

import "core:encoding/json"
import "core:os"
import "core:log"
import "core:mem"

EntityRaw :: struct {
    __identifier: string,
    px: Vector2,
    __pivot: Vector2,
    __tile: struct {
        x: i32,
        y: i32,
        w: i32, // NOT ACTUAL WIDTH
        h: i32 // NOT ACTUAL HEIGHT
    },
    width: i32,
    height: i32,

    fieldInstances: json.Array
}

DropArea :: struct {
    collider: Rectangle,
    // entity: ^Entity,
    action: proc(g_ctx: ^GameContext, entity: ^Entity, item: ^Item) -> bool
}

Entity :: struct {
    using pos: Point2,
    visible: bool,
    collider: Rectangle,

    current_animation: ^AnimatedTexture,

    use_item: proc(g_ctx: ^GameContext, entity: ^Entity, item: ^Item) -> bool,
    update: proc(g_ctx: ^GameContext, entity: ^Entity),
    render: proc(g_ctx: ^GameContext, entity: ^Entity),
    render_ui: proc(g_ctx: ^GameContext, entity: ^Entity),

    variant: union {
        // Game start => parsed directly into the level as vector
        Player,
        Door,
        Puzzle,
        CodeNote,
        Lever,
        Item,
    }
}


// Use when no action is assigned
UseItemEmpty :: proc(g_ctx: ^GameContext, entity: ^Entity, item: ^Item) -> bool {
    return false
}
UpdateEmpty :: proc(g_ctx: ^GameContext, entity: ^Entity) {}
RenderEntityDefault :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    RenderTextureDefault(entity.current_animation, entity.pos)
}
RenderEmpty :: proc(g_ctx: ^GameContext, entity: ^Entity) {}
RenderUIEmpty :: proc(g_ctx: ^GameContext, entity: ^Entity) {}

// https://www.youtube.com/watch?v=UidiNCZVPKw
EntityInstance :: struct($T: typeid) {
    using entity: ^Entity,
    using var: ^T,
}

GetEntityInstance :: proc(e: ^Entity, var: ^$T) -> EntityInstance(T) {
    return EntityInstance(T) { e, var }
}