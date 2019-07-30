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
    local angle is ship:longitude - (orbit:LAN - body:rotationAngle).
    if ship:status = "LANDED" {
        return angle - 90.
    }
    else {
        return angle.
    }
}

function angleToBodyDescendingNode {
    local angle is ship:longitude - mod(orbit:LAN - body:rotationAngle + 180, 360).
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
