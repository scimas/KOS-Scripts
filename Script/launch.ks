//Script for launching a rocket
//For now, doesn't support launching to a target

function launch {
    parameter targetAltitude is 80000.
    parameter targetInclination is 0.
    parameter targetLAN is MOD(ORBIT:LAN + 90, 360).
    parameter turnStartSpeed is 100.
    parameter profile is 0.

    print "Waiting for launch window".
    wait until ROUND(MOD(ORBIT:LAN - targetLAN + 360, 360), 0) = 90 OR
               ROUND(MOD(ORBIT:LAN - targetLAN - 180 + 360, 360), 0) = 90.
    cancelWarp().
    wait 2.
    print "Launching now".

    local targetHeading is 90.
    if ABS(targetInclination) >= ABS(SHIP:LATITUDE) {
        if targetInclination <= 90 {
            set targetHeading to arcsin(cos(targetInclination) / cos(SHIP:LATITUDE)).
        }
        else if targetInclination <= 180 {
            set targetHeading to arcsin(cos(targetInclination) / cos(SHIP:LATITUDE)) + 360.
        }
        else {
            set targetHeading to arcsin(cos(targetInclination - 180) / cos(SHIP:LATITUDE)) + 180.
        }
    }
    else {
        set targetHeading to 90.
    }
    local vOrbit is sqrt(BODY:MU / (BODY:ATM:HEIGHT + BODY:RADIUS)).
    local vRotX is vOrbit * sin(targetHeading) - (2 * CONSTANT:PI * BODY:RADIUS) / BODY:ROTATIONPERIOD * cos(SHIP:LATITUDE).
    local vRotY is vOrbit * cos(targetHeading).
    set targetHeading to arctan(vRotX / vRotY).

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

        raisePeriapsis(SHIP:APOAPSIS - 100).
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
}