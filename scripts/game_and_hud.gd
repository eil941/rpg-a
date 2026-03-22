extends Node

@onready var current_map_container: Node = $CurrentMapContainer
@onready var game_hud = $GameHUD

var current_map: Node = null

func _ready() -> void:
	print("GAME_AND_HUD READY")
	load_map_by_path("res://scenes/field_map.tscn")

func load_map_by_path(scene_path: String) -> void:
	print("GAH load_map_by_path START:", scene_path)

	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("GameAndHud: シーンを読み込めません: " + scene_path)
		return

	print("GAH load_map_by_path LOADED")
	load_map(scene)
	print("GAH load_map_by_path END")

func load_map(map_scene: PackedScene) -> void:
	print("GAH load_map START")

	if current_map != null:
		print("GAH freeing current_map:", current_map.name)
		current_map.queue_free()
		current_map = null
		print("GAH freed current_map")

	current_map = map_scene.instantiate()
	print("GAH instantiated:", current_map)

	current_map_container.add_child(current_map)
	print("GAH add_child DONE:", current_map.name)
