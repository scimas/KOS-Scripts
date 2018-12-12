function raiseApoapsis {
    parameter targetApoapsis.

    local singleDigitPower is 0.
    until ROUND(targetApoapsis / 10^singleDigitPower, 0) = 0 {
        set singleDigitPower to singleDigitPower + 1.
    }
    set singleDigitPower to singleDigitPower - 1.
    local manNode is NODE(TIME:SECONDS + ETA:PERIAPSIS, 0, 0, 0).
    ADD manNode.
    until ROUND(ABS(targetApoapsis - manNode:ORBIT:APOAPSIS), 0) < 100 {
        set manNode:PROGRADE to manNode:PROGRADE + 
            LN(1 + (targetApoapsis - manNode:ORBIT:APOAPSIS) / 10^singleDigitPower).
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

    local singleDigitPower is 0.
    until ROUND(targetPeriapsis / 10^singleDigitPower, 0) = 0 {
        set singleDigitPower to singleDigitPower + 1.
    }
    set singleDigitPower to singleDigitPower - 1.
    local manNode is NODE(TIME:SECONDS + ETA:APOAPSIS, 0, 0, 0).
    ADD manNode.
    until ROUND(ABS(targetPeriapsis - manNode:ORBIT:PERIAPSIS), 0) < 100 {
        set manNode:PROGRADE to manNode:PROGRADE + 
            LN(1 + (targetPeriapsis - manNode:ORBIT:PERIAPSIS) / 10^singleDigitPower).
    }
    local burnTime is getBurnTime(manNode:DELTAV:MAG).
    local coastTime is TIME:SECONDS + ETA:APOAPSIS - burnTime / 2  - 15.
    local burnStartTime is TIME:SECONDS + ETA:APOAPSIS - burnTime / 2.
    local burnStopTime is burnStartTime + burnTime.

    exec(coastTime, burnStartTime, burnStopTime, manNode).
    wait 1.
    REMOVE manNode.
}

function isAtBodyAscendingNode {
    return ROUND(MOD(ORBIT:LAN - BODY:ROTATIONANGLE - SHIP:LONGITUDE, 360), 0) = 0 AND 
           ROUND(SHIP:LATITUDE, 0) = 0.
}

function isAtBodyDescendingNode {
    return ROUND(MOD(ORBIT:LAN - BODY:ROTATIONANGLE - SHIP:LONGITUDE - 180, 360), 0) = 0 AND 
           ROUND(SHIP:LATITUDE, 0) = 0.
}
