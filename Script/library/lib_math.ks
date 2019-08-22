@LAZYGLOBAL OFF.

function modulo {
    parameter a.
    parameter n.

    return a - abs(n) * floor(a / abs(n)).
}

function RK4 {
    // Classic 4th Order Runge Kutta System of ODEs solver
    // Parameter in the form of a lexicon
    // Derivative function must accept each variable:
    // "derivatives": deriv(t, list[x, y, z, ...])@
    // Initial values ("init": list[x0, y0, z0, ...])
    // Step size ("step": step)
    // Initial time ("t0": t0)
    // Number of steps ("nsteps": nsteps)
    // Returns a list of the final values of the variables
    parameter sim_init is lexicon().

    local t0 is sim_init["t0"].
    local step is sim_init["step"].
    local halfstep is step/2.
    local sixthstep is step/6.
    local v is sim_init["init"].
    local num_variables is v:length.
    local midpoint is v:copy.
    local k1 is 0.
    local k2 is 0.
    local k3 is 0.
    local k4 is 0.

    for _i in range(sim_init["nsteps"]) {
        set k1 to sim_init["derivatives"]:call(t0, v).
        for i in range(num_variables) {
            set midpoint[i] to v[i] + k1[i] * halfstep.
        }
        set t0 to t0 + halfstep.
        set k2 to sim_init["derivatives"]:call(t0, midpoint).
        for i in range(num_variables) {
            set midpoint[i] to v[i] + k2[i] * halfstep.
        }
        set k3 to sim_init["derivatives"]:call(t0, midpoint).
        for i in range(num_variables) {
            set midpoint[i] to v[i] + k3[i] * step.
        }
        set t0 to t0 + halfstep.
        set k4 to sim_init["derivatives"]:call(t0, midpoint).
        for i in range(num_variables) {
            set v[i] to v[i] + (k1[i] + 2 * (k2[i] + k3[i]) + k4[i]) * sixthstep.
        }
    }
    return v.
}
