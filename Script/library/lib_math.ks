@LAZYGLOBAL OFF.

function modulo {
    parameter a.
    parameter n.

    return a - abs(n) * floor(a / abs(n)).
}
