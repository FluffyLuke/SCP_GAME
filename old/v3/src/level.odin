package game

import rl "vendor:raylib"
import "core:strconv"
import "core:strings"
import "core:fmt"
import "core:mem"
import "core:encoding/json"
import "core:os"

LevelID :: enum {
    EXIT = -1,
    MAIN_MENU = 0,
    FIRST_LEVEL = 100,
    FIRST_LEVEL_FLOOR = 110,
}

LevelState :: enum {
    // Place never visited
    NeverVisited,
    // Player just entered this place
    JustVisted,
    // Place is visited
    Visited,
}

Level :: struct {
    id: LevelID,
    // Used to get information about level from LDtk file 
    name: string,
    state: LevelState,
    dimensions: rl.Vector2,

    player_starting_pos: rl.Vector2,
    exit_points: [10]ExitPoint,
    entities: [dynamic]Entity,
    temp_entities: [dynamic]Entity,
    tiles: [dynamic]Tile,
    events: [dynamic]Event,
    current_events: [dynamic]Event,

    run_level: proc(level: ^GameContext)
}

LoadLevelData :: proc(g_ctx: ^GameContext) {
    json_data, err := json.parse(g_ctx.levels_file)
    defer {
        json.destroy_value(json_data)
    }

    if err != .None {
        fmt.printfln("Cannot load level from file!")
    }

    object, is_object := json_data.(json.Object)
    if !is_object {
        fmt.printfln("Invalid json!")
    }

    level_name: string = g_ctx.current_level.name

    if !ParseLevel(g_ctx, level_name, &object) {
        fmt.printfln("Cannot get level data!")
    }
    fmt.printfln("Got level data!")
}

// Exit point is not mandatory in some levels,
// in such cases -1 can be used
ChangeLevel :: proc(g_ctx: ^GameContext, id: LevelID, epi: i32) {
    g_ctx.next_level = id
    g_ctx.next_exit_point_id = epi
}

// -------------
// -- PARSING --
// -------------

ParseLevel :: proc(g_ctx: ^GameContext, level_name: string, object: ^json.Object) -> bool {
    level := g_ctx.current_level
    
    levels, is_array := object["levels"].(json.Array)
    if !is_array {
        fmt.printfln("Invalid json!")
        return false
    }

    level_found: bool
    level_object: json.Object
    for l in levels {

        lvl, is_object := l.(json.Object)
        if !is_object {
            continue
        }

        lvl_name, is_string := lvl["identifier"].(json.String)
        fmt.printfln("Loading level: %s", lvl_name)
        if !is_object {
            continue
        }

        if lvl_name != level_name {
            continue
        }

        level_object = lvl
        level_found = true
    }

    if(!level_found) {
        fmt.printfln("Cannot find level")
        return false
    }

    // Get level properties
    width := level_object["pxWid"].(json.Float) or_return
    height := level_object["pxHei"].(json.Float) or_return

    level.dimensions = Vector2 {f32(width), f32(height)}

    // Parse entities
    ParseEntities(g_ctx, &level_object)
    ParseTiles(g_ctx, &level_object)

    return true
}

