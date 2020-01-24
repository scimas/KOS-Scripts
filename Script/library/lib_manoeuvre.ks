@LAZYGLOBAL OFF.

function execute {
    parameter coastTime.
    parameter burnTime.

    local current_time is time:seconds.
    local adjustment_time is current_time + nextnode:eta - coastTime.
    wait until time:seconds > adjustment_time.
    lock steering to nextnode:deltaV.
    kuniverse:timewarp:cancelwarp().
    wait nextnode:eta.
    local guidance_end is time:seconds + burnTime * 0.99.
    local burn_end is time:seconds + burnTime.
    kuniverse:timewarp:cancelwarp().
    
    lock throttle to 1.
    wait until time:seconds > guidance_end.
    lock steering to ship:facing.
    wait until time:seconds > burn_end.
    lock throttle to 0.

    wait 1.
    unlock steering.
    unlock throttle.
}
