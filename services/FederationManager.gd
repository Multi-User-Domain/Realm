extends Node2D

#
#	Service for managing the interface to a federation of servers
#	(in practice one server for now)
#

# TODO: support for federations
const SERVER_ENDPOINT = "https://api.realm.games.coop/"

onready var game = get_tree().current_scene
onready var perform_action_request = get_node("PerformActionRequest")
onready var load_game_data_request = get_node("LoadGameDataRequest")

export(bool) var use_ssl = false


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var response_data = parse_json(body.get_string_from_utf8())
	game.world_manager.effect_action_consequences(response_data)


func perform_action(url_endpoint, action_data, actor_data):
	var headers = [
		"Content-Type: application/json"
	]
	
	# TODO: Godot 4 this should be JSON.stringify
	var data = {
		"worldData": game.world_manager.get_world_data(),
		"actionData": action_data,
		"actorData": actor_data
	}
	
	perform_action_request.request(url_endpoint, headers, use_ssl, HTTPClient.METHOD_POST, JSON.print(data))


func _on_LoadGameDataRequest_request_completed(result, response_code, headers, body):
	var response_data = parse_json(body.get_string_from_utf8())
	if response_data != null:
		game.battle_scene.card_tray.add_cards_to_deck(response_data)


func load_game_data():
	load_game_data_request.request(SERVER_ENDPOINT + "cards/")
