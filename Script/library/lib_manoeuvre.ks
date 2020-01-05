@LAZYGLOBAL OFF.

function execute {
    parameter coastTime.
    parameter burnTime.

    wait nextnode:eta - coastTime.
    lock steering to nextnode:deltaV.
    kuniverse:timewarp:cancelwarp().
    wait nextnode:eta.
    kuniverse:timewarp:cancelwarp().
    
    lock throttle to 1.
    wait burnTime - 1.
    lock steering to ship:facing.
    wait 1.
    lock throttle to 0.

    wait 1.
    unlock steering.
    unlock throttle.
}
