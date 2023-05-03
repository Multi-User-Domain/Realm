extends Node2D

# Declare member variables here, e.g.
# var a = 2

onready var game = get_tree().current_scene
onready var sprite = get_node("ColorRect/MarginContainer/Sprite")
onready var name_label = get_node("ColorRect/MarginContainer2/Description")
var jsonld_store = {}

func _ready():
	pass

func _init_jsonld_data(card_jsonld):
	jsonld_store = card_jsonld
	
	if not "n:fn" in jsonld_store:
		# TODO: find defaults via author name, etc
		jsonld_store["n:fn"] = "Unkown"

func init_card(card_jsonld):
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
