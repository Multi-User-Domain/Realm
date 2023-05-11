extends Node2D

onready var game = get_tree().current_scene

var player_avatars = []

# preload scenes that we want to instantiate programatically
var avatar_scene = preload("res://player/avatar/Avatar.tscn")
var selected_avatar = null

func init():
	for key in Globals.AVATAR_CACHE.keys():
		var avatar_instance = avatar_scene.instance()
		add_child(avatar_instance)
		
		var avatar_jsonld = game.load_avatar_from_jsonld(Globals.AVATAR_CACHE[key])
		avatar_instance.init_sprite(avatar_jsonld)
		
		# TODO: calculate the number of columns to a row
		var column_size = 8
		var row = ceil(len(player_avatars) / column_size) + 1
		var column = len(player_avatars) % column_size + 1
		var margin = Vector2(5, 5)
		var portrait_size = avatar_instance.get_portrait_size()
		var half_portrait_size = portrait_size * 0.5
		avatar_instance.portrait_sprite.set_scale(Vector2(0.25, 0.25))
		avatar_instance.get_node("BackgroundGlow").set_scale(Vector2(0.25, 0.25))
		
		avatar_instance.set_position(
			margin + Vector2((column * portrait_size.x) + (10 * column), (row * portrait_size.y) + (10 * row))
		)
		
		player_avatars.append(avatar_instance)
	
	set_selected_avatar(player_avatars[0])

func tear_down():
	for avatar in player_avatars:
		avatar.get_node("..").remove_child(avatar)
		avatar.queue_free()
	
	player_avatars = []

func set_selected_avatar(avatar_scene):
	if selected_avatar != null:
		selected_avatar.animate_deselect()
	selected_avatar = avatar_scene
	selected_avatar.animate_select()
