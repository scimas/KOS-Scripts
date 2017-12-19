//Script for launching and landing rockets
//Landing code only works with laser distance mod
//rmd is runmode, tH is target heading, tAP and tPE are
//target apoapsis and periapsis respectively.

parameter rmd is 1.	//{1,2,3,4,5} Launch modes {6,7,8,9} Landing modes
parameter tH is 90.
parameter tAP is 80000.
parameter tPE is 80000.

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
SAS off.
RCS off.

set runmode to rmd.
set targetAP to tAP.
set targetPE to tPE.
lock g to orbit:body:mu / (ship:altitude + orbit:body:radius)^2. //Acceleration due to gravity of
																//current SOI body at current altitude
lock twr to ship:availablethrust / (ship:mass * g).	//Thrust to weight ratio
lock normalvo to vcrs(ship:velocity:orbit:normalized,up:vector).	//Normal vector to orbital trajectory
lock normalvs to vcrs(ship:velocity:surface:normalized,up:vector).	//Normal vector to surface trajectory
lock horizo to vcrs(up:vector,normalvo).	//Horizan vector in orbit prograde and UP:vector plane
lock horizs to vcrs(up:vector,normalvs).	//Horizan vector in surface prograde and UP:vector plane
set fueltrig to true.	//Is there non zero amount of solid or liquid fuel remaining on the ship?
set tval to 0.	//Thrust value [0, 1]
if ship:modulesnamed("LaserDistModule"):length > 0 {
	set laser_mod to ship:modulesnamed("LaserDistModule")[0].
}

print "Starting with runmode " + runmode.

when engine_flameout() or ship:availablethrust = 0 then {
	set tempv to tval.
	set tval to 0.
	wait 0.5.
	if (ship:liquidfuel > 0.1) or (ship:solidfuel > 0.1) {
		stage.
		wait 0.5.
		set fueltrig to true.
	}
	else {
		set fueltrig to false.
	}
	set tval to tempv.
	return fueltrig.
}

until runmode = 0 {

	if runmode = 1 {//Launch from ground
		lock steering to up.
		set tval to 1.
		if body:atm:exists {
			gear off.
			set runmode to 2.
		}
		else {
			lock steering to heading(tH, 90).
			set runmode to 3.
		}
	}

	else if runmode = 2 {//Coast to 1000 m or 60 m/s
		lock steering to heading(tH,90).
		if twr > 1.8 {
			set tval to 1.8/twr.
		}
		else {
			set tval to 1.
		}
		if ship:velocity:surface:mag > 60 {
			set runmode to 3.
		}
	}

	else if runmode = 3 {//Gravity turn start
		if body:atm:exists {
			set targetP to 45 + 45/(targetAP/80 - targetAP/5)*(ship:altitude - targetAP/5).
			lock steering to heading(tH,targetP).
			if twr > 2.0 {
				set tval to 2.0/twr.
			}
			else {
				set tval to 1.
			}
			if ship:altitude > targetAP/5 {
				set endAP to ship:apoapsis.
				set runmode to 4.
			}
		}
		else {
			set tval to 1.
			if ship:apoapsis > 5000 {
				lock steering to heading(tH, 5).
				set runmode to 4.
			}
		}

	}

	else if runmode = 4 {//Upper gravity turn
		if body:atm:exists {
			if twr > 2.3 {
				set tval to 2.3/twr.
			}
			else {
				set tval to 1.
			}
			set targetP to 5 + 40/(targetAP - endAP)*(targetAP - ship:apoapsis).
			lock steering to heading(tH,targetP).
		}
		else {
			set tval to 1.
		}

		if ship:apoapsis > targetAP {
			set runmode to 5.
			set tval to 0.
			lock steering to heading(tH,0.5).
		}
	}

	else if runmode = 5 {//Raise PE
		lock steering to ship:velocity:orbit.
		wait until eta:apoapsis < 30.
		set addp to 0.
		set leta to eta:apoapsis.
		set targetD to ship:velocity:orbit.
		lock steering to targetD.
		until ship:periapsis > targetPE {
			if eta:apoapsis < leta {
				set tval to min(1, tval + 0.005).
				set addp to min(90, addp + 0.01).
				set targetD to horizo*cos(addp) + vcrs(normalvo, horizo)*sin(addp).
			}
			else if eta:apoapsis > leta{
				set tval to max(0, tval - 0.01).
				set targetD to horizo.
				set addp to 0.
			}
			else if eta:apoapsis < (leta - 1) {
				set tval to min(1, tval + 0.05).
				set addp to min(90, addp + 0.01).
				set targetD to horizo*cos(addp) + vcrs(normalvo, horizo)*sin(addp).
			}
			set leta to eta:apoapsis.
			wait 0.07.
		}
		set tval to 0.
		set runmode to 100.
	}


	else if runmode = 6 {//Landing sequence
		lock steering to ship:velocity:orbit * -1.
		
		if ship:periapsis < targetPE {
			set runmode to 8.
			wait eta:periapsis.
		}
		else {
			set runmode to 7.
			wait eta:apoapsis.
		}
	}

	else if runmode = 7 {
		lock steering to ship:velocity:orbit * -1.
		set tval to 1.
		if ship:periapsis < targetPE {
			set tval to 0.
			set runmode to 8.
			wait eta:periapsis - 1.
		}
	}

	else if runmode = 8 {
		lock steering to ship:velocity:orbit * -1.
		set tval to 1.
		if ship:periapsis < -targetPE/2 {
			set tval to 0.
			if eta:apoapsis < orbit:period/2 {
				wait until ship:verticalspeed < 0.
			}
			set runmode to 9.
		}
	}
	
	else if runmode = 9 {
		gear on.
		lock steering to ship:velocity:surface * -1.
		wait until ship:verticalspeed < -1.
		laser_mod:setfield("Enabled",true).
		wait until laser_mod:getfield("Hit") = body:name.
		lock acc to ship:availablethrust*tval/ship:mass - g*abs(cos(vang(up:vector, ship:velocity:surface*-1))).
		lock actdist to laser_mod:getfield("Distance") - 3.
		until actdist < 0{
			set tvacc to ship:velocity:surface:mag^2/(2*actdist).
			if acc < tvacc {
				set tval to min(1, tval + 0.01).
			}
			else {
				set tval to max(0, tval - 0.01).
			}
		}
		lock steering to up.
		set tval to 0.
		lock actdist to laser_mod:getfield("Distance") - 1.
		lock acc to ship:availablethrust*tval/ship:mass - g.
		until ship:status = "LANDED"{
			set tvacc to ship:verticalspeed^2/(2*actdist).
			if acc < tvacc {
				set tval to tval + (tvacc - acc)/tvacc * 0.1.
			}
			else {
				set tval to max(0, tval + (tvacc - acc)/tvacc * 0.1).
			}
		}
		set tval to 0.
		laser_mod:setfield("Enabled",false).
		unlock actdist.
		unlock acc.
		wait 2.
		set runmode to 100.
	}

	else if runmode = 100 {
		set tval to 0.
		unlock steering.
		unlock throttle.
		unlock g.
		unlock twr.
		unlock normalvo.
		unlock normalvs.
		unlock horizo.
		unlock horizs.
		SAS on.
		set runmode to 0.
	}

	lock throttle to tval.

	print "Runmode: " + runmode at (5,4).
}

unlock throttle.
print "Finished doing the job.".
