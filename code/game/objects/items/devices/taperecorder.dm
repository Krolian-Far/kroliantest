/datum/wires/recorder
	wires = list(WIRE_ACTIVATE, WIRE_DISABLE, WIRE_RX)
	holder_type = /obj/item/taperecorder

/datum/wires/recorder/on_pulse(wire)
	var/obj/item/taperecorder/recorder = holder
	switch(wire)
		if(WIRE_ACTIVATE)
			recorder.record()
		if(WIRE_DISABLE)
			recorder.stop()
		if(WIRE_RX)
			recorder.play()

/obj/item/taperecorder
	name = "universal recorder"
	desc = "A device that can record to cassette tapes, and play them. It automatically translates the content in playback."
	icon = 'icons/obj/device.dmi'
	icon_state = "taperecorder_empty"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	pickup_sound =  'sound/items/handling/device_pickup.ogg'
	drop_sound = 'sound/items/handling/device_drop.ogg'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	custom_materials = list(/datum/material/iron=60, /datum/material/glass=30)
	force = 2
	throwforce = 0
	var/recording = 0
	var/playing = 0
	var/playsleepseconds = 0
	var/obj/item/tape/mytape
	var/starting_tape_type = /obj/item/tape/random
	var/open_panel = 0
	var/canprint = 1
	var/list/icons_available = list()
	var/icon_directory = 'icons/effects/icons.dmi'

/obj/item/taperecorder/Initialize(mapload)
	. = ..()
	wires = new /datum/wires/recorder(src)
	if(starting_tape_type)
		mytape = new starting_tape_type(src)
	update_appearance()
	become_hearing_sensitive(ROUNDSTART_TRAIT)

/obj/item/taperecorder/Destroy()
	QDEL_NULL(wires)
	QDEL_NULL(mytape)
	return ..()

/obj/item/taperecorder/examine(mob/user)
	. = ..()
	. += "The wire panel is [open_panel ? "opened" : "closed"]."


/obj/item/taperecorder/attackby(obj/item/item, mob/user, params)
	if(!mytape && istype(item, /obj/item/tape))
		if(!user.transferItemToLoc(item,src))
			return
		mytape = item
		to_chat(user, span_notice("You insert [item] into [src]."))
		playsound(src, 'sound/items/taperecorder/taperecorder_close.ogg', 50, FALSE)
		update_appearance()
	if(open_panel)
		if(is_wire_tool(item))
			wires.interact(user)

/obj/item/taperecorder/screwdriver_act(mob/living/user, obj/item/screwdriver)
	to_chat(usr, span_notice("You [open_panel ? "close" : "open"] [src]s panel."))
	open_panel = !open_panel

/obj/item/taperecorder/proc/eject(mob/user)
	if(mytape)
		to_chat(user, span_notice("You remove [mytape] from [src]."))
		playsound(src, 'sound/items/taperecorder/taperecorder_open.ogg', 50, FALSE)
		stop()
		user.put_in_hands(mytape)
		mytape = null
		update_appearance()

/obj/item/taperecorder/fire_act(exposed_temperature, exposed_volume)
	mytape.ruin() //Fires destroy the tape
	..()

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/taperecorder/attack_hand(mob/user)
	if(loc != user || !mytape || !user.is_holding(src))
		return ..()
	eject(user)

/obj/item/taperecorder/proc/can_use(mob/user)
	if(user && ismob(user))
		if(!user.incapacitated())
			return TRUE
	return FALSE


/obj/item/taperecorder/verb/ejectverb()
	set name = "Eject Tape"
	set category = "Object"

	if(!can_use(usr))
		return
	if(!mytape)
		return

	eject(usr)


/obj/item/taperecorder/update_icon_state()
	if(!mytape)
		icon_state = "taperecorder_empty"
		return ..()
	if(recording)
		icon_state = "taperecorder_recording"
		return ..()
	if(playing)
		icon_state = "taperecorder_playing"
		return ..()
	icon_state = "taperecorder_idle"
	return ..()


/obj/item/taperecorder/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, spans, list/message_mods = list())
	. = ..()
	if(mytape && recording)
		mytape.timestamp += mytape.used_capacity
		mytape.storedinfo += "\[[time2text(mytape.used_capacity * 10,"mm:ss")]\] [speaker.GetVoice()] [speaker.say_mod(raw_message, message_language, message_mods)], \"[raw_message]\""

