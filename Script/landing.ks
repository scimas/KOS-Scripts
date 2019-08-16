@lazyglobal off.

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
    -0.2,
    0.2
).
set throttlePID:setpoint to 0.

local isp is _avg_isp().
function derivs {
    parameter t, rv.
    
    local dr is rv[1].
    local dv is g(-rv[0]) -
    vcrs(body:angularvel, vcrs(body:angularvel, rv[0])) -
    2 * vcrs(body:angularvel, rv[1]) -
    ship:availablethrust*0.8 / rv[2] * rv[1]:normalized.
    local dm is -ship:availablethrust*0.8 / isp.

    return list(dr, dv, dm).
}

local step is 0.4.
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
    set sim_params["t0"] to t.
    until result[1]:mag < 5 {
        set sim_params["t0"] to t.
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
lock throttle to 0.8 + thr.
until alt:radar < 20 {
    local t is time:seconds.
    local ti is t.
    set result to list(-body:position, ship:velocity:surface, ship:mass).
    set sim_params["init"] to result.
    set sim_params["t0"] to t.
    until result[1]:mag < 5 {
        set sim_params["t0"] to t.
        set result to RK4(sim_params).
        set sim_params["init"] to result.
        set t to t + step.
    }
    set line to 0.
    set col to 17.
    print round(t - ti, 1) + " s" at (col, line).
    set line to 1.
    set col to 5.
    print round(agl:call(), 2) + " m" at (col, line).
    set thr to throttlePID:update(time:seconds, agl:call() - 20).
}
lock steering to up.
set thr to 0.2.
wait until ship:velocity:surface:mag < 1.5.
lock throttle to ship:mass * g():mag / ship:availablethrust.
wait until ship:status = "LANDED".
lock throttle to 0.
wait 10.
unlock steering.
unlock throttle.
clearvecdraws().
