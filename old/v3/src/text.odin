package game

import rl "vendor:raylib"
import str "core:strings"

import "core:fmt"

IntroText :: struct {
    text: string,
    opacity: u8,
    continue_text: bool,
}

RenderIntroText :: proc(g_ctx: ^GameContext, text: EntityInstance(IntroText)) {
    ctext := str.clone_to_cstring(text.text)
    rl.DrawTextEx(
        rl.GetFontDefault(),
        ctext,
        text.pos,
        6,
        1,
        {255,0,0,text.opacity}
    )

    cam_pos := GetCameraPosition(g_ctx)
    cam_dim := GetCameraDimensions(g_ctx)
    if text.continue_text {
        rl.DrawTextEx(
            rl.GetFontDefault(),
            "press \"LEFT\" to continue",
            {
                cam_pos.x + cam_dim.x - 100,
                cam_pos.y + cam_dim.y - 10,
            },
            6,
            1,
            {255,255,255,text.opacity}
        )
    }
    delete(ctext)
}