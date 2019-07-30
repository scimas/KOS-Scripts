@LAZYGLOBAL OFF.

function getBurnTime {
    parameter deltaV.
    
    if deltaV:typename() = "Vector" {
        set deltaV to deltaV:mag.
    }
    local burnEngines is list().
    list engines in burnEngines.
    local massBurnRate is 0.
    local g0 is 9.80665.
    for e in burnEngines {
        if e:ignition {
            set massBurnRate to massBurnRate + e:availableThrust/(e:ISP * g0).
        }
    }
    local isp is ship:availablethrust / massBurnRate.
    
    local burnTime is ship:mass * (1 - CONSTANT:E ^ (-deltaV / isp)) / massBurnRate.
    return burnTime.
}

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
