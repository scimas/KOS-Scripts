global lock orbitTangent to SHIP:VELOCITY:ORBIT:NORMALIZED.
global lock orbitBinormal to VCRS(SHIP:BODY:POSITION, orbitTangent):NORMALIZED.
global lock orbitNormal to VCRS(orbitTangent, orbitBinormal):NORMALIZED.

global lock surfaceTangent to SHIP:VELOCITY:surface:NORMALIZED.
global lock surfaceBinormal to VCRS(SHIP:BODY:POSITION, surfaceTangent):NORMALIZED.
global lock surfaceNormal to VCRS(surfaceTangent, surfaceBinormal):NORMALIZED.

function cancelWarp {
    until kuniverse:TimeWarp:RATE = 1 {
        set WARP to WARP - 1.
        wait until kuniverse:TimeWarp:RATE = kuniverse:TimeWarp:RATELIST[WARP].
    }
    wait until SHIP:UNPACKED AND SHIP:LOADED.
}
