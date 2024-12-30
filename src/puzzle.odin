package game

import "core:math/rand"
import "core:log"
import conv "core:strconv"
import convi "core:strconv/decimal"
import str "core:strings"
import json "core:encoding/json"


import rl "vendor:raylib"

Puzzle :: struct {
    finished: bool,
    inited: bool,
    clicked: bool,

    puzzle_variant: union {
        CodePuzzle,
        LeverPuzzle,
        FuzePuzzle,
    }
}

// === CODE PUZZLE ===

LetterCount :: 4

CodePuzzle :: struct {
    code: i32,
    open: bool,
    input_index: i32,
    code_input: [4]rune,
    default_animation: AnimatedTexture
}

CodeNote :: struct {
    code: i32,
    open: bool,
    default_animation: AnimatedTexture
}

ParseRawCodePuzzle :: proc(g_ctx: ^GameContext, p: ^EntityRaw) -> EntityInstance(Puzzle) {
    pos := RetartedVectorToPoint(p.px)

    puzzle := new(Entity)
    puzzle^ = Entity {
        pos = pos,
        visible = true,
        collider = GetCollider(p),
        use_item = UseItemEmpty,
        update = UpdateCodePuzzle,
        render = RenderCodePuzzle,
        render_ui = RenderUICodePuzzle,
        variant = Puzzle {
            finished = false,
            puzzle_variant = CodePuzzle {
                code = rand.int31_max(9000) + 1000, // Random code
                input_index = 0,
                default_animation = NewAnimatedTexture(
                    g_ctx,
                    "./assets/puzzle/code_puzzle/placeholders/pad.png",
                    {32,32},
                    {16,16},
                    1,
                    1,
                )
            }
        }
    }
    p1 := GetEntityInstance(puzzle, &puzzle.variant.(Puzzle))
    p2 := &p1.puzzle_variant.(CodePuzzle)
    puzzle.current_animation = &p2.default_animation

    return GetEntityInstance(puzzle, &puzzle.variant.(Puzzle))
}

UpdateCodePuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := GetPuzzleInstance(p, &p.puzzle_variant.(CodePuzzle))
    player := g_ctx.player

    if puzzle.clicked {
        puzzle.clicked = false
        puzzle.open = true
        DisablePlayer(g_ctx)
    }

    
    if puzzle.open {
        num := rl.GetCharPressed()
        // TODO make string be allocated using temp allocator
        for num > 0 && puzzle.input_index < len(puzzle.code_input) {
            num_str := RuneToString(num)
            defer delete(num_str)
            if _, ok := conv.parse_i64(num_str); ok {
                puzzle.code_input[puzzle.input_index] = num
                puzzle.input_index += 1
            }
            num = rl.GetCharPressed()
        }

        if rl.IsKeyPressed(.BACKSPACE) && puzzle.input_index > 0{
            puzzle.code_input[puzzle.input_index-1] = 0
            puzzle.input_index -= 1
        }

        if rl.IsKeyPressed(.C) {
            puzzle.open = false
            EnablePlayer(g_ctx)
        }
        log.info(puzzle.code)
        if rl.IsKeyPressed(.ENTER) {
            num_str := RunesToString(puzzle.code_input[:])
            defer delete(num_str)
            if code, ok := conv.parse_i64(num_str); ok {
                if i32(code) == puzzle.code {
                    puzzle.open = false
                    puzzle.finished = true
                    EnablePlayer(g_ctx)
                }
            }
        } 
    }
}

RenderCodePuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    RenderTextureDefault(entity.current_animation, entity.pos)
}

RenderUICodePuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := GetPuzzleInstance(p, &p.puzzle_variant.(CodePuzzle))

    if !puzzle.open do return
    
    screen_w, screen_h := rl.GetScreenWidth(), rl.GetScreenHeight()
    pad_base_w, pad_base_h: i32 = 600, 600
    pad_base_pos := Vector2 { 
        f32((screen_w - pad_base_w) / 2),
        f32((screen_h - pad_base_h) / 2),
    }
    pad_base := Rectangle {
        pad_base_pos[0],
        pad_base_pos[1],
        f32(pad_base_w),
        f32(pad_base_h),
    }
    rl.DrawRectanglePro(pad_base, 0, 0, rl.GRAY)

    num_panel_w, num_panel_h: i32 = pad_base_w-100, 100
    num_panel_pos := pad_base_pos+50
    num_panel := Rectangle {
        num_panel_pos[0],
        num_panel_pos[1],
        f32(num_panel_w),
        f32(num_panel_h),
    }
    rl.DrawRectanglePro(num_panel, 0, 0, rl.WHITE)

    num_cstr := RunesToCString(puzzle.code_input[:])
    num_pos := num_panel_pos+25
    rl.DrawTextPro(g_ctx.font, num_cstr, num_panel_pos+15, {0,0}, 0, 80, 95, rl.RED)
}

