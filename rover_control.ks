parameter tH is 90.
clearscreen.
set northpole to latlng(90, 0).

declare function shipheading {
	if northpole:bearing <= 0 {
		return abs(northpole:bearing).
	}
	else {
		return 360 - northpole:bearing.
	}
}

declare function modulus {
	parameter a, b.
	return a - abs(b)*floor(a/abs(b)).
}

declare function surface_orientation {
	set v1 to body:geopositionof(ship:position + ship:facing:forevector*0.3):position.
	set v2 to body:geopositionof(ship:position - ship:facing:forevector):position.
	set v3 to body:geopositionof(ship:position - ship:facing:forevector*0.5 + ship:facing:starvector*0.5):position.
	set v4 to body:geopositionof(ship:position - ship:facing:forevector*0.5 - ship:facing:starvector*0.5):position.
	set nv1 to v1 - v2.
	set nv2 to v3 - v4.
	return vcrs(nv1, nv2):normalized.
}

sas off.
set wtval to 0.
set wsval to 0.

set targetheading to tH.
set targetspeed to 0.

lock wheelthrottle to wtval.
lock wheelsteering to wsval.

set wtpid to pidloop(0.1,0.002,0.004,-1,1).
set wspid to pidloop(0.2,0.001,0.001,-2,2).
set wtpid:setpoint to 0.
set wspid:setpoint to 0.

until targetspeed > 0 {
	if ship:control:pilotwheelsteer > 0 {
		set targetheading to modulus(targetheading - 1, 360).
	}
	else if ship:control:pilotwheelsteer < 0 {
		set targetheading to modulus(targetheading + 1, 360).
	}
	if ship:control:pilotwheelthrottle > 0 {
		set targetspeed to targetspeed + 0.1.
	}
	else if ship:control:pilotwheelthrottle < 0 {
		set targetspeed to targetspeed - 0.1.
	}
}

brakes off.
lock headingerror to shipheading() - targetheading.
lock speederror to ship:velocity:surface:mag - targetspeed*abs(180 - abs(headingerror))/180.
set reached to false.

when brakes then {
	set targetspeed to 0.
	set targetheading to shipheading().
	set reached to true.
}

until reached {
	clearscreen.
	print "Target heading: " + round(targetheading, 2) at (0,2).
	print "Current heading: " + round(shipheading(), 2) at (0,3).
	print "Target speed: " + round(targetspeed, 2) + " m/s" at (0,4).
	print "Current speed: " + round(ship:velocity:surface:mag, 2) + " m/s" at (0,5).

	set wtval to wtpid:update(time:seconds, speederror).
	set wsval to shipheading() + wspid:update(time:seconds, headingerror).

	if ship:control:pilotwheelsteer > 0 {
		set targetheading to modulus(targetheading - 1, 360).
	}
	else if ship:control:pilotwheelsteer < 0 {
		set targetheading to modulus(targetheading + 1, 360).
	}
	if ship:control:pilotwheelthrottle > 0 {
		set targetspeed to targetspeed + 0.1.
	}
	else if ship:control:pilotwheelthrottle < 0 {
		set targetspeed to targetspeed - 0.1.
	}
	if vang(ship:facing:topvector, surface_orientation()) > 3 {
		set desired_rot to rotatefromto(ship:facing:topvector, surface_orientation()).
		lock steering to desired_rot.
	}
	wait 0.05.
	unlock steering.
}

set ctime to time:seconds.
until time:seconds > ctime + 5 {
	print "Target heading: " + round(targetheading, 2) at (0,2).
	print "Current heading: " + round(shipheading(), 2) at (0,3).
	print "Target speed: " + round(targetspeed, 2) + " m/s" at (0,4).
	print "Current speed: " + round(ship:velocity:surface:mag, 2) + " m/s" at (0,5).
	set wtval to wtpid:update(time:seconds, speederror).
	set wsval to shipheading() + wspid:update(time:seconds, headingerror).
}

brakes on.
unlock wheelthrottle.
unlock wheelsteering.
unlock speederror.
unlock headingerror.
sas on.
