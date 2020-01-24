@lazyglobal off.
parameter end_altitude is 2, sim_throttle is 0.8.

local restore_ipu is config:ipu.
set config:ipu to 1000.

clearscreen.
runoncepath("library/lib_math.ks").
runoncepath("library/lib_navigation.ks").

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
local sim_params is lexicon().
set sim_params["derivatives"] to derivs@.
set sim_params["nsteps"] to 10.
lock steering to srfretrograde.
local offset is ship:bounds:size:mag.

local line is 0.
local col is 0.
print "Landing time:          s" at (col, line).
set line to line + 1.
print "AGL:                   m" at (col, line).
local agl is { return body:altitudeof(result[0] + body:position) - body:geopositionof(result[0]):terrainheight - offset. }.
set line to line + 1.
print "Simulation time:       s" at (col, line).

until agl:call() < end_altitude or quit {
    set result to list(-body:position, ship:velocity:surface, ship:mass).
    set sim_params["init"] to result.
    local ti is time:seconds.
    local tf is getBurnTime(result[1]:mag, isp) / sim_throttle.
    local dV is result[1] + g(body:position:normalized * body:radius) * tf.
    set tf to ti + getBurnTime(dV:mag, isp) / sim_throttle.
    set sim_params["step"] to (tf - ti) / sim_params["nsteps"].
    set sim_params["t0"] to ti.
    set result to RK4(sim_params).
    set line to 0.
    set col to 14.
    print round(tf - ti, 1) at (col, line).
    set line to line + 1.
    set col to 5.
    print round(agl:call(), 2) at (col, line).
    set line to line + 1.
    set col to 17.
    print round(time:seconds - ti, 2) at (col, line).
    wait 0.
}

local thr is 0.
lock throttle to sim_throttle + thr.
until ship:velocity:surface:mag < 3 or quit {
    set result to list(-body:position, ship:velocity:surface, ship:mass).
    set sim_params["init"] to result.
    local ti is time:seconds.
    local tf is getBurnTime(result[1]:mag, isp) / sim_throttle.
    local dV is result[1] + g(body:position:normalized * body:radius) * tf.
    set tf to ti + getBurnTime(dV:mag, isp) / sim_throttle.
    set sim_params["step"] to (tf - ti) / sim_params["nsteps"].
    set sim_params["t0"] to ti.
    set result to RK4(sim_params).
    set line to 0.
    set col to 14.
    print round(tf - ti, 1) at (col, line).
    set line to line + 1.
    set col to 5.
    print round(agl:call(), 2) at (col, line).
    set line to line + 1.
    set col to 17.
    print round(time:seconds - ti, 2) at (col, line).
    set thr to throttlePID:update(time:seconds, agl:call() - end_altitude).
}

local dir is up.
local head is modulo(compassHeading() - 180, 360).
set thr to 0.
if not quit {
    lock throttle to thr.    
    lock steering to dir.
}
wait until ship:verticalspeed < -1.
until ship:status = "LANDED" or quit {
    set dir to heading(head, 88).
    set thr to ship:mass * g():mag / ship:availablethrust.
}
if not quit {
    set thr to 0.
    local landspot is ship:geoposition:position.
    local east_ref is body:geopositionof(landspot + heading(90, 0):vector):position.
    local north_ref is body:geopositionof(landspot + heading(0, 0):vector):position.
    local slopevec is vcrs(north_ref - landspot, east_ref - landspot).
    set dir to lookdirup(slopevec, ship:facing:topvector).
    wait 10.
}
unlock steering.
unlock throttle.
sas on.
set config:ipu to restore_ipu.
