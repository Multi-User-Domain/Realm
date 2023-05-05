extends Node2D

#
#	CardTray is the player's control for injecting cards into the simulation
#	They are presented with a stream of cards, and select whether to give
#	The card to one player or the other, or to discard it
#

onready var game = get_tree().current_scene
# at the base, it is wrapper around a CardManager with no discard_pile,
# and where the hand progresses as one-in with each one-out
onready var card_manager = get_node("CardManager")
onready var active_card_pos_node = get_node("ActiveCardPos")
onready var inactive_cards_pos_node = get_node("InactiveCardsPos")

# TODO: should the hand_size be calculated based on screen width?
export var hand_size = 7

var card_scene = preload("res://obj/card/Card.tscn")
var active_card = null

func init_deck(cards):
	card_manager.init_deck(null, cards)
	draw_new_hand()

func draw_new_hand():
	card_manager.draw_hand(hand_size)
	
	# render the first card in the active card position
	var top_card = card_manager.hand.pop_front()
	_render_active_card(top_card)
	
	# render the rest of the hand in the inactive tray
	for i in range(len(card_manager.hand)):
		var card_jsonld = card_manager.hand[i]
		var card_scene_instance = card_scene.instance()
		card_scene_instance.scale = card_scene_instance.scale * game.card_scale
		card_scene_instance.set_position(Vector2(inactive_cards_pos_node.position.x + ((i * game.get_card_size().x) * 1.2), -game.get_card_size().y * 0.125))
		inactive_cards_pos_node.add_child(card_scene_instance)
		card_scene_instance.init_card(card_jsonld)

func _render_active_card(card_jsonld):
	# renders the given card in the active card position
	var card_scene_instance = card_scene.instance()
	card_scene_instance.set_position(Vector2(active_card_pos_node.position.x, -game.get_card_size().y * 0.75))
	active_card_pos_node.add_child(card_scene_instance)
	card_scene_instance.init_card(card_jsonld)
	active_card = card_scene_instance
	
	game.set_selected_card(card_scene_instance)

func _get_inactive_card_matching(this_card):
	# sorry
	for child in inactive_cards_pos_node.get_children():
		if child.get_rdf_property("@id") == this_card["@id"]:
			return child
	return null

func get_card_to_left_of(this_card):
	"""
	:return: card to the left of the parameterised card in the UI
	:return: null if there is no card to the left
	"""
	if this_card == active_card:
		return null
	
	for i in range(len(card_manager.hand)):
		if this_card.get_rdf_property("@id") == card_manager.hand[i]["@id"]:
			if i == 0:
				return active_card
			return _get_inactive_card_matching(card_manager.hand[i - 1])

func get_card_to_right_of(this_card):
	"""
	:return: card to the left of the parameterised card in the UI
	:return: null if there is no card to the right
	"""
	if this_card == active_card:
		return _get_inactive_card_matching(card_manager.hand[0])
	
	for i in range(len(card_manager.hand)):
		if this_card.get_rdf_property("@id") == card_manager.hand[i]["@id"]:
			if i < len(card_manager.hand) - 1:
				return _get_inactive_card_matching(card_manager.hand[i + 1])
			return null

func remove_card(card_scene_instance):
	if card_scene_instance != active_card:
		var card_jsonld = card_scene_instance.jsonld_store
		card_manager.hand.erase(card_jsonld)
	card_scene_instance.get_node("..").remove_child(card_scene_instance)
	card_scene_instance.queue_free()
