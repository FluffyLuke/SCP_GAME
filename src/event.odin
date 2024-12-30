package game

import "core:mem"
import "core:log"

import rl "vendor:raylib"

// Each "Event" is made up of smaller events
Event :: struct {
    elements: [dynamic]EventElement
}

EventElement :: union {
    SetPlayerStateEvent,
    MoveCameraEvent,
}

EventElementFinishedSignal :: enum {
    NotFinished,
    Finished,
    FinishedAndSkip,
}

SetPlayerStateEvent :: struct { 
    state: PlayerState
}
AddSetPlayerStateEvent :: proc(event: ^Event, state: PlayerState) {
    append(&event.elements, SetPlayerStateEvent {state})
}
RunSetPlayerStateEvent :: proc(g_ctx: ^GameContext, event: ^SetPlayerStateEvent) -> EventElementFinishedSignal {
    g_ctx.player.state = event.state
    return .FinishedAndSkip
}

// If speed = 0, camera teleports to the target
MoveCameraEvent :: struct {
    speed: f32,
    target: ^Point2,
}

AddMoveCameraStateEvent :: proc(event: ^Event, speed: f32, target: ^Point2) {
    append(&event.elements, MoveCameraEvent {speed, target})
} 
RunMoveCameraEvent :: proc(g_ctx: ^GameContext, event: ^MoveCameraEvent) -> EventElementFinishedSignal {
    camera := &g_ctx.camera
    camera.speed = event.speed
    camera.target_ref = event.target
    log.debug("Target:",event.target)
    if Vector2(event.target^) == camera.target {
        log.error("FINISHEd")
        return .Finished
    }
    return .NotFinished
}

// Since most of the levels will handle the events in the same way here is a function for it
RunEventsDefault :: proc(g_ctx: ^GameContext, events: ^[dynamic]Event) {
    if len(events) < 1 do return
    for &event, i in events {
        if RunEventLogic(g_ctx, &event) {
            // FIX potential memory leak when level is changed before all events are finalized
            delete(event.elements)
            ordered_remove(events, i)
        }
    }
}

// This is used to run a single event
RunEventLogic :: proc(g_ctx: ^GameContext, event: ^Event) -> bool {
    // For loop is necessary, since some elements execute instantly
    // They will run next element immediately
    event_logic: for {
        status: EventElementFinishedSignal
        if len(event.elements) <= 0 {
            return true
        }

        event_element := &event.elements[0]
        switch &s in event_element {
            case SetPlayerStateEvent: status = RunSetPlayerStateEvent(g_ctx, &s)
            case MoveCameraEvent: status = RunMoveCameraEvent(g_ctx, &s)
        }

        switch status {
            case .NotFinished: return false
            case .Finished: {
                ordered_remove(&event.elements, 0)
                return false
            }
            case .FinishedAndSkip: {
                ordered_remove(&event.elements, 0)
                continue event_logic
            }
        }
    }
}

