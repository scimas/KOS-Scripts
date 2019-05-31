global lock orbitTangent to SHIP:VELOCITY:ORBIT:NORMALIZED.
global lock orbitBinormal to VCRS(-BODY:POSITION, orbitTangent):NORMALIZED.
global lock orbitNormal to VCRS(orbitBinormal, orbitTangent):NORMALIZED.
global lock orbitLAN to ANGLEAXIS(ORBIT:LAN, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.

global lock surfaceTangent to SHIP:VELOCITY:surface:NORMALIZED.
global lock surfaceBinormal to VCRS(-BODY:POSITION, surfaceTangent):NORMALIZED.
global lock surfaceNormal to VCRS(surfaceBinormal, surfaceTangent):NORMALIZED.
global lock surfaceLAN to ANGLEAXIS(ORBIT:LAN - 90, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.

function cancelWarp {
    until kuniverse:TimeWarp:RATE = 1 {
        set WARP to WARP - 1.
        wait until kuniverse:TimeWarp:RATE = kuniverse:TimeWarp:RATELIST[WARP].
    }
    wait until SHIP:UNPACKED AND SHIP:LOADED.
}

function orbitFromTarget {
    if defined TARGET {
        global lock targetApoapsis to TARGET:ORBIT:APOAPSIS.
        global lock targetPeriapsis to TARGET:ORBIT:PERIAPSIS.
        global lock targetInclination to TARGET:ORBIT:INCLINATION.
        global lock targetLAN to ANGLEAXIS(TARGET:ORBIT:LAN, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.
        global lock targetBinormal to (-ANGLEAXIS(targetInclination, targetLAN) * BODY:ANGULARVEL):NORMALIZED.
        global lock targetARGP to (ANGLEAXIS(TARGET:ORBIT:ARGUMENTOFPERIAPSIS, targetBinormal) * targetLAN):NORMALIZED.
        return TRUE.
    }
    else {
        return FALSE.
    }
}

function modulo {
    parameter a.
    parameter n.

    return a - ABS(n) * FLOOR(a/ABS(n)).
}