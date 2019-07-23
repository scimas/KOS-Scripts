// Script for launching a rocket
// A target orbit can be achieved or
// Can be launched to a target vessel orbit
@lazyglobal off.

function verticalAscent {
    parameter targetHeading is 90.
    parameter turnStartSpeed is 80.

    lock STEERING to HEADING(targetHeading, 90).
    lock THROTTLE to 1.

    wait until SHIP:VELOCITY:SURFACE:MAG > turnStartSpeed.
}

function gravityTurn {
    parameter targetAltitude is 80000.
    parameter targetHeading is 90.
    parameter maintainTWR is false.
    parameter targetTWR is 0.
    
    lock twrScale to 1.
    if maintainTWR {
        lock twrScale to targetTWR / (SHIP:AVAILABLETHRUST / (SHIP:MASS * BODY:MU / BODY:RADIUS ^ 2)).
    }
    lock THROTTLE to min(twrScale, 1).

    local turnParameter is BODY:ATM:HEIGHT * 0.7.
    lock STEERING to HEADING(
        targetHeading,
        ((90 / turnParameter^4) * (turnParameter - SHIP:ALTITUDE)^4 + (90 / turnParameter^0.5) * (turnParameter - SHIP:ALTITUDE)^0.5)/2
    ).
    wait until SHIP:ALTITUDE > turnParameter - 100 or SHIP:APOAPSIS > targetAltitude.

    lock STEERING to  HEADING(targetHeading, 0).
    wait until SHIP:APOAPSIS > targetAltitude.
    
    lock THROTTLE to 0.
    unlock twrScale.
}

function atmosphereExit {
    lock STEERING to SHIP:VELOCITY:SURFACE.
    wait until SHIP:ALTITUDE > BODY:ATM:HEIGHT.
}

function circularize {
    parameter targetHeading is -1.
    local targetPeriapsis is SHIP:APOAPSIS.
    local currentOrbitSpeed is sqrt(BODY:MU * (2/(BODY:RADIUS + SHIP:APOAPSIS) - 1/(BODY:RADIUS + SHIP:APOAPSIS/2 + SHIP:PERIAPSIS/2))).
    local targetOrbitSpeed is sqrt(BODY:MU * (2/(BODY:RADIUS + SHIP:APOAPSIS) - 1/(BODY:RADIUS + SHIP:APOAPSIS))).
    local deltaV is targetOrbitSpeed - currentOrbitSpeed.
    local burnTime is getBurnTime(deltaV).
    print "Delta V: " + deltaV.
    print "Burn Time: " + burnTime.
    if targetHeading = -1 {
        lock STEERING to orbitTangent().
    }
    else {
        lock STEERING to HEADING(
            targetHeading,
            90 - VANG(UP:VECTOR, orbitTangent())
        ).
    }
    wait ETA:APOAPSIS - getBurnTime(deltaV/2) - 15.
    cancelWarp().
    wait 15.
    lock THROTTLE to 1.
    wait burnTime.
    lock THROTTLE to 0.
    wait 2.
    unlock THROTTLE.
    unlock STEERING.
}

function launch {
    parameter targetAltitude is 80000.
    parameter targetInclination is SHIP:LATITUDE.
    parameter atAN is false.
    parameter turnStartSpeed is 60.
    parameter maintainTWR is false.
    parameter targetTWR is 0.
    parameter targetLAN is MOD(ORBIT:LAN + 90, 360).
    
    local stageControl is FALSE.

    when STAGE:NUMBER > 0 and stageControl = TRUE then {
        if needsStaging() {
            wait 0.5.
            STAGE.
            wait until STAGE:READY.
        }
        if STAGE:NUMBER = 0 {
            return FALSE.
        }
        else {
            return TRUE.
        }
    }

    local targetHeading is arcsin(cos(targetInclination) / cos(SHIP:LATITUDE)).
    if atAN {
        set targetHeading to 90 + (90 - targetHeading).
    }
    local vOrbit is sqrt(BODY:MU / (BODY:ATM:HEIGHT + BODY:RADIUS)).
    local vRotX is vOrbit * sin(targetHeading) - (2 * CONSTANT:PI * BODY:RADIUS) / BODY:ROTATIONPERIOD * cos(SHIP:LATITUDE).
    local vRotY is vOrbit * cos(targetHeading).
    set targetHeading to arctan2(vRotX, vRotY).
    cancelWarp().
    wait 2.
    print "Launching now".

    set stageControl to TRUE.
    if SHIP:AVAILABLETHRUST = 0 {
        STAGE.
    }

    print "Starting vertical ascent".
    verticalAscent(targetHeading, turnStartSpeed).
    print "Vertical ascent complete".

    print "Starting gravity turn".
    gravityTurn(targetAltitude, targetHeading, maintainTWR, targetTWR).
    print "Gravity turn complete".

    print "Coasting to atmosphere exit, if it exists".
    atmosphereExit().
    print "Out of atmosphere".

    print "Waiting for circularization burn".
    circularize().
    print "Entered orbit".

    set stageControl to FALSE.
    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Launch complete".
}

