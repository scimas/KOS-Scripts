@lazyglobal off.
parameter end_altitude is 20, sim_throttle is 0.8, step is 2.

clearscreen.
runoncepath("/library/lib_math.ks").
runoncepath("/library/lib_navigation.ks").

local quit is false.
on AG10 {
    set quit to true.
}

local throttlePID is pidloop(
    0.01,
    0,
    0.001,
    sim_throttle - 1,
    1 - sim_throttle
).
set throttlePID:setpoint to 0.

local isp is _avg_isp().
function derivs {
    parameter t, rv.
    
    local dr is rv[1].
    local dv is g(-rv[0]) -
    vcrs(body:angularvel, vcrs(body:angularvel, rv[0])) -
    2 * vcrs(body:angularvel, rv[1]) -
    ship:availablethrust*sim_throttle / rv[2] * rv[1]:normalized.
    local dm is -ship:availablethrust*sim_throttle / isp.

    return list(dr, dv, dm).
}

local result is list(-body:position, ship:velocity:surface, ship:mass).
clearvecdraws().
local prediction is vecdraw(V(0,0,0), { return result[0] + body:position. }, red, "Final Position", 1, true, 0.5).
local sim_params is lexicon().
set sim_params["derivatives"] to derivs@.
set sim_params["step"] to step.
lock steering to srfretrograde.

local line is 0.
local col is 0.
print "Landing time: " at (col, line).
set line to line + 1.
print "AGL: " at (col, line).
local agl is { return body:altitudeof(result[0] + body:position) - body:geopositionof(result[0]):terrainheight. }.
set line to line + 1.
print "Simulation time: " at (col, line).

until agl:call() < ship:groundspeed or quit {
    set line to 0.
    local t is time:seconds.
    local ti is t.
    set result to list(-body:position, ship:velocity:surface, ship:mass).
    set sim_params["init"] to result.
    until result[1]:mag < 5 {
        set sim_params["t"] to t.
        set result to RK4(sim_params).
        set sim_params["init"] to result.
        set t to t + step.
    }
    set col to 14.
    print round(t - ti, 1) + " s" at (col, line).
    set line to line + 1.
    set col to 5.
    print round(agl:call(), 2) + " m" at (col, line).
    set line to line + 1.
    set col to 17.
    print round(time:seconds - ti, 2) + " s" at (col, line).
    wait 0.
}

set step to step/2.
set sim_params["step"] to step.
local thr is 0.
lock throttle to sim_throttle + thr.
until alt:radar < end_altitude or quit {
    set line to 0.
    local t is time:seconds.
    local ti is t.
    set result to list(-body:position, ship:velocity:surface, ship:mass).
    set sim_params["init"] to result.
    until result[1]:mag < 5 {
        set sim_params["t"] to t.
        set result to RK4(sim_params).
        set sim_params["init"] to result.
        set t to t + step.
    }
    set col to 14.
    print round(t - ti, 1) + " s" at (col, line).
    set line to line + 1.
    set col to 5.
    print round(agl:call(), 2) + " m" at (col, line).
    set line to line + 1.
    set col to 17.
    print round(time:seconds - ti, 2) + " s" at (col, line).
    set thr to throttlePID:update(time:seconds, agl:call() - end_altitude).
}

set thr to 1.
lock throttle to thr.
local dir is srfretrograde.
lock steering to dir.
until ship:status = "LANDED" or quit {
    if ship:verticalspeed > 0 {
        set dir to srfretrograde.
        set thr to 0.
    }
    else if ship:verticalspeed < -1.5 or ship:groundspeed > 1.5 {
        set dir to srfretrograde.
        set thr to 1.
    }
    else {
        set dir to lookdirup(up:vector, vxcl(up:vector, srfprograde:vector):normalized).
        set thr to ship:mass * g():mag / ship:availablethrust.
    }
}
if not quit {
    set thr to 0.
    wait 5.
}
unlock steering.
unlock throttle.
clearvecdraws().
