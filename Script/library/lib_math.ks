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
