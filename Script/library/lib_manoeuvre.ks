@LAZYGLOBAL OFF.

function execute {
    parameter coastTime.
    parameter burnStartTime.
    parameter burnTime.

    wait until time:seconds > coastTime.
    kuniverse:timewarp:cancelwarp().

    lock steering to nextnode:deltaV.
    wait until time:seconds > burnStartTime - 0.05.
    
    lock throttle to 1.
    wait burnTime.
    
    lock throttle to 0.
    unlock steering.
    unlock throttle.
}