ParseEntities :: proc(g_ctx: ^GameContext, level_json: ^json.Object) -> bool {
    level := g_ctx.current_level
    layer_instances := level_json["layerInstances"].(json.Array) or_return

    event_list := [dynamic]EventJSON {}
    event_element_list := [dynamic]EventElementJSON {}

    defer {
        delete(event_list)
        delete(event_element_list)
    }

    for l, i in layer_instances {
        fmt.println("Reading layer of index: ", i)

        // Get current layer
        layer := l.(json.Object) or_continue

        // Check layer's type
        layer_type := layer["__type"].(json.String) or_continue
        if layer_type != "Entities" {
            fmt.println("Cannot read layer's type or is not of type \"Entities\"")
            continue
        }

        ent_instances := layer["entityInstances"].(json.Array) or_continue
        for e in ent_instances {
            entity := e.(json.Object) or_continue
            ent_id := entity["__identifier"].(json.String) or_continue
            switch ent_id {
                case "Player": {
                    fmt.printfln("Parsing Player")
                    ParsePlayer(g_ctx, &entity)
                    continue
                }
                case "StaticCollider": {
                    fmt.printfln("Parsing StaticCollider")
                    ParseStaticCollider(g_ctx, &entity)
                    continue
                }
                case "Door": {
                    fmt.printfln("Parsing Door")
                    ParseDoor(g_ctx, &entity)
                    continue
                }
                case "DoorExitPoint": {
                    fmt.printfln("Parsing door exit point")
                    ParseExitPoint(g_ctx, &entity)
                    continue
                }
                case "Event": {
                    fmt.printfln("Parsing Event")
                    new_event_json, result := ParseEvent(g_ctx, &entity)
                    if !result {
                        fmt.printfln("Cannot parse eevent!")
                    }
                    append(&event_list, new_event_json)
                    continue
                }
                case: {
                    fmt.printfln("Parsing Something else %s", ent_id)
                }
            }

            ent_tags := entity["__tags"].(json.Array) or_continue
            
            for value in ent_tags {
                tag := value.(json.String) or_continue
                if tag == "Event_Element" {
                    if element, success := ParseEventElement(g_ctx, &entity); success {
                        append(&event_element_list, element)
                    } else {
                        fmt.printfln("Cannot parse event element!")
                    }
                }
            }
        }
    }

    // Connect events with event elements
    for &event_json in event_list {
        // For every event, check all event elements and see if IDs match
        LinkEvent(&event_json, event_element_list[:])
        delete(event_json.element_ids)
        fmt.printfln("Current level name: %s", level.name)
        append(&level.events, event_json.event)
    }
    return true
}

LinkEvent :: proc(event_json: ^EventJSON, event_element_list: []EventElementJSON) {
    for element_id_json in event_json.element_ids {
        for element_json in event_element_list {
            if element_id_json == element_json.id {
                append(&event_json.event.elements, element_json.element)
            }
        }
    }
}

ParseEvent :: proc(g_ctx: ^GameContext, event_json: ^json.Object) -> (e: EventJSON, result: bool) {
    first_entry, entry: bool
    id: i32
    event_ref_ids: [dynamic]string = {}
    
    field_instances := event_json["fieldInstances"].(json.Array) or_return
    fields: for e in field_instances {
        field := e.(json.Object) or_continue
        field_id := field["__identifier"].(json.String) or_continue

        switch field_id {
            case "id": {
                id = i32(field["__value"].(json.Float) or_continue)
            }
            case "First_Entry_Event": {
                first_entry = field["__value"].(json.Boolean) or_continue
            }
            case "Entry_Event": {
                entry = field["__value"].(json.Boolean) or_continue
            }
            case "Entity_ref": {
                refs := field["__value"].(json.Array) or_continue
                for element_ref in refs {
                    ref := element_ref.(json.Object) or_continue fields
                    ref_id := ref["entityIid"].(json.String) or_continue fields
                    append(&event_ref_ids, ref_id)
                }
            }
            case: {
                fmt.printfln("Unknown event field")
                continue
            }
        }
    }

    e = EventJSON {
        event = Event {
            id = id,
            first_entry_event = first_entry,
            entry_event = entry,
            elements = {}
        },
        element_ids = event_ref_ids,
    }

    return e, true
}

