//General boot file for all crafts.
//Actual instructions to be written in update_ship_name.ks

@lazyglobal off.

wait until SHIP:UNPACKED.
wait 2.

wait until ADDONS:RT:HASKSCCONNECTION(SHIP).

CORE:DOACTION("open terminal", true).
local updatefile is "0:/boot/update_" + SHIP:NAME + ".ks".

if EXISTS(updatefile) {
    COPYPATH(updatefile, "update.ks").
    print "Found update file".
    print "Running new instructions".
    RUNPATH("update.ks").
    DELETEPATH(updatefile).
    print "New instructions executed, exiting".
}
else {
    print "No new instructions found".
    print "Exiting".
}