/obj/item/taperecorder/verb/record()
	set name = "Start Recording"
	set category = "Object"

	if(!can_use(usr))
		return
	if(!mytape || mytape.ruined)
		return
	if(recording)
		return
	if(playing)
		return

	if(mytape.used_capacity < mytape.max_capacity)
		to_chat(usr, span_notice("Recording started."))
		recording = 1
		update_appearance()
		mytape.timestamp += mytape.used_capacity
		mytape.storedinfo += "\[[time2text(mytape.used_capacity * 10,"mm:ss")]\] Recording started."
		var/used = mytape.used_capacity	//to stop runtimes when you eject the tape
		var/max = mytape.max_capacity
		while(recording && used < max)
			mytape.used_capacity++
			used++
			sleep(10)
		recording = 0
		update_appearance()
	else
		to_chat(usr, span_notice("[src] is full."))


/obj/item/taperecorder/verb/stop()
	set name = "Stop"
	set category = "Object"

	if(!can_use(usr))
		return

	if(recording)
		recording = 0
		mytape.timestamp += mytape.used_capacity
		mytape.storedinfo += "\[[time2text(mytape.used_capacity * 10,"mm:ss")]\] Recording stopped."
		playsound(src, 'sound/items/taperecorder/taperecorder_stop.ogg', 50, FALSE)
		to_chat(usr, span_notice("Recording stopped."))
		return
	else if(playing)
		playing = 0
		var/turf/T = get_turf(src)
		playsound(src, 'sound/items/taperecorder/taperecorder_stop.ogg', 50, FALSE)
		T.visible_message("<font color=Maroon><B>Tape Recorder</B>: Playback stopped.</font>")
	update_appearance()


/obj/item/taperecorder/verb/play()
	set name = "Play Tape"
	set category = "Object"

	if(!can_use(usr))
		return
	if(!mytape || mytape.ruined)
		return
	if(recording)
		return
	if(playing)
		return

	playing = 1
	update_appearance()
	playsound(src, 'sound/items/taperecorder/taperecorder_play.ogg', 50, FALSE)
	to_chat(usr, span_notice("Playing started."))
	var/used = mytape.used_capacity	//to stop runtimes when you eject the tape
	var/max = mytape.max_capacity
	for(var/i = 1, used <= max, sleep(10 * playsleepseconds))
		if(!mytape)
			break
		if(playing == 0)
			break
		if(mytape.storedinfo.len < i)
			break
		say(mytape.storedinfo[i])
		if(mytape.storedinfo.len < i + 1)
			playsleepseconds = 1
			sleep(10)
			say("End of recording.")
		else
			playsleepseconds = mytape.timestamp[i + 1] - mytape.timestamp[i]
		if(playsleepseconds > 14)
			sleep(10)
			say("Skipping [playsleepseconds] seconds of silence")
			playsleepseconds = 1
		i++

	playing = 0
	update_appearance()


/obj/item/taperecorder/attack_self(mob/user)
	if(!mytape)
		to_chat(user, span_notice("The [src] does not have a tape inside."))
	if(mytape.ruined)
		to_chat(user, span_notice("The tape inside the [src] appears to be broken."))
		return

	update_available_icons()
	if(icons_available)
		var/selection = show_radial_menu(user, src, icons_available, radius = 38, require_near = TRUE, tooltips = TRUE)
		if(!selection)
			return
		switch(selection)
			if("Pause")
				stop()
			if("Stop Recording")  // yes we actually need 2 seperate stops for the same proc- Hopek
				stop()
			if("Record")
				record()
			if("Play")
				play()
			if("Print Transcript")
				print_transcript()
			if("Eject")
				eject(user)


/obj/item/taperecorder/verb/print_transcript()
	set name = "Print Transcript"
	set category = "Object"

	if(!can_use(usr))
		return
	if(!mytape)
		return
	if(!canprint)
		to_chat(usr, span_notice("The recorder can't print that fast!"))
		return
	if(recording || playing)
		return

	to_chat(usr, span_notice("Transcript printed."))
	playsound(src, 'sound/items/taperecorder/taperecorder_print.ogg', 50, FALSE)
	var/obj/item/paper/transcript_paper = new /obj/item/paper(get_turf(src))
	var/t1 = "<h2><center>Transcript:</h2><center><HR><BR>"
	for(var/i = 1, mytape.storedinfo.len >= i, i++)
		t1 += "[mytape.storedinfo[i]]<BR>"
	transcript_paper.add_raw_text(t1)
	transcript_paper.update_appearance()
	usr.put_in_hands(transcript_paper)
	canprint = FALSE
	addtimer(VARSET_CALLBACK(src, canprint, TRUE), 30 SECONDS)

/obj/item/taperecorder/AltClick(mob/user)
	. = ..()
	if (recording)
		stop()
	else
		record()

