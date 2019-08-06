@LAZYGLOBAL OFF.

parameter point is 0.

clearscreen.
runOncePath("library/lib_navigation.ks").

local guiding is FALSE.
local handlePitch is FALSE.
local handleRoll is FALSE.
local quit is FALSE.

local change is 0.

local rollPID is pidLoop(
    0.02,
    0.005,
    0.008,
    -1,
    1
).
set rollPID:setpoint to 0.

local pitchPID is pidLoop(
    0.005,
    0.0016,
    0.001,
    -1,
    1
).
set pitchPID:setpoint to SHIP:verticalSpeed.

local window is gui(300).
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
local nav_box is window:addvbox().
local waylist is nav_box:addpopupmenu().
local head_label is nav_box:addlabel("Heading").
local head_value is nav_box:addlabel("-").
local head_button is nav_box:addbutton("Turn On").

for wp in allWaypoints() {
    waylist:addoption(wp).
}
set waylist:maxvisible to 5.
window:show().

function pitch_button_function {
    if handlePitch {
        set pitch_button:text to "Turn On".
        pitchPID:reset().
        set ship:control:neutralize to TRUE.
    }
    else {
        set pitch_button:text to "Turn Off".
        set pitchPID:setpoint to round(ship:verticalSpeed, 0).
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
        set ship:control:neutralize to TRUE.
    }
    else {
        set roll_button:text to "Turn Off".
        set rollPID:setpoint to round(rollAngle(), 0).
    }
    set handleRoll to not(handleRoll).
}
function roll_update_function {
    set rollPID:setpoint to roll_change:text:toscalar().
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
set head_button:onclick to head_button_function@.
set waylist:onchange to waylist_function@.

on AG6 {
    head_button_function().
    return TRUE.
}

on AG7 {
    pitch_button_function().
    return TRUE.
}

on AG9 {
    roll_button_function().
    return TRUE.
}

on AG10 {
    set quit to TRUE.
}

local head is 0.

until quit {
    if handlePitch {
        set ship:control:pitch to pitchPID:update(time:seconds, ship:verticalSpeed).
    }
    if handleRoll {
        set ship:control:roll to rollPID:update(time:seconds, rollAngle()).
    }
    if guiding {
        set head to greatCircleHeading(point).
    }
    if not (handlePitch or handleRoll) {
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
        else if change = "b" {
            toggle BRAKES.
        }
        else if change = "g" {
            toggle GEAR.
        }
        else if change = "6" {
            toggle AG6.
        }
        else if change = "7" {
            toggle AG7.
        }
        else if change = "9" {
            toggle AG9.
        }
    }
    set pitch_value:text to round(ship:verticalspeed):tostring().
    set roll_value:text to round(rollAngle(), 3):tostring().
    set head_value:text to round(head, 0):tostring().
    wait 0.
}

set ship:control:neutralize to TRUE.
window:hide().
window:dispose().
