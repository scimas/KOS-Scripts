@LAZYGLOBAL OFF.

runOncePath("lib_navigation.ks").
runOncePath("lib_math.ks").

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

    local coast_time is max(nextnode:eta - adjustment_time, 0).
    wait coast_time.
    kuniverse:timewarp:cancelwarp().
    local node is nextNode.
    local burnvector is node:deltav.
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
    local tock is tick.
    wait 0.
    until ship:mass <= after_burn_mass {
        set tock to time:seconds.
        local phy_delta is tock - tick.
        local req_mass_burn_rate is (ship:mass - after_burn_mass) / phy_delta.
        // If burning at higher rate than required in one physics tick
        if massBurnRate > req_mass_burn_rate {
            // Then reduce throttle so that it will only burn the required fuel in one tick
            set throt to req_mass_burn_rate / massBurnRate.
        }
        if hasnode and abs(node:deltav:mag - nextNode:deltav:mag) < 0.001 {
            set burnvector to nextnode:deltav.
        } else {
            local tangent is orbitTangent().
            local tangent_angle is vang(tangent, ship:facing:vector).
            local normal is orbitNormal().
            local normal_angle is vang(normal, ship:facing:vector).
            local binormal is orbitBinormal().
            local binormal_angle is vang(binormal, ship:facing:vector).
            if tangent_angle < 0.1 or (180 - tangent_angle) < 0.1 {
                set burnvector to tangent * sign(vdot(tangent, ship:facing:vector)).
            } else if normal_angle < 0.1 or (180 - normal_angle) < 0.1 {
                set burnvector to normal * sign(vdot(normal, ship:facing:vector)).
            } else if binormal_angle < 0.1 or (180 - binormal_angle) < 0.1 {
                set burnvector to binormal * sign(vdot(binormal, ship:facing:vector)).
            } else {
                set burnvector to ship:facing:vector.
            }
        }
        set tick to tock.
        wait 0.
    }
    unlock throttle.
    unlock steering.
}
