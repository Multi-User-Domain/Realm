extends Node2D

#
#	Service for managing the interface to a federation of servers
#	(in practice one server for now)
#

onready var game = get_tree().current_scene
onready var http_request = get_node("HTTPRequest")

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
	
	http_request.request(url_endpoint, headers, use_ssl, HTTPClient.METHOD_POST, JSON.print(data))
