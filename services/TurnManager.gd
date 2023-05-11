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
	game.battle_scene.player1_avatar.card_manager.deck.shuffle()
	game.battle_scene.player2_avatar.card_manager.deck.shuffle()

func stop():
	turn_timer.stop()
	card_action_timer.stop()

func _on_TurnTimer_timeout():
	game.battle_scene.player1_avatar.play_cards()
	game.battle_scene.player2_avatar.play_cards()

func _get_attackable_cards(cards):
	var attackable_cards = []
	for card in cards:
		if "mudcombat:hasHealthPoints" in card:
			attackable_cards.append(card)
	return attackable_cards

func _handle_attack(player_avatar_scene, opponent_avatar_scene, opponent_attackable_cards, attack_data=null):
	var attack_dmg = Globals.DEFAULT_ATTACK_DAMAGE
	var damage_type = Globals.DEFAULT_DAMAGE_TYPE
	if attack_data != null:
		if "mudcombat:hasAttackDetails" in attack_data:
			if "mudcombat:fixedDamage" in attack_data["mudcombat:hasAttackDetails"]:
				attack_dmg = attack_data["mudcombat:hasAttackDetails"]["mudcombat:fixedDamage"]
			
			if "mudcombat:typeDamage" in attack_data["mudcombat:hasAttackDetails"]:
				if "@id" in attack_data["mudcombat:hasAttackDetails"]["mudcombat:typeDamage"]:
					damage_type = attack_data["mudcombat:hasAttackDetails"]["mudcombat:typeDamage"]["@id"]
				else:
					print("ERR _handle_attack. Misformed action has typeDamage which doesn't include id key")
					print(str(attack_data["mudcombat:hasAttackDetails"]))
	
	# attack the enemy avatar if they have no protection
	if len(opponent_attackable_cards) == 0:
		opponent_avatar_scene.health_bar.remove_health(attack_dmg)
		if opponent_avatar_scene.health_bar.health_value <= 0:
			game.end_battle()
		return
	
	# otherwise attack the first card
	var opponent_card = opponent_attackable_cards[0]["@id"]
	var destroyed = opponent_avatar_scene.card_manager.damage_card(
		opponent_card, attack_dmg, damage_type
	)
	if destroyed != null:
		game.battle_scene._remove_card_with_urlid(destroyed)
		_apply_card_effects(attack_data, null)
	else:
		_apply_card_effects(attack_data, opponent_card)

func _handle_unknown_action(actor, action):
	if "mudlogic:actAt" in action:
		game.federation_manager.perform_action(action["mudlogic:actAt"], action, actor)
		_apply_card_effects(action, null)
	else:
		print("ERR _handle_unknown_action given an action without required mudlogic:actAt property")
		print(action["@id"])

func _apply_card_effects(attack_data, opponent_card=null):
	if attack_data != null and "mudcombat:hasAttackDetails" in attack_data:
		if "mudcombat:imbuesEffects" in attack_data["mudcombat:hasAttackDetails"]:
			for effect in attack_data["mudcombat:hasAttackDetails"]["mudcombat:imbuesEffects"]:
				if effect["@id"] == Globals.BUILT_IN_EFFECTS.POISON:
					if opponent_card == null:
						continue
					var opponent_card_scene = game.battle_scene.get_card_with_urlid(opponent_card)
					if opponent_card_scene != null:
						opponent_card_scene.add_effect(effect)
					else:
						print("ERR _apply_card_effects couldn't find card scene with urlid " + opponent_card)
		
		# TODO: support effects on caster
		# TODO: support effects on either player
		# TODO: support other effects

func _play_card_actions(player_avatar_scene, opponent_avatar_scene):
	elapsed_card_turns += 1
	var opponent_attackable_cards = _get_attackable_cards(opponent_avatar_scene.card_manager.active_cards)
	for action in player_avatar_scene.card_manager.play_card_actions():
		var actor = action[0]
		action = action[1]
		
		if action["@id"] in Globals.BUILT_IN_ATTACK_ACTIONS:
			_handle_attack(player_avatar_scene, opponent_avatar_scene, opponent_attackable_cards, action)
		else:
			_handle_unknown_action(actor, action)

func apply_effects():
	for card in game.battle_scene.player1_cards.get_children():
		if card.has_method("apply_effects"):
			card.apply_effects()
	
	for card in game.battle_scene.player2_cards.get_children():
		if card.has_method("apply_effects"):
			card.apply_effects()

# allow active cards to make attacks
func _on_CardActionTimer_timeout():
	elapsed_player_turns += 1
	self._play_card_actions(game.battle_scene.player1_avatar, game.battle_scene.player2_avatar)
	self._play_card_actions(game.battle_scene.player2_avatar, game.battle_scene.player1_avatar)
	apply_effects()
