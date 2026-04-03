extends Node

@onready var current_map_container: Node = $CurrentMapContainer
@onready var game_hud = $GameHUD
@onready var inventory_ui = $InventoryUI
@onready var trade_ui: TradeUI = $TradeUI

var current_map: Node = null
var trade_return_context: Dictionary = {}


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

	if DialogueManager != null and DialogueManager.has_method("is_dialog_open"):
		if DialogueManager.is_dialog_open():
			return

	if is_trade_ui_open():
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


func is_inventory_open() -> bool:
	if inventory_ui == null:
		return false
	return inventory_ui.visible


func open_trade_ui(player_unit, merchant_unit, return_context: Dictionary = {}) -> void:
	if trade_ui == null:
		push_error("TradeUI が見つかりません")
		return

	trade_return_context = return_context.duplicate(true)

	if DialogueManager != null and DialogueManager.has_method("close_dialog"):
		DialogueManager.close_dialog()

	trade_ui.open_trade_ui(player_unit, merchant_unit)


func close_trade_ui() -> void:
	if trade_ui == null:
		return

	trade_ui.close_trade_ui()


func is_trade_ui_open() -> bool:
	if trade_ui == null:
		return false

	if trade_ui.has_method("is_trade_open"):
		return trade_ui.is_trade_open()

	return trade_ui.visible


func on_trade_ui_closed() -> void:
	if DialogueManager == null:
		return

	if trade_return_context.is_empty():
		return

	if DialogueManager.has_method("reopen_dialog_from_context"):
		DialogueManager.reopen_dialog_from_context(trade_return_context)

	trade_return_context = {}
