package game

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

// Type used in linking event with event elements
EventElementJSON :: struct {
    id: string,
    element: EventElement,
}

// Type used in linking event with event elements
EventJSON :: struct {
    event: Event,
    element_ids: [dynamic]string
}

Event :: struct {
    id: i32,
    // Event run when level is entered for the first time
    first_entry_event: bool,
    // Event run when level is entered and it is not the first time
    entry_event: bool,
    elements: [dynamic]EventElement,
}

PositionCamera :: struct {
    new_camera_pos: rl.Vector2,
}

@(private="file")
RunPositionCamera :: proc(g_ctx: ^GameContext, event: ^PositionCamera) -> bool {
    camera: ^rl.Camera2D = &g_ctx.camera
    camera_dim := GetCameraDimensions(g_ctx)/2
    new_position := event.new_camera_pos - camera_dim
    new_position += 8
    camera.target = new_position

    return true
}

MoveCamera :: struct {
    new_camera_pos: rl.Vector2,
    camera_speed: f32,
}

@(private="file")
RunMoveCamera :: proc(g_ctx: ^GameContext, event: ^MoveCamera) -> bool {
    camera: ^rl.Camera2D = &g_ctx.camera

    camera_dim := GetCameraDimensions(g_ctx)/2
    new_position := event.new_camera_pos - camera_dim
    // Add half of a tile to center the camera in the middle of it
    new_position += 8


    // Get distance
    distance := rl.Vector2Distance(camera.target, new_position)
    // Get direction vector
    direction := new_position - camera.target
    direction /= distance
    direction *= event.camera_speed*rl.GetFrameTime()*50

    // Check if the next move would place the camera beyond the target
    next_position := camera.target + direction
    next_distance := rl.Vector2Distance(next_position, new_position)

    if next_distance > distance {
        camera.target = new_position
        return true
    }

    camera.target += direction

    return false
}

SetPlayerState :: struct {
    enabled: bool
}

@(private="file")
RunSetPlayerState :: proc(g_ctx: ^GameContext, event: ^SetPlayerState) -> bool {
    player := GetPlayer(g_ctx)
    player.enabled = event.enabled
    return true
}

Wait :: struct {
    time_passed: f32,
    time_secs: f32
}

@(private="file")
RunWait :: proc(g_ctx: ^GameContext, event: ^Wait) -> bool {
    event.time_passed += rl.GetFrameTime()
    if event.time_secs < event.time_passed {
        return true
    }
    return false
}

SetTransition :: struct {
    opacity: f32,
    initial_opacity: f32,
    transition_time_secs: f32,
    time_passed: f32,
}

@(private="file")
RunSetTransition :: proc(g_ctx: ^GameContext, event: ^SetTransition) -> bool {
    transition := &g_ctx.transition_layer
    if event.time_passed == 0 {
        event.initial_opacity = transition.opacity
    }
    event.time_passed += rl.GetFrameTime()

    percent := (event.time_passed / event.transition_time_secs)
    new_opacity := event.initial_opacity + (event.opacity - event.initial_opacity)*percent

    if(percent >= 1) {
        transition.opacity = event.opacity
        return true
    }

    transition.opacity = new_opacity
    return false
}

AddPredefinedEvent :: struct {
    event_id: i32
}

@(private="file")
RunAddPredefinedEvent :: proc(g_ctx: ^GameContext, event: ^AddPredefinedEvent) -> bool {
    level := g_ctx.current_level
    for e in level.events {
        if e.id == event.event_id {
            append(&level.current_events, e)
            return true
        }
    }
    fmt.printfln("Cannot add predefined event of id \"%s\", since there is no such event with this id", event.event_id)
    return true
}

DisplayIntroText :: struct {
    text: string,
    time_to_show: f32,

    opacity: f32,
    flag: u8,
}

