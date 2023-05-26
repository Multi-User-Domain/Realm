extends CanvasLayer

onready var game = get_tree().current_scene
onready var event_window = get_node("EventWindow")
onready var summary_window = get_node("BattleSummaryWindow")

func _ready():
	pass

func get_battle_summary_text():
	# first summarise the battle result
	var winner_name = null
	var battle_summary_text = ""
	if game.battle_scene.winner != null:
		winner_name = game.battle_scene.winner.get_rdf_property("n:fn")
		battle_summary_text = winner_name + " triumphed in this game."
	else:
		battle_summary_text = "Game over."
	
	# explain what happens next
	var next_what_happens = "The output world of your game has been saved on a server which one day you'll be able to take to other games, please ask us what that means. We wanted to show you more but we ran out of time ^^'"
	
	return battle_summary_text + "\n\n" + next_what_happens

func get_battle_summary_depiction():
	var depiction = null
	
	if game.battle_scene.winner != null:
		game.battle_scene.winner.get_rdf_property("foaf:depiction")
	
	return depiction

func display_battle_summary():
	# TODO: added recorded history summary which I can scroll through before hitting accept
	# var recorded_history = game.world_manager.get_rdf_property("twt2023:hasRecordedHistory")
	
	var summary_obj = {
		"@context": {
			"n": "http://www.w3.org/2006/vcard/ns#",
			"foaf": "http://xmlns.com/foaf/0.1/",
			"mud": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mud#",
			"mudchar": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudchar.ttl#",
			"mudcard": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcard.ttl#",
			"mudcombat": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudcombat.ttl#",
			"twt2023": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#"
		},
		"@id": "_:TempSummaryObj",
		"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#Event",
		"n:fn": "Game Over",
		"n:hasNote": get_battle_summary_text(),
		"twt2023:maximumUses": 1,
		"mudlogic:hasChoices": [
			{
				"n:fn": "Restart",
				"@id": "_:SPECIAL_RESET_GAME",
				"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/mudlogic.ttl#Action",
			}
		]
	}
	
	var depiction = get_battle_summary_depiction()
	if depiction != null:
		summary_obj["foaf:depiction"] = depiction
	
	summary_window.configure(summary_obj)
