@lazyglobal off.

parameter point is 0.

clearscreen.
runoncepath("library/lib_navigation.ks").
runoncepath("library/lib_math.ks").

local quit is false.
local handleYaw is false.
local handleThrottle is false.
local guiding is false.
local head is 0.
local distance is 0.
local turn is 0.
local comp_head is 0.
local offset is 0.
local change is 0.

local yawPID is pidloop(
    0.01,
    0.005,
    0.005,
    -0.25,
    0.25
).
set yawPID:setpoint to 0.

local accelerationPID is pidloop(
    1,
    0.05,
    0.1,
    -1,
    1
).
set accelerationPID:setpoint to 0.

local throttlePID is pidloop(
    0.1,
    0.005,
    0.03,
    -0.99,
    0.99
).
set throttlePID:setpoint to 0.

local width is 400.
local window is gui(width).
local control_layout is window:addhlayout().
local yaw_box is control_layout:addvbox().
local yaw_label is yaw_box:addlabel("Yaw Angle").
local yaw_values is yaw_box:addhlayout().
local yaw_value is yaw_values:addlabel("0").
local yaw_change is yaw_values:addtextfield("0").
local yaw_button is yaw_box:addbutton("Turn On").
local yaw_update is yaw_box:addbutton("Update").
local throttle_box is control_layout:addvbox().
local throttle_label is throttle_box:addlabel("Speed").
local throttle_values is throttle_box:addhlayout().
local throttle_value is throttle_values:addlabel("0").
local throttle_change is throttle_values:addtextfield("0").
local throttle_button is throttle_box:addbutton("Turn On").
local throttle_update is throttle_box:addbutton("Update").
local nav_box is window:addvbox().
local waylist is nav_box:addpopupmenu().
local head_label is nav_box:addlabel("Heading").
local head_value is nav_box:addlabel("-").
local distance_value is nav_box:addlabel("-").
local head_button is nav_box:addbutton("Turn On").

set yaw_box:style:width to width/4.
set yaw_label:style:align to "LEFT".
set yaw_value:style:align to "RIGHT".
set throttle_box:style:width to width/4.
set throttle_label:style:align to "LEFT".
set throttle_value:style:align to "RIGHT".
set head_label:style:align to "LEFT".
set head_value:style:align to "RIGHT".
set distance_value:style:align to "RIGHT".

for wp in allWaypoints() {
    waylist:addoption(wp).
}
set waylist:maxvisible to 5.
window:show().

function yaw_button_function {
    if handleYaw {
        set yaw_button:text to "Turn On".
        yawPID:reset().
        set ship:control:neutralize to true.
    }
    else {
        set yaw_button:text to "Turn Off".
        set offset to round(compassHeading()).
    }
    set handleYaw to not(handleYaw).
}
function yaw_update_function {
    set offset to yaw_change:text:toscalar().
}
function throttle_button_function {
    if handleThrottle {
        set throttle_button:text to "Turn On".
        accelerationPID:reset().
        throttlePID:reset().
        set ship:control:neutralize to true.
    }
    else {
        set throttle_button:text to "Turn Off".
        set accelerationPID:setpoint to ship:velocity:surface:mag.
        set throttlePID:setpoint to accelerationPID:output.
    }
    set handleThrottle to not(handleThrottle).
}
function throttle_update_function {
    set accelerationPID:setpoint to throttle_change:text:toscalar().
}
function head_button_function {
    if guiding {
        set head_button:text to "Turn On".
    }
    else {
        set point to waylist:value.
        set head_button:text to "Turn Off".
    }
    set guiding to not(guiding).
}
function waylist_function {
    parameter wp.
    set point to wp.
}
set yaw_button:onclick to yaw_button_function@.
set yaw_update:onclick to yaw_update_function@.
set throttle_button:onclick to throttle_button_function@.
set throttle_update:onclick to throttle_update_function@.
set head_button:onclick to head_button_function@.
set waylist:onchange to waylist_function@.

