extends Node2D

# Declare member variables here, e.g.
# var a = 2

onready var game = get_tree().current_scene
onready var sprite = get_node("ColorRect/MarginContainer/Sprite")
onready var name_label = get_node("ColorRect/MarginContainerName/Title")
onready var description_label = get_node("ColorRect/MarginContainer2/Description")
onready var image_request = get_node("ImageRequest")
var jsonld_store = {}

# for controlling the animation of card selection
export(float) var grow_factor = 1.5
export(Vector2) var default_scale = Vector2(1, 1) # the default scale of a card
var init_scale
var init_position
var focus_position

# the card_manager which controls this card
var card_manager

# effects which are applied each turn
var active_effects = []

func _ready():
	pass

func _init_jsonld_data(card_jsonld):
	jsonld_store = card_jsonld
	
	if not "n:fn" in jsonld_store:
		# TODO: find defaults via author name, etc
		jsonld_store["n:fn"] = "Unknown"
	
	if not "@id" in jsonld_store:
		jsonld_store["@id"] = "_Card_" + jsonld_store["n:fn"] + str(randi())
	
	jsonld_store = game.rdf_manager.parse_health_points(jsonld_store)

func init_card(card_jsonld, card_manager):
	if len(card_jsonld.keys()) == 1 and "@id" in card_jsonld:
		card_jsonld = game.rdf_manager.load_from_jsonld(card_jsonld["@id"])
		card_manager.replace_card_jsonld(card_jsonld["@id"], card_jsonld)
	
	# calculate and log variables used in animating select/deselect
	init_scale = get_scale()
	init_position = get_position()
	focus_position = init_position + Vector2(0, -200)
	
	self.card_manager = card_manager
	_init_jsonld_data(card_jsonld)
	
	var depiction = get_rdf_property("foaf:depiction")
	if depiction != null:
		var tex = game.rdf_manager.get_texture_from_jsonld(self, depiction)
		# NOTE: texture may be null because it's being fetched from server asynchronously
		if tex != null:
			_set_and_scale_sprite_texture(tex)
	
	name_label.set_text(get_rdf_property("n:fn"))
	description_label.set_text(get_rdf_property("n:hasNote"))

func _set_and_scale_sprite_texture(tex):
	# TODO: https://github.com/Multi-User-Domain/games-transformed-jam-2023/issues/1
	sprite.set_texture(tex)
	# 128, 128 with the in-built textures
	sprite.set_scale(Vector2(0.125, 0.125))

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

func has_active_effect(effect_urlid):
	for e in active_effects:
		if e["@id"] == effect_urlid:
			return true
	return false

func add_effect(effect):
	if not has_active_effect(effect["@id"]):
		active_effects.append(effect.duplicate(true))
		
		if effect["@id"] == Globals.BUILT_IN_EFFECTS.POISON:
			# TODO: Godot 4, set_color
			get_node("ColorRect").set_frame_color(Color(0, 1, 0, 1))

func remove_effect(effect):
	active_effects.erase(effect)
	
	if effect["@id"] == Globals.BUILT_IN_EFFECTS.POISON:
		get_node("ColorRect").set_frame_color(Color(0, 0, 0, 1))

func apply_effects():
	for effect in active_effects:
		if "mudcombat:hasAttackDetails" in effect and card_manager != null:
			var attack_dmg = Globals.DEFAULT_ATTACK_DAMAGE
			var damage_type = Globals.DEFAULT_DAMAGE_TYPE
			var attack_data = effect["mudcombat:hasAttackDetails"]
			
			if "mudcombat:fixedDamage" in attack_data:
				attack_dmg = attack_data["mudcombat:fixedDamage"]
			
			if "mudcombat:typeDamage" in attack_data:
				if "@id" in attack_data["mudcombat:typeDamage"]:
					damage_type = attack_data["mudcombat:typeDamage"]["@id"]
				else:
					print("ERR apply_effects. Malformed effect has typeDamage which doesn't include id key")
					print(str(attack_data))
			
			var destroyed = card_manager.damage_card(get_rdf_property("@id"), attack_dmg, damage_type)
			if destroyed != null:
				game.battle_scene._remove_card_with_urlid(destroyed["@id"])
				game.world_manager.record_death_by_effect(destroyed, effect)
		
		# check if the effect should expire
		if "mudlogic:expiresAfterOccurences" in effect:
			effect["mudlogic:expiresAfterOccurences"] -= 1
		else:
			effect["mudlogic:expiresAfterOccurences"] = 0
		
		if effect["mudlogic:expiresAfterOccurences"] <= 0:
			remove_effect(effect)

func get_remote_image(depiction_url):
	var http_error = image_request.request(depiction_url, PoolStringArray(), false)
	if http_error != OK:
		print("ERR get_texture_from_jsonld: An error occurred in the HTTP request.")

func _on_ImageRequest_request_completed(result, response_code, headers, body):
	var image = Image.new()
	# TODO: handle other image file types
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image.")
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	# Assign to the child TextureRect node
	# TODO: sprite is not re-rendered immediately after being set
	_set_and_scale_sprite_texture(texture)
