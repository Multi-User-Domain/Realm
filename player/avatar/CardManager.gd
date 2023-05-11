extends Node2D

export var hand_size = Globals.DEFAULT_HAND_SIZE
var avatar = null;
# hand and deck contain JSON-LD representations of the cards
var active_cards = [] # a list of cards in play
var hand = []
var deck = []
var discard_pile = []

func _ready():
	pass

func init_deck(avatar, cards=[]):
	self.avatar = avatar
	for card_jsonld in cards:
		add_to_deck(card_jsonld)
	deck.shuffle()

func add_to_deck(card_jsonld):
	if not "@id" in card_jsonld:
		card_jsonld["@id"] = "_Card_" + str(randi())
	deck.append(card_jsonld)
	if avatar != null:
		avatar.deck_prompt.set_visible(true)
		avatar.deck_prompt.text_content.set_text(str(len(deck)))

func add_to_active_cards(card_jsonld):
	active_cards.append(card_jsonld)

func discard_active_card(card_id):
	for card in active_cards:
		if card["@id"] == card_id:
			add_to_discard_pile(active_cards.pop(card))
			break

func add_to_discard_pile(card_jsonld):
	discard_pile.append(card_jsonld)

func add_to_hand(card_jsonld):
	hand.append(card_jsonld)

func shuffle_discard_pile():
	deck += discard_pile
	discard_pile = []

func draw_hand(count=hand_size):
	for i in range(count):
		if len(deck) == 0:
			"""
			if len(discard_pile) == 0:
				break
			shuffle_discard_pile()
			"""
			break
		
		hand.append(deck.pop_back())
	
	if avatar != null:
		if len(deck) > 0:
			avatar.deck_prompt.text_content.set_text(str(len(deck)))
		else:
			avatar.deck_prompt.set_visible(false)

func discard_hand():
	discard_pile += hand
	hand = []

# gets a list of types in the active card tray
# used for informing the AI script what kind of cards they have in a set (active, hand, deck)
func _get_card_types(cards=[]):
	var active_types = []
	for card in cards:
		if "@type" in card:
			active_types.append(card["@type"])
	return active_types

# AI component, ask it to play some cards, and return those played
func get_cards_to_play():
	discard_hand()
	draw_hand()
	
	# if there are no active characters, prioritise that
	if not Globals.MUD_CHAR.Character in _get_card_types(active_cards):
		if Globals.MUD_CHAR.Character in _get_card_types(hand):
			# select the first character in hand
			for card in hand:
				if "@type" in card and card["@type"] == Globals.MUD_CHAR.Character:
					return [card]
	
	# default to greedy algorithm: play the first card you see
	var top_card = hand.pop_back()
	if top_card == null:
		return []
	return [top_card]

# AI component, ask it to use the active effects of cards on the table
func play_card_actions(opponent_active=[]):
	var actions_to_play = []
	
	for card in active_cards:
		# chooses action randomly
		# TODO: actions should have constraints about usage. Probably not in this game jam
		if "mudcard:hasAvailableInstantActions" in card:
			var idx = randi()%len(card["mudcard:hasAvailableInstantActions"])
			actions_to_play.append([card, card["mudcard:hasAvailableInstantActions"][idx]])
	
	return actions_to_play

func get_resistance_points(resistance, damage):
	"""
	:param resistance: JSON-LD data of type mudcombat:DamageResistance
	:param damage: the integer amount of damage being done of this type
	:return: the amount to change the damage by (e.g. -1 for a resistance, or +1 for a weakness)
	"""
	var res_factor = resistance["mudcombat:resistanceValue"] # a value between -1.0 to +1.0
	var res_val = damage * res_factor
	return -damage * res_val
	

func damage_card(urlid_to_damage, damage, damage_type):
	"""
	damages a card with given urlid
	:return: card urlid if the card was destroyed, otherwise null
	"""
	for card in active_cards:
		if card["@id"] == urlid_to_damage:
			if "mudcombat:hasHealthPoints" in card:
				if "mudcombat:hasResistances" in card:
					for resistance in card["mudcombat:hasResistances"]:
						if resistance["@id"] == damage_type:
							damage = max(0, damage - get_resistance_points(resistance, damage))
							break
				
				card["mudcombat:hasHealthPoints"]["mudcombat:currentP"] -= damage

				# discard card if it's been destroyed
				if card["mudcombat:hasHealthPoints"]["mudcombat:currentP"] <= 0:
					active_cards.erase(card)
					add_to_discard_pile(card)
					return card["@id"]
	return null
