//Script to execute manoeuvres given a delta V vector and
//a time in future or a position like Ap, Pe, and
//a frame - orbit or surface

@lazyglobal off.

parameter dV_tangent is 0.
parameter dV_normal is 0.
parameter dV_binormal is 0.
parameter burnStart is 0.
parameter position is "NONE".
parameter frame is "ORBIT".

function getBurnTime {
    parameter dV.
    
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
    return burnTime.
}

local dir_tangent is V(0, 0, 0).
local dir_normal is V(0, 0, 0).
local dir_binormal is V(0, 0, 0).
local dV is V(0, 0, 0).

if frame = "ORBIT" {
    lock dir_tangent to SHIP:VELOCITY:ORBIT:NORMALIZED.
}
else if frame = "SURFACE" {
    lock dir_tangent to SHIP:VELOCITY:SURFACE:NORMALIZED.
}

lock dir_binormal to VCRS(BODY:POSITION, dir_tangent):NORMALIZED.
lock dir_normal to VCRS(dir_tangent, dir_binormal):NORMALIZED.

lock dV to (dV_tangent * dir_tangent) + (dV_normal * dir_normal) + (dV_binormal * dir_binormal).
lock STEERING to dV.

local burnTime is getBurnTime(dV:MAG).
local coastTime is 0.
local burnStartTime is 0.
local burnStopTime is 0.

print "Burn time is " + burnTime + " s".

if burnStart <> 0 {
    set coastTime to TIME:SECONDS + MAX(burnStart - 15, 0).
    set burnStartTime to TIME:SECONDS + burnStart.
    set burnStopTime to burnStartTime + burnTime.
}
else if position = "Ap" {
    set coastTime to TIME:SECONDS + MAX(ETA:APOAPSIS - burnTime * 0.45 - 15, 0).
    set burnStartTime to TIME:SECONDS + ETA:APOAPSIS - burnTime * 0.45.
    set burnStopTime to burnStartTime + burnTime.
}
else if position = "Pe" {
    set coastTime to TIME:SECONDS + MAX(ETA:PERIAPSIS - burnTime * 0.45 - 15, 0).
    set burnStartTime to TIME:SECONDS + ETA:PERIAPSIS - burnTime * 0.45.
    set burnStopTime to burnStartTime + burnTime.
}
else {
    print "Invalid position argument".
    return.
}

TIMEWARP:WARPTO(coastTime).
wait until TIME:SECONDS > burnStartTime.

LOCK THROTTLE to 1.
wait until TIME:SECONDS > burnStopTime.

print "Manoeuvre executed".
