package game

import "core:math"
import str "core:strings"
import "core:log"

import rl "vendor:raylib"


DialogHandle :: struct {
    finished: bool
}

DestroyDialogHandle :: proc(d: ^DialogHandle) {
    free(d)
}

DialogNormal :: struct {
    // Time to wait after dialog is over
    // before erasing the text
    time_to_wait: f32
}

DialogEvent :: struct {
    // This handle is used to check whether dialog has ended
    // Handle is used, because reference to dialog can become invalid
    handle: ^DialogHandle,
}

Dialog :: struct {
    entity: ^Entity,
    text: string,
    speed: f32, // How many characters should be shown every second

    delta: f32, // Time this text has already been shown

    type: union {
        DialogNormal,
        DialogEvent,
    },
}

AddDialogNormal :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32, time_to_wait: f32) {
    dialog := Dialog {
        entity = entity,
        text = text,
        speed = speed,
        delta = 1,
        type = DialogNormal {
            time_to_wait
        }
    }

    append(&g_ctx.dialogs, dialog)
}

AddDialogEvent :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32, time_to_wait: f32) -> ^DialogHandle {
    handle := new(DialogHandle)
    handle^ = DialogHandle {
        finished = false
    }

    dialog := Dialog {
        entity = entity,
        text = text,
        speed = speed,
        type = DialogEvent {
            handle = handle
        }
    }

    append(&g_ctx.dialogs, dialog)
    return handle
}

RenderDialogs :: proc(g_ctx: ^GameContext) {
    for &d in g_ctx.dialogs {
        d.delta += rl.GetFrameTime()
        DrawDialog(g_ctx, &d)
    }
}

CharactersInLine :: 20
DialogSize :: 5
DialogSpacing :: 3

DialogBoxPadding :: 5

DrawDialog :: proc(g_ctx: ^GameContext, dialog: ^Dialog) {
    line_pos := Vector2(dialog.entity.pos)

    length := len(dialog.text) // Get total runes in text
    runes_to_show := int(math.floor_f32(dialog.delta*dialog.speed)) // Get numbers of runes to show
    runes_to_show = length < runes_to_show ? length : runes_to_show

    lines := (runes_to_show / CharactersInLine) + 1

    // Draw box
    {
        first_line := runes_to_show < 50 ? str.clone_to_cstring(dialog.text[0:runes_to_show], context.temp_allocator) : str.clone_to_cstring(dialog.text[0:50], context.temp_allocator)
        text_dim := rl.MeasureTextEx(g_ctx.font, first_line, DialogSize, DialogSpacing)
        
        box := Rectangle {
            g_ctx.player.x,
            g_ctx.player.y,
            text_dim.x * f32(lines) + DialogBoxPadding,
            text_dim.y * f32(lines) + DialogBoxPadding,
        }
        
        rl.DrawRectanglePro(box, {0,0}, 0, rl.GRAY)
    }

    start: int = 0
    end: int = 0
    // Draw lines (1 ; n-1)
    for i in 0..<(lines-1) {
        start = i * 50
        end = start + 50

        line := str.clone_to_cstring(dialog.text[start:end], context.temp_allocator)
        text_dim := rl.MeasureTextEx(g_ctx.font, line, DialogSize, DialogSpacing)
        
        rl.DrawTextPro(g_ctx.font, line, line_pos, {0,0}, 0, DialogSize, DialogSpacing, rl.GREEN)
    
        // Since there will be one line after the for loop, additional spacing must be added
        // even after the last line in for loop
        line_pos.y += text_dim.y
    }
    // Draw last line
    {
        start = end
        end = runes_to_show

        line := str.clone_to_cstring(dialog.text[start:end], context.temp_allocator)
        text_dim := rl.MeasureTextEx(g_ctx.font, line, DialogSize, DialogSpacing)

        rl.DrawTextPro(g_ctx.font, line, line_pos, {0,0}, 0, DialogSize, DialogSpacing, rl.GREEN)
    }
}