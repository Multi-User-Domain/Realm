extends Node2D

onready var game = get_tree().current_scene
onready var wd = get_node("WindowDialog")
onready var sprite = get_node("WindowDialog/Sprite")
onready var des_label = get_node("WindowDialog/DescriptionLabel")
onready var choices_pos = get_node("WindowDialog/ChoicesPos")

var active_player_scene = null
var opponent_scene = null

func _get_sprite_size():
	return Vector2(512, 512)

func render_elements():
	# size the window
	var viewport_size = get_viewport_rect().size
	var margin = Vector2(100, 100)
	
	wd.set_size(viewport_size - margin)
	wd.rect_position = margin * 0.5
	
	# position the window elements
	sprite.set_position(wd.rect_position + Vector2(10, 10) + _get_sprite_size() * 0.5)
	var aligned_x = sprite.position.x
	sprite.position.x = viewport_size.x * 0.5
	des_label.rect_position = Vector2(aligned_x, (sprite.position.y + 10) + (_get_sprite_size().y * 0.5))
	des_label.set_size(Vector2(wd.rect_size.x - 10, 20))
	choices_pos.set_position(des_label.rect_position + Vector2(0, 30))

func get_title_from_event(event_jsonld):
	var event_string = "Event"
	
	if "n:fn" in event_jsonld:
		event_string = event_jsonld["n:fn"]
	if "foaf:name" in event_jsonld:
		event_string = event_jsonld["foaf:name"]
	if "@id" in event_jsonld:
		event_string = event_jsonld["@id"]
	
	var avatar_string = ""
	if active_player_scene != null:
		avatar_string = " - " + active_player_scene.get_rdf_property("n:fn")
	
	return event_string + avatar_string

func configure(event_jsonld, active_player_index=0):
	if not "mudlogic:hasChoices" in event_jsonld:
		return
	
	# configure the active player
	if active_player_index == 0:
		active_player_scene = game.battle_scene.player1_avatar
		opponent_scene = game.battle_scene.player2_avatar
	else:
		active_player_scene = game.battle_scene.player2_avatar
		opponent_scene = game.battle_scene.player1_avatar
	
	# configure event content
	wd.set_title(get_title_from_event(event_jsonld))
	if "foaf:depiction" in event_jsonld:
		# function initialises the Avatar with new player information
		sprite.set_texture(game.rdf_manager.get_texture_from_jsonld(event_jsonld["foaf:depiction"]))
		# TODO: https://github.com/Multi-User-Domain/games-transformed-jam-2023/issues/1
		# 128, 128 with the in-built textures
		# portrait_sprite.set_scale(Vector2(0.25, 0.25))
	if "n:hasNote" in event_jsonld:
		des_label.set_text(event_jsonld["n:hasNote"])
	
	# add buttons for each choice
	for choice in event_jsonld["mudlogic:hasChoices"]:
		if not "n:fn" in choice:
			continue
		var button = Button.new()
		var margin = Vector2(0, 30) * (choices_pos.get_child_count() + 1)
		button.set_position(choices_pos.position + margin)
		button.set_text(choice["n:fn"])
		button.connect("pressed", self, "_choice_button_pressed", [choice, active_player_index])
		choices_pos.add_child(button)
	
	wd.popup_centered()
	render_elements()

func _choice_button_pressed(choice_jsonld):
	game.turn_manager._play_card_actions(
		active_player_scene, opponent_scene, [[choice_jsonld, choice_jsonld]]
	)
	wd.hide()
