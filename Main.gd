extends Node2D


# when the node is loaded into the scene we fetch references to its children
onready var HUD = get_node("HUD")
onready var federation_manager = get_node("FederationManager")
onready var rdf_manager = get_node("RDFManager")
onready var turn_manager = get_node("TurnManager")
onready var world_manager = get_node("WorldManager")
onready var battle_scene = get_node("BattleScene")
onready var player_select_scene = get_node("PlayerSelectScene")

# export means that it can be set from the Scene editor
# the scale transformation to apply to card size
var full_card_size = Vector2(128, 176)
export var card_scale = 0.5

var game_phase = null

# preload scenes that we want to instantiate programatically
var card_scene = preload("res://obj/card/Card.tscn")


func get_card_size():
	return full_card_size * card_scale

func load_avatar_from_jsonld(file_path):
	var save_file = File.new()
	save_file.open(file_path, File.READ)
	return parse_json(save_file.get_as_text())

func load_avatar_from_urlid(urlid):
	if urlid in Globals.AVATAR_CACHE:
		return load_avatar_from_jsonld(Globals.AVATAR_CACHE[urlid])
	
	# TODO: support distant characters
	return null

func load_cards_for_tray():
	var save_file = File.new()
	save_file.open("res://assets/rdf/deck/coreOptionals.json", File.READ)
	return parse_json(save_file.get_as_text())

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: set a random seed - do for prod
	# randomize()
	
	# init game
	world_manager.init_world()
	set_game_phase(Globals.GAME_PHASE.PLAYER_SELECTION)

# NOTE: feel free to use mouse input in debugging, but the game is for an xbox controller
# https://github.com/Multi-User-Domain/games-transformed-jam-2023/issues/2
"""
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			# event.position for mouse screen co-ords
			pass
		
		elif event.button_index == BUTTON_RIGHT:
			pass
"""

func set_game_phase(new_phase):
	# tear down the old phase
	if game_phase == Globals.GAME_PHASE.PLAYER_SELECTION:
		player_select_scene.tear_down()
	
	game_phase = new_phase
	
	# set up the new phase
	if game_phase == Globals.GAME_PHASE.PLAYER_SELECTION:
		player_select_scene.init()
	elif game_phase == Globals.GAME_PHASE.DECK_BUILDING:
		var selected_players = player_select_scene.confirm_selected_players
		if len(selected_players) < 2:
			selected_players = [
				load_avatar_from_jsonld(Globals.AVATAR_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/ospreyWithers.json"]),
				load_avatar_from_jsonld(Globals.AVATAR_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/sumeri.json"])
			]
		battle_scene.init(
			selected_players[0],
			selected_players[1]
		)
		
	elif game_phase == Globals.GAME_PHASE.BATTLE:
		turn_manager.start()

func display_battle_results():
	var recorded_history = world_manager.get_rdf_property("twt2023:hasRecordedHistory")

func end_battle():
	game_phase = Globals.GAME_PHASE.BATTLE_SUMMARY
	turn_manager.stop()
	display_battle_results()