@(private="file")
RunDisplayIntroText :: proc(g_ctx: ^GameContext, event: ^DisplayIntroText) -> bool {
    level := g_ctx.current_level
    cam_pos := GetCameraPosition(g_ctx)
    e := Entity {
        pos = cam_pos+10,
        layer = .Text,
        visible = true,
        variant = IntroText {
            text = event.text,
            opacity = u8(event.opacity),
            continue_text = event.flag == 1
        }
    }
    append(&level.temp_entities, e)
    switch {
        case event.flag == 0: {
            event.opacity += rl.GetFrameTime() * 255 / event.time_to_show
            if event.opacity >= 255 || rl.IsMouseButtonPressed(.LEFT) {
                event.opacity = 255
                event.flag += 1
                return false
            }
        }
        case event.flag == 1: {
            if rl.IsMouseButtonPressed(.LEFT) {
                event.flag += 1
                return false
            }
        }
        case event.flag == 2: {
            event.opacity -= rl.GetFrameTime() * 255 / event.time_to_show
            if event.opacity <= 0 || rl.IsMouseButtonPressed(.LEFT) {
                event.opacity = 0
                event.flag += 1
                return false
            }
        }
        case: {
            return true
        }
    }
    // fmt.printfln("op %f", event.opacity)

    return false
}

EventElement :: union {
    MoveCamera,
    PositionCamera,
    SetPlayerState,
    Wait,
    SetTransition,
    AddPredefinedEvent,
    DisplayIntroText,
}

RunEvent :: proc(g_ctx: ^GameContext, event: ^Event) -> bool {
    // For loop is necessary, since some elements execute instantly
    // They will run next element immediately
    for {
        if len(event.elements) <= 0 {
            return true
        }
        event_element := &event.elements[0]
        switch &s in event_element {
            case PositionCamera: {
                RunPositionCamera(g_ctx, &s)
                ordered_remove(&event.elements, 0)
                continue
            }
            case MoveCamera: {
                if RunMoveCamera(g_ctx, &s) {
                    ordered_remove(&event.elements, 0)
                }
                return false
            }
            case SetPlayerState: {
                RunSetPlayerState(g_ctx, &s)
                ordered_remove(&event.elements, 0)
                continue
            }
            case Wait: {
                if RunWait(g_ctx, &s) {
                    ordered_remove(&event.elements, 0)
                }
                return false
            }
            case SetTransition: {
                if RunSetTransition(g_ctx, &s) {
                    ordered_remove(&event.elements, 0)
                }
                return false
            }
            case AddPredefinedEvent: {
                if RunAddPredefinedEvent(g_ctx, &s) {
                    ordered_remove(&event.elements, 0)
                }
                return false
            }
            case DisplayIntroText: {
                if RunDisplayIntroText(g_ctx, &s) {
                    ordered_remove(&event.elements, 0)
                }
                return false
            }
        }
    }
    return true
}

LoadFirstEntryEvents :: proc(g_ctx: ^GameContext) {    
    level := g_ctx.current_level
    for event in level.events {
        if event.first_entry_event {
            append(&level.current_events, event)
        }
    }
}

LoadEntryEvents :: proc(g_ctx: ^GameContext) {    
    level := g_ctx.current_level
    for event in level.events {
        if event.entry_event {
            append(&level.current_events, event)
        }
    }
}

GetFirstEntryEvents :: proc(g_ctx: ^GameContext) -> (result: [dynamic]Event) {    
    level := g_ctx.current_level
    for &event in level.events {
        if event.first_entry_event {
            append(&result, event)
        }
    }
    return result
}

GetEntryEvents :: proc(g_ctx: ^GameContext) -> (result: [dynamic]Event) {
    level := g_ctx.current_level
    for &event in level.events {
        if event.entry_event {
            append(&result, event)
        }
    }
    return result
}

CleanEvents :: proc(level: ^Level) {
    for event in level.events {
        for element in event.elements {
            #partial switch &s in element {
                case DisplayIntroText: {
                    delete(s.text)
                }
            }
        }
        delete(event.elements)
    }
}