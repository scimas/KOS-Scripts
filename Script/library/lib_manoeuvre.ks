@LAZYGLOBAL OFF.

function execute {
    parameter coastTime.
    parameter burnTime.

    local current_time is time:seconds.
    local adjustment_time is current_time + nextnode:eta - coastTime.
    wait until time:seconds > adjustment_time.
    lock steering to nextnode:deltaV.
    kuniverse:timewarp:cancelwarp().
    local tick1 is time:seconds.
    wait 0.
    local tick2 is time:seconds.
    local phys_delta is tick2 - tick1.
    wait nextnode:eta - phys_delta.
    local burn_end is time:seconds + burnTime - phys_delta.
    kuniverse:timewarp:cancelwarp().
    
    lock throttle to 1.
    wait until time:seconds > burn_end.
    lock throttle to 0.

    wait 1.
    unlock steering.
    unlock throttle.
}
