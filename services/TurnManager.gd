extends Node2D

onready var game = get_tree().current_scene
onready var turn_timer = get_node("TurnTimer")
onready var card_action_timer = get_node("CardActionTimer")

# the purpose of this Node is to manage turns, i.e.
# the actions of each active card on each cycle,
# the actions of players on each turn (when they can play cards)

func start():
	# start game timer
	turn_timer.start()
	card_action_timer.start()
	game.player1_avatar.card_manager.deck.shuffle()
	game.player2_avatar.card_manager.deck.shuffle()

func _on_TurnTimer_timeout():
	game.player1_avatar.play_cards()
	game.player2_avatar.play_cards()

func _play_card_actions(player_avatar_scene, opponent_avatar_scene):
	for card in player_avatar_scene.card_manager.play_card_actions():
		if card["@id"] == Globals.BUILT_IN_ACTIONS.BASIC_ATTACK:
			opponent_avatar_scene.health_bar.remove_health(1)

# allow active cards to make attacks
func _on_CardActionTimer_timeout():
	# TODO: using a timer for each card (e.g. each action is completed every x seconds)
	self._play_card_actions(game.player1_avatar, game.player2_avatar)
	self._play_card_actions(game.player2_avatar, game.player1_avatar)
