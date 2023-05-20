extends Node2D

onready var game = get_tree().current_scene
onready var turn_timer = get_node("TurnTimer")
onready var card_action_timer = get_node("CardActionTimer")
onready var event_timer = get_node("EventActionTimer")

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
	event_timer.start()

func stop():
	turn_timer.stop()
	card_action_timer.stop()
	event_timer.stop()

func _on_TurnTimer_timeout():
	game.battle_scene.player1_avatar.play_cards()
	game.battle_scene.player2_avatar.play_cards()

func _get_attackable_cards(cards):
	var attackable_cards = []
	for card in cards:
		if "mudcombat:hasHealthPoints" in card:
			attackable_cards.append(card)
	return attackable_cards

func _get_attack_dmg(attack_data):
	if attack_data != null:
		if "mudcombat:hasAttackDetails" in attack_data:
			var attack_details = attack_data["mudcombat:hasAttackDetails"]
			if "mudcombat:fixedDamage" in attack_details:
				return attack_details["mudcombat:fixedDamage"]
			if "mudcombat:minDamage" in attack_details and "mudcombat:maxDamage" in attack_details:
				return (randi() % attack_details["mudcombat:maxDamage"]) + attack_details["mudcombat:minDamage"]
	return Globals.DEFAULT_ATTACK_DAMAGE

func _handle_attack(player_avatar_scene, opponent_avatar_scene, opponent_attackable_cards, attack_data=null):
	var attack_dmg = _get_attack_dmg(attack_data)
	var damage_type = Globals.DEFAULT_DAMAGE_TYPE
	if attack_data != null:
		if "mudcombat:hasAttackDetails" in attack_data:
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
		if "mudcombat:deathTriggersActions" in opponent_card:
			_play_card_actions(player_avatar_scene, opponent_avatar_scene, opponent_card["mudcombat:deathTriggersActions"])
	else:
		_apply_card_effects(attack_data, opponent_card)

# -1 for healing all valid targets
func _handle_healing(player_avatar_scene, data, heal_number=1):
	var attack_dmg = _get_attack_dmg(data)
	var valid_targets = _get_attackable_cards(player_avatar_scene.card_manager.active_cards)
	for card in valid_targets:
		var hp = card["mudcombat:hasHealthPoints"]
		if hp["mudcombat:maximumP"] > hp["mudcombat:currentP"]:
			player_avatar_scene.card_manager.heal_cards([card["@id"]], attack_dmg)
			heal_number -= 1
			if heal_number == 0:
				break

func _handle_spell(player_avatar_scene, opponent_avatar_scene, opponent_attackable_cards, data):
	if data["@id"] == Globals.BUILT_IN_ACTIONS.HEALING_WORD:
		return _handle_healing(player_avatar_scene, data)
	if data["@id"] == Globals.BUILT_IN_ACTIONS.HEAL_PARTY:
		return _handle_healing(player_avatar_scene, data, -1)

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

func _handle_generate_card(player_avatar_scene, opponent_avatar_scene, action):
	if not "twt2023:generatesCardFrom" in action:
		print("ERR _handle_generate_card given an action without any cards to generate from")
		print(str(action))
		return
	
	var generate_probability = 0.1
	if "twt2023:generateCardProbability" in action:
		generate_probability = max(0, min(action["twt2023:generateCardProbability"], 1.0))
	
	# if the probability check passes, add it to the player's deck
	if generate_probability >= ((randi() % 10) * 0.1):
		var idx = randi()%len(action["twt2023:generatesCardFrom"])
		var gen_card = action["twt2023:generatesCardFrom"][idx]
		player_avatar_scene.card_manager.add_to_deck(gen_card)
		if "twt2023:onGeneratedMessage" in gen_card:
			game.world_manager.add_to_history({
				"@id": "_generate_card_history_" + str(randi()),
				"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#RecordedHistory",
				"n:hasNote": gen_card["twt2023:onGeneratedMessage"]
			})
		elif "n:fn" in action and "n:fn" in gen_card:
			game.world_manager.add_to_history({
				"@id": "_generate_card_history_" + str(randi()),
				"@type": "https://raw.githubusercontent.com/Multi-User-Domain/vocab/main/games/twt2023.ttl#RecordedHistory",
				"n:hasNote": str(gen_card["n:fn"]) + " emerged from " + str(action["n:fn"]) + " and joined the faction " + player_avatar_scene.get_rdf_property("n:fn")
			})

func _play_card_actions(player_avatar_scene, opponent_avatar_scene, actions=null):
	if actions == null:
		actions = player_avatar_scene.card_manager.play_card_actions()
	elapsed_card_turns += 1
	var opponent_attackable_cards = _get_attackable_cards(opponent_avatar_scene.card_manager.active_cards)
	for action in actions:
		var actor = action[0]
		action = action[1]
		
		if action["@id"] in Globals.BUILT_IN_ATTACK_ACTIONS:
			_handle_attack(player_avatar_scene, opponent_avatar_scene, opponent_attackable_cards, action)
		elif action["@id"] == Globals.BUILT_IN_ACTIONS.GENERATE_CARD:
			_handle_generate_card(player_avatar_scene, opponent_avatar_scene, action)
		elif action["@id"] in Globals.BUILT_IN_SPELL_ACTIONS:
			_handle_spell(player_avatar_scene, opponent_avatar_scene, opponent_attackable_cards, action)
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

# active cards can also have events
func _on_EventActionTimer_timeout():
	turn_timer.stop()
	card_action_timer.stop()

	# play one event, from either player 1 or 2
	if not game.battle_scene.player1_avatar.card_manager.play_card_event():
		game.battle_scene.player2_avatar.card_manager.play_card_event()
	
	turn_timer.start()
	card_action_timer.start()
