@lazyglobal off.

parameter wpname is "0".

clearscreen.

local guiding is false.
local handlePitch is false.
local handleRoll is false.
local quit is false.

local wp is 0.
lock rollAngle to VANG(UP:VECTOR, SHIP:FACING:TOPVECTOR) * VDOT(VCRS(SHIP:FACING:TOPVECTOR, UP:VECTOR), SHIP:FACING:VECTOR).

local rollPID is PIDLOOP(
    0.1,
    0.04,
    0.02,
    -1,
    1
).
set rollPID:SETPOINT to 0.

local pitchPID is PIDLoop(
    0.01,
    0.008,
    0.005,
    -1,
    1
).
set pitchPID:SETPOINT to 0.

on AG6 {
    if guiding {
        set guiding to false.
    }
    else {
        set guiding to true.
        set wp to WAYPOINT(wpname).
    }
    return true.
}

on AG7 {
    if handlePitch {
        set handlePitch to false.
        pitchPID:RESET().
        set SHIP:CONTROL:NEUTRALIZE to true.
    }
    else {
        set handlePitch to true.
    }
    return true.
}

on AG9 {
    if handleRoll {
        set handleRoll to false.
        rollPID:RESET().
        set SHIP:CONTROL:NEUTRALIZE to true.
    }
    else {
        set handleRoll to true.
    }
    return true.
}

on AG10 {
    set quit to true.
}

print "Pitch" at (0, 0).
print "Roll" at (14, 0).
local head is 0.
local headN is 0.
local headD is 0.
until quit {
    if handlePitch {
        set SHIP:CONTROL:PITCH to pitchPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
        print "On " at (0, 4).
    }
    else {
        print "Off" at (0, 4).
    }
    if handleRoll {
        set SHIP:CONTROL:ROLL to rollPID:UPDATE(TIME:SECONDS, rollAngle).
        print "On " at (14, 4).
    }
    else {
        print "Off" at (14, 4).
    }
    if guiding {
        set headN to cos(wp:GEOPOSITION:LAT) * sin(wp:GEOPOSITION:LNG - SHIP:LONGITUDE).
        set headD to cos(SHIP:LATITUDE) * sin(wp:GEOPOSITION:LAT) - sin(SHIP:LATITUDE) * cos(wp:GEOPOSITION:LAT) * cos(wp:GEOPOSITION:LNG - SHIP:LONGITUDE).
        set head to mod(arctan2(headN, headD) + 360, 360).
    }
    if not (handlePitch or handleRoll) {
        wait 0.25.
    }
    print ROUND(SHIP:VERTICALSPEED, 3) at (0, 1).
    print ROUND(pitchPID:OUTPUT, 3) at (0, 2).
    print ROUND(rollAngle, 3) at (14, 1).
    print ROUND(rollPID:OUTPUT, 3) at (14, 2).
    print "Heading " + head at (0, 5).
    wait 0.
}

set SHIP:CONTROL:NEUTRALIZE to true.
unlock rollAngle.
