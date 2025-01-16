package game

import "core:encoding/json"
import str "core:strings"
import "core:os"
import "core:log"
import "core:mem"

AutoLayerTile :: struct { 
    px: [2]i32,
    src: [2]i32,
}

LevelJSON :: struct 
{
    toc: []struct {
        identifier: string,
        instancesData: []struct {
            worldX: i32,
            worldY: i32,
        }
    },

    levels: []struct {
        identifier: string,
        pxHei: i32,
        pxWid: i32,
        layerInstances: []struct {
            __identifier: string,
            __type: string,

            autoLayerTiles: []AutoLayerTile,
            gridTiles: []AutoLayerTile,

            // For entites
            entityInstances: []EntityRaw
        }
    }
}

ParseLevels :: proc(g_ctx: ^GameContext, path: string) {
    l: LevelJSON
    if json_data, ok := os.read_entire_file(path, allocator=context.temp_allocator); ok {
        if json.unmarshal(json_data, &l, allocator=context.temp_allocator) == nil {
            g_ctx.default_tile_height = 16
            g_ctx.default_tile_width = 16

            // Get player start
            log.info(l.toc[0].instancesData[0].worldX, " ", l.toc[0].instancesData[0].worldY)
            g_ctx.player_starting_pos = { f32(l.toc[0].instancesData[0].worldX), f32(l.toc[0].instancesData[0].worldY) }

            // Process each level
            ProcessLevels(g_ctx, &l)
        } else {
            log.error("Failed to unmarshal levels' json!")
        }
    } else {
        log.error("Cannot find levels!")
    }
    free_all(context.temp_allocator)
}

@(private="file")
ProcessLevels :: proc(g_ctx: ^GameContext, levelJSON: ^LevelJSON) {
    for level_raw in levelJSON.levels {

        level := new(Level)
        level^ = Level {
            name = str.clone(level_raw.identifier),
            state = .StartState,

            tiles = {},
            walls = {},

            dimensions = { f32(level_raw.pxWid), f32(level_raw.pxHei) }
        }
        
        for &layer in level_raw.layerInstances {
            switch layer.__identifier {
                case "Foreground": ParseTiles(g_ctx, level, &layer.gridTiles, g_ctx.tilesets[.RoomTileset], .Foreground)
                case "Background": ParseTiles(g_ctx, level, &layer.gridTiles, g_ctx.tilesets[.RoomTileset], .Background)
                case "Tiles": ParseTiles(g_ctx, level, &layer.gridTiles, g_ctx.tilesets[.RoomTileset], .Room)
                case "Room": ParseTiles(g_ctx, level, &layer.autoLayerTiles, g_ctx.tilesets[.RoomTileset], .Room)
                case "Entities": ParseEntities(g_ctx, level, layer.entityInstances)
                case "MetaEntities": ParseEntities(g_ctx, level, layer.entityInstances)
                case: log.warn("Unrecognized layer: ", layer.__identifier)
            }
        }
        BindLevelData(level)
        append(&g_ctx.levels, level);
    }

    g_ctx.current_level = g_ctx.levels[0]
}

@(private="file")
ParseEntities :: proc(g_ctx: ^GameContext, level: ^Level, entities: []EntityRaw) {
    for &e in entities {
        switch e.__identifier {
            case "Door": {
                append(&level.entities, ParseRawDoor(g_ctx, &e))
            }
            case "Wall": {
                append(&level.walls, ParseRawWall(&e))
            }
            case "GameStart": {
                g_ctx.player_starting_pos = RetartedVectorToPoint(e.px)
            }
            // === PUZZLES ===
            case "CodePuzzle": {
                append(&level.entities, ParseRawCodePuzzle(g_ctx, &e))
            }
            case "CodeNote": {
                append(&level.entities, ParseRawCodeNote(g_ctx, &e))
            }
            case "LeverPuzzle": {
                append(&level.entities, ParseRawLeverPuzzle(g_ctx, &e))
            }
            case "FuzePuzzle": {
                append(&level.entities, ParseRawFuzePuzzle(g_ctx, &e))
            }
            case "Lever": {
                append(&level.entities, ParseRawLever(g_ctx, &e))
            }
            case "Item": {
                append(&level.entities, ParseRawItem(g_ctx, &e))
            }
            case: {
                log.info("Instance: ", e)
            }
        }
    }
}

CreateCollider :: proc(rec: Rectangle) -> Collider {
    return {
        rec = rec,
        disabled = false,
    }
}

GetColliderRetarded :: proc(e: ^EntityRaw) -> Collider {
    return {
        rec = {e.px.x, e.px.y, f32(e.width), f32(e.height)},
        disabled = false,
    }
}

GetCollider:: proc(e: ^EntityRaw) -> Collider {
    return {
        rec = {e.px.x - f32(e.width/2), e.px.y - f32(e.height/2), f32(e.width), f32(e.height)},
        disabled = false,
    }
}

GetPoint :: proc(e: ^EntityRaw) -> Point2 {
    return VectorToPoint(e.px, {f32(e.width), f32(e.height)})
}