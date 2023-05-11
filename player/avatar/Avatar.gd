extends Node2D

onready var game = get_tree().current_scene
onready var portrait_sprite = get_node("PortraitSprite")
onready var name_label = get_node("NameLabel")
onready var health_bar = get_node("HealthBar")
# deck prompt is the little card icon indicating how many cards are left in the deck
onready var deck_prompt = get_node("DeckPrompt")
onready var card_manager = get_node("CardManager")
export var default_hp = 100
export var player_index = 0
var jsonld_store = {}

func _ready():
	pass

func _init_jsonld_data(character_jsonld):
	jsonld_store = character_jsonld
	jsonld_store["@type"] = Globals.MUD_CHAR.Character
	
	if not "foaf:depiction" in jsonld_store:
		jsonld_store["foaf:depiction"] = "https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/ospreyWithers.png"
	
	if not "n:fn" in jsonld_store:
		jsonld_store["n:fn"] = "Avatar"
	
	if not "mudcombat:hasHealthPoints" in jsonld_store:
		jsonld_store["mudcombat:hasHealthPoints"] = {
			"mudcombat:maximumP": default_hp,
			"mudcombat:currentP": default_hp
		}

func _init_health_bar():
	var health_points = get_rdf_property("mudcombat:hasHealthPoints")
	health_bar.set_health(health_points["mudcombat:currentP"], health_points["mudcombat:maximumP"])

func _init_starting_region():
	"""
	Players might be configured as the lord of a starting region
	This function incorporates that region into the world state
	"""
	if "twt2023:lordOfRegion" in jsonld_store:
		game.world_manager.add_new_sub_region(get_rdf_property("twt2023:lordOfRegion"))

func _get_deck_configured_on_jsonld():
	var deck = get_rdf_property("mudcard:hasDeck")
	if deck != null:
		if "mudcard:hasCards" in deck:
			return deck["mudcard:hasCards"]
		print("ERR (Avatar.gd): deck configured with no cards, or with a property unknown to this game")
		return []
	else:
		return []

func init_sprite(character_jsonld=jsonld_store):
	if "foaf:depiction" in character_jsonld:
		# function initialises the Avatar with new player information
		portrait_sprite.set_texture(game.rdf_manager.get_texture_from_jsonld(character_jsonld["foaf:depiction"]))
		# TODO: https://github.com/Multi-User-Domain/games-transformed-jam-2023/issues/1
		# 128, 128 with the in-built textures
		portrait_sprite.set_scale(Vector2(0.25, 0.25))

func get_portrait_size():
	return Vector2(128, 128) # TODO: actually calculate this

func init_player(player_index, character_jsonld):
	self.player_index = player_index
	_init_jsonld_data(character_jsonld)
	init_sprite(character_jsonld)
	
	var portrait_size = get_portrait_size()
	var half_portrait = portrait_size * 0.5
	# centre along the x axis
	portrait_sprite.set_position(Vector2(get_viewport_rect().size.x * 0.5, self.position.y) + half_portrait)
	health_bar.set_position(portrait_sprite.position - Vector2(portrait_size.x + 20, 0))
	deck_prompt.set_position(portrait_sprite.position + Vector2(portrait_size.x + 10, 0))
	
	name_label.set_text(get_rdf_property("n:fn"))
	name_label.set_position(portrait_sprite.position + Vector2(-half_portrait.x + 1, half_portrait.y + 1))
	
	_init_health_bar()
	card_manager.init_deck(self, _get_deck_configured_on_jsonld())
	_init_starting_region()

# TODO: find a more DRY way to do this across nodes
func get_rdf_property(property):
	if property in self.jsonld_store:
		return self.jsonld_store[property]
	
	return null

func set_rdf_property(property, value):
	self.jsonld_store[property] = value

func play_cards():
	for card in card_manager.get_cards_to_play():
		card_manager.add_to_active_cards(card)
		game.battle_scene._add_card_for_player(player_index, card)

func animate_select():
	get_node("BackgroundGlow").set_visible(true)

func animate_deselect():
	get_node("BackgroundGlow").set_visible(false)
