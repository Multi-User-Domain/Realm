extends Node2D


# Declare member variables here, e.g.
# var a = 2

# when the node is loaded into the scene we fetch references to its children
onready var HUD = get_node("HUD")


# Called when the node enters the scene tree for the first time.
func _ready():
	# init game
	pass

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
