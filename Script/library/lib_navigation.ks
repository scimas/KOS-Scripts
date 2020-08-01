@LAZYGLOBAL OFF.

// Same as orbital prograde vector for ves
function orbitTangent {
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}

// Normalized acceleration vector, typically corresponds to radial-in
function orbitNormal {
    parameter ves is ship.

    local g is ves:body:mu / ves:body:position:sqrmagnitude * ves:body:position:normalized.
    local thrust_vec is V(0, 0, 0).
    // TODO: change ves:loaded to ves:unpacked in case reading engine properties
    // needs unpacked vessels.
    if (kuniverse:activevessel() = ves and throttle <> 0) or ves:loaded {
        list engines in eng_list.
        for e in eng_list {
            if e:ignition {
                set thrust_vec to thrust_vec + e:thrust * e:facing:vector.
            }
        }
    }
    return (g + thrust_vec):normalized.
}

// Forms left handed orthogonal reference frame with orbitTangent and orbitNormal
function orbitBinormal {
    parameter ves is ship.

    return vcrs(orbitTangent(ves), orbitNormal(ves)).
}

// Vector pointing in the direction of longitude of ascending node
function orbitLAN {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN, ves:body:angularVel) * solarPrimeVector.
}

// Same as surface prograde vector for ves
function surfaceTangent {
    parameter ves is ship.

    return ves:velocity:surface:normalized.
}

// In the direction of surface angular momentum of ves
function surfaceBinormal {
    parameter ves is ship.

    return vcrs(ves:position - ves:body:position, surfaceTangent(ves)):normalized.
}

// Perpedicular to  both tangent and binormal, typically radially inward
function surfaceNormal {
    parameter ves is ship.

    return vcrs(surfaceBinormal(ves), surfaceTangent(ves)):normalized.
}

// Vector pointing in the direction of longitude of ascending node
function surfaceLAN {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN - 90, ves:body:angularVel) * solarPrimeVector.
}

// Vector directly away from the body at ves' position
function localVertical {
    parameter ves is ship.

    return ves:up:vector.
}

function localHorizontal {
    parameter ves is ship.

    local tangent is orbitTangent(ves).
    if ves:status = "LANDED" or (ves:body:atm:exists and ves:altitude < ves:body:atm:height) {
        set tangent to surfaceTangent(ves).
    }

    return vxcl(localVertical(), tangent):normalized.
}

function pitchAngle {
    return 90 - vang(ship:facing:vector, localVertical()).
}

function yawAngle {
    return vang(localHorizontal(), vxcl(localVertical(), ship:facing:starvector)) - 90.
}

function rollAngle {
    return vang(localVertical(), vxcl(localHorizontal(), ship:facing:starvector)) - 90.
}

function compassHeading {
    local lh is localHorizontal().
    local head is vang(lh, north:vector).
    if vdot(vcrs(north:vector, lh), up:vector) < 0 {
        set head to 360 - head.
    }
    return head.
}

// Angle to ascending node with respect to ves' body's equator
function angleToBodyAscendingNode {
    parameter ves is ship.

    local angle is vang(ves:position - ves:body:position, orbitLAN(ves)).
    if ves:status = "LANDED" {
        return angle - 90.
    }
    else {
        return angle.
    }
}

// Angle to descending node with respect to ves' body's equator
function angleToBodyDescendingNode {
    parameter ves is ship.

    local angle is vang(ves:position - ves:body:position, -orbitLAN(ves)).
    if ves:status = "LANDED" {
        return angle - 90.
    }
    else {
        return angle.
    }
}

// Angle to relative ascending node determined from args
function angleToRelativeAscendingNode {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is vcrs(orbitBinormal, targetBinormal).
    return vang(-body:position, joinVector).
}

// Angle to relative descending node determined from args
function angleToRelativeDescendingNode {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is -vcrs(orbitBinormal, targetBinormal).
    return vang(-body:position, joinVector).
}

