// Match orbit to a given target
// Currently only matches orbit with a target

function match_orbit {
    parameter targetOrbit.

    print "Raising apoapsis to " + targetOrbit["APOAPSIS"] + " m".
    raiseApoapsis(targetOrbit["APOAPSIS"]).
    wait 5.
    print "Raising periapsis to " + targetOrbit["PERIAPSIS"] + " m".
    raisePeriapsis(targetOrbit["PERIAPSIS"]).
    wait 5.
    wait until isAtTargetAscendingNode() or isAtTargetDescendingNode().
    cancelWarp().
    if isAtTargetAscendingNode() {
        lock STEERING to -orbitBinormal.
        lock THROTTLE to 1.
        wait until ROUND(ORBIT:INCLINATION, 1) = ROUND(targetOrbit["INCLINATION"], 1).
        lock THROTTLE to 0.
        wait 1.
        unlock STEERING.
        unlock THROTTLE.
    }
    else {
        lock STEERING to orbitBinormal.
        lock THROTTLE to 1.
        wait until ROUND(ORBIT:INCLINATION, 1) = ROUND(targetOrbit["INCLINATION"], 1).
        lock THROTTLE to 0.
        wait 1.
        unlock STEERING.
        unlock THROTTLE.
    }
}
