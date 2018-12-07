//General boot file for all crafts.
//Actual instructions to be written in update_ship_name.ks

@lazyglobal off.

wait until SHIP:UNPACKED AND SHIP:LOADED.
wait 2.

global lock orbitTangent to SHIP:VELOCITY:ORBIT:NORMALIZED.
global lock orbitBinormal to VCRS(BODY:POSITION, orbitTanget):NORMALIZED.
global lock orbitNormal to VCRS(dir_tangent, orbitBinormal):NORMALIZED.

global lock surfaceTanget to SHIP:VELOCITY:surface:NORMALIZED.
global lock surfaceBinormal to VCRS(BODY:POSITION, surfaceTanget):NORMALIZED.
global lock surfaceNormal to VCRS(dir_tangent, surfaceBinormal):NORMALIZED.

wait until ADDONS:RT:HASKSCCONNECTION(SHIP).

CORE:DOACTION("open terminal", true).
COPYPATH("0:/launch.ks", "").
COPYPATH("0:/manoeuvre.ks", "").
RUNONCEPATH("manoeuvre.ks").
RUNONCEPATH("launch.ks").

local updatefile is "0:/boot/update_" + SHIP:NAME + ".ks".

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