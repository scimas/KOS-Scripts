@LAZYGLOBAL OFF.

function execute {
    // Extra time before burn start to get the ship pointed at the node
    parameter coastTime.
    parameter burnTime.

    local current_time is time:seconds.
    local adjustment_time is current_time + nextnode:eta - coastTime.
    lock steering to nextnode:deltaV.
    wait until time:seconds > adjustment_time.
    // Cancel warp for coastTime
    kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled.
    // Take a measurement of the physics tick duration.
    local tick1 is time:seconds.
    wait 0.
    local tick2 is time:seconds.
    local phys_delta is tick2 - tick1.

    wait nextnode:eta - phys_delta.
    kuniverse:timewarp:cancelwarp().    
    lock throttle to 1.
    // Change steering lock one tick before burn end (workaround for Principia
    // deleting manoeuvres)
    wait burnTime - phys_delta.
    lock steering to ship:facing.
    wait 0.
    lock throttle to 0.
    
    unlock steering.
    unlock throttle.
    // Force a tick before any other code
    wait 0.
}
