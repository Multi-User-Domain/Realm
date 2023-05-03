extends Node2D

export var hand_size = Globals.DEFAULT_HAND_SIZE
var avatar = null;
# hand and deck contain JSON-LD representations of the cards
var hand = []
var deck = []
var discard_pile = []

func _ready():
	pass

func init_deck(avatar, cards=[]):
	self.avatar = avatar
	deck += cards
	deck.shuffle()

func add_to_deck(card_jsonld):
	deck.append(card_jsonld)

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
			if len(discard_pile) == 0:
				break
			shuffle_discard_pile()
		
		hand.append(deck.pop_back())

func discard_hand():
	discard_pile += hand
	hand = []

# TODO: AI component, ask it to play some cards, and return those played
func play_cards():
	discard_hand()
	draw_hand()
	return [hand.pop_back()]
