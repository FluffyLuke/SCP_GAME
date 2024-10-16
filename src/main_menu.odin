package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

@(private)
InitMainMenu :: proc(ctx: ^GameContext, level: ^Level) {
    level.data = nil
    level.clickables = nil
    level.collaidables = nil

    level.state = .Initialized

    level.clickables = {}
    level.collaidables = {}

    game_name_label := NewLabel("SCP Escape", 50, rl.RED, {50, 50})

    play_button_widget := NewButton("Play", {50, 100, 200, 50})
    ButtonStylizeText(cast(^Button)play_button_widget, {30, rl.BLACK}, {40, rl.WHITE}, {50, rl.WHITE}, {40, rl.RED})

    exit_button_widget := NewButton("Exit", {50, 180, 200, 50})
    ButtonStylizeText(cast(^Button)exit_button_widget, {30, rl.BLACK}, {40, rl.WHITE}, {50, rl.WHITE}, {40, rl.RED})
    ButtonSetAction(cast(^Button)exit_button_widget, CloseLevel, level)

    level.widgets = {
        game_name_label,
        play_button_widget,
        exit_button_widget,
    }

    level.drawables = {

    }
}

@(private)
RunLogicMainMenu :: proc(ctx: ^GameContext, level: ^Level) {
    
}

@(private)
DeinitMainMenu :: proc(ctx: ^GameContext, level: ^Level) {
    for widget in level.widgets {
        free(widget)
    }
    delete(level.widgets)
    for drawable in level.drawables {
        free(drawable)
    }
    delete(level.drawables)
    level.state = .ShouldClose
}

GetMainMenu :: proc() -> ^Level {
    level := new(Level)

    level.state = .Uninitialized

    level.init = InitMainMenu
    level.run_logic = RunLogicMainMenu
    level.deinit = DeinitMainMenu

    return level
}