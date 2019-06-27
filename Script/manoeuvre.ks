//Script to execute manoeuvres given a delta V vector and
//a time in future or a position like Ap, Pe, and
//a frame - orbit or surface

function exec {
    parameter coastTime.
    parameter burnStartTime.
    parameter burnStopTime.
    parameter manNode.

    lock STEERING to manNode:DELTAV.
    WARPTO(coastTime).
    wait until TIME:SECONDS > burnStartTime.

    lock THROTTLE to 1.
    wait until TIME:SECONDS > burnStopTime.

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
    local halfTime is getBurnTime(requiredDeltaV/2).
    local coastTime is 0.
    local burnStartTime is 0.
    local burnStopTime is 0.

    print "Burn time is " + burnTime + " s".
    local okayToBurn is true.

    if burnStart <> 0 {
        set coastTime to TIME:SECONDS + MAX(burnStart - 60, 0).
        set burnStartTime to TIME:SECONDS + burnStart.
        set burnStopTime to burnStartTime + burnTime.
        set manNode:ETA to burnStart.
    }
    else if position = "AP" {
        set coastTime to TIME:SECONDS + ETA:APOAPSIS - halfTime - 60.
        set burnStartTime to TIME:SECONDS + ETA:APOAPSIS - halfTime.
        set burnStopTime to burnStartTime + burnTime.
        set manNode:ETA to ETA:APOAPSIS.
    }
    else if position = "PE" {
        set coastTime to TIME:SECONDS + ETA:PERIAPSIS - halfTime - 60.
        set burnStartTime to TIME:SECONDS + ETA:PERIAPSIS - halfTime.
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
