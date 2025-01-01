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
    WaitEvent,
    DialogEvent,
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
    should_wait: bool, // Whether event should wait for camera to center on the target
}

AddMoveCameraStateEvent :: proc(event: ^Event, target: ^Point2, speed: f32, wait: bool) {
    append(&event.elements, MoveCameraEvent {speed, target, wait})
}

RunMoveCameraEvent :: proc(g_ctx: ^GameContext, event: ^MoveCameraEvent) -> EventElementFinishedSignal {
    camera := &g_ctx.camera
    camera.speed = event.speed
    camera.target_ref = event.target

    if !event.should_wait do return .FinishedAndSkip

    if Vector2(event.target^) == camera.target {
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

WaitEvent :: struct {
    time: f32,
    delta: f32,
}

AddWaitEvent :: proc(event: ^Event, time: f32) {
    append(&event.elements, WaitEvent {time, 0})
}

RunWaitEvent :: proc(g_ctx: ^GameContext, event: ^WaitEvent) -> EventElementFinishedSignal {
    event.delta += rl.GetFrameTime();
    if event.delta >= event.time do return .Finished
    return .NotFinished
}

DialogEventState :: enum {
    AddingDialog,
    Logic,
}
DialogEvent :: struct {
    state: DialogEventState,
    dialog: Dialog,
    handle: ^DialogHandle // Can be nil!
}

AddDialogEvent :: proc(event: ^Event, dialog: Dialog, handle: ^DialogHandle = nil) {
    append(&event.elements, DialogEvent { .AddingDialog, dialog, handle })
}

RunDialogEvent :: proc(g_ctx: ^GameContext, event: ^DialogEvent) -> EventElementFinishedSignal {
    switch &s in event.dialog.type {
        case DialogNormal: {
            append(&g_ctx.dialogs, event.dialog)
            event.state = .Logic // Not used
            return .FinishedAndSkip
        }
        case DialogWait: {
            switch event.state {
                case .AddingDialog: {
                    append(&g_ctx.dialogs, event.dialog)
                    fallthrough
                }
                case .Logic: {
                    if rl.IsKeyPressed(.E) {
                        event.handle.finished = true;
                        return .Finished
                    }
                    return .NotFinished
                }
            }
        }
    }
    log.error("This point should never be reached!")
    return .Finished
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
            case WaitEvent: status = RunWaitEvent(g_ctx, &s)
            case DialogEvent: status = RunDialogEvent(g_ctx, &s)
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

