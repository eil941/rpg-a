extends Node

@onready var current_map_container: Node = $CurrentMapContainer
@onready var game_hud = $GameHUD
@onready var inventory_ui = $InventoryUI
@onready var status_ui = $StatusUI

var current_map: Node = null
var trade_return_context: Dictionary = {}


func _ready() -> void:
	load_map_by_path("res://scenes/field_map.tscn")
	refresh_hud()

	if status_ui != null:
		if status_ui.has_method("close_ui"):
			status_ui.close_ui()
		else:
			status_ui.visible = false


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

	var total_max_hp: int = int(player.stats.max_hp)
	if player.has_method("get_total_max_hp"):
		total_max_hp = int(player.get_total_max_hp())

	var current_mp: int = 0
	var total_max_mp: int = 0
	if _stats_has_property(player.stats, "mp"):
		current_mp = int(player.stats.mp)
	if _stats_has_property(player.stats, "max_mp"):
		total_max_mp = int(player.stats.max_mp)

	var current_stamina: int = 0
	var total_max_stamina: int = 0
	if _stats_has_property(player.stats, "stamina"):
		current_stamina = int(player.stats.stamina)
	if _stats_has_property(player.stats, "max_stamina"):
		total_max_stamina = int(player.stats.max_stamina)

	game_hud.set_player_status(
		player.name,
		int(player.stats.hp),
		total_max_hp,
		current_mp,
		total_max_mp,
		current_stamina,
		total_max_stamina
	)


func _stats_has_property(stats, property_name: String) -> bool:
	if stats == null:
		return false

	for info in stats.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true

	return false


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

	if is_status_open():
		return

	if DialogueManager != null and DialogueManager.has_method("is_dialog_open"):
		if DialogueManager.is_dialog_open():
			return

	if inventory_ui.has_method("is_trade_mode_open"):
		if inventory_ui.is_trade_mode_open():
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
	if inventory_ui == null:
		push_error("InventoryUI が見つかりません")
		return

	if is_status_open():
		return

	if player_unit == null:
		push_error("open_trade_ui: player_unit is null")
		return

	if merchant_unit == null:
		push_error("open_trade_ui: merchant_unit is null")
		return

	if player_unit.inventory == null:
		push_error("open_trade_ui: player_unit.inventory is null")
		return

	if merchant_unit.inventory == null:
		push_error("open_trade_ui: merchant_unit.inventory is null")
		return

	trade_return_context = return_context.duplicate(true)

	if DialogueManager != null and DialogueManager.has_method("close_dialog"):
		DialogueManager.close_dialog()

	if inventory_ui.has_method("open_trade_mode"):
		inventory_ui.open_trade_mode(
			player_unit.inventory,
			player_unit,
			merchant_unit.inventory,
			merchant_unit
		)
	else:
		push_error("InventoryUI に open_trade_mode() がありません")


func close_trade_ui() -> void:
	if inventory_ui == null:
		return

	if inventory_ui.has_method("is_trade_mode_open"):
		if not inventory_ui.is_trade_mode_open():
			return

	if inventory_ui.has_method("close_inventory"):
		inventory_ui.close_inventory()


func is_trade_ui_open() -> bool:
	if inventory_ui == null:
		return false

	if inventory_ui.has_method("is_trade_mode_open"):
		return inventory_ui.is_trade_mode_open()

	return false


func on_trade_ui_closed() -> void:
	if DialogueManager == null:
		return

	if trade_return_context.is_empty():
		return

	if DialogueManager.has_method("reopen_dialog_from_context"):
		DialogueManager.reopen_dialog_from_context(trade_return_context)

	trade_return_context = {}


func toggle_status_ui() -> void:
	if status_ui == null:
		push_error("StatusUI が見つかりません")
		return

	if is_trade_ui_open():
		return

	if DialogueManager != null and DialogueManager.has_method("is_dialog_open"):
		if DialogueManager.is_dialog_open():
			return

	if is_inventory_open():
		return

	if is_status_open():
		close_status_ui()
		return

	open_status_ui()


func open_status_ui() -> void:
	if status_ui == null:
		return

	if is_trade_ui_open():
		return

	if is_inventory_open():
		return

	if DialogueManager != null and DialogueManager.has_method("is_dialog_open"):
		if DialogueManager.is_dialog_open():
			return

	var player = find_player()
	if player == null:
		return

	if game_hud != null:
		game_hud.visible = false

	if status_ui.has_method("open_for_unit"):
		status_ui.open_for_unit(player)
	else:
		status_ui.visible = true


func close_status_ui() -> void:
	if status_ui == null:
		return

	if status_ui.has_method("close_ui"):
		status_ui.close_ui()
	else:
		status_ui.visible = false

	if game_hud != null:
		game_hud.visible = true


func is_status_open() -> bool:
	if status_ui == null:
		return false

	if status_ui.has_method("is_open"):
		return status_ui.is_open()

	return status_ui.visible
