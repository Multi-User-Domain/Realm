extends Node2D


# when the node is loaded into the scene we fetch references to its children
onready var HUD = get_node("HUD")
onready var player1_avatar = get_node("Player1Avatar")
onready var player1_cards = get_node("Player1Cards")
onready var player2_cards = get_node("Player2Cards")
onready var player2_avatar = get_node("Player2Avatar")
onready var card_tray = get_node("CardTray")
onready var rdf_manager = get_node("RDFManager")
onready var turn_manager = get_node("TurnManager")
onready var world_manager = get_node("WorldManager")

# export means that it can be set from the Scene editor
# the scale transformation to apply to card size
var full_card_size = Vector2(128, 176)
export var card_scale = 0.5

var selected_card = null

# preload scenes that we want to instantiate programatically
var card_scene = preload("res://obj/card/Card.tscn")


func get_card_size():
	return full_card_size * card_scale

func _add_card_for_player(player_index: int, jsonld_data):
	var node = null
	if player_index == 0:
		node = player1_cards
	else:
		node = player2_cards
	
	# instantiate card and add to scene
	var card = card_scene.instance()
	card.scale = card.scale * card_scale
	card.set_position(node.position + Vector2((node.get_child_count() * get_card_size().x) * 1.2, 0))
	node.add_child(card)
	
	# init card data
	card.init_card(jsonld_data)

func _remove_card_with_urlid(urlid):
	var card_found = null
	
	for card in player1_cards.get_children():
		if card.has_method("get_rdf_property") and card.get_rdf_property("@id") == urlid:
			card_found = card
			break
	
	if card_found == null:
		for card in player2_cards.get_children():
			if card.has_method("get_rdf_property") and card.get_rdf_property("@id") == urlid:
				card_found = card
				break
	
	if card_found != null:
		card_found.get_node("..").remove_child(card_found)
		card_found.queue_free()
	else:
		print("ERR _remove_card_with_urlid. Card not found in active cards " + urlid)

func load_avatar_from_jsonld(file_path):
	var save_file = File.new()
	save_file.open(file_path, File.READ)
	return parse_json(save_file.get_as_text())

func load_cards_for_tray():
	var save_file = File.new()
	save_file.open("res://assets/rdf/deck/coreOptionals.json", File.READ)
	return parse_json(save_file.get_as_text())

# Called when the node enters the scene tree for the first time.
func _ready():
	# init game
	# position the UI in segments
	var viewport_size = get_viewport().size
	var y_margin = 5
	var quarter_height = viewport_size.y * 0.25
	var x_margin = 10
	
	# top 3 quarters for the arena
	var three_quarters = quarter_height * 3
	var arena_quarter = three_quarters * 0.25
	
	# of that split into 4 (each player has an avatar and a card field)
	player1_avatar.set_position(Vector2(x_margin, y_margin))
	player1_cards.set_position(Vector2(x_margin, y_margin + arena_quarter))
	player2_cards.set_position(Vector2(x_margin, y_margin + (arena_quarter * 2)))
	player2_avatar.set_position(Vector2(x_margin, y_margin + (arena_quarter * 3)))
	
	# bottom quarter for player card actions
	card_tray.set_position(Vector2(x_margin, y_margin + (quarter_height * 3)))
	card_tray.cards_start_pos.position.y = card_tray.position.y
	
	# init players with JSON-LD data for the avatar, and their starting cards
	player1_avatar.init_player(0, load_avatar_from_jsonld(Globals.AVATAR_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/ospreyWithers.json"]))
	player2_avatar.init_player(1, load_avatar_from_jsonld(Globals.AVATAR_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/rdf/avatar/sumeri.json"]))
	
	card_tray.init_deck(load_cards_for_tray())
	world_manager.init_world()

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

# takes a turn for both players
func next_turn():
	for card in player1_avatar.card_manager.play_cards():
		_add_card_for_player(0, card)
	
	for card in player2_avatar.card_manager.play_cards():
		_add_card_for_player(1, card)

func _give_selected_card_to_player(player_index):
	if selected_card == null:
		return
	
	# player_index is 0 or 1
	if player_index == 0:
		get_node("Player1Avatar").card_manager.add_to_deck(selected_card.jsonld_store)
	else:
		get_node("Player2Avatar").card_manager.add_to_deck(selected_card.jsonld_store)
	
	# remove the card from the tray and get the next one
	var right_card = card_tray.get_card_to_right_of(selected_card)
	var left_card = card_tray.get_card_to_left_of(selected_card)
	card_tray.remove_card(selected_card)
	if card_tray.has_empty_hand():
		card_tray.draw_new_hand()
		# still has empty hand after drawing - ran out of cards
		if card_tray.has_empty_hand():
			turn_manager.start()
	else:
		if right_card != null:
			set_selected_card(right_card)
		else:
			set_selected_card(left_card)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# UI accept is bound to Xbox A and keyboard space
	if Input.is_action_just_pressed("ui_accept"):
		_give_selected_card_to_player(0)
	# UI cancel is bound to Xbox B and keyboard escape
	elif Input.is_action_just_pressed("ui_cancel"):
		_give_selected_card_to_player(1)
	# TODO: pressing Xbox "X" should discard the card
	
	# cycling through the selectable cards with UI controls
	var next_card = null
	if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_left"):
		if Input.is_action_just_pressed("ui_right"):
			next_card = card_tray.get_card_to_right_of(selected_card)
		if Input.is_action_just_pressed("ui_left"):
			next_card = card_tray.get_card_to_left_of(selected_card)
	
		if next_card != null:
			set_selected_card(next_card)
		else:
			# TODO: support selecting cards in the battlefield
			pass

func set_selected_card(card_scene):
	if selected_card != null:
		selected_card.animate_deselect()
	selected_card = card_scene
	var card_parent = selected_card.get_node("..")
	card_parent.move_child(selected_card, card_parent.get_child_count())
	selected_card.animate_select()
