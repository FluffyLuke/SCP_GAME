package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import log "core:log"

@(private)
MainMenuData :: struct {}
@(private)
main_menu_data: MainMenuData

@(private)
InitMainMenu :: proc(ctx: ^GameContext, level: ^Level) {
    level.state = .Initialized
    level.colliders = {}

    game_name_label := NewLabel("SCP Escape", 50, rl.RED, {50, 50})

    play_button_widget, pb_area := NewButton("Play", {50, 100, 200, 50}, "Play")
    ButtonStylizeText(cast(^Button)play_button_widget, {30, rl.BLACK}, {40, rl.WHITE}, {50, rl.WHITE}, {40, rl.RED})

    exit_button_widget, eb_area := NewButton("Exit", {50, 180, 200, 50}, "Exit")
    ButtonStylizeText(cast(^Button)exit_button_widget, {30, rl.BLACK}, {40, rl.WHITE}, {50, rl.WHITE}, {40, rl.RED})
    eb_area.state = ClickAreaEnabled { clicked = false }

    level.click_areas = {
        pb_area,
        eb_area,
    }

    level.widgets = {
        game_name_label,
        play_button_widget,
        exit_button_widget,
    }

    level.drawables = {
    
    }

    level.state = .Initialized
}

@(private)
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

@(private)
RunLogicMainMenu :: proc(ctx: ^GameContext, level: ^Level) {
    for click_area in level.click_areas {
        switch &cs in click_area.state {
            case ClickAreaDisabled: {}
            case ClickAreaEnabled: {
                CheckClickArea(click_area.rec, &cs)
                if cs.clicked {
                    CheckMessages(ctx, level, click_area.message)
                }
            }
        }
    }
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

    for area in level.click_areas {
        free(area)
    }
    delete(level.click_areas)

    for collider in level.colliders {
        free(collider)
    }
    delete(level.colliders)

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