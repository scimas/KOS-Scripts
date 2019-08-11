@LAZYGLOBAL OFF.

function execute {
    parameter coastTime.
    parameter burnStartTime.
    parameter burnTime.

    kuniverse:timewarp:warpto(time:seconds + coastTime).

    lock steering to nextnode:deltaV.
    wait until time:seconds > burnStartTime - 0.1.
    
    lock throttle to 1.
    wait burnTime - 0.05.
    
    lock throttle to 0.
    unlock steering.
    unlock throttle.
}
