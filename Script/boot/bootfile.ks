//General boot file for all crafts.
//Actual instructions to be written in update_ship_name.ks

@lazyglobal off.

wait until SHIP:UNPACKED AND SHIP:LOADED.
wait 2.
wait until ADDONS:RT:HASKSCCONNECTION(SHIP).

CORE:DOACTION("open terminal", true).
RUNONCEPATH("0:/utilities.ks").
RUNONCEPATH("0:/manoeuvre.ks").
RUNONCEPATH("0:/launch.ks").
RUNONCEPATH("0:/functions.ks").

local updatefile is "0:/boot/update_" + SHIP:NAME + CORE:TAG + ".ks".
print updatefile.

if EXISTS(updatefile) {
    COPYPATH(updatefile, "update.ks").
    DELETEPATH(updatefile).
    print "Found update file".
    print "Running new instructions".
    RUNPATH("update.ks").
    print "New instructions executed, exiting".
    DELETEPATH("update.ks").
}
else {
    print "No new instructions found".
    print "Exiting".
}
