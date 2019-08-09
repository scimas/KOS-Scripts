// Script for launching a rocket
// A target orbit can be achieved or
// Can be launched to a target vessel orbit
@lazyglobal off.

runOncePath("library/lib_manoeuvre.ks").
runOncePath("library/lib_navigation.ks").
runOncePath("library/lib_utilities.ks").

function verticalAscent {
    parameter launch_params is lexicon(
        "target_heading", { return 90. },
        "turn_start_speed", 80
    ).

    lock STEERING to HEADING(launch_params["target_heading"]:call(), 90).
    lock THROTTLE to 1.

    wait until SHIP:VELOCITY:SURFACE:MAG > launch_params["turn_start_speed"].
}

function gravityTurn {
    parameter launch_params is lexicon(
        "target_altitude", 80_000,
        "target_heading", { return 90. },
        "maintain_twr", 0
    ).

    local twrScale is 1.
    lock THROTTLE to min(twrScale, 1).
    
    local turnParameter is BODY:ATM:HEIGHT * 0.7.
    lock STEERING to HEADING(
        launch_params["target_heading"]:call(),
        ((90 / turnParameter^4) * (turnParameter - SHIP:ALTITUDE)^4 + (90 / turnParameter^0.5) * (turnParameter - SHIP:ALTITUDE)^0.5)/2
    ).
    until SHIP:ALTITUDE > turnParameter - 100 or SHIP:APOAPSIS > launch_params["target_altitude"] {
        if launch_params["maintain_twr"] <> 0 {
            if ship:availableThrust <> 0 {
                set twrScale to launch_params["maintain_twr"] / (SHIP:AVAILABLETHRUST / (SHIP:MASS * BODY:MU / (BODY:RADIUS + SHIP:ALTITUDE) ^ 2)).
            }
            else {
                set twrScale to 1.
            }
        }
        wait 0.
    }

    lock STEERING to  HEADING(launch_params["target_heading"]:call(), 0).
    until SHIP:APOAPSIS > launch_params["target_altitude"] {
        if launch_params["maintain_twr"] <> 0 {
            if ship:availableThrust <> 0 {
                set twrScale to launch_params["maintain_twr"] / (SHIP:AVAILABLETHRUST / (SHIP:MASS * BODY:MU / (BODY:RADIUS + SHIP:ALTITUDE) ^ 2)).
            }
            else {
                set twrScale to 1.
            }
        }
        wait 0.
    }
    
    lock THROTTLE to 0.
}

function atmosphereExit {
    lock STEERING to SHIP:VELOCITY:SURFACE.
    wait until SHIP:ALTITUDE > BODY:ATM:HEIGHT.
}

function circularize {
    local currentOrbitSpeed is sqrt(BODY:MU * (2/(BODY:RADIUS + SHIP:APOAPSIS) - 1/(BODY:RADIUS + SHIP:APOAPSIS/2 + SHIP:PERIAPSIS/2))).
    local targetOrbitSpeed is sqrt(BODY:MU * (2/(BODY:RADIUS + SHIP:APOAPSIS) - 1/(BODY:RADIUS + SHIP:APOAPSIS))).
    local deltaV is targetOrbitSpeed - currentOrbitSpeed.
    local burnTime is getBurnTime(deltaV).
    print "Delta V: " + deltaV.
    print "Burn Time: " + burnTime.
    
    lock STEERING to orbitTangent().
    wait ETA:APOAPSIS - getBurnTime(deltaV/2) - 15.
    kuniverse:timewarp:cancelWarp().
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
    parameter targetInclination is ship:latitude.
    parameter turnStartSpeed is 60.
    parameter maintainTWR is 0.
    parameter targetLAN is MOD(ORBIT:LAN + 90, 360).
    
    local launch_params is lexicon(
        "target_altitude", targetAltitude,
        "target_inclination", targetInclination,
        "turn_start_speed", turnStartSpeed,
        "maintain_twr", maintainTWR,
        "target_lan", targetLAN
    ).

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

    set launch_params["target_heading"] to { return azimuth(launch_params["target_inclination"], launch_params["target_altitude"]). }.
    kuniverse:timewarp:cancelWarp().
    print "Launching now".

    set stageControl to TRUE.
    if SHIP:AVAILABLETHRUST = 0 {
        STAGE.
    }

    print "Starting vertical ascent".
    verticalAscent(launch_params).
    print "Vertical ascent complete".

    print "Starting gravity turn".
    gravityTurn(launch_params).
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

    kuniverse:timewarp:cancelWarp().
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