/obj/item/taperecorder/proc/update_available_icons()
	icons_available = list()

	if(recording)
		icons_available += list("Stop Recording" = image(icon = icon_directory, icon_state = "record_stop"))
	else
		if(!playing)
			icons_available += list("Record" = image(icon = icon_directory, icon_state = "record"))

	if(playing)
		icons_available += list("Pause" = image(icon = icon_directory, icon_state = "pause"))
	else
		if(!recording)
			icons_available += list("Play" = image(icon = icon_directory, icon_state = "play"))

	if(canprint && !recording && !playing)
		icons_available += list("Print Transcript" = image(icon = icon_directory, icon_state = "print"))
	if(mytape)
		icons_available += list("Eject" = image(icon = icon_directory, icon_state = "eject"))

//empty tape recorders
/obj/item/taperecorder/empty
	starting_tape_type = null


/obj/item/tape
	name = "tape"
	desc = "A magnetic tape that can hold up to ten minutes of content."
	icon_state = "tape_white"
	icon = 'icons/obj/device.dmi'
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron=20, /datum/material/glass=5)
	force = 1
	throwforce = 0
	var/max_capacity = 600
	var/used_capacity = 0
	var/list/storedinfo = list()
	var/list/timestamp = list()
	var/ruined = 0

/obj/item/tape/Initialize()
	. = ..()
	if(ruined)
		add_overlay("ribbonoverlay")

/obj/item/tape/fire_act(exposed_temperature, exposed_volume)
	if(!ruined)
		ruin()
	..()

/obj/item/tape/attack_self(mob/user)
	if(!ruined)
		if(do_after(user, 30, src))
			to_chat(user, span_notice("You pull out all the tape!"))
			ruin()

/obj/item/tape/proc/ruin()
	add_overlay("ribbonoverlay")
	ruined = 1

/obj/item/tape/proc/fix()
	cut_overlay("ribbonoverlay")
	ruined = 0


/obj/item/tape/attackby(obj/item/I, mob/user, params)
	if(ruined && (I.tool_behaviour == TOOL_SCREWDRIVER || istype(I, /obj/item/pen)))
		to_chat(user, span_notice("You start winding the tape back in..."))
		if(I.use_tool(src, user, 120))
			to_chat(user, span_notice("You wound the tape back in."))
			fix()

//Random colour tapes
/obj/item/tape/random
	icon_state = "random_tape"

/obj/item/tape/random/Initialize()
	. = ..()
	icon_state = "tape_[pick("white", "blue", "red", "yellow", "purple")]"

//How 2 set custom recorded tapes:
//create a list of lines to populate stored_info. Each line should follow a format like "[timestamp] [speaker] [speaking verb] ["what they're saying"]"
//create a list of timestamps. Each one should correspond to how long the recorder should wait before saying the line associated with the timestamp.
//e.g. "[00:00] Recording started." timestamp = 0
//"[00:15] [span_name("berry fox")] says "wow. I love eating berries so much"" timestamp = 15
//set used capacity to how many 'seconds' used by the prerecorded message
//optional: set max capacity to used capacity
//optional: set ruined var (you can fix this with a pen)

/obj/item/tape/random/preset/wreckage/captain
	used_capacity = 120

