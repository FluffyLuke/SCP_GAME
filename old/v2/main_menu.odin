package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import log "core:log"

@(private="file")
MainMenuData :: struct {}
@(private="file")
main_menu_data: MainMenuData

@(private="file")
InitMainMenu :: proc(ctx: ^GameContext, level: ^Level) { 
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_ALIGNMENT_VERTICAL), i32(rl.GuiTextAlignment.TEXT_ALIGN_LEFT))
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SPACING), 5)
    level.state = .Initialized

    level.colliders = {}

    level.drawables = {
    
    }

    level.state = .Initialized
}

@(private="file")
CheckMessages :: proc(ctx: ^GameContext, level: ^Level, message: cstring) {
    switch message {
        case "Exit": {
            fmt.print("Exiting...")
            ChangeLevel(ctx, level, nil)
        }

        case: {
            log.errorf("Unknown message %s in main menu", message)
        }
    }
}

@(private="file")
MainMenuUI :: proc(ctx: ^GameContext, level: ^Level) {
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 100)

    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiControlProperty.TEXT_COLOR_NORMAL), i32(rl.ColorToInt(rl.RED)))
    rl.GuiLabel({40, 40, 800, 150}, "SCP ESCAPE")

    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 50)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_ALIGNMENT_VERTICAL), i32(rl.GuiTextAlignmentVertical.TEXT_ALIGN_MIDDLE))
    if rl.GuiButton({40, 180, 300, 70}, "Play") {
        ChangeLevel(ctx, level, .FIRST_LEVEL)
    }

    if rl.GuiButton({40, 260, 300, 70}, "Exit") {
        ChangeLevel(ctx, level, nil)
    }
}

@(private="file")
RunLogicMainMenu :: proc(ctx: ^GameContext, level: ^Level) {
    MainMenuUI(ctx, level)
}

@(private="file")
DeinitMainMenu :: proc(ctx: ^GameContext, level: ^Level) {
    delete(level.drawables)
    delete(level.colliders)

    level.state = .ShouldClose
}

GetMainMenu :: proc() -> ^Level {
    level := new(Level)

    level.state = .Uninitialized
    level.id = .MAIN_MENU

    level.init = InitMainMenu
    level.run_logic = RunLogicMainMenu
    level.deinit = DeinitMainMenu

    return level
}