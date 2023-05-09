extends Node2D

#
#	Service for managing the interface to a federation of servers
#	(in practice one server for now)
#

onready var http_request = get_node("HTTPRequest")


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	pass
