extends Node2D

# Declare member variables here, e.g.
# var a = 2

onready var game = get_tree().current_scene
onready var sprite = get_node("ColorRect/MarginContainer/Sprite")
onready var name_label = get_node("ColorRect/MarginContainer2/Description")
var jsonld_store = {}

# for controlling the animation of card selection
export(float) var grow_factor = 1.5
export(Vector2) var default_scale = Vector2(1, 1) # the default scale of a card
var init_scale
var init_position
var focus_position

func _ready():
	pass

func _init_jsonld_data(card_jsonld):
	jsonld_store = card_jsonld
	
	if not "n:fn" in jsonld_store:
		# TODO: find defaults via author name, etc
		jsonld_store["n:fn"] = "Unknown"
	
	if not "@id" in jsonld_store:
		jsonld_store["@id"] = "_Card_" + jsonld_store["n:fn"] + str(randi())

func init_card(card_jsonld):
	# calculate and log variables used in animating select/deselect
	init_scale = get_scale()
	init_position = get_position()
	focus_position = init_position + Vector2(0, -200)
	
	_init_jsonld_data(card_jsonld)
	
	# TODO: https://github.com/Multi-User-Domain/games-transformed-jam-2023/issues/1
	var depiction = get_rdf_property("foaf:depiction")
	if depiction != null:
		sprite.set_texture(load(depiction))
		# 128, 128 with the in-built textures
		sprite.set_scale(Vector2(0.125, 0.125))
	
	name_label.set_text(get_rdf_property("n:fn"))

# TODO: find a more DRY way to do this across nodes
func get_rdf_property(property):
	if property in self.jsonld_store:
		return self.jsonld_store[property]
	
	return null

func set_rdf_property(property, value):
	self.jsonld_store[property] = value

# animations for card selection
func animate_select():
	$BackgroundGlow.set_visible(true)
	$Tween.interpolate_property(self, "position", init_position, focus_position, .5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.interpolate_property(self, "scale", init_scale, default_scale * grow_factor, .5,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
	$Tween.start()

func animate_deselect():
	$BackgroundGlow.set_visible(false)
	$Tween.interpolate_property(self, "position", focus_position, init_position, .5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.interpolate_property(self, "scale", default_scale * grow_factor, init_scale, .5,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
	$Tween.start()
