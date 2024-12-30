package game

import rl "vendor:raylib"
import str "core:strings"
import "core:log"

// Dialog :: struct {
//     dialog_parts: [dynamic]DialogPart,
//     current_part: ^DialogPart,
// }

// DestroyDialog :: proc(d: ^Dialog) {
//     delete(d.dialog_parts)
// }

// DialogPart :: struct {
//     text: string,
//     color: rl.Color,
//     speed: f32, // Chars per second
//     num_of_chars: f32, 
// }

// RenderDialog :: proc(g_ctx: ^GameContext, dialog: ^Dialog) {
//     part := dialog.current_part

//     part.num_of_chars += rl.GetFrameTime() * part.speed
    
//     text_to_draw := str.clone_to_cstring(part.text)

//     rl.DrawText(rl.TextSubtext(text_to_draw, ))
// }