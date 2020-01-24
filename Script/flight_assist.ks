@LAZYGLOBAL OFF.

parameter point is 0.

clearscreen.
runOncePath("library/lib_navigation.ks").

local guiding is false.
local handleThrottle is false.
local handlePitch is false.
local handleRoll is false.
local handleYaw is false.
local quit is false.

local change is 0.

local rollPID is pidloop(
    0.02,
    0.005,
    0.008,
    -1,
    1
).
set rollPID:setpoint to 0.

local pitchPID is pidloop(
    0.008,
    0.002,
    0.002,
    -1,
    1
).
set pitchPID:setpoint to ship:verticalspeed.

local accelerationPID is pidloop(
    0.5,
    0.005,
    0.03,
    -10,
    10
).
set accelerationPID:setpoint to 0.

local throttlePID is pidloop(
    0.1,
    0.008,
    0.01,
    0.01,
    0.99
).
set throttlePID:setpoint to 0.

local yawPID is pidloop(
    0.02,
    0.005,
    0.008,
    -1,
    1
).
set yawPID:setpoint to 0.

local width is 400.
local window is gui(width).
local control_layout is window:addhlayout().
local pitch_box is control_layout:addvbox().
local pitch_label is pitch_box:addlabel("Vert Speed").
local pitch_values is pitch_box:addhlayout().
local pitch_value is pitch_values:addlabel("0").
local pitch_change is pitch_values:addtextfield("0").
local pitch_button is pitch_box:addbutton("Turn On").
local pitch_update is pitch_box:addbutton("Update").
local roll_box is control_layout:addvbox().
local roll_label is roll_box:addlabel("Roll Angle").
local roll_values is roll_box:addhlayout().
local roll_value is roll_values:addlabel("0").
local roll_change is roll_values:addtextfield("0").
local roll_button is roll_box:addbutton("Turn On").
local roll_update is roll_box:addbutton("Update").
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

set pitch_box:style:width to width/4.
set pitch_label:style:align to "LEFT".
set pitch_value:style:align to "RIGHT".
set roll_box:style:width to width/4.
set roll_label:style:align to "LEFT".
set roll_value:style:align to "RIGHT".
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

function pitch_button_function {
    if handlePitch {
        set pitch_button:text to "Turn On".
        pitchPID:reset().
        set ship:control:neutralize to true.
    }
    else {
        set pitch_button:text to "Turn Off".
        set pitchPID:setpoint to round(ship:verticalSpeed).
    }
    set handlePitch to not(handlePitch).
}
function pitch_update_function {
    set pitchPID:setpoint to pitch_change:text:toscalar().
}
function roll_button_function {
    if handleRoll {
        set roll_button:text to "Turn On".
        rollPID:reset().
        set ship:control:neutralize to true.
    }
    else {
        set roll_button:text to "Turn Off".
        set rollPID:setpoint to round(rollAngle()).
    }
    set handleRoll to not(handleRoll).
}
function roll_update_function {
    set rollPID:setpoint to roll_change:text:toscalar().
}
function yaw_button_function {
    if handleYaw {
        set yaw_button:text to "Turn On".
        yawPID:reset().
        set ship:control:neutralize to true.
    }
    else {
        set yaw_button:text to "Turn Off".
        set yawPID:setpoint to round(yawAngle()).
    }
    set handleYaw to not(handleYaw).
}
function yaw_update_function {
    set yawPID:setpoint to yaw_change:text:toscalar().
}
function throttle_button_function {
    if handleThrottle {
        set throttle_button:text to "Turn On".
        accelerationPID:reset().
        throttlePID:reset().
        set ship:control:pilotmainthrottle to ship:control:mainthrottle.
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
        set head_button:text to "Turn Off".
    }
    set guiding to not(guiding).
}
function waylist_function {
    parameter wp.
    set point to wp.
}
set pitch_button:onclick to pitch_button_function@.
set pitch_update:onclick to pitch_update_function@.
set roll_button:onclick to roll_button_function@.
set roll_update:onclick to roll_update_function@.
set yaw_button:onclick to yaw_button_function@.
set yaw_update:onclick to yaw_update_function@.
set throttle_button:onclick to throttle_button_function@.
set throttle_update:onclick to throttle_update_function@.
set head_button:onclick to head_button_function@.
set waylist:onchange to waylist_function@.