function launchToTarget {
    parameter targetAltitude is 100000.
    parameter turnStartSpeed is 60.

    orbitFromTarget().

    local stageControl is FALSE.

    when STAGE:NUMBER > 0 and stageControl = TRUE then {
        if needsStaging() {
            wait 0.5.
            STAGE.
            wait until STAGE:READY.
        }
        if STAGE:NUMBER = 0 {
            return FALSE.
        }
        else {
            return TRUE.
        }
    }

    print "Waiting for launch window".
    wait until isAtTargetAscendingNode() or isAtTargetDescendingNode().
    local targetHeading is arcsin(cos(targetInclination()) / cos(SHIP:LATITUDE)).
    local vOrbit is sqrt(BODY:MU / (BODY:ATM:HEIGHT + BODY:RADIUS)).
    local vRotX is vOrbit * sin(targetHeading) - (2 * CONSTANT:PI * BODY:RADIUS) / BODY:ROTATIONPERIOD * cos(SHIP:LATITUDE).
    local vRotY is ABS(vOrbit * cos(targetHeading)).
    set targetHeading to arctan(vRotX / vRotY).
    if isAtTargetAscendingNode() {
        set targetHeading to 180 - arcsin(cos(targetInclination()) / cos(SHIP:LATITUDE)).
    }
    cancelWarp().
    wait 2.
    print "Launching now".

    set stageControl to TRUE.
    if SHIP:AVAILABLETHRUST = 0 {
        STAGE.
    }

    print "Starting vertical ascent".
    verticalAscent(targetHeading, turnStartSpeed).
    print "Vertical ascent complete".

    print "Starting gravity turn".
    gravityTurn(targetAltitude, targetHeading).
    print "Gravity turn complete".

    print "Coasting to atmosphere exit, if it exists".
    atmosphereExit().
    print "Out of atmosphere".

    print "Waiting for circularization burn".
    circularize(targetHeading).
    print "Entered orbit".

    set stageControl to FALSE.
    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Launch complete".
}

function primitive_launch {
    parameter targetAltitude is 80000.
    parameter targetHeading is 90.
    parameter turnStartSpeed is 60.
    
    local stageControl is FALSE.

    when STAGE:NUMBER > 0 and stageControl = TRUE then {
        if needsStaging() {
            wait 0.5.
            STAGE.
            wait until STAGE:READY.
        }
        if STAGE:NUMBER = 0 {
            return FALSE.
        }
        else {
            return TRUE.
        }
    }

    cancelWarp().
    wait 2.
    print "Launching now".

    set stageControl to TRUE.
    if SHIP:AVAILABLETHRUST = 0 {
        STAGE.
    }

    verticalAscent(targetHeading, turnStartSpeed).
    lock STEERING to HEADING(targetHeading, 85).
    
    wait until SHIP:ALTITUDE > 2_000.
    lock STEERING to HEADING(targetHeading, 75).

    wait until SHIP:ALTITUDE > 5_000.
    lock STEERING to HEADING(targetHeading, 70).

    wait until SHIP:ALTITUDE > 8_000.
    lock STEERING to HEADING(targetHeading, 60).

    wait until SHIP:ALTITUDE > 11_000.
    lock STEERING to HEADING(targetHeading, 50).

    wait until SHIP:ALTITUDE > 14_000.
    lock STEERING to HEADING(targetHeading, 45).

    wait until SHIP:ALTITUDE > 20_000.
    lock STEERING to HEADING(targetHeading, 40).

    wait until SHIP:ALTITUDE > 30_000.
    lock STEERING to HEADING(targetHeading, 30).

    wait until SHIP:ORBIT:APOAPSIS > 50_000.
    lock STEERING to HEADING(targetHeading, 15).

    wait until SHIP:ORBIT:APOAPSIS > 70_000.
    lock STEERING to HEADING(targetHeading, 0).

    wait until SHIP:ORBIT:APOAPSIS > targetAltitude.
    lock THROTTLE to 0.
    
    print "Coasting to atmosphere exit, if it exists.".
    atmosphereExit().
    print "Out of atmosphere".

    print "Waiting for circularization burn".
    circularize().
    print "Entered orbit".

    set stageControl to FALSE.
    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Launch complete".
}
