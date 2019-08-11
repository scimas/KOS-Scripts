@LAZYGLOBAL OFF.

function needsStaging {
    local engineList is list().
    list engines in engineList.
    for e in engineList {
        if e:flameout {
            for en in engineList {
                if not en:flameout and en <> e {
                    return true.
                }
            }
        }
    }
    if ship:maxthrust = 0 {
        for en in engineList {
            if not en:flameout {
                return true.
            }
        }
    }
    return false.
}
