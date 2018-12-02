//Script for launching a rocket
//For now, doesn't support launching to a target

@lazyglobal off.

parameter targetAltitude is 80000.
parameter targetHeading is 90.
parameter turnStartSpeed is 100.
parameter profile is 0.

local stageControl is FALSE.
local engineList is LIST().
LIST ENGINES in engineList.

when stageControl = TRUE and STAGE:NUMBER > 0 then {
    for e in engineList {
        if e:FLAMEOUT {
            STAGE.
            wait until STAGE:READY.
            LIST ENGINES in engineList.
            BREAK.
        }
    }

    until SHIP:AVAILABLETHRUST <> 0 AND engineList:LENGTH > 0 {
        STAGE.
        wait until STAGE:READY.
        LIST ENGINES in engineList.
    }
    
    if STAGE:NUMBER = 0 {
        return FALSE.
    }
    else if engineList:LENGTH = 0 {
        return FALSE.
    }
    else {
        return TRUE.
    }
}

function verticalAscent {
    parameter turnStartSpeed is 80.

    lock STEERING to HEADING(targetHeading, 90).
    lock THROTTLE to 1.

    wait until SHIP:VELOCITY:SURFACE:MAG > turnStartSpeed.
}

function gravityTurn {
    parameter targetAltitude is 80000.
    parameter targetHeading is 90.
    parameter profile is 0.

    set profile to profile/10.

    local turnStartAltitude is SHIP:ALTITUDE.
    lock STEERING to HEADING(
        targetHeading,
        90 - 90 * ((SHIP:ALTITUDE - turnStartAltitude)/(targetAltitude - turnStartAltitude))^(0.5 - profile)
    ).

    wait until SHIP:APOAPSIS > targetAltitude.
    lock THROTTLE to 0.
}

function atmosphereExit {
    lock STEERING to SHIP:VELOCITY:SURFACE.
    wait until SHIP:ALTITUDE > BODY:ATM:HEIGHT.
}

function circularize {
    parameter targetAltitude is 80000.

    local r is BODY:RADIUS + SHIP:APOAPSIS.

    local targetSemimajorAxis is BODY:RADIUS + (SHIP:APOAPSIS + targetAltitude)/2.
    local currentSemimajorAxis is BODY:RADIUS + (SHIP:APOAPSIS + SHIP:PERIAPSIS)/2.

    local targetSpeed is sqrt(BODY:MU * (2/r - 1/targetSemimajorAxis)).
    local currentSpeed is sqrt(BODY:MU * (2/r - 1/currentSemimajorAxis)).

    local dV is targetSpeed - currentSpeed.

    print dV + " m/s required for orbit".

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
    
    local burnTime is SHIP:MASS * (1 - CONSTANT:E ^ (-dV / isp)) / massBurnRate.
    local coastTime is TIME:SECONDS + ETA:APOAPSIS - burnTime * 0.45.
    
    print "Burn time is " + burnTime + "s".

    lock STEERING to SHIP:VELOCITY:ORBIT.
    wait until TIME:SECONDS > coastTime.
    lock THROTTLE to 1.
    
    local burnStartTime is TIME:SECONDS.
    wait until TIME:SECONDS > burnStartTime + burnTime.
    lock THROTTLE to 0.
}

set stageControl to TRUE.
if SHIP:AVAILABLETHRUST = 0 {
    STAGE.
}

print "Starting vertical ascent".
verticalAscent(turnStartSpeed).
print "Vertical ascent complete".

print "Starting gravity turn".
gravityTurn(targetAltitude, targetHeading, profile).
print "Gravity turn complete".

print "Coasting to atmosphere exit, if it exists".
atmosphereExit().
print "Out of atmosphere".

print "Waiting for circularization burn".
circularize(targetAltitude).
print "Orbit achieved".

set stageControl to FALSE.
lock THROTTLE to 0.
unlock STEERING.
unlock THROTTLE.

print "Launch complete".
