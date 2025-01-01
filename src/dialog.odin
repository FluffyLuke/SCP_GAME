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
    time_to_wait: f32,
    delta: f32,
}

DialogWait :: struct {
    // This handle is used to check whether dialog has ended
    // Handle is used, because reference to dialog can become invalid
    handle: ^DialogHandle,
}

Dialog :: struct {
    entity: ^Entity,
    text: string,
    speed: f32, // How many characters should be shown every second
    fully_displayed: bool,

    delta: f32, // Time this text has already been shown

    type: union {
        DialogNormal,
        DialogWait,
    },
}

AddDialogNormal :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32, time_to_wait: f32) {
    dialog := Dialog {
        entity = entity,
        text = text,
        speed = speed,
        delta = 0,
        type = DialogNormal {
            time_to_wait,
            0,
        }
    }

    append(&g_ctx.dialogs, dialog)
}

AddDialogWait :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32, time_to_wait: f32) -> ^DialogHandle {
    handle := new(DialogHandle)
    handle^ = DialogHandle {
        finished = false
    }

    dialog := Dialog {
        entity = entity,
        text = text,
        speed = speed,
        type = DialogWait {
            handle = handle
        }
    }

    append(&g_ctx.dialogs, dialog)
    return handle
}

RenderDialogs :: proc(g_ctx: ^GameContext) {
    for &d, i in g_ctx.dialogs {
        d.delta += rl.GetFrameTime()
        switch &s in d.type {
            case DialogNormal: {
                if d.fully_displayed do s.delta += rl.GetFrameTime()

                if s.delta > s.time_to_wait do ordered_remove(&g_ctx.dialogs, i)
                else do DrawDialog(g_ctx, &d)
            }
            case DialogWait: {
                if s.handle.finished do ordered_remove(&g_ctx.dialogs, i)
                else do DrawDialog(g_ctx, &d)
            }
        }
    }
}

@(private="file") CharactersInLine :: 30
@(private="file") DialogSize :: 5
@(private="file") DialogSpacing :: 1

@(private="file") DialogBoxPadding :: 12
@(private="file") DialogBoxPaddingRight :: 4

SlowDialogSpeed :: 10
DefaultDialogSpeed :: 20
FastDialogSpeed :: 30

DefaultDialogWaitTime :: 2

DrawDialog :: proc(g_ctx: ^GameContext, dialog: ^Dialog) {
    line_pos := Vector2(dialog.entity.pos)

    length := len(dialog.text) // Get total runes in text
    runes_to_show := int(math.floor_f32(dialog.delta*dialog.speed)) // Get numbers of runes to show

    log.error("Dialog delta:", dialog.delta)
    log.error("Dialog speed:", dialog.speed)
    log.error("Runes to show:", runes_to_show)
    
    //runes_to_show = length < runes_to_show ? length : runes_to_show

    if length < runes_to_show {
        dialog.fully_displayed = true;
        runes_to_show = length
    }

    lines := (runes_to_show / CharactersInLine) + 1

    entity_height := dialog.entity.current_animation.render_dimensions.y

    origin: Vector2
    // Draw box
    {
        first_line := runes_to_show < CharactersInLine ? \
            str.clone_to_cstring(dialog.text[0:runes_to_show], context.temp_allocator) : 
            str.clone_to_cstring(dialog.text[0:CharactersInLine], context.temp_allocator)
            
        text_dim := rl.MeasureTextEx(g_ctx.font, first_line, DialogSize, DialogSpacing)
        
        box := Rectangle {
            g_ctx.player.x,
            g_ctx.player.y,
            text_dim.x + DialogBoxPadding + DialogBoxPaddingRight,
            text_dim.y * f32(lines) + DialogBoxPadding,
        }

        // origin box
        origin = Vector2 {
            box.width / 2,
            entity_height + text_dim.y*f32(lines),
        }
        
        rl.DrawRectanglePro(box, origin, 0, rl.GRAY)
    }

    origin -= DialogBoxPadding/2

    start: int = 0
    end: int = 0
    // Draw lines (1 ; n-1)
    for i in 0..<(lines-1) {
        start = i * CharactersInLine
        end = start + CharactersInLine

        line := str.clone_to_cstring(dialog.text[start:end], context.temp_allocator)
        text_dim := rl.MeasureTextEx(g_ctx.font, line, DialogSize, DialogSpacing)
        
        rl.DrawTextPro(g_ctx.font, line, line_pos, origin, 0, DialogSize, DialogSpacing, rl.GREEN)
    
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

        rl.DrawTextPro(g_ctx.font, line, line_pos, origin, 0, DialogSize, DialogSpacing, rl.GREEN)
    }
}