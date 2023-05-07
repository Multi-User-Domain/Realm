extends Node2D

onready var game = get_tree().current_scene
onready var turn_timer = get_node("TurnTimer")
onready var card_action_timer = get_node("CardActionTimer")

# the purpose of this Node is to manage turns, i.e.
# the actions of each active card on each cycle,
# the actions of players on each turn (when they can play cards)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func start():
	# start game timer
	turn_timer.start()
	card_action_timer.start()
	game.player1_avatar.card_manager.deck.shuffle()
	game.player2_avatar.card_manager.deck.shuffle()


func _on_TurnTimer_timeout():
	game.player1_avatar.play_cards()
	game.player2_avatar.play_cards()


# TODO: allow active cards to make attacks
func _on_CardActionTimer_timeout():
	pass