ParseRawCodeNote :: proc(g_ctx: ^GameContext, p: ^EntityRaw) -> EntityInstance(CodeNote) {
    pos := RetartedVectorToPoint(p.px)

    note := new(Entity)
    note^ = Entity {
        pos = pos,
        visible = true,
        collider = GetCollider(p),
        use_item = UseItemEmpty,
        update = UpdateCodeNote,
        render = RenderCodeNote,
        render_ui = RenderUICodeNote,
        variant = CodeNote {
            default_animation = NewAnimatedTexture(
                g_ctx,
                "./assets/puzzle/code_puzzle/placeholders/code_note.png",
                {32,32},
                {16,16},
                1,
                1,
            )
        }
    }
    n := GetEntityInstance(note, &note.variant.(CodeNote))
    n.current_animation = &n.default_animation

    return n
}

UpdateCodeNote :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    note := GetEntityInstance(entity, &entity.variant.(CodeNote))

    // IF statement of death
    if note.code == 0 {
        l := g_ctx.current_level
        for e in l.entities {
            if p, ok := e.variant.(Puzzle); ok {
                p_i := GetEntityInstance(e, &p)
                code_p := GetPuzzleInstance(p_i, &p_i.puzzle_variant.(CodePuzzle))

                note.code = code_p.code
            }
        }
    }

    if note.open {
        DisablePlayer(g_ctx)
        
        if rl.IsKeyPressed(.C) {
            EnablePlayer(g_ctx)
            note.open = false
        }
    }
}

RenderCodeNote :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    RenderTextureDefault(entity.current_animation, entity.pos)
}

RenderUICodeNote :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    note := GetEntityInstance(entity, &entity.variant.(CodeNote))

    if !note.open do return
    
    screen_w, screen_h := rl.GetScreenWidth(), rl.GetScreenHeight()
    note_w, note_h: i32 = 600, 600
    note_pos := Vector2 { 
        f32((screen_w - note_w) / 2),
        f32((screen_h - note_h) / 2),
    }
    pad_base := Rectangle {
        note_pos[0],
        note_pos[1],
        f32(note_w),
        f32(note_h),
    }
    rl.DrawRectanglePro(pad_base, 0, 0, rl.WHITE)

    buf: [16]byte = {}
    code_str := conv.append_int(buf[:], i64(note.code), 10)
    code_cstr := str.clone_to_cstring(code_str, context.temp_allocator)

    rl.DrawTextPro(g_ctx.font, code_cstr, note_pos+15, {0,0}, 0, 100, 20, rl.RED)
}

// === LEVER PUZZLE ===

LeverPuzzle :: struct {
    levers: [3]^Lever,
    connected: bool,
    default_animation: AnimatedTexture,
    light_animation: AnimatedTexture,
}

Lever :: struct {
    pulled: bool,
    default_animation: AnimatedTexture,
}

ParseRawLeverPuzzle :: proc(g_ctx: ^GameContext, p: ^EntityRaw) -> EntityInstance(Puzzle) {
    pos := RetartedVectorToPoint(p.px)

    puzzle := new(Entity)
    puzzle^ = Entity {
        pos = pos,
        visible = true,
        collider = GetCollider(p),
        use_item = UseItemEmpty,
        update = UpdateLeverPuzzle,
        render = RenderLeverPuzzle,
        render_ui = RenderUIEmpty,
        variant = Puzzle {
            finished = false,
            puzzle_variant = LeverPuzzle {
                default_animation = NewAnimatedTexture(
                    g_ctx,
                    "./assets/puzzle/lever_puzzle/placeholders/lever_puzzle.png",
                    {150,100},
                    {150,100},
                    1,
                    1,
                ),
                light_animation = NewAnimatedTexture(
                    g_ctx,
                    "./assets/puzzle/lever_puzzle/placeholders/light.png",
                    {64,32},
                    {32,32},
                    2,
                    1,
                ),
            }
        }
    }
    p1 := GetEntityInstance(puzzle, &puzzle.variant.(Puzzle))
    p2 := &p1.puzzle_variant.(LeverPuzzle)
    puzzle.current_animation = &p2.default_animation

    return GetEntityInstance(puzzle, &puzzle.variant.(Puzzle))
}

UpdateLeverPuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := &p.puzzle_variant.(LeverPuzzle)

    if !puzzle.connected {
        l := g_ctx.current_level
        for &e, i in l.entities {
            if lever, ok := &e.variant.(Lever); ok {
                puzzle.levers[i-1] = lever
            }
        }
        puzzle.connected = true
    }

    p.finished = true
    for l in puzzle.levers {
        if !l.pulled {
            p.finished = false
            break
        }
    }
}

RenderLeverPuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := &p.puzzle_variant.(LeverPuzzle)

    RenderTextureDefault(entity.current_animation, entity.pos)
    start_pos := PointToVector(entity.pos, {150, 100})
    start_pos.x += 15 + 16 // Light size = 32, so 32 / 2 = 16
    start_pos.y += 70
    for l in puzzle.levers {
        if l == nil do continue
        puzzle.light_animation.current_frame = l.pulled ? 1 : 0
        RenderTextureDefault(&puzzle.light_animation, RetartedVectorToPoint(start_pos))
        start_pos.x += 40
    }
}

ParseRawLever :: proc(g_ctx: ^GameContext, p: ^EntityRaw) -> EntityInstance(Lever) {
    pos := RetartedVectorToPoint(p.px)

    lever := new(Entity)
    lever^ = Entity {
        pos = pos,
        visible = true,
        collider = GetCollider(p),
        use_item = UseItemEmpty,
        update = UpdateLever,
        render = RenderLever,
        render_ui = RenderUIEmpty,
        variant = Lever {
            pulled = false,
            default_animation = NewAnimatedTexture(
                g_ctx,
                "./assets/puzzle/lever_puzzle/placeholders/lever.png",
                {64,32},
                {16,16},
                2,
                1,
            ),
        }
    }

    lever_instance := GetEntityInstance(lever, &lever.variant.(Lever))
    lever.current_animation = &lever_instance.default_animation

    return lever_instance
}

UpdateLever :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    
}

RenderLever :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    lever := GetEntityInstance(entity, &entity.variant.(Lever))
    lever.default_animation.current_frame = lever.pulled ? 1 : 0
    RenderTextureDefault(entity.current_animation, entity.pos)
}

// === FUZE PUZZLE ===

FuzeItemName :: "Fuze"
FuzeItemTexturePath :: ItemParseData {
    "./assets/puzzle/fuze_puzzle/placeholders/fuze.png",
    1,
    1,
    false,
    {16,16},
    {16,16},
}

FuzePuzzleNotPowered :: struct {}
FuzePuzzleNormal :: struct {}
FuzePuzzleMovingCore :: struct {
    cell_index: int
}

FuzePuzzleState :: union {
    FuzePuzzleNotPowered,
    FuzePuzzleNormal,
    FuzePuzzleMovingCore
}

FuzePuzzle :: struct {
    default_animation: AnimatedTexture,
    fuze_pad_animation: AnimatedTexture,
    cores_animation: AnimatedTexture,
    state: FuzePuzzleState,
    open: bool,
    
    // 0, 1, 2 -> these numbers are used to determine what cell is in place.
        // n-1 is used, because they are also used when indexing the right texture for them
    cores: [3]int
}

CoreCellWidth :: 24 * 4// 4 pixels

ParseRawFuzePuzzle :: proc(g_ctx: ^GameContext, p: ^EntityRaw) -> EntityInstance(Puzzle) {
    pos := RetartedVectorToPoint(p.px)

    puzzle := new(Entity)
    puzzle^ = Entity {
        pos = pos,
        visible = true,
        collider = GetCollider(p),
        use_item = FuzeItemAction,
        update = UpdateFuzePuzzle,
        render = RenderFuzePuzzle,
        render_ui = RenderUIFuzePuzzle,
        variant = Puzzle {
            finished = false,
            puzzle_variant = FuzePuzzle {
                state = FuzePuzzleNotPowered {},
                default_animation = NewAnimatedTexture(
                    g_ctx,
                    "./assets/puzzle/fuze_puzzle/placeholders/fuze_puzzle.png",
                    {64,32},
                    {16,16},
                    2,
                    1,
                ),
                fuze_pad_animation = NewAnimatedTexture(
                    g_ctx,
                    "./assets/puzzle/fuze_puzzle/placeholders/fuze_pad.png",
                    {128,128},
                    {128,128} * 4,
                    1,
                    1,
                ),
                cores_animation = NewAnimatedTexture(
                    g_ctx,
                    "./assets/puzzle/fuze_puzzle/placeholders/cores.png",
                    {42,28},
                    {14,28} * 4,
                    3,
                    1,
                ),
            }
        }
    }
    p1 := GetEntityInstance(puzzle, &puzzle.variant.(Puzzle))
    p2 := &p1.puzzle_variant.(FuzePuzzle)
    puzzle.current_animation = &p2.default_animation

    for &core, i in p2.cores {
        core = i
    }

    return GetEntityInstance(puzzle, &puzzle.variant.(Puzzle))
}

