//General boot file for all crafts.
//Actual instructions to be written in update_ship_name.ks

@lazyglobal off.

wait until SHIP:UNPACKED AND SHIP:LOADED.
wait 2.

global lock orbitTangent to SHIP:VELOCITY:ORBIT:NORMALIZED.
global lock orbitBinormal to VCRS(SHIP:BODY:POSITION, orbitTangent):NORMALIZED.
global lock orbitNormal to VCRS(orbitTangent, orbitBinormal):NORMALIZED.

global lock surfaceTangent to SHIP:VELOCITY:surface:NORMALIZED.
global lock surfaceBinormal to VCRS(SHIP:BODY:POSITION, surfaceTangent):NORMALIZED.
global lock surfaceNormal to VCRS(surfaceTangent, surfaceBinormal):NORMALIZED.

wait until ADDONS:RT:HASKSCCONNECTION(SHIP).

CORE:DOACTION("open terminal", true).
COPYPATH("0:/launch.ks", "").
COPYPATH("0:/manoeuvre.ks", "").
COPYPATH("0:/functions.ks", "").
RUNONCEPATH("manoeuvre.ks").
RUNONCEPATH("launch.ks").
RUNONCEPATH("functions.ks").

local updatefile is "0:/boot/update_" + SHIP:NAME + CORE:TAG + ".ks".

if EXISTS(updatefile) {
    COPYPATH(updatefile, "update.ks").
    DELETEPATH(updatefile).
    print "Found update file".
    print "Running new instructions".
    RUNPATH("update.ks").
    print "New instructions executed, exiting".
}
else {
    print "No new instructions found".
    print "Exiting".
}