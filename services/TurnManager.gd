extends Node2D

onready var game = get_tree().current_scene
onready var turn_timer = get_node("TurnTimer")
onready var card_action_timer = get_node("CardActionTimer")

# the purpose of this Node is to manage turns, i.e.
# the actions of each active card on each cycle,
# the actions of players on each turn (when they can play cards)

# keep track of how many player and card turns have been completed
var elapsed_player_turns = 0
var elapsed_card_turns = 0

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
	elapsed_card_turns += 1
	for action in player_avatar_scene.card_manager.play_card_actions():
		# card.take_turn(elapsed_card_turns, opponent_avatar_scene, opponent_avatar_scene.card_manager.active_cards)
		opponent_avatar_scene.health_bar.remove_health(1)

# allow active cards to make attacks
func _on_CardActionTimer_timeout():
	elapsed_player_turns += 1
	self._play_card_actions(game.player1_avatar, game.player2_avatar)
	self._play_card_actions(game.player2_avatar, game.player1_avatar)
