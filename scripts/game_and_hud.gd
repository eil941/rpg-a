extends Node2D

@onready var current_map_container: Node = $CurrentMapContainer
@onready var game_hud = $GameHUD

var current_map: Node = null

func _ready() -> void:
	load_map(preload("res://scenes/Main.tscn"))

func load_map(map_scene: PackedScene) -> void:
	if current_map != null:
		current_map.queue_free()
		current_map = null

	current_map = map_scene.instantiate()
	current_map_container.add_child(current_map)
