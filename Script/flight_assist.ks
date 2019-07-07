@lazyglobal off.

clearscreen.

local handleRoll is false.
local quit is false.

lock rollAngle to VANG(UP:VECTOR, SHIP:FACING:TOPVECTOR) * VDOT(VCRS(SHIP:FACING:TOPVECTOR, UP:VECTOR), SHIP:FACING:VECTOR).

local rollPID is PIDLOOP(
    0.1,
    0.02,
    0.02,
    -0.5,
    0.5
).

set rollPID:SETPOINT to 0.

on AG10 {
    if handleRoll {
        set handleRoll to false.
        rollPID:RESET().
        set SHIP:CONTROL:NEUTRALIZE to true.
        clearscreen.
        print "Roll to you." at (0, 3).
    }
    else {
        set handleRoll to true.
        clearscreen.
        print "Handling roll now." at (0, 3).
    }
    return true.
}

on AG9 {
    set quit to true.
}

until quit {
    if handleRoll {
        set SHIP:CONTROL:ROLL to rollPID:UPDATE(TIME:SECONDS, rollAngle).
    }
    else {
        wait 0.25.
    }
    print rollAngle at (0, 0).
    print rollPID:OUTPUT at (0, 1).
    wait 0.
}

set SHIP:CONTROL:NEUTRALIZE to true.
unlock rollAngle.
