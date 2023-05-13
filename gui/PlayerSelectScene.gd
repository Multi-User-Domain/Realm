extends Node2D

onready var game = get_tree().current_scene

export var column_size = 8
var player_avatars = []

# preload scenes that we want to instantiate programatically
var avatar_scene = preload("res://player/avatar/Avatar.tscn")
var selected_avatar = null
var _selected_avatar_row_idx = null
var _selected_avatar_col_idx = null

func get_avatar_count():
	var row_count = len(player_avatars)
	if row_count == 0:
		return 0
	var last_row_col_count = len(player_avatars[row_count - 1])
	return last_row_col_count + ((row_count - 1) * column_size)

func init():
	for key in Globals.AVATAR_CACHE.keys():
		var avatar_instance = avatar_scene.instance()
		add_child(avatar_instance)
		
		var avatar_jsonld = game.load_avatar_from_jsonld(Globals.AVATAR_CACHE[key])
		avatar_instance.init_sprite(avatar_jsonld)
		
		# TODO: calculate the number of columns to a row
		var row = ceil(get_avatar_count() / column_size) + 1
		var row_idx = row - 1
		if row_idx >= len(player_avatars):
			player_avatars.append([])
		
		var column = len(player_avatars[row_idx]) + 1
		var margin = Vector2(5, 5)
		var portrait_size = avatar_instance.get_portrait_size()
		var half_portrait_size = portrait_size * 0.5
		avatar_instance.portrait_sprite.set_scale(Vector2(0.25, 0.25))
		avatar_instance.get_node("BackgroundGlow").set_scale(Vector2(0.25, 0.25))
		
		avatar_instance.set_position(
			margin + Vector2((column * portrait_size.x) + (10 * column), (row * portrait_size.y) + (10 * row))
		)
		
		player_avatars[row_idx].append(avatar_instance)
	
	if len(player_avatars) > 0:
		set_selected_avatar(0, 0)

func tear_down():
	for row in player_avatars:
		for avatar in player_avatars[row]:
			avatar.get_node("..").remove_child(avatar)
			avatar.queue_free()
	
	player_avatars = []

func set_selected_avatar(row_idx, col_idx):
	# animating the deselection of current avatar
	if selected_avatar != null:
		var ava = player_avatars[_selected_avatar_row_idx][_selected_avatar_col_idx]
		selected_avatar.animate_deselect()
	
	# bounding the row_idx and col_idx given
	if row_idx >= len(player_avatars):
		row_idx = 0
	elif row_idx < 0:
		row_idx = len(player_avatars) - 1
	
	if col_idx >= len(player_avatars[row_idx]):
		col_idx = 0
	elif col_idx < 0:
		col_idx = len(player_avatars[row_idx]) - 1
	
	# setting the new selected avatar
	_selected_avatar_row_idx = row_idx
	_selected_avatar_col_idx = col_idx
	selected_avatar = player_avatars[row_idx][col_idx]
	selected_avatar.animate_select()

func _process(delta):
	# only process input if the scene is active
	if game.game_phase != Globals.GAME_PHASE.PLAYER_SELECTION:
		return
	
	# cycling through the selectable avatars with UI controls
	if Input.is_action_just_pressed("ui_right"):
		set_selected_avatar(_selected_avatar_row_idx, _selected_avatar_col_idx + 1)
	if Input.is_action_just_pressed("ui_left"):
		set_selected_avatar(_selected_avatar_row_idx, _selected_avatar_col_idx - 1)
	if Input.is_action_just_pressed("ui_up"):
		set_selected_avatar(_selected_avatar_row_idx + 1, _selected_avatar_col_idx)
	if Input.is_action_just_pressed("ui_down"):
		set_selected_avatar(_selected_avatar_row_idx - 1, _selected_avatar_col_idx)
