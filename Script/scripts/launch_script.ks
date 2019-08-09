copyPath("0:/launch.ks", "").
runOncePath("library/lib_navigation.ks").
runOncePath("launch.ks").

// local bd is body("Minmus").

// clearScreen.

// until (angleToRelativeAscendingNode(orbitBinormal(), orbitBinormal(bd)) < 0.2 or
// angleToRelativeDescendingNode(orbitBinormal(), orbitBinormal(bd)) < 0.2) {
//     print angleToRelativeAscendingNode(orbitBinormal(), orbitBinormal(bd)) at (0, 0).
// }
// kuniverse:timewarp:cancelwarp().
// local targetAltitude is 80_000.
// local targetInclination is bd:orbit:inclination.
// local turnStartSpeed is 60.
// local maintainTWR is 2.

// if angleToRelativeAscendingNode(orbitBinormal(), orbitBinormal(bd)) < angleToRelativeDescendingNode(orbitBinormal(), orbitBinormal(bd)) {
//     set targetInclination to targetInclination * -1.
// }
// launch(targetAltitude, targetInclination, turnStartSpeed, maintainTWR).

launch().
