extends Node

@onready var current_map_container: Node = $CurrentMapContainer
@onready var game_hud = $GameHUD
@onready var inventory_ui = $InventoryUI

var current_map: Node = null


func _ready() -> void:
	load_map_by_path("res://scenes/field_map.tscn")
	refresh_hud()


func load_map_by_path(scene_path: String) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("GameAndHud: シーンを読み込めません: " + scene_path)
		return

	load_map(scene)


func load_map(map_scene: PackedScene) -> void:
	if current_map != null:
		current_map.queue_free()
		current_map = null

	current_map = map_scene.instantiate()
	current_map_container.add_child(current_map)

	refresh_hud()


func refresh_hud() -> void:
	update_hud_time()
	update_hud_player_status()


func update_hud_time() -> void:
	if game_hud == null:
		return
	if not game_hud.has_method("set_time_info"):
		return

	game_hud.set_time_info(
		TimeManager.get_day(),
		TimeManager.get_time_string(),
		TimeManager.get_time_of_day()
	)

func update_hud_player_status() -> void:
	if game_hud == null:
		return
	if not game_hud.has_method("set_player_status"):
		return

	var player = find_player()
	if player == null:
		return
	if player.stats == null:
		return

	game_hud.set_player_status(
		player.name,
		player.stats.hp,
		player.stats.max_hp,
		0,
		0,
		0,
		0
	)


func add_hud_log(text: String) -> void:
	if game_hud == null:
		return
	if not game_hud.has_method("add_log"):
		return

	game_hud.add_log(text)


func find_player():
	if current_map == null:
		return null

	var units_node = current_map.get_node_or_null("Units")
	if units_node == null:
		return null

	for child in units_node.get_children():
		if child == null:
			continue
		if child.get("is_player_unit"):
			return child

	return null
	
func toggle_inventory_ui() -> void:
	if inventory_ui == null:
		print("inventory_ui is null")
		return

	var player = find_player()
	if player == null:
		print("player is null")
		return

	if player.inventory == null:
		print("player.inventory is null")
		return

	print("OPEN INVENTORY", player.inventory.get_all_items())
	inventory_ui.toggle_with_inventory(player.inventory)
