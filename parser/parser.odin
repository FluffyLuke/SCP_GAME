package parser

import "core:encoding/json"
import "core:os"
import "core:fmt"
import "core:mem"

main :: proc()
{
    ConfigAlloc()

    l: MyLevels
    if json_data, ok := os.read_entire_file("./levels/levels.ldtk"); ok {
        if json.unmarshal(json_data, &l) == nil {
            // my_struct now contains
            // the data from my_struct_file.
            fmt.println("It worked: ", l.__header__.fileType)
            fmt.println(l)
        } else {
            fmt.println("Failed to unmarshal JSON")
        }
    } else {
        fmt.println("Failed to read my_struct_file")
    }
    
}

ConfigAlloc :: proc()
{
    // Configure allocator
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer 
    {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }
}