package game

Timer :: struct {
    current: f64,
    barrier: f64,
}

NewTimer :: proc(barrier: f64) -> Timer {
    return {
        current = 0,
        barrier = barrier
    }
}

RestartTimer :: proc(timer: ^Timer) {
    timer.current = 0;
}

ReinitTimer :: proc(timer: ^Timer, barrier: f64) {
    timer.current = 0
    timer.barrier = barrier
}

CheckTimer :: proc(timer: ^Timer, time: f64) -> bool {
    timer.current += time
    return timer.current >= timer.barrier
}