/obj/item/tape/random/preset/wreckage/captain/Initialize()
	. = ..()
	storedinfo = list(
		"\[00:00\] Recording started.",
		"\[00:02\] loud rustling, heavy breathing",
		"\[00:05\] frantic kepori shakily speaks, \"This.. uhm.. This is Captain Suuri Natir-Eshi, and..\"",
		"\[00:07\] paper rustling, upset sigh",
		"\[00:10\] frantic kepori shakily speaks, \"We- We're aboard a Befallen-class freighter. For.. |some reason|,  the- the.. Colonials, they want me to.. submit to a search.\"",
		"\[00:12\] frantic kepori suddenly shouts, \"And I'll be DAMNED If- If I let some blueberries walk all over +my+ fucking sh-ship! Yeah..! eerm..\"",
		"\[00:15\] hull groaning, two radar pings",
		"\[00:18\] frantic kepori hastily chirps, \"They'll be here any minute...\"",
		"\[00:21\] frantic kepori hastily chirps, \"What do I say..? To hell with it, they wouldn't believe me...\"",
		"\[00:27\] rustling, then a loud crackle",
		"\[00:29\] wideband relay alarms, \"SV Nebulae! Desist your fleeing this instant or be fired upon!\"",
		"\[00:32\] frantic kepori loudly retorts, \"+G-GO TO HELL, BLUEBERRIES!!+\"",
		"\[00:37\] wideband relay alarms, \"SV Nebulae, this is your final warning! Halt your ship or we will resort to firing our main battery!\"",
		"\[00:42\] loud explosions, hull creaking",
		"\[00:45\] frantic kepori screams, \"Shh-shit! CREW?! PREPARE FOR- ERM- EHH-EVASIVE MANEUVERS- HOLD ON- +WHY AREN'T MMYYY ENGINES WORKING?!+\"",
		"\[00:48\] frantic kepori chirps, \"Fffuck, how do I-\"",
		"\[00:50\] distant explosions, hull creaking",
		"\[00:54\] frantic kepori chirps, \"I need- I need a moment- okay.. I need to help my crew- we're in orbit.. we'll crash land.. and- and they shouldn't chase..\"",
		"\[00:57\] frantic kepori declares, \"Yes.. yes, that will work.. er..\"",
		"\[01:00\] frantic kepori exclaims, \"CREW?! I'M COMING TO HELP! JUST, JUST DO DAMAGE CONTROL FOR NOW, WE'LL-!\"",
		"\[01:02\] airlock opens, loud depressurization, rapidly fading scream",
		"\[01:05\] airlock closes",
		"\[02:00\] bridge recorder states, \"Internal storage filled. Ejecting tape.\"",
	)
	timestamp = list(
		0,
		2,
		5,
		7,
		10,
		12,
		15,
		18,
		21,
		27,
		29,
		32,
		37,
		42,
		45,
		48,
		50,
		54,
		57,
		60,
		62,
		65,
		120
	)
/obj/item/tape/random/preset/wreckage/engineer
	desc = "A magnetic tape that can hold up to ten minutes of content. This one appears to be scratched up, but not in an attempt to destroy it; as the tape is still completely intact. It will need to be wound back in, though, and a screwdriver or pen should work."
	ruined = 1
	used_capacity = 60

/obj/item/tape/random/preset/wreckage/engineer/Initialize()
	. = ..()
	storedinfo = list(
		"\[00:00\] Recording started.",
		"\[00:02\] dejected kepori solemnly chirps, \".. 'ere we go, alright..\"",
		"\[00:05\] long inhale, heavy sigh",
		"\[00:09\] dejected kepori chirps, \"Three whole days on this rock. I don' need'ta tell ya'll how that makes a man feel.\"",
		"\[00:12\] rustling, chair creaking",
		"\[00:15\] dejected kepori chirps, \"I've been through th' wringer enough to know this is a lost cause, so I'm gettin' th' fuck outta dodge before th' air runs out.\"",
		"\[00:18\] dejected kepori chirps loudly, \"I can't keep +fekkin+ waitin' on ya'll to wake up, slowly losin' my mind as th' power slowly dies!\"",
		"\[00:22\] long sigh, plastic clattering",
		"\[00:25\] dejected kepori solemnly chirps, \"I'm sorry I can't stick around. I've gotta find my way outta 'ere alone or die tryin'- cause I'm goin' crazy from th' loneliness.\"",
		"\[00:28\] dejected kepori chirps, \"I foamed up what I could, an' I'm gonna foam up th' exit I take so ya'll don't get monoxide in ya' lungs.\"",
		"\[00:31\] pen tapping on metal",
		"\[00:34\] dejected kepori grumbles, \"An', if ya' see th' captain? |Beat th' fek outta him fer stranding me on this rock|. Please.\"",
		"\[00:37\] dejected kepori rasps, \"If ya had t' rewind th' tape t' hear this, I needed th' relief. Tha's all. I ain't got nothin' t' hide.\"",
		"\[00:40\] dejected kepori chirps, \"Not like th' weasel of a 'captain' we had.. |Fekkin' prick|.\"",
		"\[00:44\] dejected kepori chirps, \"When ya'll wake up, and you will- th' cyrogenics is gonna die out, don't come lookin' fer me. I'll be a day away by th' time ya' get ejected.\"",
		"\[00:48\] dejected kepori warns, \"an' be careful. Th' clippers 'ave been sending shuttles around to search fer.. somethin'. Probably us, given.. y'know.\"",
		"\[00:50\] shaky sigh, chair moving",
		"\[00:55\] dejected kepori quietly grumbles, \"nothin' more t' say.. ugh.. Fek this fekkin' ship.\"",
		"\[01:00\] Recording ended.",
	)
	timestamp = list(
		0,
		2,
		5,
		9,
		12,
		15,
		18,
		22,
		25,
		28,
		31,
		34,
		37,
		40,
		44,
		48,
		50,
		55,
		60
	)