// Orbital phase angle with assumed target
// Positive when you are behind the target, negative when ahead
function phaseAngle {
    local common_ancestor is 0.
    local my_ancestors is list().
    local your_ancestors is list().

    my_ancestors:add(ship:body).
    until not(my_ancestors[my_ancestors:length-1]:hasBody) {
        my_ancestors:add(my_ancestors[my_ancestors:length-1]:body).
    }
    your_ancestors:add(ship:body).
    until not(your_ancestors[your_ancestors:length-1]:hasBody) {
        your_ancestors:add(your_ancestors[your_ancestors:length-1]:body).
    }

    for my_ancestor in my_ancestors {
        local found is false.
        for your_ancestor in your_ancestors {
            if my_ancestor = your_ancestor {
                set common_ancestor to my_ancestor.
                set found to true.
                break.
            }
        }
        if found {
            break.
        }
    }

    local vel is ship:velocity:orbit.
    local my_ancestor is my_ancestors[0].
    until my_ancestor = common_ancestor {
        set vel to vel + my_ancestor:velocity:orbit.
        set my_ancestor to my_ancestor:body.
    }
    local binormal is vcrs(-common_ancestor:position, vel):normalized.

    local phase is vang(-common_ancestor:position, target:position - common_ancestor:position).
    local signVector is vcrs(-common_ancestor:position, target:position - common_ancestor:position).
    local sign is vdot(binormal, signVector).
    if sign < 0 {
        return -phase.
    }
    else {
        return phase.
    }
}

// Instantaneous heading to go from current postion to a final position along the geodesic
function greatCircleHeading {
    parameter point.    // Should be GeoCoordinates, a waypoint, a vector or any orbitable
    local spot is latlng(0, 0).

    if point:typename() = "GeoCoordinates" {
        set spot to point.
    }
    else if point:istype("Orbitable") or point:istype("Waypoint") {
        set spot to point:geoPosition.
    }
    else if point:typename() = "Vector" {
        set spot to body:geoPositionOf(point).
    }
    else {
        return -1.
    }
    
    local head is spot:heading.
    return head.
}

// Average Isp calculation
function _avg_isp {
    local burnEngines is list().
    list engines in burnEngines.
    local massBurnRate is 0.
    for e in burnEngines {
        if e:ignition {
            set massBurnRate to massBurnRate + e:availableThrust/(e:ISP * constant:g0).
        }
    }
    local isp is -1.
    if massBurnRate <> 0 {
        set isp to ship:availablethrust / massBurnRate.
    }
    return isp.
}

// Burn time from rocket equation
function getBurnTime {
    parameter deltaV.
    parameter isp is 0.

    if deltaV:typename() = "Vector" {
        set deltaV to deltaV:mag.
    }
    if isp = 0 {
        set isp to _avg_isp().
    }
    
    local burnTime is -1.
    if ship:availablethrust <> 0 {
        set burnTime to ship:mass * (1 - CONSTANT:E ^ (-deltaV / isp)) / (ship:availablethrust / isp).
    }
    return burnTime.
}

// Instantaneous azimuth
function azimuth {
    parameter inclination.
    parameter orbit_alt.
    parameter auto_switch is false.

    if abs(inclination) < abs(ship:latitude) {
        set inclination to ship:latitude.
    }

    local head is arcsin(cos(inclination) / cos(ship:latitude)).
    if auto_switch {
        if angleToBodyDescendingNode(ship) < angleToBodyAscendingNode(ship) {
            set head to 180 - head.
        }
    }
    else if inclination < 0 {
        set head to 180 - head.
    }
    local vOrbit is sqrt(body:mu / (orbit_alt + body:radius)).
    local vRotX is vOrbit * sin(head) - min(vdot(ship:velocity:orbit, heading(90, 0):vector), vOrbit).
    local vRotY is vOrbit * cos(head) - min(vdot(ship:velocity:orbit, heading(0, 0):vector), vOrbit).
    set head to 90 - arctan2(vRotY, vRotX).
    return mod(head + 360, 360).
}

// Gravitational acceleration here
function g {
    parameter pos is body:position.

    return body:mu/pos:sqrmagnitude * pos:normalized.
}