on AG5 {
    head_button_function().
    return true.
}
on AG6 {
    throttle_button_function().
    return true.
}
on AG7 {
    pitch_button_function().
    return true.
}
on AG8 {
    roll_button_function().
    return true.
}
on AG9 {
    yaw_button_function().
    return true.
}
on AG10 {
    set quit to true.
}

print "Speed: AG6".
print "Pitch: AG7".
print "Roll:  AG8".
print "Yaw:   AG9".

local head is 0.
local distance is 0.

until quit {
    if handlePitch {
        set ship:control:pitch to pitchPID:update(time:seconds, ship:verticalSpeed).
    }
    if handleRoll {
        set ship:control:roll to rollPID:update(time:seconds, rollAngle()).
    }
    if handleYaw {
        set ship:control:yaw to yawPID:update(time:seconds, yawAngle()).
    }
    if handleThrottle {
        set throttlePID:setpoint to accelerationPID:update(time:seconds, ship:velocity:surface:mag).
        set ship:control:mainthrottle to throttlePID:update(time:seconds, accelerationPID:changerate).
    }
    if guiding {
        set head to greatCircleHeading(point).
        set distance to point:geoposition:distance.
    }
    if not (handlePitch or handleRoll or handleYaw or handleThrottle) {
        wait 0.25.
    }
    if terminal:input:haschar() {
        set change to terminal:input:getchar().
        if change = "w" {
            set pitchPID:setpoint to pitchPID:setpoint - 1.
            set pitch_change:text to pitchPID:setpoint:tostring().
        }
        else if change = "s" {
            set pitchPID:setpoint to pitchPID:setpoint + 1.
            set pitch_change:text to pitchPID:setpoint:tostring().
        }
        else if change = "x" {
            set pitchPID:setpoint to 0.
            set pitch_change:text to "0".
        }
        else if change = "q" {
            set rollPID:setpoint to rollPID:setpoint - 1.
            set roll_change:text to rollPID:setpoint:tostring().
        }
        else if change = "e" {
            set rollPID:setpoint to rollPID:setpoint + 1.
            set roll_change:text to rollPID:setpoint:tostring().
        }
        else if change = "r" {
            set rollPID:setpoint to 0.
            set roll_change:text to "0".
        }
        else if change = "a" {
            set yawPID:setpoint to yawPID:setpoint - 1.
            set yaw_change:text to yawPID:setpoint:tostring().
        }
        else if change = "d" {
            set yawPID:setpoint to yawPID:setpoint + 1.
            set yaw_change:text to yawPID:setpoint:tostring().
        }
        else if change = "f" {
            set yawPID:setpoint to 0.
            set yaw_change:text to "0".
        }
        else if change = "n" {
            set accelerationPID:setpoint to accelerationPID:setpoint - 1.
            set throttle_change:text to round(accelerationPID:setpoint):tostring().
        }
        else if change = "h" {
            set accelerationPID:setpoint to accelerationPID:setpoint + 1.
            set throttle_change:text to round(accelerationPID:setpoint):tostring().
        }
        else if change = "b" {
            toggle BRAKES.
            set accelerationPID:setpoint to 0.
            set throttle_change:text to "0".
        }
        else if change = " " {
            stage.
        }
        else if change = "g" {
            toggle GEAR.
        }
        else if change = "5" {
            toggle AG5.
        }
        else if change = "6" {
            toggle AG6.
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
        else if change = "1" {
            toggle AG1.
        }
        else if change = "2" {
            toggle AG2.
        }
        else if change = "3" {
            toggle AG3.
        }
        else if change = "4" {
            toggle AG4.
        }
    }
    set pitch_value:text to round(ship:verticalspeed):tostring().
    set roll_value:text to round(rollAngle(), 3):tostring().
    set throttle_value:text to round(ship:velocity:surface:mag):tostring().
    set head_value:text to round(head, 0):tostring().
    set distance_value:text to round(distance, 0):tostring().
    wait 0.
}

set ship:control:neutralize to true.
window:hide().
window:dispose().
