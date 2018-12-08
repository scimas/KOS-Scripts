RUNONCEPATH("launch.ks").
RUNONCEPATH("manoeuvre.ks").

function raiseApoapsis {
    parameter targetApoapsis.

    local manNode is NODE(TIME:SECONDS + ETA:PERIAPSIS, 0, 0, 0).
    ADD manNode.
    until ROUND(ABS(targetApoapsis - manNode:ORBIT:APOAPSIS), 0) = 0 {
        set manNode:PROGRADE to manNode:PROGRADE + LN(1 + ABS(targetApoapsis - manNode:ORBIT:APOAPSIS)).
    }
}

function raisePeriapsis {
    parameter targetPeriapsis.

    local manNode is NODE(TIME:SECONDS + ETA:APOAPSIS, 0, 0, 0).
    ADD manNode.
    until ROUND(ABS(targetPeriapsis - manNode:ORBIT:PERIAPSIS), 0) = 0 {
        set manNode:PROGRADE to manNode:PROGRADE + LN(1 + ABS(targetPeriapsis - manNode:ORBIT:PERIAPSIS)).
    }
}
