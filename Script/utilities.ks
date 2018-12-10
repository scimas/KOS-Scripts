function cancelWarp {
    until kuniverse:TimeWarp:RATE = 1 {
        set WARP to WARP - 1.
        wait until kuniverse:TimeWarp:RATE = kuniverse:TimeWarp:RATELIST[WARP].
    }
    wait until SHIP:UNPACKED AND SHIP:LOADED.
}