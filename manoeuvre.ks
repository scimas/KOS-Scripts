parameter dV.	//Node delta V
sas off.

declare function engine_flameout {	//Used to determine when to stage
	list engines in engs.

	for e in engs {
		if e:flameout = true {
			return true.
		}
	}
	return false.
}

clearscreen.
lock throttle to 0.
set man to nextnode.

when engine_flameout() or ship:availablethrust = 0 then {
	set tempval to tval.
	set tval to 0.
	wait 0.1.
	if (ship:liquidfuel > 1) or (ship:solidfuel > 1) {
		stage.
		wait 0.1.
		set fueltrig to true.
		set tval to tempval.
	}
	else {
		set fueltrig to false.
	}
	return fueltrig.	//True -> ship still has non zero amount of solid or liquid fuel available
}

print "Target deltaV: " + round(dV, 3) at (1,1).
set tval to 0.	//Throttle value [0, 1]
wait man:eta - 15.

lock steering to man:deltav.

wait max(0, man:eta).

set expended_dV to 0.
set tval to 1.
lock throttle to tval.
set oldT to time:seconds.

until expended_dV >= dV {
	if (dV - expended_dV)/ (ship:availablethrust / ship:mass) <= 1 {	//if less than one second
		set tval to 0.1.									//to burn end, reduce throttle for finer control
	}
	set dt to time:seconds - oldT.
	set expended_dV to expended_dV + ship:availablethrust * tval / ship:mass * dt.
	set oldT to oldT + dt.
	print "Expended deltaV " + round(expended_dV, 3) at (1,2).
}

lock throttle to 0.
unlock steering.
wait 1.
unlock throttle.
sas on.
