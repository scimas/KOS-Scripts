@LAZYGLOBAL OFF.

function orbitTangent {
    return ship:velocity:orbit:normalized.
}

function orbitBinormal {
    return vcrs(-body:position, orbitTangent()):normalized.
}

function orbitNormal {
    return vcrs(orbitBinormal(), orbitTangent()):normalized.
}

function orbitLAN {
    return angleAxis(orbit:LAN, body:angularVel) * solarPrimeVector.
}

function surfaceTangent {
    return ship:velocity:surface:normalized.
}

function surfaceBinormal {
    return vcrs(-body:position, surfaceTangent()):normalized.
}

function surfaceNormal {
    return vcrs(surfaceBinormal(), surfaceTangent()):normalized.
}

function surfaceLAN {
    return angleAxis(orbit:LAN - 90, body:angularVel) * solarPrimeVector.
}

function localVertical {
    return up:vector.
}

function pitchAngle {
    return 90 - vang(ship:facing:vector, localVertical()).
}

function yawAngle {
    local tangent is orbitTangent().
    if body:atm:exists and ship:altitude < body:atm:height {
        set tangent to surfaceTangent().
    }
    return vang(vxcl(localVertical(), ship:facing:vector), tangent).
}

function rollAngle {
    local tangent is orbitTangent().
    if body:atm:exists and ship:altitude < body:atm:height {
        set tangent to surfaceTangent().
    }
    return vang(localVertical(), vxcl(tangent, ship:facing:starvector)) - 90.
}

function targetTangent {
    return target:velocity:orbit:normalized.
}

function targetBinormal {
    return vcrs(target:position - target:body:position, targetTangent()):normalized.
}

function targetNormal {
    return vcrs(targetBinormal(), targetTangent()):normalized.
}

function targetLAN {
    return angleAxis(target:orbit:LAN, target:body:angularVel) * solarPrimeVector.
}

function angleToBodyAscendingNode {
    local angle is vang(-body:position, orbitLAN()).
    if ship:status = "LANDED" {
        return angle - 90.
    }
    else {
        return angle.
    }
}

function angleToBodyDescendingNode {
    local angle is vang(-body:position, -orbitLAN()).
    if ship:status = "LANDED" {
        return angle - 90.
    }
    else {
        return angle.
    }
}

function angleToRelativeAscendingNode {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is vcrs(orbitBinormal, targetBinormal).
    return vang(-body:position, joinVector).
}

function angleToRelativeDescendingNode {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is -vcrs(orbitBinormal, targetBinormal).
    return vang(-body:position, joinVector).
}

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

function greatCircleHeading {
    parameter point.    // Should be GeoCoordinates, a waypoint or a vessel
    local spot is 0.
    if point:typename() = "Waypoint" {
        set spot to point:geoPosition.
    }
    else if point:typename() = "Vessel" {
        set spot to point:body:geoPositionOf(point).
    }
    
    local headN is cos(spot:lat) * sin(spot:lng - ship:longitude).
    local headD is cos(ship:latitude) * sin(spot:lat) - sin(ship:latitude) * cos(spot:lat) * cos(spot:lng - ship:longitude).
    local head is mod(arctan2(headN, headD) + 360, 360).
    return head.
}
