extends Node2D


onready var text_content = get_node("TextContent")
export var max_health := 100
export var health_value := 100

func set_health(health: int=health_value, max_health:int=max_health):
	self.health_value = health
	self.max_health = max_health
	text_content.set_text(str(health_value) + " HP")

func add_health(health: int):
	self.health_value = min(health_value + health, max_health)
	text_content.set_text(str(health_value) + " HP")

func remove_health(health: int):
	self.health_value = max(health_value - health, 0)
	text_content.set_text(str(health_value) + " HP")
