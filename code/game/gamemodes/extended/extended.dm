/datum/game_mode/extended
	name = "secret extended"
	config_tag = "secret_extended"
	report_type = "extended"
	false_report_weight = 5
	required_players = 0

	announce_span = "notice"
	announce_text = "Just have fun and enjoy the game!"

	title_icon = "shiptest"

/datum/game_mode/extended/pre_setup()
	return 1