ParseEventElement :: proc(g_ctx: ^GameContext, event_json: ^json.Object) -> (e: EventElementJSON, res: bool) {
    event_id := event_json["__identifier"].(json.String) or_return
    field_instances: json.Array

    switch event_id {
        case "CameraMove": {
            id := event_json["iid"].(json.String) or_return
            field_instances = event_json["fieldInstances"].(json.Array) or_return

            where_to_move := field_instances[0].(json.Object) or_return
            vals := where_to_move["__value"].(json.Object) or_return
            x := vals["cx"].(json.Float) or_return
            y := vals["cy"].(json.Float) or_return

            speed_field := field_instances[1].(json.Object) or_return
            speed := speed_field["__value"].(json.Float) or_return
            e = EventElementJSON {
                id = id,
                element = MoveCamera {
                    camera_speed = f32(speed),
                    new_camera_pos = Vector2 {f32(x*16), f32(y*16)},
                }
            }

            return e, true
        }
        case "CameraPosition": {
            id := event_json["iid"].(json.String) or_return
            field_instances = event_json["fieldInstances"].(json.Array) or_return

            camera_pos := field_instances[0].(json.Object) or_return
            vals := camera_pos["__value"].(json.Object) or_return
            x := vals["cx"].(json.Float) or_return
            y := vals["cy"].(json.Float) or_return

            e = EventElementJSON {
                id = id,
                element = PositionCamera {
                    new_camera_pos = Vector2 {f32(x*16), f32(y*16)},
                }
            }

            return e, true
        }
        case "SetPlayerState": {
            id := event_json["iid"].(json.String) or_return
            field_instances = event_json["fieldInstances"].(json.Array) or_return

            player_state := field_instances[0].(json.Object) or_return
            val := player_state["__value"].(json.Boolean) or_return

            e = EventElementJSON {
                id = id,
                element = SetPlayerState {
                    enabled = val
                }
            }

            return e, true
        }
        case "Wait": {
            id := event_json["iid"].(json.String) or_return
            field_instances = event_json["fieldInstances"].(json.Array) or_return

            wait := field_instances[0].(json.Object) or_return
            val := wait["__value"].(json.Float) or_return

            e = EventElementJSON {
                id = id,
                element = Wait {
                    time_passed = 0,
                    time_secs = f32(val),
                }
            }

            return e, true
        }
        case "SetTransition": {
            id := event_json["iid"].(json.String) or_return
            field_instances = event_json["fieldInstances"].(json.Array) or_return

            op := field_instances[0].(json.Object) or_return
            opacity := op["__value"].(json.Float) or_return

            trans := field_instances[1].(json.Object) or_return
            transition_time := trans["__value"].(json.Float) or_return

            e = EventElementJSON {
                id = id,
                element = SetTransition {
                    opacity = f32(opacity),
                    transition_time_secs = f32(transition_time),
                    time_passed = 0,
                }
            }
            return e, true
        }
        case "AddEvent": {
            id := event_json["iid"].(json.String) or_return
            field_instances = event_json["fieldInstances"].(json.Array) or_return

            val := field_instances[0].(json.Object) or_return
            event_to_add_id := val["__value"].(json.Float) or_return
            e = EventElementJSON {
                id = id,
                element = AddPredefinedEvent {
                    event_id = i32(event_to_add_id)
                }
            }
            return e, true
        }
        case "DisplayIntroText": {
            id := event_json["iid"].(json.String) or_return
            field_instances = event_json["fieldInstances"].(json.Array) or_return

            tts := field_instances[0].(json.Object) or_return
            time_to_show := tts["__value"].(json.Float) or_return

            text_val := field_instances[1].(json.Object) or_return
            text := text_val["__value"].(json.String) or_return

            e = EventElementJSON {
                id = id,
                element = DisplayIntroText {
                    text = text,
                    time_to_show = f32(time_to_show),
                }
            }
            return e, true
        }
        case: {
            fmt.printfln("Unrecognized event element!")
        }
    }
    return e, false
}

