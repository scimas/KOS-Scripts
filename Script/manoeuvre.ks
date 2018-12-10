//Script to execute manoeuvres given a delta V vector and
//a time in future or a position like Ap, Pe, and
//a frame - orbit or surface
RUNONCEPATH("utilities.ks").

function getBurnTime {
    parameter deltaV.
    
    local burnEngines is LIST().
    LIST ENGINES in burnEngines.
    local massBurnRate is 0.
    local g0 is 9.80665.
    for e in burnEngines {
        if e:IGNITION {
            set massBurnRate to massBurnRate + e:AVAILABLETHRUST/(e:ISP * g0).
        }
    }
    local isp is SHIP:AVAILABLETHRUST / massBurnRate.
    
    local burnTime is SHIP:MASS * (1 - CONSTANT:E ^ (-deltaV / isp)) / massBurnRate.
    return burnTime.
}

function exec {
    parameter coastTime.
    parameter burnStartTime.
    parameter burnStopTime.
    parameter manNode.

    lock STEERING to manNode:DELTAV.
    WARPTO(coastTime).
    wait until TIME:SECONDS > burnStartTime.

    lock THROTTLE to 1.
    wait until manNode:DELTAV:MAG < 1.

    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Manoeuvre executed".
}

function manoeuvre {
    parameter dV_tangent is 0.
    parameter dV_normal is 0.
    parameter dV_binormal is 0.
    parameter burnStart is 0.
    parameter position is "NONE".
//    parameter frame is "ORBIT".

    local manNode is NODE(TIME:SECONDS + 1, dV_normal, dV_binormal, dV_tangent).
    
    local requiredDeltaV is V(dV_tangent, dV_normal, dV_binormal):MAG.
    local burnTime is getBurnTime(requiredDeltaV).
    local coastTime is 0.
    local burnStartTime is 0.
    local burnStopTime is 0.

    print "Burn time is " + burnTime + " s".
    local okayToBurn is true.

    if burnStart <> 0 {
        set coastTime to TIME:SECONDS + MAX(burnStart - 15, 0).
        set burnStartTime to TIME:SECONDS + burnStart.
        set burnStopTime to burnStartTime + burnTime.
        set manNode:ETA to burnStart.
    }
    else if position = "AP" {
        set coastTime to TIME:SECONDS + ETA:APOAPSIS - burnTime / 2 - 15.
        set burnStartTime to TIME:SECONDS + ETA:APOAPSIS - burnTime / 2.
        set burnStopTime to burnStartTime + burnTime.
        set manNode:ETA to ETA:APOAPSIS.
    }
    else if position = "PE" {
        set coastTime to TIME:SECONDS + ETA:PERIAPSIS - burnTime / 2 - 15.
        set burnStartTime to TIME:SECONDS + ETA:PERIAPSIS - burnTime / 2.
        set burnStopTime to burnStartTime + burnTime.
        set manNode:ETA to ETA:PERIAPSIS.
    }
    else {
        print "Invalid position argument".
        set okayToBurn to false.
    }

    if okayToBurn {
        ADD manNode.
        lock STEERING to manNode:DELTAV.
        exec(coastTime, burnStartTime, burnStopTime, manNode).
        REMOVE manNode.
    }
    else {
        print "One or more arguments were invalid".
        print "Exiting without executing manoeuvre".
    }
}