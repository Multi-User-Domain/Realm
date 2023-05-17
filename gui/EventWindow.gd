extends Node2D

onready var game = get_tree().current_scene
onready var wd = get_node("WindowDialog")
onready var sprite = get_node("WindowDialog/Sprite")
onready var des_label = get_node("WindowDialog/DescriptionLabel")
onready var choices_pos = get_node("WindowDialog/ChoicesPos")

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
	if "n:fn" in event_jsonld:
		return event_jsonld["n:fn"]
	if "foaf:name" in event_jsonld:
		return event_jsonld["foaf:name"]
	if "@id" in event_jsonld:
		return event_jsonld["@id"]
	return "Event"

func configure(event_jsonld):
	if not "mudlogic:hasChoices" in event_jsonld:
		return
	
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
		choices_pos.add_child(button)
	
	wd.popup_centered()
	render_elements()
