package game

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

Nothing :: proc(game_ctx: ^GameContext, data: rawptr) {}

ButtonStyle :: struct {
    text_size: f32,
    text_color: rl.Color,
}

ButtonState :: enum {
    BUTTON_DISABLED,
    BUTTON_NORMAL,
    BUTTON_HOVER,
    BUTTON_CLICKED,
}

Button :: struct {
    text: cstring,
    click_area: ^ClickArea,

    rec: rl.Rectangle,
    state: ButtonState,

    b_disabled: ButtonStyle,
    b_normal: ButtonStyle,
    b_hover: ButtonStyle,
    b_clicked: ButtonStyle,
}

NewButton :: proc(text: cstring, rec: rl.Rectangle, message: cstring) -> (^Widget, ^ClickArea) {
    area: ^ClickArea = new(ClickArea)
    area.rec = rec
    area.message = message
    area.state = ClickAreaDisabled {}
    
    button := Button {
        text = text,
        click_area = area,
        rec = rec,
        state = .BUTTON_DISABLED
    }
    new_button := new(Widget)
    new_button^ = button

    return new_button, area;
}

ButtonSetText :: proc(button: ^Button, text: cstring) {
    button.text = text
}

ButtonStylizeText :: proc(
    button: ^Button,
    b_disabled: ButtonStyle,
    b_normal: ButtonStyle,
    b_hover: ButtonStyle,
    b_clicked: ButtonStyle,
) {
    button.b_disabled = b_disabled
    button.b_normal = b_normal
    button.b_hover = b_hover
    button.b_clicked = b_clicked
}

CheckButtonState :: proc(game_ctx: ^GameContext, button: ^Button) {
    pos := rl.GetMousePosition()
    clicked := rl.IsMouseButtonReleased(.LEFT)
    hold := rl.IsMouseButtonDown(.LEFT)

    #partial switch v in button.click_area.state {
        case ClickAreaDisabled: {
            button.state = .BUTTON_DISABLED
            return
        }
    }

    if !rl.CheckCollisionPointRec(pos, button.click_area.rec) {
        button.state = .BUTTON_NORMAL
        return
    }

    button.state = .BUTTON_HOVER;

    if hold {
        button.state = .BUTTON_CLICKED
        return
    }
}

Label :: struct {
    text: cstring,
    text_size: i32,
    text_color: rl.Color,
    pos: Vector2,
}

NewLabel :: proc(text: cstring, text_size: i32, text_color: rl.Color, pos: Vector2) -> ^Widget {
    label := Label {
        text = text,
        text_color = text_color,
        text_size = text_size,
        pos = pos,
    }

    new_label := new(Widget)
    new_label^ = label

    return new_label
}

LabelStylizeText :: proc (label: ^Label, text_size: i32, text_color: rl.Color) {
    label.text_color = text_color
    label.text_size = text_size
}

LabelSetText :: proc(label: ^Label, text: cstring) {
    label.text = text
}

Widget :: union {
    Button,
    Label,
}