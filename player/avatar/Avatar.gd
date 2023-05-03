extends Node2D

onready var portrait_sprite = get_node("PortraitSprite")

func _ready():
	pass

func init_new_player(texture_path):
	# function initialises the Avatar with new player information
	portrait_sprite.set_texture(load(texture_path))
	# TODO: https://github.com/Multi-User-Domain/games-transformed-jam-2023/issues/1
	# 128, 128 with the in-built textures
	portrait_sprite.set_scale(Vector2(0.25, 0.25))
	var half_portrait = Vector2(64, 64) # also needs to become relative to size
	# centre along the x axis
	portrait_sprite.set_position(Vector2(get_viewport_rect().size.x * 0.5, self.position.y) + half_portrait)
