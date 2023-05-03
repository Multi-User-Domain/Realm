extends Node2D


# when the node is loaded into the scene we fetch references to its children
onready var HUD = get_node("HUD")
onready var player1_avatar = get_node("Player1Avatar")
onready var player1_cards = get_node("Player1Cards")
onready var player2_cards = get_node("Player2Cards")
onready var player2_avatar = get_node("Player2Avatar")
onready var card_tray = get_node("CardTray")

# preload scenes that we want to instantiate programatically
var card_scene = preload("res://obj/card/Card.tscn")


func _add_card_to_node(node: Node2D):
	var card = card_scene.instance()
	card.scale = card.scale * 0.5
	card.set_position(node.position)
	node.add_child(card)

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
	
	# spawn placeholder cards to test placement
	_add_card_to_node(player1_avatar)
	_add_card_to_node(player1_cards)
	_add_card_to_node(player2_cards)
	_add_card_to_node(player2_avatar)
	_add_card_to_node(card_tray)
	
	player1_avatar.init_new_player()
	player2_avatar.init_new_player()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			# event.position for mouse screen co-ords
			pass
		
		elif event.button_index == BUTTON_RIGHT:
			pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
