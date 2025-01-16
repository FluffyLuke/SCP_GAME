#+feature dynamic-literals

package game

import "core:mem"
import "core:log"

import rl "vendor:raylib"

TriggerArea :: struct {
    action_name: string,
    using area: Rectangle,
    enabled: bool,
    action: proc(g_ctx: ^GameContext)
}

AssignProcToTriggerAreas :: proc(areas: ^[]TriggerArea) {
    list_of_procs := map[string]proc(^GameContext) {
        "InitGame" = InitGame
    }
    
    for &area in areas {
        if action, ok := list_of_procs[area.action_name]; ok {
            area.action = action
        } else {
            area.action = EmptyAction
            log.error("Cannot assign event area action called:", area.action_name)
        }
    }
}

@(private="file")
EmptyAction :: proc(g_ctx: ^GameContext) {}

@(private="file")
InitGame :: proc(g_ctx: ^GameContext) {}