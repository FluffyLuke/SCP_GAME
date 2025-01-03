package game

import "core:math"
import str "core:strings"
import "core:log"

import rl "vendor:raylib"


DialogueHandle :: struct {
    finished: bool
}

DestroyDialogueHandle :: proc(d: ^DialogueHandle) {
    free(d)
}

DialogueNormal :: struct {
    // Time to wait after dialogue is over
    // before erasing the text
    time_to_wait: f32,
    delta: f32,
}

DialogueWait :: struct {
    // This handle is used to check whether dialogue has ended
    // Handle is used, because reference to dialogue can become invalid
    handle: ^DialogueHandle,
}

Dialogue :: struct {
    entity: ^Entity,
    text: string,
    speed: f32, // How many characters should be shown every second
    fully_displayed: bool,

    delta: f32, // Time this text has already been shown

    type: union {
        DialogueNormal,
        DialogueWait,
    },
}

AddDialogueNormal :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32, time_to_wait: f32) {
    dialogue := Dialogue {
        entity = entity,
        text = text,
        speed = speed,
        delta = 0,
        type = DialogueNormal {
            time_to_wait,
            0,
        }
    }

    append(&g_ctx.dialogues, dialogue)
}

GetDialogueNormal :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32, time_to_wait: f32) -> Dialogue {
    dialogue := Dialogue {
        entity = entity,
        text = text,
        speed = speed,
        delta = 0,
        type = DialogueNormal {
            time_to_wait,
            0,
        }
    }

    return dialogue
}

AddDialogueWait :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32) -> ^DialogueHandle {
    handle := new(DialogueHandle)
    handle^ = DialogueHandle {
        finished = false
    }

    dialogue := Dialogue {
        entity = entity,
        text = text,
        speed = speed,
        type = DialogueWait {
            handle = handle
        }
    }

    append(&g_ctx.dialogues, dialogue)
    return handle
}

GetDialogueWait :: proc(g_ctx: ^GameContext, entity: ^Entity, text: string, speed: f32) -> (Dialogue, ^DialogueHandle) {
    handle := new(DialogueHandle)
    handle^ = DialogueHandle {
        finished = false
    }

    dialogue := Dialogue {
        entity = entity,
        text = text,
        speed = speed,
        type = DialogueWait {
            handle = handle
        }
    }

    return dialogue, handle
}

RenderDialogues :: proc(g_ctx: ^GameContext) {
    for &d, i in g_ctx.dialogues {
        d.delta += rl.GetFrameTime()
        switch &s in d.type {
            case DialogueNormal: {
                if d.fully_displayed do s.delta += rl.GetFrameTime()

                if s.delta > s.time_to_wait do ordered_remove(&g_ctx.dialogues, i)
                else do DrawDialogue(g_ctx, &d)
            }
            case DialogueWait: {
                if s.handle.finished do ordered_remove(&g_ctx.dialogues, i)
                else do DrawDialogue(g_ctx, &d)
            }
        }
    }
}

@(private="file") CharactersInLine :: 30
@(private="file") DialogueSize :: 5
@(private="file") DialogueSpacing :: 1

@(private="file") DialogueBoxPadding :: 12
@(private="file") DialogueBoxPaddingRight :: 4

SlowDialogueSpeed :: 10
DefaultDialogueSpeed :: 20
FastDialogueSpeed :: 30

DefaultDialogueWaitTime :: 2

DrawDialogue :: proc(g_ctx: ^GameContext, dialogue: ^Dialogue) {
    line_pos := Vector2(dialogue.entity.pos)

    length := len(dialogue.text) // Get total runes in text
    runes_to_show := int(math.floor_f32(dialogue.delta*dialogue.speed)) // Get numbers of runes to show

    // log.error("Dialogue delta:", dialogue.delta)
    // log.error("Dialogue speed:", dialogue.speed)
    // log.error("Runes to show:", runes_to_show)
    
    //runes_to_show = length < runes_to_show ? length : runes_to_show

    if length < runes_to_show {
        dialogue.fully_displayed = true;
        runes_to_show = length
    }

    lines := (runes_to_show / CharactersInLine) + 1

    entity_height := dialogue.entity.current_animation.render_dimensions.y

    origin: Vector2
    // Draw box
    {
        first_line := runes_to_show < CharactersInLine ? \
            str.clone_to_cstring(dialogue.text[0:runes_to_show], context.temp_allocator) : 
            str.clone_to_cstring(dialogue.text[0:CharactersInLine], context.temp_allocator)
            
        text_dim := rl.MeasureTextEx(g_ctx.font, first_line, DialogueSize, DialogueSpacing)
        
        box := Rectangle {
            g_ctx.player.x,
            g_ctx.player.y,
            text_dim.x + DialogueBoxPadding + DialogueBoxPaddingRight,
            text_dim.y * f32(lines) + DialogueBoxPadding,
        }

        // origin box
        origin = Vector2 {
            box.width / 2,
            entity_height + text_dim.y*f32(lines),
        }
        
        rl.DrawRectanglePro(box, origin, 0, rl.GRAY)
    }

    origin -= DialogueBoxPadding/2

    start: int = 0
    end: int = 0
    // Draw lines (1 ; n-1)
    for i in 0..<(lines-1) {
        start = i * CharactersInLine
        end = start + CharactersInLine

        line := str.clone_to_cstring(dialogue.text[start:end], context.temp_allocator)
        text_dim := rl.MeasureTextEx(g_ctx.font, line, DialogueSize, DialogueSpacing)
        
        rl.DrawTextPro(g_ctx.font, line, line_pos, origin, 0, DialogueSize, DialogueSpacing, rl.GREEN)
    
        // Since there will be one line after the for loop, additional spacing must be added
        // even after the last line in for loop
        line_pos.y += text_dim.y
    }
    // Draw last line
    {
        start = end
        end = runes_to_show

        line := str.clone_to_cstring(dialogue.text[start:end], context.temp_allocator)
        text_dim := rl.MeasureTextEx(g_ctx.font, line, DialogueSize, DialogueSpacing)

        rl.DrawTextPro(g_ctx.font, line, line_pos, origin, 0, DialogueSize, DialogueSpacing, rl.GREEN)
    }
}