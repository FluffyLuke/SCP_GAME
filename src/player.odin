package game

import rl "vendor:raylib"
import "core:math"
import "core:log"

DefaultPlayerWalkingSpeed :: 200.0

PlayerDisabledState :: struct {}
PlayerStandingState :: struct {}
PlayerWalkingState :: struct { flip: bool, speed: f32 }

PlayerState :: union {
    PlayerDisabledState,
    PlayerStandingState,
    PlayerWalkingState,
}

Player :: struct {
    state: PlayerState,

    range: f32,

    selected_entity: i32,
    entities_in_range: [dynamic]^Entity,
    
    selected_inventory_item: i32,
    inventory: [9]struct {
        occupied: bool,
        selected: bool,
        using item: EntityInstance(Item),
    },

    standing: AnimatedTexture,
    walking: AnimatedTexture,
}

PreparePlayer :: proc(g_ctx: ^GameContext) {
    p := new(Entity, context.allocator)
    p^ = Entity {
        pos = {0, 0},
        visible = true,
        collider = {0, 0, 16, 32},
        variant = Player {
            entities_in_range = {},
            range = 30,
            standing = NewAnimatedTexture(
                g_ctx, 
                "./assets/player/placeholders/player_standing.png",
                {16,32},
                {16,32},
                1,
                1,
            ),
            walking = NewAnimatedTexture(
                g_ctx, 
                "./assets/player/placeholders/player_standing.png",
                {16,32},
                {16,32},
                1,
                1,
            ),
        }
    }

    player := GetEntityInstance(p, &p.variant.(Player))

    player.current_animation = &player.standing
    g_ctx.player = player
}

EnablePlayer :: proc(g_ctx: ^GameContext) {
    player := g_ctx.player
    player.state = PlayerStandingState {}
}

DisablePlayer :: proc(g_ctx: ^GameContext) {
    player := g_ctx.player
    player.state = PlayerDisabledState {}
}

SpawnPlayer :: proc(g_ctx: ^GameContext, new_pos: Point2) {
    g_ctx.player.visible = true
    g_ctx.player.state = PlayerStandingState {}
    TeleportPlayer(g_ctx, g_ctx.player, new_pos)
}

DespawnPlayer :: proc(g_ctx: ^GameContext) {
    g_ctx.player.visible = false
    g_ctx.player.state = PlayerDisabledState {}
}

RunPlayerLogic :: proc(g_ctx: ^GameContext, player: EntityInstance(Player)) {
    delta := rl.GetFrameTime()
    clear(&player.entities_in_range)

    for e in g_ctx.current_level.entities {
        if _, ok := e.variant.(Player); !ok {
            if Point2Distance(e.pos, player.pos) < player.range {
                append(&player.entities_in_range, e)
            }
        }
    }

    if _, ok := player.state.(PlayerDisabledState); !ok {
        ParsePlayerInput(g_ctx, player)
    }


    switch s in player.state {
        case PlayerDisabledState: {}
        case PlayerStandingState: {
            //ChangePlayerAnimation(player, &player.standing)
        }
        case PlayerWalkingState: {
            player.current_animation.flip = s.flip
            ChangePlayerAnimation(player, &player.walking)
            move := Point2 {1, 0} * s.speed * delta
            if s.flip {
                move *= -1
            }
            MovePlayer(g_ctx, player, move)
        }
    }
}

ParsePlayerInput :: proc(g_ctx: ^GameContext, player: EntityInstance(Player)) {
    // Move
    {
        if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
            player.state = PlayerWalkingState {
                speed = DefaultPlayerWalkingSpeed,
                flip = true,
            }
        } else if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
            player.state = PlayerWalkingState {
                speed = DefaultPlayerWalkingSpeed,
                flip = false,
            }
        } else {
            player.state = PlayerStandingState {}
        }
    }

    // Manipulate selected entity
    {
        if rl.IsKeyDown(.Q) {
            player.selected_entity -= 1;
        } else if rl.IsKeyDown(.E) {
            player.selected_entity += 1;
        }
    
        if e_len := i32(len(player.entities_in_range))-1; player.selected_entity > e_len {
            player.selected_entity = e_len
        }
        if player.selected_entity < 0 {
            player.selected_entity = 0
        }
    }

    // Manipulate items
    proc(g_ctx: ^GameContext, player: EntityInstance(Player)) {
        Check :: rl.IsKeyPressed
        num: int
        if Check(.ONE) do num = 0
        else if Check(.TWO) do num = 1
        else if Check(.THREE) do num = 2
        else if Check(.FOUR) do num = 3
        else if Check(.FIVE) do num = 4
        else if Check(.SIX) do num = 5
        else if Check(.SEVEN) do num = 6
        else if Check(.EIGHT) do num = 7
        else if Check(.NINE) do num = 8
        else do return

        item_num := -1
        for &item, i in player.inventory {
            if !item.occupied do continue
            item_num += 1
            if item_num != num {
                item.selected = false // Deselect potentially selected items
                continue
            }
            item.selected = !item.selected // Deselect if clicked twice
        }
    }(g_ctx, player)

    // Use selected item
    proc(g_ctx: ^GameContext, player: EntityInstance(Player)) {\
        if !rl.IsKeyPressed(.Z) do return
        if len(player.entities_in_range) < 1 do return
        selected_item: EntityInstance(Item)
        index: int
        flag := false
        for &item, i in player.inventory {
            if item.selected {
                selected_item = &item
                flag = true
                index = i
                break
            }
        }
        if !flag do return
        selected_entity := player.entities_in_range[player.selected_entity]
        
        res := selected_entity.use_item(g_ctx, selected_entity, selected_item)
        // In the future this can be usefull to show player that item cannot be used here
        if !res {
            log.info("Cannot use this item here")
            return
        }

        if selected_item.destroyed {
            player.inventory[index] = {
                false,
                false,
                {}
            }
        }
    }(g_ctx, player)

    // Use selected entity
    proc(g_ctx: ^GameContext, player: EntityInstance(Player)) {
        if !rl.IsKeyPressed(.F) do return
        if len(player.entities_in_range) < 1 do return
        selected_entity := player.entities_in_range[player.selected_entity]
        #partial switch &s in selected_entity.variant {
            case Door: {
                GoThruDoor(g_ctx, GetEntityInstance(selected_entity, &s))
            }
            case Puzzle: {
                s.clicked = true
            }
            case CodeNote: {
                s.open = true
            }
            case Lever: {
                // log.info("Pulled lever")
                s.pulled = !s.pulled
            }
            case Item: {
                for slot, i in player.inventory {
                    if slot.occupied do continue
                    selected_entity.collider = ItemEmptyCollider
                    selected_entity.pos = ItemPositionCollected
                    selected_entity.visible = false
                    player.inventory[i] = {
                        true,
                        false,
                        GetEntityInstance(selected_entity, &s),
                    }
                    log.info("Picked up item")
                    return
                }
                log.info("Cannot pick up item")
            }
        }
    }(g_ctx, player)
}


