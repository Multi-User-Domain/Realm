extends Node2D


# Declare member variables here, e.g.
# var a = 2

# when the node is loaded into the scene we fetch references to its children
onready var HUD = get_node("HUD")
onready var player1_hand = get_node("Player1Hand")
onready var player1_active = get_node("Player1Active")
onready var player2_active = get_node("Player2Active")
onready var player2_hand = get_node("Player2Hand")

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
	# position parts of the UI
	var viewport_size = get_viewport().size
	var y_margin = 5
	var quarter_height = viewport_size.y * 0.25
	var x_margin = 10
	player1_hand.set_position(Vector2(x_margin, y_margin))
	player1_active.set_position(Vector2(x_margin, y_margin + quarter_height))
	player2_active.set_position(Vector2(x_margin, y_margin + (quarter_height * 2)))
	player2_hand.set_position(Vector2(x_margin, y_margin + (quarter_height * 3)))
	
	# spawn placeholder cards to test placement
	_add_card_to_node(player1_hand)
	_add_card_to_node(player1_active)
	_add_card_to_node(player2_active)
	_add_card_to_node(player2_hand)

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
