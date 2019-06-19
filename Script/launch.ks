// Script for launching a rocket
// A target orbit can be achieved or
// Can be launched to a target vessel orbit

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
    
    local turnStartApoapsis is SHIP:APOAPSIS.
    lock STEERING to HEADING(
        targetHeading,
        80 * (targetAltitude - SHIP:APOAPSIS)/(targetAltitude - turnStartAPOAPSIS)
    ).

    wait until SHIP:APOAPSIS > targetAltitude.
    lock THROTTLE to 0.
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
    wait ETA:APOAPSIS - burnTime/2.
    cancelWarp().
    lock THROTTLE to 1.
    wait until SHIP:PERIAPSIS > targetPeriapsis.
    lock THROTTLE to 0.
    wait 2.
    unlock THROTTLE.
    unlock STEERING.
}

function launch {
    parameter targetAltitude is 80000.
    parameter targetInclination is 0.
    parameter targetLAN is MOD(ORBIT:LAN + 90, 360).
    parameter targetArgP is 0.
    parameter turnStartSpeed is 60.
    
    local stageControl is FALSE.
    local engineList is LIST().
    LIST ENGINES in engineList.

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
    local targetHeading is arcsin(cos(targetInclination) / cos(SHIP:LATITUDE)).
    local vOrbit is sqrt(BODY:MU / (BODY:ATM:HEIGHT + BODY:RADIUS)).
    local vRotX is vOrbit * sin(targetHeading) - (2 * CONSTANT:PI * BODY:RADIUS) / BODY:ROTATIONPERIOD * cos(SHIP:LATITUDE).
    local vRotY is ABS(vOrbit * cos(targetHeading)).
    set targetHeading to arctan(vRotX / vRotY).
    if isAtTargetAscendingNode() {
        set targetHeading to 180 - arcsin(cos(targetInclination) / cos(SHIP:LATITUDE)).
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
