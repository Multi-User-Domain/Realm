extends Node2D

onready var game = get_tree().current_scene
onready var player1_avatar = get_node("Player1Avatar")
onready var player1_cards = get_node("Player1Cards")
onready var player2_cards = get_node("Player2Cards")
onready var player2_avatar = get_node("Player2Avatar")
onready var history_stream = get_node("HistoryStream")
onready var card_tray = get_node("CardTray")

var winner = null
var selected_card = null

# preload scenes that we want to instantiate programatically
var card_scene = preload("res://obj/card/Card.tscn")

func init(player1_jsonld, player2_jsonld):
	# position the UI in segments
	var viewport_size = get_viewport_rect().size
	var quarter_height = viewport_size.y * 0.25
	
	# top 3 quarters for the arena
	var three_quarters = quarter_height * 3
	var arena_quarter = three_quarters * 0.25
	
	var portrait_size = player1_avatar.get_portrait_size()
	var half_portrait = portrait_size * 0.5
	
	# of that split into 4 (each player has an avatar and a card field)
	var avatar_x_pos = viewport_size.x * 0.4
	var avatar_y_pos = half_portrait.y
	player1_avatar.set_position(Vector2(avatar_x_pos, avatar_y_pos))
	player1_cards.set_position(Vector2(0, arena_quarter))
	player2_cards.set_position(Vector2(0, arena_quarter * 1.5))
	# temporary place in the same place as their cards - will later be moved down the screen
	player2_avatar.set_position(Vector2(avatar_x_pos, avatar_y_pos + (arena_quarter * 1.5)))
	
	# bottom quarter for player card actions
	card_tray.set_position(Vector2(0, arena_quarter * 2))
	card_tray.cards_start_pos.position.y = card_tray.position.y
	
	# init players with JSON-LD data for the avatar, and their starting cards
	winner = null
	player1_avatar.init_player(0, player1_jsonld)
	player2_avatar.init_player(1, player2_jsonld)
	
	history_stream.set_position(Vector2(player1_avatar.position.x + 200, 0))
	history_stream.set_size(Vector2(viewport_size.x - history_stream.rect_position.x, viewport_size.y - 5))
	
	card_tray.init_deck(game.load_cards_for_tray())

func tear_down():
	for card in player1_cards.get_children():
		player1_cards.remove_child(card)
		card.queue_free()
	for card in player2_cards.get_children():
		player2_cards.remove_child(card)
		card.queue_free()
	player1_avatar.card_manager.clear_cards()
	player2_avatar.card_manager.clear_cards()
	winner = null
	selected_card = null
	set_visible(false)

func start_battle():
	var viewport_size = get_viewport_rect().size
	var portrait_size = player1_avatar.get_portrait_size()
	var half_portrait = portrait_size * 0.5
	var avatar_x_pos = viewport_size.x * 0.4
	var avatar_y_pos = half_portrait.y
	# top 3 quarters for the arena
	var quarter_height = viewport_size.y * 0.25
	var three_quarters = quarter_height * 3
	var arena_quarter = three_quarters * 0.25
	
	player2_avatar.set_position(Vector2(avatar_x_pos, avatar_y_pos + (arena_quarter * 3.5)))

func _position_card_in_node_for_active_cards(node, card):
	# positions the card in a tray of active cards
	# makes sure not to overlap cards
	for i in range(node.get_child_count() + 1):
		var candidate_pos = node.position + Vector2((i * game.get_card_size().x) * 1.2, 0)
		var can_place_here = true
		for peer in node.get_children():
			if peer.position.x - candidate_pos.x == 0:
				can_place_here = false
				break
		if can_place_here:
			card.set_position(candidate_pos)
			return
	card.set_position(node.position + Vector2(0, 0))

func _add_card_for_player(player_index: int, jsonld_data):
	var node = null
	var player_cm = null
	if player_index == 0:
		node = player1_cards
		player_cm = player1_avatar.card_manager
	else:
		node = player2_cards
		player_cm = player2_avatar.card_manager
	
	# instantiate card and add to scene
	var card = card_scene.instance()
	card.scale = card.scale * game.card_scale
	_position_card_in_node_for_active_cards(node, card)
	node.add_child(card)
	
	# init card data
	card.init_card(jsonld_data, player_cm)

func get_card_with_urlid(urlid):
	"""
	:return: card_scene matching urlid, null if not found
	"""
	for card in player1_cards.get_children():
		if card.has_method("get_rdf_property") and card.get_rdf_property("@id") == urlid:
			return card
	
	for card in player2_cards.get_children():
		if card.has_method("get_rdf_property") and card.get_rdf_property("@id") == urlid:
			return card
	
	return null

func _remove_card_with_urlid(urlid):
	var card_scene = get_card_with_urlid(urlid)
	
	if card_scene != null:
		card_scene.get_node("..").remove_child(card_scene)
		card_scene.queue_free()
	else:
		print("ERR _remove_card_with_urlid. Card not found in active cards " + urlid)

func set_selected_card(card_scene):
	if selected_card != null:
		selected_card.animate_deselect()
	selected_card = card_scene
	var card_parent = selected_card.get_node("..")
	card_parent.move_child(selected_card, card_parent.get_child_count())
	selected_card.animate_select()

# takes a turn for both players
func next_turn():
	for card in player1_avatar.card_manager.play_cards():
		_add_card_for_player(0, card)
	
	for card in player2_avatar.card_manager.play_cards():
		_add_card_for_player(1, card)

func _remove_selected_card_from_tray():
	if selected_card == null:
		return
	
	var right_card = card_tray.get_card_to_right_of(selected_card)
	var left_card = card_tray.get_card_to_left_of(selected_card)
	card_tray.remove_card(selected_card)
	if card_tray.has_empty_hand():
		card_tray.draw_new_hand()
		# still has empty hand after drawing - ran out of cards, so start the game!
		if card_tray.has_empty_hand():
			game.set_game_phase(Globals.GAME_PHASE.BATTLE)
	else:
		if right_card != null:
			set_selected_card(right_card)
		else:
			set_selected_card(left_card)

func _give_selected_card_to_player(player_index):
	if selected_card == null:
		return
	
	# player_index is 0 or 1
	if player_index == 0:
		player1_avatar.card_manager.add_to_deck(selected_card.jsonld_store)
	else:
		player2_avatar.card_manager.add_to_deck(selected_card.jsonld_store)
	
	# remove the card from the tray and get the next one
	_remove_selected_card_from_tray()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# only process input if the scene is active
	if not game.game_phase in [Globals.GAME_PHASE.DECK_BUILDING]:
		return
	
	# UI accept is bound to Xbox A and keyboard space
	if Input.is_action_just_pressed("ui_accept"):
		_give_selected_card_to_player(0)
	# UI cancel is bound to Xbox B and keyboard escape
	elif Input.is_action_just_pressed("ui_cancel"):
		_give_selected_card_to_player(1)
	# pressing keyboard or Xbox "X" should discard the card
	elif Input.is_action_just_pressed("x_button"):
		_remove_selected_card_from_tray()
	
	# cycling through the selectable cards with UI controls
	var next_card = null
	if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_left"):
		if Input.is_action_just_pressed("ui_right"):
			next_card = card_tray.get_card_to_right_of(selected_card)
		if Input.is_action_just_pressed("ui_left"):
			next_card = card_tray.get_card_to_left_of(selected_card)
	
		if next_card != null:
			set_selected_card(next_card)
