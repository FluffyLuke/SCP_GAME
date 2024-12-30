package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

@(private="file")
InitMainMenu :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    level.state = .Visited
    g_ctx.camera = rl.Camera2D {
        offset = 0,
        target = {0, 0},
        zoom = 1,
        rotation = 0
    }
}

@(private="file")
MainMenuLogic :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 100)

    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiControlProperty.TEXT_COLOR_NORMAL), i32(rl.ColorToInt(rl.RED)))
    rl.GuiLabel({40, 40, 800, 150}, "SCP ESCAPE")

    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 50)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_ALIGNMENT_VERTICAL), i32(rl.GuiTextAlignmentVertical.TEXT_ALIGN_MIDDLE))
    if rl.GuiButton({40, 180, 300, 70}, "Play") {
        ChangeLevel(g_ctx, .FIRST_LEVEL, -1)
    }

    if rl.GuiButton({40, 260, 300, 70}, "Exit") {
        ChangeLevel(g_ctx, .EXIT, -1)
    }

}

@(private="file")
RunMainMenu :: proc(g_ctx: ^GameContext) {
    level := g_ctx.current_level
    switch level.state {
        case .NeverVisited: {
            InitMainMenu(g_ctx)
            MainMenuLogic(g_ctx)
        }
        case .JustVisted: {
            level.state = .Visited
            MainMenuLogic(g_ctx)
        }
        case .Visited: {
            MainMenuLogic(g_ctx)
        }
    }
}

GetMainMenu :: proc() -> ^Level {
    level := new(Level)
    level^ = Level {
        id = .MAIN_MENU,
        name = "MainMenu",
        state = .NeverVisited,
        tiles = {},
        run_level = RunMainMenu,
    }
    return level
}