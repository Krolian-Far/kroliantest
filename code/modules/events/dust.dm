/*/datum/round_event_control/space_dust
	name = "Minor Space Dust"
	typepath = /datum/round_event/space_dust
	weight = 200
	max_occurrences = 1000
	earliest_start = 0 MINUTES
	alert_observers = FALSE

/datum/round_event/space_dust
	start_when		= 1
	end_when			= 2
	fakeable = FALSE

/datum/round_event/space_dust/start()
	spawn_meteors(1, GLOB.meteorsC)

/datum/round_event_control/sandstorm
	name = "Sandstorm"
	typepath = /datum/round_event/sandstorm
	weight = 0
	max_occurrences = 0
	earliest_start = 0 MINUTES

/datum/round_event/sandstorm
	start_when = 1
	end_when = 150 // ~5 min
	announce_when = 0
	fakeable = FALSE

/datum/round_event/sandstorm/tick()
	spawn_meteors(10, GLOB.meteorsC)*/ // WS Edit - Removes the 100% Free Lag button
