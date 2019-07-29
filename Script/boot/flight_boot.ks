//General boot file for all airplanes.
//Actual instructions to be written in update_<ship name>_<core tag>.ks

@LAZYGLOBAL OFF.

wait until ship:unpacked and ship:loaded.
core:doaction("open terminal", true).
clearscreen.

local flist is list().
list files in flist.

print "Checking for connection to KSC.".
if not homeConnection:isconnected() {
    print "No connection. Waiting.".
    wait until homeConnection:isconnected().
}

if flist:length <= 1 {
    copypath("0:/library/lib_Navigation.ks").
    copypath("0:/flight_assist.ks", "").
}

print "Enter waypoint name (or 0)".
local wpname is "".
until false {
    local ch is terminal:input:getchar().
    if ch = terminal:input:return {
        break.
    }
    else if ch = terminal:input:backspace {
        set wpname to wpname:remove(wpname:length - 1, 1).
    }
    else {
        set wpname to wpname + ch.
    }
    print wpname at (0, 3).
}

print "Activating flight assist system.".
SAS off.
runpath("flight_assist.ks", wpname).
