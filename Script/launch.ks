// Script for launching a rocket
// A target orbit can be achieved or
// Can be launched to a target vessel orbit
@lazyglobal off.

runOncePath("library/lib_manoeuvre.ks").
runOncePath("library/lib_navigation.ks").
runOncePath("library/lib_utilities.ks").

function verticalAscent {
    parameter launch_params is lexicon(
        "turn_start_speed", 80
    ).

    lock steering to lookdirup(localVertical(), ship:facing:topvector).
    lock throttle to 1.

    wait until ship:velocity:surface:mag > launch_params["turn_start_speed"].
}

function gravityTurn {
    parameter launch_params is lexicon(
        "target_altitude", 80_000,
        "target_heading", { return 90. },
        "maintain_twr", 0
    ).

    local twrScale is 1.
    lock throttle to min(twrScale, 1).
    
    local turnParameter is body:atm:height.
    lock steering to heading(
        launch_params["target_heading"]:call(),
        (((turnParameter - ship:apoapsis)/turnParameter)^4 + ((turnParameter - ship:apoapsis)/turnParameter)^0.5) * 90 / 2
    ) * R(0, 0, 180).
    until ship:apoapsis > turnParameter - 500 or ship:apoapsis > launch_params["target_altitude"] {
        if launch_params["maintain_twr"] <> 0 {
            if ship:availableThrust <> 0 {
                set twrScale to launch_params["maintain_twr"] / (ship:availablethrust / (ship:mass * constant:g0)).
            }
            else {
                set twrScale to 1.
            }
        }
    }

    lock steering to  heading(launch_params["target_heading"]:call(), 5) * R(0, 0, 180).
    set twrScale to 1.
    wait until ship:apoapsis > launch_params["target_altitude"].
    
    lock throttle to 0.
}

function atmosphereExit {
    lock steering to lookdirup(surfaceTangent(), -localVertical()).
    wait until ship:altitude > body:atm:height.
}

function circularize {
    local currentOrbitSpeed is sqrt(body:mu * (2/(body:radius + ship:apoapsis) - 1/(body:radius + ship:apoapsis/2 + ship:periapsis/2))).
    local targetOrbitSpeed is sqrt(body:mu * (2/(body:radius + ship:apoapsis) - 1/(body:radius + ship:apoapsis))).
    local deltaV is targetOrbitSpeed - currentOrbitSpeed.
    local burnTime is getBurnTime(deltaV).
    print "Delta V: " + deltaV.
    print "Burn Time: " + burnTime.
    
    lock steering to lookdirup(orbitTangent(), -localVertical()).
    wait eta:apoapsis - getBurnTime(deltaV/2) - 15.
    kuniverse:timewarp:cancelWarp().
    wait 15.
    lock throttle to 1.
    wait burnTime.
    lock throttle to 0.
    wait 2.
    unlock throttle.
    unlock steering.
}

function launch {
    parameter targetAltitude is 80000.
    parameter targetInclination is ship:latitude.
    parameter turnStartSpeed is 60.
    parameter maintainTWR is 0.
    
    local launch_params is lexicon(
        "target_altitude", targetAltitude,
        "target_inclination", targetInclination,
        "turn_start_speed", turnStartSpeed,
        "maintain_twr", maintainTWR
    ).

    local stageControl is false.
    local launch_complete is false.

    local last_maxthrust is 0.
    local last_stage is stage:number.

    when ship:maxthrustat(0) <> last_maxthrust and stage:number > 0 and stageControl then {
        if stage:number = last_stage {
            wait until stage:ready.
            stage.
            wait until stage:ready.
            set last_maxthrust to ship:maxthrustat(0).
            set last_stage to stage:number.
            if launch_complete or stage:number = 0 {
                return false.
            }
            else {
                return true.
            }
        }
        else {
            set last_maxthrust to ship:maxthrustat(0).
        }
    }

    set launch_params["target_heading"] to { return azimuth(launch_params["target_inclination"], launch_params["target_altitude"]). }.
    kuniverse:timewarp:cancelWarp().
    print "Launching now".

    if SHIP:AVAILABLETHRUST = 0 {
        lock throttle to 1.
        STAGE.
        wait until stage:ready.
        set last_maxthrust to ship:maxthrustat(0).
        set last_stage to stage:number.
        set stageControl to true.
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

    set stageControl to false.
    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Launch complete".
    set launch_complete to true.
}

function primitive_launch {
    parameter targetAltitude is 80000.
    parameter targetHeading is 90.
    parameter turnStartSpeed is 60.
    
    local stageControl is false.

    when STAGE:NUMBER > 0 and stageControl = true then {
        if needsStaging() {
            wait 0.5.
            STAGE.
            wait until STAGE:READY.
        }
        if STAGE:NUMBER = 0 {
            return false.
        }
        else {
            return true.
        }
    }

    kuniverse:timewarp:cancelWarp().
    wait 2.
    print "Launching now".

    set stageControl to true.
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

    set stageControl to false.
    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Launch complete".
}
