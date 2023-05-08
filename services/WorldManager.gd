extends Node2D

onready var game = get_tree().current_scene

# the purpose of this Node is to manage the world state, i.e.
# to record history and world changes made by cards

var jsonld_store = {}
var history = []

func load_world(file_path):
	var save_file = File.new()
	save_file.open(file_path, File.READ)
	return parse_json(save_file.get_as_text())

func init_world():
	jsonld_store = load_world("res://assets/rdf/world/defaultWorld.json")

# TODO: find a more DRY way to do this across nodes
func get_rdf_property(property):
	if property in self.jsonld_store:
		return self.jsonld_store[property]
	
	return null

func set_rdf_property(property, value):
	self.jsonld_store[property] = value
