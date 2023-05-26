extends Node2D

onready var game = get_tree().current_scene

# the purpose of this Node is to manage the world state, i.e.
# to record history and world changes made by cards

var jsonld_store = {}
var history = []

func get_world_data():
	return jsonld_store

func load_world(file_path):
	var save_file = File.new()
	save_file.open(file_path, File.READ)
	return parse_json(save_file.get_as_text())

func init_world():
	jsonld_store = load_world("res://assets/rdf/world/defaultWorld.json")
	
	if not "mudworld:hasRegions" in jsonld_store:
		jsonld_store["mudworld:hasRegions"] = []
	
	if not "twt2023:hasRecordedHistory" in jsonld_store:
		jsonld_store["twt2023:hasRecordedHistory"] = []

# uses the region & subregion schema of mudworld (https://github.com/Multi-User-Domain/vocab/blob/main/mudworld.ttl)
func add_new_sub_region(sub_region):
	jsonld_store["mudworld:hasRegions"].append(sub_region)

func render_history():
	var history_text = ""
	for item in history:
		history_text += item["n:hasNote"] + "\n\n"
	game.battle_scene.history_stream.set_text(history_text)

func add_to_history(recorded_history_item):
	history.append(recorded_history_item)
	render_history()

func record_death_by_effect(deceased, event):
	if event["@id"] == Globals.BUILT_IN_EFFECTS.POISON:
		add_to_history({
			"@id": "_:death_" + str(randi()),
			"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#RecordedHistory",
			"n:hasNote": deceased["n:fn"] + " died from an old wound"
		})

func record_death_by_attack(deceased, actor, attack):
	attack = game.rdf_manager.obj_through_urlid(attack)
	add_to_history({
		"@id": "_:death_" + str(randi()),
		"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#RecordedHistory",
		"n:hasNote": deceased["n:fn"] + " was slain by " + actor["n:fn"] + "  while performing a " + attack["n:fn"]
	})

func record_defense_roll_success(roller, roll):
	var damage_evaded = roll["mudcombat:resistanceValue"] * 100
	if damage_evaded > 0:
		add_to_history({
			"@id": "_:defence_roll_" + str(randi()),
			"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#RecordedHistory",
			"n:hasNote": roller["n:fn"] + " evaded " + str(damage_evaded) + "%  of an attack damage via their defence " + roll["n:fn"]
		})
	elif damage_evaded < 0:
		add_to_history({
			"@id": "_:defence_roll_" + str(randi()),
			"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#RecordedHistory",
			"n:hasNote": roller["n:fn"] + " was wounded by an additional " + str(damage_evaded) + "%  of damage because of their weakness " + roll["n:fn"]
		})

func clear_history():
	history = []
	render_history()

# TODO: seriously unoptimised
func _exhaustively_search_world_data_for_obj(world_data, urlid, search_chain=[]):
	"""
	Iterates over EVERY key in the world data nesting searching for the urlid
	:param world_data: the space to search
	:param urlid: the key to search for
	:param search_chain: set automatically by recursive calls and then returned. The keys called to arrive at the object
	:return: search_chain, or null if not found
	"""
	if "@id" in world_data and world_data["@id"] == urlid:
		# search_chain.push_front("@id")
		return search_chain
	
	for key in world_data:
		if typeof(key) == TYPE_STRING:
			if key == "@context" or key == "twt2023:hasRecordedHistory":
				continue
		
		if typeof(world_data[key]) == TYPE_ARRAY:
			for i in range(len(world_data[key])):
				var item = world_data[key][i]
				if "@id" in item and item["@id"] == urlid:
					# search_chain.push_front("@id")
					search_chain.push_front(i)
					search_chain.push_front(key)
					return search_chain
				
				var res = _exhaustively_search_world_data_for_obj(world_data[key][i], urlid, search_chain)
				if res != null:
					search_chain.push_front(i)
					search_chain.push_front(key)
					return search_chain
		
		elif typeof(world_data[key]) == TYPE_DICTIONARY:
			var res = _exhaustively_search_world_data_for_obj(world_data[key], urlid, search_chain)
			if res != null:
				search_chain.push_front(key)
				return search_chain
	return null

"""
func _handle_generic_delete(data):
	var search_chain = _exhaustively_search_world_data_for_obj(jsonld_store, data["@id"])
	if search_chain == null:
		return
	var parent = jsonld_store
	for key in search_chain:
		if typeof(key) == TYPE_STRING and key == "@id" and parent[key] == data["@id"]:
			parent.erase(key)
		else:
			parent = parent[key]
"""

func _merge_inserted_data(data, search_chain, insert_data):
	var key = search_chain.pop_front()
	if len(search_chain) == 0:
		data[key] = insert_data
		return data
	_merge_inserted_data(data[key], search_chain, insert_data)

# TODO: handle inserting new object
func _handle_generic_insert(data):
	# first we figure out the chain of keys used to access the object we're looking for, e.g.
	# ["mudworld:hasRegions", 0, "mudworld:hasRegions", 0, "mudworld:hasPopulations", 0, "@id"]
	var search_chain = _exhaustively_search_world_data_for_obj(jsonld_store, data["@id"])
	if search_chain == null:
		return
	
	# then we perform the merge recursively
	_merge_inserted_data(jsonld_store, search_chain, data)

func effect_action_consequences(consequences_jsonld):
	if consequences_jsonld == null or not "mudlogic:patchesOnComplete" in consequences_jsonld:
		return
	
	var patch = consequences_jsonld["mudlogic:patchesOnComplete"]
	"""
	if "mudlogic:deletes" in patch:
		for delete in patch["mudlogic:deletes"]:
			print("DELETE " + str(delete))
			_handle_generic_delete(delete)
	"""
	
	if "mudlogic:inserts" in patch:
		for insert in patch["mudlogic:inserts"]:
			if "@type" in insert and insert["@type"] == "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#RecordedHistory":
				add_to_history(insert)
			else:
				_handle_generic_insert(insert)

# TODO: find a more DRY way to do this across nodes
func get_rdf_property(property):
	if property in self.jsonld_store:
		return self.jsonld_store[property]
	
	return null

func set_rdf_property(property, value):
	self.jsonld_store[property] = value
