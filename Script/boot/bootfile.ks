//General boot file for all crafts.
//Actual instructions to be written in update_ship_name.ks

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
    COPYPATH("0:/utilities.ks", "").
    COPYPATH("0:/functions.ks", "").
    COPYPATH("0:/manoeuvre.ks", "").
    COPYPATH("0:/launch.ks",    "").
}

local updatefile is "0:/boot/update_" + SHIP:NAME + "_" + CORE:TAG + ".ks".
print "Looking for".
print updatefile.
if EXISTS(updatefile) {
    COPYPATH(updatefile, "update.ks").
    DELETEPATH(updatefile).
}

if EXISTS("update.ks") {
    print "Found update file".
    print "Running new instructions".
    RUNONCEPATH("utilities.ks").
    RUNONCEPATH("functions.ks").
    RUNONCEPATH("manoeuvre.ks").
    RUNONCEPATH("launch.ks").
    RUNPATH("update.ks").
    print "New instructions executed, exiting".
    DELETEPATH("update.ks").
}
else {
    print "No new instructions found".
    print "Exiting".
}
