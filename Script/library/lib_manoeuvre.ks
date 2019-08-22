@LAZYGLOBAL OFF.

function execute {
    parameter coastTime.
    parameter burnStartTime.
    parameter burnTime.

    lock steering to nextnode:deltaV.
    wait until time:seconds > coastTime.
    kuniverse:timewarp:cancelwarp.
    wait until time:seconds > burnStartTime - 0.1.
    
    lock throttle to 1.
    wait until time:seconds > burnStartTime + burnTime - 1.
    lock steering to ship:facing.
    wait 1.
    
    lock throttle to 0.
    unlock steering.
    unlock throttle.
}
