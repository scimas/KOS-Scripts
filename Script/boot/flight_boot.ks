//General boot file for all airplanes.
//Actual instructions to be written in update_<ship name>_<core tag>.ks

@lazyglobal off.

wait until SHIP:UNPACKED AND SHIP:LOADED.
CORE:DOACTION("open terminal", true).

local flist is LIST().
list FILES in flist.

print "Checking for connection to KSC.".
if not HOMECONNECTION:ISCONNECTED {
    print "No connection. Waiting.".
    wait until HOMECONNECTION:ISCONNECTED.
}

if flist:LENGTH <= 1 {
    COPYPATH("0:/flight_assist.ks", "").
}

print "Activating flight assist system.".
SAS off.
RUNPATH("flight_assist.ks").
