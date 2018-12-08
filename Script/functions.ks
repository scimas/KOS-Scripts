RUNONCEPATH("launch.ks").
RUNONCEPATH("manoeuvre.ks").

function raiseApoapsis {
    parameter targetApoapsis.

    local manNode is NODE(TIME:SECONDS + ETA:PERIAPSIS, 0, 0, 0).
    ADD manNode.
    until ROUND(ABS(targetApoapsis - manNode:ORBIT:APOAPSIS), 0) = 0 {
        set manNode:PROGRADE to manNode:PROGRADE + LN(1 + ABS(targetApoapsis - manNode:ORBIT:APOAPSIS)).
    }
    local burnTime is getBurnTime(manNode:DELTAV:MAG).
    local coastTime is TIME:SECONDS + ETA:PERIAPSIS - burnTime / 2  - 15.
    local burnStartTime is TIME:SECONDS + ETA:PERIAPSIS - burnTime / 2.
    local burnStopTime is burnStartTime + burnTime.

    exec(coastTime, burnStartTime, burnStopTime, manNode).
    wait 1.
    REMOVE manNode.
}

function raisePeriapsis {
    parameter targetPeriapsis.

    local manNode is NODE(TIME:SECONDS + ETA:APOAPSIS, 0, 0, 0).
    ADD manNode.
    until ROUND(ABS(targetPeriapsis - manNode:ORBIT:PERIAPSIS), 0) = 0 {
        set manNode:PROGRADE to manNode:PROGRADE + LN(1 + ABS(targetPeriapsis - manNode:ORBIT:PERIAPSIS)).
    }
    local burnTime is getBurnTime(manNode:DELTAV:MAG).
    local coastTime is TIME:SECONDS + ETA:APOAPSIS - burnTime / 2  - 15.
    local burnStartTime is TIME:SECONDS + ETA:APOAPSIS - burnTime / 2.
    local burnStopTime is burnStartTime + burnTime.

    exec(coastTime, burnStartTime, burnStopTime, manNode).
    wait 1.
    REMOVE manNode.
}
