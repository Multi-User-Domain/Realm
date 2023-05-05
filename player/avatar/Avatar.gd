extends Node2D

onready var portrait_sprite = get_node("PortraitSprite")
onready var name_label = get_node("NameLabel")
# deck prompt is the little card icon indicating how many cards are left in the deck
onready var deck_prompt = get_node("DeckPrompt")
onready var card_manager = get_node("CardManager")
export var default_hp = 100
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

func _get_texture_from_jsonld(depiction_url):	
	if depiction_url == null:
		return load(Globals.PORTRAIT_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/ospreyWithers.png"])
	
	if depiction_url in Globals.PORTRAIT_CACHE.keys():
		return load(Globals.PORTRAIT_CACHE[depiction_url])
	
	print("ERR: requested portrait not in cache, remote portraits unsupported for Avatars")
	print(depiction_url)
	return load(Globals.PORTRAIT_CACHE["https://raw.githubusercontent.com/Multi-User-Domain/games-transformed-jam-2023/assets/portrait/ospreyWithers.png"])

func init_new_player(character_jsonld, cards=[]):
	_init_jsonld_data(character_jsonld)
	
	# function initialises the Avatar with new player information
	portrait_sprite.set_texture(_get_texture_from_jsonld(get_rdf_property("foaf:depiction")))
	# TODO: https://github.com/Multi-User-Domain/games-transformed-jam-2023/issues/1
	# 128, 128 with the in-built textures
	portrait_sprite.set_scale(Vector2(0.25, 0.25))
	var portrait_size = Vector2(128, 128) # also needs to become relative to size
	var half_portrait = portrait_size * 0.5
	# centre along the x axis
	portrait_sprite.set_position(Vector2(get_viewport_rect().size.x * 0.5, self.position.y) + half_portrait)
	deck_prompt.set_position(portrait_sprite.position + Vector2(portrait_size.x + 10, 0))
	
	name_label.set_text(get_rdf_property("n:fn"))
	name_label.set_position(portrait_sprite.position + Vector2(-half_portrait.x + 1, half_portrait.y + 1))
	
	card_manager.init_deck(self, cards)

# TODO: find a more DRY way to do this across nodes
func get_rdf_property(property):
	if property in self.jsonld_store:
		return self.jsonld_store[property]
	
	return null

func set_rdf_property(property, value):
	self.jsonld_store[property] = value
