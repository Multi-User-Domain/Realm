extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# below is for references to other nodes when we add them
# onready var grid = get_node("Grid")


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