MovePlayer :: proc(g_ctx: ^GameContext, player: EntityInstance(Player), add_pos: Point2) {
    player.pos += add_pos
    vec := PointToVector(player.pos, { player.collider.width, player.collider.height } )
    player.collider = { vec.x, vec.y, player.collider.width, player.collider.height }


    for w in g_ctx.current_level.walls {
        if !rl.CheckCollisionRecs(player.collider, w.collider) { continue }
        // Is on the right side of the wall
        if player.x > w.collider.x {
            player.pos.x = w.collider.x + w.collider.width + player.collider.width/2

        // Is on the left side of the wall
        } else if player.x < w.collider.x {
            player.pos.x = w.collider.x - player.collider.width/2
        }
        // Move back the collider
        vec = PointToVector(player.pos, { player.collider.width, player.collider.height } )
        player.collider = { vec.x, vec.y, player.collider.width, player.collider.height }
    }
}

TeleportPlayer :: proc(g_ctx: ^GameContext, player: EntityInstance(Player), pos: Point2) {
    player.pos = pos
    vec := PointToVector(player.pos, { player.collider.width, player.collider.height } )
    player.collider = { vec.x, vec.y, player.collider.width, player.collider.height }
}


ChangePlayerAnimation :: proc(player: EntityInstance(Player), anim: ^AnimatedTexture) {
    // If this animation is playing, return
    if(anim == player.current_animation) {
        return
    }

    anim.current_frame = 0
    player.current_animation = anim
}

RenderPlayer :: proc(g_ctx: ^GameContext) {
    player := g_ctx.player
    anim := player.current_animation
    UpdateAnimatedTexture(anim)
    RenderTextureDefault(anim, player.pos)
    
    // === Render entities in reach ===

    line_len := f32(len(player.entities_in_range))

    if line_len == 0 {
        return
    }

    // Draw line holding entities
    line_height := f32(20)
    line_width := line_len*20
    line_pos := PointToVector(player.pos+{0, -30}, {line_width, line_height})
    line_rec := Rectangle { line_pos.x, line_pos.y, line_width, line_height }
    rl.DrawRectanglePro(line_rec, 0, 0, rl.WHITE)

    item_pos: Point2 = VectorToPoint(line_pos - {line_width/2, 0} + {10, 0}, {line_width, line_height})

    for e, i in player.entities_in_range {
        if i32(i) == player.selected_entity {
            selected_square_pos: Rectangle = {item_pos.x-10, item_pos.y-10, 20, 20}
            rl.DrawRectanglePro(selected_square_pos, 0, 0, rl.RED)
        }
        RenderTextureCustomDim(e.current_animation, item_pos, {16, 16})
        item_pos += {20, 0}
    }
}

InventoryBarColor :: rl.Color{55, 67, 87, 200}

RenderUIPlayer :: proc(g_ctx: ^GameContext) {
    player := g_ctx.player
    
    // Render Inventory
    {
        if _, ok := g_ctx.player.state.(PlayerDisabledState); ok {
            return
        }

        flag := false
        for i in player.inventory {
            if i.occupied {
                flag = true
                break
            }
        }

        if !flag do return

        inventory_bar := Rectangle {
            0,0,
            f32(rl.GetScreenWidth()),
            100,
        }

        rl.DrawRectanglePro(inventory_bar, 0, 0, InventoryBarColor)

        offset: f32 = 50.0
        for item, i in player.inventory {
            if !item.occupied do continue
            pos := Point2 {offset, 50}
            size := item.selected ? Vector2 { 75, 75 } : Vector2 {50, 50}
            if item.selected {
                rec_pos := PointToVector(pos,size+5)
                rec_size := size+5
                rl.DrawRectanglePro({rec_pos.x, rec_pos.y, rec_size.x, rec_size.y}, {0,0}, 0, rl.RED)
            }
            RenderTextureCustomDim(&item.default_animation, pos, size)
            offset += 100
        }
    }
}