ParseExitPoint :: proc(g_ctx: ^GameContext, exit_point_json: ^json.Object) -> bool {
    pos_json := exit_point_json["px"].(json.Array) or_return
    pos := rl.Vector2 {f32(pos_json[0].(json.Float)), f32(pos_json[1].(json.Float))}

    field_instances := exit_point_json["fieldInstances"].(json.Array) or_return

    id := field_instances[0].(json.Object) or_return
    exit_point_id := i32(id["__value"].(json.Float) or_return)

    exit_point := ExitPoint {
        id = exit_point_id,
        pos = pos,
    }

    g_ctx.current_level.exit_points[exit_point_id % 10] = exit_point
    return true
}

ParseDoor :: proc(g_ctx: ^GameContext, door_json: ^json.Object) -> bool {
    pos_json := door_json["px"].(json.Array) or_return
    pos := rl.Vector2 {f32(pos_json[0].(json.Float)), f32(pos_json[1].(json.Float))}

    field_instances := door_json["fieldInstances"].(json.Array) or_return

    epi := field_instances[0].(json.Object) or_return
    exit_point_id := i32(epi["__value"].(json.Float) or_return)

    dt := field_instances[1].(json.Object) or_return
    door_type_str := dt["__value"].(json.String) or_return
    door_type := GetDoorType(door_type_str) or_return

    door := InitDoor(g_ctx, door_type, pos, exit_point_id)
    door_ent := Entity {
        pos = pos,
        layer = .CloseBackground,
        visible = true,
        variant = door
    }

    append(&g_ctx.current_level.entities, door_ent);

    return true
}

ParseStaticCollider :: proc(g_ctx: ^GameContext, collider_json: ^json.Object) -> bool {
    pos_json := collider_json["px"].(json.Array) or_return
    pos := rl.Vector2 {f32(pos_json[0].(json.Float)), f32(pos_json[1].(json.Float))}
    width := collider_json["width"].(json.Float) or_return
    height := collider_json["height"].(json.Float) or_return
    if len(pos) < 2 {
        return false
    }

    sc := StaticCollider {
        collider = rl.Rectangle {
            x = pos.x,
            y = pos.y,
            width = f32(width),
            height = f32(height),
        }
    }

    sc_ent := Entity {
        pos = pos,
        layer = .Props,
        visible = false,
        variant = sc
    }

    append(&g_ctx.current_level.entities, sc_ent)

    return true
}

// Used to get the starting position of a player
ParsePlayer :: proc(g_ctx: ^GameContext, player_json: ^json.Object) -> bool {
    player_pos := player_json["px"].(json.Array) or_return
    if len(player_pos) < 2 {
        return false
    }
    level := g_ctx.current_level
    level.player_starting_pos = {
        f32(player_pos[0].(json.Float))+8,
        f32(player_pos[1].(json.Float))+8,
    }

    fmt.printfln("%s", level.player_starting_pos)
    return true
}

RemoveFileName :: proc(path_with_file_name: string) -> string {
    // Since regexes aren't a thing, get the path manually
    low := len(path_with_file_name)
    #reverse for r in path_with_file_name {
        if r == '/' {
            break
        }
        low -= 1
    }
    return path_with_file_name[low:]
}

ParseTiles :: proc(g_ctx: ^GameContext, level_json: ^json.Object) -> bool {
    level := g_ctx.current_level
    layer_instances := level_json["layerInstances"].(json.Array) or_return

    for l, i in layer_instances {
        fmt.println("Reading layer of index: ", i)

        // Get current layer
        layer := l.(json.Object) or_continue

        // Get grid size
        grid_size := layer["__gridSize"].(json.Float) or_continue

        // Check layer's type
        layer_type := layer["__type"].(json.String) or_continue
        if layer_type != "IntGrid" {
            fmt.println("Cannot read layer's type or is not of type \"IntGrid\"")
            continue
        }

        // -- Get tiles --
        tileset_path := layer["__tilesetRelPath"].(json.String) or_continue
        tileset_path = RemoveFileName(tileset_path)
        tiles := layer["autoLayerTiles"].(json.Array) or_continue
        LoadTiles(g_ctx, level, tiles[:], tileset_path, grid_size)
    }

    return true
}