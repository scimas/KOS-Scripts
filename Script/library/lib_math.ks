@LAZYGLOBAL OFF.

function modulo {
    parameter a.
    parameter n.

    return a - abs(n) * floor(a / abs(n)).
}

function sign {
    parameter num.

    if num < 0 {
        return -1.
    } else if num > 0 {
        return 1.
    } else {
        return 0.
    }
}

function sqrmag {
    parameter v.

    if v:istype("Scalar") {
        return v * v.
    } else if v:istype("Vector") {
        return v:sqrmagnitude.
    }
}

// Classic 4th Order Runge Kutta System of ODEs solver
// Initial time: ti
// Final time: tf
// Step size: Δt
// Initial values: init: list[x0, y0, z0, ...]
// Derivatives deligate: deriv(t, list[x, y, z, ...])@
// Derivative function must accept each variable
// Returns a list of the final values of the variables
function RK4 {
    parameter ti.
    parameter tf.
    parameter Δt.
    parameter init.
    parameter derivatives.

    local t is ti.
    local v is init.
    until t = tf {
        if t + Δt > tf {
            set Δt to tf - t.
        }
        set v to RK4_step(t, Δt, v, derivatives).
        set t to t + Δt.
    }
    
    return v.
}

function RK4_step {
    parameter ti.
    parameter Δt.
    parameter init.
    parameter derivatives.
    
    local a2 is 0.5. local a3 is 0.5. local a4 is 1.
    local b21 is 0.5.
    local b32 is 0.5.
    local b43 is 1.
    local c1 is 1/6. local c2 is 1/3. local c3 is 1/3. local c4 is 1/6.

    local t is ti.
    local v is init.
    local num_variables is v:length.
    local midpoint is v:copy.
    local k1 is list().
    local k2 is list().
    local k3 is list().
    local k4 is list().
    
    set k1 to derivatives:call(t, v).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + b21 * k1[i] * Δt.
    }
    set t to ti + a2 * Δt.
    set k2 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + b32 * k2[i] * Δt.
    }
    set t to ti + a3 * Δt.
    set k3 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + b43 * k3[i] * Δt.
    }
    set t to ti + a4 * Δt.
    set k4 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set v[i] to v[i] + (
            c1 * k1[i] +
            c2 * k2[i] +
            c3 * k3[i] +
            c4 * k4[i]
        ) * Δt.
    }
    return v.
}

// Runge-Kutta-Fehlberg aka embedded RK method
// with adaptive step size control
function RKF {
    parameter ti.
    parameter tf.
    parameter Δt.
    parameter init.
    parameter derivatives.
    parameter err_thresh.

    local result is list().
    local v is init.
    local t is ti.
    until t = tf {
        if t + Δt > tf {
            set Δt to tf - t.
        }
        set result to RKF_step_adapt(t, Δt, v, derivatives, err_thresh).
        set t to t + Δt.
        set v to result[0].
        set Δt to result[1].
    }
    return v.
}

function RKF_step_adapt {
    parameter ti.
    parameter Δt.
    parameter init.
    parameter derivatives.
    parameter err_thresh.

    local result is RKKC_step(ti, Δt, init, derivatives).
    local v is result[0].
    local err is result[1].
    local vscale is result[2].

    local emax is vscale * err_thresh / err.
    if emax >= 1 {
        set Δt to Δt * emax ^ 0.2.
    } else {
        set Δt to Δt * emax ^ 0.25.
    }
    return list(v, Δt).
}

// Runge-Kutta Cash-Karp method
function RKKC_step {
    parameter ti.
    parameter Δt.
    parameter init.
    parameter derivatives.

    local a2 is 0.2. local a3 is 0.3. local a4 is 0.6. local a5 is 1. local a6 is 0.875.
    local b21 is 0.2.
    local b31 is 0.075. local b32 is 0.225.
    local b41 is 0.3. local b42 is -0.9. local b43 is 1.2.
    local b51 is -11 / 54. local b52 is 2.5. local b53 is -70 / 27. local b54 is 35 / 27.
    local b61 is 1_631 / 55_296. local b62 is 175 / 512. local b63 is 575 / 13_824. local b64 is 44_275 / 110_592. local b65 is 253 / 4_096.
    local c1 is 37 / 378. local c3 is 250 / 621. local c4 is 125 / 594. local c6 is 512 / 1_771.
    local dc1 is 2_825 / 27_648 - c1. local dc3 is 18_575 / 48_384 - c3. local dc4 is 13_525 / 55_296 - c4. local dc5 is 277 / 14_336. local dc6 is 0.25 - c6.

    local v is init.
    local t is ti.
    local err is 0.
    local epsilon is 1e-13.
    local vmag is 0.
    local step1mag is 0.
    local num_variables is v:length.
    local midpoint is v:copy.
    local k1 is list().
    local k2 is list().
    local k3 is list().
    local k4 is list().
    local k5 is list().
    local k6 is list().

    set k1 to derivatives:call(t, v).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + b21 * k1[i] * Δt.
        set vmag to vmag + sqrmag(v[i]).
        set step1mag to step1mag + sqrmag(k1[i]).
    }
    set vmag to sqrt(vmag).
    set step1mag to Δt * sqrt(step1mag).
    local vscale is vmag + step1mag + epsilon.
    set t to ti + a2 * Δt.
    set k2 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + (
            b31 * k1[i] +
            b32 * k2[i]
        ) * Δt.
    }
    set t to ti + a3 * Δt.
    set k3 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + (
            b41 * k1[i] +
            b42 * k2[i] +
            b43 * k3[i]
        ) * Δt.
    }
    set t to ti + a4 * Δt.
    set k4 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + (
            b51 * k1[i] +
            b52 * k2[i] +
            b53 * k3[i] +
            b54 * k4[i]
        ) * Δt.
    }
    set t to ti + a5 * Δt.
    set k5 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set midpoint[i] to v[i] + (
            b61 * k1[i] +
            b62 * k2[i] +
            b63 * k3[i] +
            b64 * k4[i] +
            b65 * k5[i]
        ) * Δt.
    }
    set t to ti + a6 * Δt.
    set k6 to derivatives:call(t, midpoint).
    for i in range(num_variables) {
        set v[i] to v[i] + (
            c1 * k1[i] +
            c3 * k3[i] +
            c4 * k4[i] +
            c6 * k6[i]
        ) * Δt.
        set err to err + sqrmag(
            dc1 * k1[i] +
            dc3 * k3[i] +
            dc4 * k4[i] +
            dc5 * k5[i] +
            dc6 * k6[i]
        ).
    }
    set err to Δt * sqrt(err).
    return list(v, err, vscale).
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