on AG7 {
    head_button_function().
    return true.
}
on AG8 {
    throttle_button_function().
    return true.
}
on AG9 {
    yaw_button_function().
    return true.
}
on AG10 {
    set quit to true.
}

until quit {
    if ship:status <> "LANDED" {
        set ship:control:neutralize to true.
        local dir is lookdirup(localHorizontal(), localVertical()).
        lock steering to dir.
        local p1 is ship:geoposition:position.
        local p2 is (p1 + localHorizontal()):geoposition:position.
        local p3 is (p1 + surfaceBinormal()):geoposition:position.
        local perpendicular is vcrs(p2 - p1, p3 - p1):normalized.
        until ship:status = "LANDED" {
            set p1 to ship:geoposition:position.
            set p2 to (p1 + localHorizontal()):geoposition:position.
            set p3 to (p1 + surfaceBinormal()):geoposition:position.
            set perpendicular to vcrs(p2 - p1, p3 - p1):normalized.
            set dir to lookdirup(vxcl(perpendicular, surfaceTangent()), perpendicular).
            wait 0.
        }
        unlock steering.
    }
    if handleYaw {
        set comp_head to compassHeading().
        set turn to min(modulo(offset - comp_head, 360), modulo(comp_head - offset, 360)).
        if modulo(comp_head + turn, 360) = offset {
            set ship:control:wheelsteer to yawPID:update(time:seconds, -turn).
        }
        else {
            set ship:control:wheelsteer to yawPID:update(time:seconds, turn).
        }
    }
    if handleThrottle {
        set throttlePID:setpoint to accelerationPID:update(
            time:seconds,
            ship:velocity:surface:mag * (choose 1 if vdot(ship:velocity:surface, ship:facing:vector) > 0 else -1)
        ).
        set ship:control:wheelthrottle to throttlePID:update(time:seconds, accelerationPID:changerate).
        if not(brakes) and accelerationPID:setpoint = 0 and ship:velocity:surface:mag < 0.2 {
            set brakes to true.
        }
        if brakes and accelerationPID:setpoint <> 0 {
            set brakes to false.
        }
    }
    if guiding {
        set head to greatCircleHeading(point).
        set distance to point:geoposition:distance.
    }
    if not (handleYaw or handleThrottle) {
        wait 0.25.
    }
    if terminal:input:haschar() {
        set change to terminal:input:getchar().
        if change = "j" {
            set offset to modulo(offset - 1, 360).
            set yaw_change:text to offset:tostring().
        }
        else if change = "l" {
            set offset to modulo(offset + 1, 360).
            set yaw_change:text to offset:tostring().
        }
        else if change = "f" {
            set offset to round(compassHeading()).
            set yaw_change:text to offset:tostring().
        }
        else if change = "k" {
            set accelerationPID:setpoint to accelerationPID:setpoint - 1.
            set throttle_change:text to round(accelerationPID:setpoint):tostring().
        }
        else if change = "i" {
            set accelerationPID:setpoint to accelerationPID:setpoint + 1.
            set throttle_change:text to round(accelerationPID:setpoint):tostring().
        }
        else if change = "x" {
            set accelerationPID:setpoint to 0.
            set throttle_change:text to "0".
        }
        else if change = "b" {
            toggle BRAKES.
        }
        else if change = "g" {
            toggle GEAR.
        }
        else if change = "7" {
            toggle AG7.
        }
        else if change = "8" {
            toggle AG8.
        }
        else if change = "9" {
            toggle AG9.
        }
        else if change = "0" {
            toggle AG10.
        }
    }
    set yaw_value:text to round(compassHeading(), 1):tostring().
    set throttle_value:text to round(ship:velocity:surface:mag, 1):tostring().
    set head_value:text to round(head, 1):tostring().
    set distance_value:text to round(distance):tostring().
    wait 0.
}

set ship:control:neutralize to true.
window:hide().
window:dispose().
