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

function mass_execute {
    parameter adjustment_time, after_burn_mass.

    local coast_time is nextnode:eta - adjustment_time.
    wait coast_time.
    kuniverse:timewarp:cancelwarp().
    local burnvector is nextNode:deltav.
    lock steering to burnvector.
    wait adjustment_time.

    local burnEngines is list().
    list engines in burnEngines.
    local massBurnRate is 0.
    for e in burnEngines {
        if e:ignition {
            set massBurnRate to massBurnRate + e:availableThrust/(e:ISP * constant:g0).
        }
    }

    local throt is 1.
    lock throttle to throt.
    local tick is time:seconds.
    local tock is time:seconds.
    until ship:mass <= after_burn_mass {
        set tock to time:seconds.
        local req_mass_change is ship:mass - after_burn_mass.
        // Will the next two ticks change more mass than required?
        if 10 * massBurnRate * (tock - tick) > req_mass_change {
            // Then reduce throttle so that it will only change a fifth of the required change in one tick.
            set throt to req_mass_change / massBurnRate / (tock - tick) / 10.
        } else if hasnode {
            set burnvector to nextnode:deltav.
        }
        set tick to tock.
        wait 0.
    }
    unlock throttle.
    unlock steering.
}
