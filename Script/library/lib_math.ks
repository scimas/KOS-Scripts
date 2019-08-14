@LAZYGLOBAL OFF.

function modulo {
    parameter a.
    parameter n.

    return a - abs(n) * floor(a / abs(n)).
}

function RK4 {
    // Classic 4th Order Runge Kutta System of ODEs solver
    // Parameter in the form of a lexicon
    // One key for every variable. Value should be the derivative function delegate
    // Derivatives must accept each variable: deriv(t, list[x, y, z, ...])
    // Third last lexicon item should be ("init": list[x0, y0, z0, ...])
    // Second last lexicon item should be step size ("h": h)
    // Last lexicon item should be integration interval ("interval": list[Ti, Tf])
    // Returns a list of the final values of the variables
    parameter sim_init is lexicon().

    local num_variables is sim_init:length - 3.
    local variables is sim_init:keys:sublist(0, num_variables).
    local ti is sim_init["interval"][0].
    local tf is sim_init["interval"][1].
    local h is sim_init["h"].
    local steps is ceiling((tf - ti) / h).
    local v is sim_init["init"].
    local midpoint is v:copy.
    local k1 is v:copy.
    local k2 is v:copy.
    local k3 is v:copy.
    local k4 is v:copy.
    
    local t is ti.
    for _ in range(steps) {
        from {local i is 0.} until i = num_variables step {set i to i + 1.} do {
            set k1[i] to sim_init[variables[i]]:call(t, v).
            set midpoint[i] to v[i] + k1[i] * h / 2.
        }
        from {local i is 0.} until i = num_variables step {set i to i + 1.} do {
            set k2[i] to sim_init[variables[i]]:call(t + h/2, midpoint).
            set midpoint[i] to v[i] + k2[i] * h / 2.
        }
        from {local i is 0.} until i = num_variables step {set i to i + 1.} do {
            set k3[i] to sim_init[variables[i]]:call(t + h/2, midpoint).
            set midpoint[i] to v[i] + k3[i] * h.
        }
        from {local i is 0.} until i = num_variables step {set i to i + 1.} do {
            set k4[i] to sim_init[variables[i]]:call(t + h, midpoint).
        }
        from {local i is 0.} until i = num_variables step {set i to i + 1.} do {
            set v[i] to v[i] + (k1[i] + 2 * (k2[i] + k3[i]) + k4[i]) / 6.
        }
        set t to t + h.
    }
    return v.
}
