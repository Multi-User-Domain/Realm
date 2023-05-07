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

# AI component, ask it to play some cards, and return those played
func get_cards_to_play():
	discard_hand()
	draw_hand()
	
	# greedy algorithm: play the first card you see
	var top_card = hand.pop_back()
	if top_card == null:
		return []
	return [top_card]

# AI component, ask it to use the active effects of cards on the table
func play_card_actions(opponent_active=[]):
	var actions_to_play = []
	
	# TODO: consider opponent active cards?
	for card in active_cards:
		# greedy algorithm, play every action
		# TODO: choose an action
		# TODO: actions should have constraints about usage
		if "mudcard:hasAvailableInstantActions" in card:
			actions_to_play.append(card["mudcard:hasAvailableInstantActions"][0])
	
	return actions_to_play

func damage_card(urlid_to_damage, damage):
	"""
	damages a card with given urlid
	:return: card urlid if the card was destroyed, otherwise null
	"""
	for card in active_cards:
		if card["@id"] == urlid_to_damage:
			if "mudcombat:hasHealthPoints" in card:
				card["mudcombat:hasHealthPoints"]["mudcombat:currentP"] -= damage

				# discard card if it's been destroyed
				if card["mudcombat:hasHealthPoints"]["mudcombat:currentP"] <= 0:
					active_cards.erase(card)
					add_to_discard_pile(card)
					return card["@id"]
	return null