FuzeItemAction :: proc(g_ctx: ^GameContext, entity: ^Entity, item: ^Item) -> bool {
    if str.compare(item.id, FuzeItemName) != 0 {
        return false
    }

    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := &p.puzzle_variant.(FuzePuzzle)

    if _, not_powered := puzzle.state.(FuzePuzzleNotPowered); !not_powered do return false

    puzzle.state = FuzePuzzleNormal {}
    item.destroyed = true

    return true
}

UpdateFuzePuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := &p.puzzle_variant.(FuzePuzzle)

    if _, ok := puzzle.state.(FuzePuzzleNotPowered); ok {
        return
    }

    if _, ok := puzzle.state.(FuzePuzzleNotPowered); !ok && p.clicked {
        p.clicked = false
        puzzle.open = true
        DisablePlayer(g_ctx)
    }

    if puzzle.open {
        DisablePlayer(g_ctx)
        
        if rl.IsKeyPressed(.C) {
            EnablePlayer(g_ctx)
            puzzle.open = false
        }

        Check :: rl.IsKeyPressed
        #partial switch &s in puzzle.state {
            case FuzePuzzleNormal: {
                good_answer: [3]int = {2,1,0}
                if CompareLists(puzzle.cores[:], good_answer[:]) {
                    EnablePlayer(g_ctx)
                    puzzle.open = false
                    p.finished = true
                }

                num: int
                if Check(.ONE) do num = 0
                else if Check(.TWO) do num = 1
                else if Check(.THREE) do num = 2
                else do return

                puzzle.state = FuzePuzzleMovingCore { num }
            }
            case FuzePuzzleMovingCore: {
                cell_temp: int

                if Check(.A) && s.cell_index != 0 {
                    cell_temp = puzzle.cores[s.cell_index-1]
                    puzzle.cores[s.cell_index-1] = puzzle.cores[s.cell_index]
                    puzzle.cores[s.cell_index] = cell_temp
                    puzzle.state = FuzePuzzleNormal {}
                } else if Check(.D) && s.cell_index != len(puzzle.cores)-1 {
                    cell_temp = puzzle.cores[s.cell_index+1]
                    puzzle.cores[s.cell_index+1] = puzzle.cores[s.cell_index]
                    puzzle.cores[s.cell_index] = cell_temp
                    puzzle.state = FuzePuzzleNormal {}
                } else if rl.GetCharPressed() != 0 {
                    puzzle.state = FuzePuzzleNormal {}
                }
            }
        }
    }
}

RenderFuzePuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := &p.puzzle_variant.(FuzePuzzle)

    _, no_fuze := puzzle.state.(FuzePuzzleNotPowered)

    puzzle.default_animation.current_frame = no_fuze ? 0 : 1
    RenderTextureDefault(entity.current_animation, entity.pos)
}

RenderUIFuzePuzzle :: proc(g_ctx: ^GameContext, entity: ^Entity) {
    p := GetEntityInstance(entity, &entity.variant.(Puzzle))
    puzzle := &p.puzzle_variant.(FuzePuzzle)

    if !puzzle.open do return

    screen_w, screen_h := rl.GetScreenWidth(), rl.GetScreenHeight()
    pad_base_w, pad_base_h: i32 = 512, 512
    pad_base_pos := Point2 { 
        f32((screen_w) / 2),
        f32((screen_h) / 2),
    }

    RenderTextureDefault(&puzzle.fuze_pad_animation, pad_base_pos)

    pad_base_pos_vec := Vector2 { 
        f32((screen_w - pad_base_w) / 2),
        f32((screen_h - pad_base_h) / 2),
    }

    for core, i in puzzle.cores {
        anim := puzzle.cores_animation
        anim.current_frame = f32(core)

        pos_x := CoreCellWidth/2 + 16*(i+1) + CoreCellWidth*(i)
        pos_y := (512 - 16) - anim.render_dimensions[1]/2-8
        pos := Point2 {f32(pos_x), f32(pos_y)}
        pos += RetartedVectorToPoint(pad_base_pos_vec)

        RenderTextureDefault(&anim, pos)

        if s, ok := puzzle.state.(FuzePuzzleMovingCore); ok && s.cell_index == i{
            anim.render_dimensions *= 1.2
            RenderTextureDefault(&anim, pos)
        } else {
            RenderTextureDefault(&anim, pos)
        }
    }
}

// https://www.youtube.com/watch?v=UidiNCZVPKw
PuzzleInstance :: struct($T: typeid) {
    using puzzle: EntityInstance(Puzzle),
    using p_var: ^T,
}

GetPuzzleInstance :: proc(e: EntityInstance(Puzzle), p_var: ^$T) -> PuzzleInstance(T) {
    return PuzzleInstance(T) { e, p_var }
}
