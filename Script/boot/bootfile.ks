//General boot file for all crafts.
//Actual instructions to be written in update_<ship name>_<core tag>.ks

@LAZYGLOBAL OFF.

wait until ship:unpacked and ship:loaded.
core:doaction("open terminal", true).

// local flist is list().
// list FILES in flist.

print "Checking for connection to KSC.".
if not HOMECONNECTION:ISCONNECTED {
    print "No connection. Waiting.".
    wait until HOMECONNECTION:ISCONNECTED.
}

if not(exists("/library")) {
    createDir("/library").
}
copyPath("0:/library/lib_manoeuvre.ks", "library/").
copyPath("0:/library/lib_navigation.ks", "library/").
copyPath("0:/library/lib_utilities.ks", "library/").
copyPath("0:/library/lib_math.ks", "library/").

print "Files copied.".

// local updatefile is "0:/boot/update_" + SHIP:NAME + "_" + CORE:TAG + ".ks".
// print "Looking for".
// print updatefile.
// if exists(updatefile) {
//     copyPath(updatefile, "update.ks").
//     deletePath(updatefile).
// }

// if exists("update.ks") {
//     print "Found update file".
//     print "Running new instructions".
//     runPath("update.ks").
//     print "New instructions executed, exiting".
//     deletePath("update.ks").
// }
// else {
//     print "No new instructions found".
//     print "Exiting".
// }
