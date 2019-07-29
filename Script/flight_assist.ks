@LAZYGLOBAL OFF.

parameter wpname is "0".

clearscreen.
runpath("lib_Navigation.ks").

function rollAngle {
    return vang(localVertical(), vxcl(surfaceTangent(), ship:facing:starvector)).
}

local guiding is FALSE.
local handlePitch is FALSE.
local handleRoll is FALSE.
local quit is FALSE.

local wp is 0.
local change is 0.

local rollPID is pidLoop(
    0.02,
    0.005,
    0.008,
    -1,
    1
).
set rollPID:setpoint to 0.

local pitchPID is pidLoop(
    0.005,
    0.0016,
    0.001,
    -1,
    1
).
set pitchPID:setpoint to SHIP:verticalSpeed.

on AG6 {
    if guiding {
        set guiding to FALSE.
    }
    else {
        set guiding to TRUE.
        set wp to waypoint(wpname).
    }
    return TRUE.
}

on AG7 {
    if handlePitch {
        set handlePitch to FALSE.
        pitchPID:reset().
        set ship:control:neutralize to TRUE.
    }
    else {
        set handlePitch to TRUE.
        set pitchPID:setpoint to round(ship:verticalSpeed, 0).
    }
    return TRUE.
}

on AG9 {
    if handleRoll {
        set handleRoll to FALSE.
        rollPID:reset().
        set ship:control:neutralize to TRUE.
    }
    else {
        set handleRoll to TRUE.
        set rollPID:setpoint to round(rollAngle(), 0).
    }
    return TRUE.
}

on AG10 {
    set quit to TRUE.
}

print "Pitch" at (0, 0).
print "Roll" at (14, 0).
local head is 0.
local headN is 0.
local headD is 0.
until quit {
    if handlePitch {
        set ship:control:pitch to pitchPID:update(time:seconds, ship:verticalSpeed).
        print "On " at (0, 4).
    }
    else {
        print "Off" at (0, 4).
    }
    if handleRoll {
        set ship:control:roll to rollPID:update(time:seconds, rollAngle()).
        print "On " at (14, 4).
    }
    else {
        print "Off" at (14, 4).
    }
    if guiding {
        set headN to cos(wp:geoposition:lat) * sin(wp:geoposition:lng - ship:longitude).
        set headD to cos(ship:latitude) * sin(wp:geoPosition:lat) - sin(ship:latitude) * cos(wp:geoPosition:lat) * cos(wp:geoPosition:lng - ship:longitude).
        set head to mod(arctan2(headN, headD) + 360, 360).
    }
    if not (handlePitch or handleRoll) {
        wait 0.25.
    }
    if terminal:input:haschar() {
        set change to terminal:input:getchar().
        if change = "w" {
            set pitchPID:setpoint to pitchPID:setpoint - 1.
        }
        else if change = "s" {
            set pitchPID:setpoint to pitchPID:setpoint + 1.
        }
        else if change = "x" {
            set pitchPID:setpoint to 0.
        }
        else if change = "q" {
            set rollPID:setpoint to rollPID:setpoint - 1.
        }
        else if change = "e" {
            set rollPID:setpoint to rollPID:setpoint + 1.
        }
        else if change = "r" {
            set rollPID:setpoint to 0.
        }
        else if change = "b" {
            toggle BRAKES.
        }
        else if change = "g" {
            toggle GEAR.
        }
        else if change = "7" {
            toggle AG7.
        }
        else if change = "9" {
            toggle AG9.
        }
    }
    print round(ship:verticalSpeed, 3) at (0, 1).
    print round(pitchPID:output, 3) at (0, 2).
    print round(rollAngle(), 3) at (14, 1).
    print round(rollPID:output, 3) at (14, 2).
    print "Heading " + head at (0, 5).
    wait 0.
}

set ship:control:neutralize to TRUE.
