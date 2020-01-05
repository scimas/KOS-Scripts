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
    parameter sim_init is lexicon(
        "t0", 0,
        "step", 1,
        "init", list(),
        "nsteps", 1,
        "derivatives", { return 0. }
    ).

    local t0 is sim_init["t0"].
    local step is sim_init["step"].
    local halfstep is step/2.
    local sixthstep is step/6.
    local v is sim_init["init"].
    local num_variables is v:length.
    local midpoint is v:copy.
    local k1 is list().
    local k2 is list().
    local k3 is list().
    local k4 is list().

    for _ in range(sim_init["nsteps"]) {
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

function false_position {
    parameter root_function, xl, xu, tolerance is 0.1, xr is (xl + xu) / 2, max_iter is 10.

    local ea is tolerance + 1.
    local iter is 0.
    until false {
        set iter to iter + 1.
        local fl is root_function:call(xl).
        local fu is root_function:call(xu).
        local xr_old is xr.
        set xr to xu - (fu * (xu - xl)) / (fu -fl).
        local fr is root_function:call(xr).
        if xr <> 0 {
            set ea to abs((xr - xr_old) / xr).
        }
        local condition is fl * fr.
        if condition < 0 {
            set xu to xr.
        }
        else if condition > 0 {
            set xl to xr.
        }
        else {
            set ea to 0.
        }
        if ea < tolerance or iter >= max_iter {
            break.
        }
    }
    return xr.
}