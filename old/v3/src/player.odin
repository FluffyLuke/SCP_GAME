package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:math"

Standing :: struct {}
Walking :: struct {
    flip: bool
}

PlayerState :: union {
    Standing,
    Walking
}

Player :: struct {
    current_animation: ^AnimatedTexture,

    reach: f32,

    collider: Collider,
    enabled: bool,
    state: PlayerState,

    anim_walk: AnimatedTexture,
    anim_stand: AnimatedTexture,
}

CreatePlayer :: proc(g_ctx: ^GameContext) {
    fmt.printfln("Getting player's texture")
    g_ctx.player = Entity {
        layer = .Player,
        visible = true,

        variant = Player {
            reach = 50,
            anim_stand = NewAnimatedTexture(
                g_ctx,
                "./assets/demo/demo_player_stand.png",
                {32, 16},
                {16, 16},
                2,
                2
            ),
            anim_walk = NewAnimatedTexture(
                g_ctx,
                "./assets/demo/demo_player_walk.png",
                {64, 16},
                {16, 16},
                4,
                3
            )
        }
    }
    
    player := GetPlayer(g_ctx)
    player.current_animation = &player.anim_stand
}

@(private="file")
CheckItems :: proc(level: ^Level, player: EntityInstance(Player)) -> (doors: [dynamic]EntityInstance(Door))
{
    for &e in level.entities {
        #partial switch &v in e.variant {
            case Door: {
                if rl.Vector2Distance(e.pos, player.pos) < player.reach {
                    e.in_players_reach = true;
                    append(&doors, GetEntityInstance(&e, &v))
                } else {
                    e.in_players_reach = false;
                }
            }
        }
    }
    return
}

RunPlayerLogic :: proc(g_ctx: ^GameContext, player: EntityInstance(Player)) {
    delta := rl.GetFrameTime()

    doors := CheckItems(g_ctx.current_level, player)

    defer {
        delete(doors)
    }

    if(player.enabled) {
        if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
            player.state = Walking {
                flip = true
            }
        } else if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
            player.state = Walking {
                flip = false
            }
        } else {
            player.state = Standing {}
        }
    }

    if rl.IsKeyDown(.E) {
        ChangeLevel(g_ctx, LevelID(doors[0].level_id), doors[0].exit_point_id)
    }

    switch s in player.state {
        case Standing: {
            ChangePlayerAnimation(player, &player.anim_stand)
        }
        case Walking: {
            player.current_animation.flip = s.flip
            if(s.flip) {
                if CheckPlayerCollisions(g_ctx, player) != .LEFT {
                    pos := Vector2 {0,0}
                    MovePlayer(player, {-60*delta, 0})
                    ChangePlayerAnimation(player, &player.anim_walk)
                }
            } else {
                if CheckPlayerCollisions(g_ctx, player) != .RIGHT {
                    pos := Vector2 {0,0}
                    MovePlayer(player, {60*delta, 0})
                    ChangePlayerAnimation(player, &player.anim_walk)
                }
            }
        }
    }

    player.collider = GetCenteredRec(player.pos, 16, 16)
}

GetPlayer :: proc(g_ctx: ^GameContext) -> EntityInstance(Player) {
    return GetEntityInstance(&g_ctx.player, &g_ctx.player.variant.(Player))
}

MovePlayer :: proc(player: EntityInstance(Player), add_pos: Vector2) {
    player.pos += add_pos
}

ChangePlayerAnimation :: proc(player: EntityInstance(Player), anim: ^AnimatedTexture) {
    // If this animation is playing, return
    if(anim == player.current_animation) {
        return
    }

    anim.current_frame = 0
    player.current_animation = anim
}

CollisionSide :: enum {
    NONE,
    LEFT,
    RIGHT
}


CheckPlayerCollisions :: proc(g_ctx: ^GameContext, player: EntityInstance(Player)) -> CollisionSide {
    // TODO move walls into other list
    level := g_ctx.current_level
    for entity in level.entities {
        #partial switch v in entity.variant {
            case StaticCollider: {
                side: CollisionSide = .NONE
                if !rl.CheckCollisionRecs(v.collider, player.collider)  {
                    // Nothing
                } else if(GetCenterRec(player.collider).x > GetCenterRec(v.collider).x) {
                    return .LEFT
                } else {
                    return .RIGHT
                }
            }
        }
    }
    return .NONE
}

RenderPlayer :: proc(player: EntityInstance(Player)) {
    anim := player.current_animation

    UpdateAnimatedTexture(anim)

    origin := anim.texture_dimensions / 2

    frame_size := anim.texture_source[0]/f32(anim.frames) 

    // Source
    src := rl.Rectangle {
        x = math.floor(anim.current_frame)*frame_size,
        y = 0,
        width = frame_size,
        height = anim.texture_source[1]
    }

    // Use texture width and height, but player position
    dest := rl.Rectangle {
        player.pos.x,
        player.pos.y,
        anim.texture_dimensions[0],
        anim.texture_dimensions[1]
    }

    if anim.flip {
        src.width = -src.width
    }

    rl.DrawTexturePro(anim.texture_image, src, dest, origin, 0, rl.WHITE)
}