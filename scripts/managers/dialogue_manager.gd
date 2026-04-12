extends Node

var dialogue_ui = null
var current_unit = null
var current_player_unit = null
var current_context: Dictionary = {}
var base_context: Dictionary = {}
var is_open: bool = false

var pending_failed_quest_dialogs: Array[Dictionary] = []
var showing_failed_quest_dialog: bool = false


func register_ui(ui) -> void:
	dialogue_ui = ui


func open_unit_dialog(target_unit, player_unit) -> void:
	if target_unit == null:
		return

	if showing_failed_quest_dialog:
		return

	current_unit = target_unit
	current_player_unit = player_unit
	current_context = target_unit.build_talk_context()
	base_context = current_context.duplicate(true)
	is_open = true

	if dialogue_ui != null:
		dialogue_ui.open_dialog(current_context)


func reopen_dialog_from_context(context: Dictionary) -> void:
	if context.is_empty():
		return

	if showing_failed_quest_dialog:
		return

	current_context = context.duplicate(true)
	is_open = true

	if dialogue_ui != null:
		dialogue_ui.open_dialog(current_context)


func close_dialog() -> void:
	is_open = false

	if dialogue_ui != null and dialogue_ui.has_method("close_dialog"):
		dialogue_ui.close_dialog()


func fully_close_dialog() -> void:
	is_open = false
	current_unit = null
	current_player_unit = null
	current_context = {}
	base_context = {}

	if dialogue_ui != null and dialogue_ui.has_method("close_dialog"):
		dialogue_ui.close_dialog()


func is_dialog_open() -> bool:
	return is_open


func is_input_locked_by_failed_quest_dialog() -> bool:
	return showing_failed_quest_dialog


func set_dialog_text(text: String) -> void:
	if not is_open:
		return

	current_context["text"] = text

	if dialogue_ui != null and dialogue_ui.has_method("set_dialog_text"):
		dialogue_ui.set_dialog_text(text)


func set_dialog_actions(actions: Array) -> void:
	if not is_open:
		return

	current_context["actions"] = actions

	if dialogue_ui != null and dialogue_ui.has_method("set_actions"):
		dialogue_ui.set_actions(actions)


func update_dialog(text: String, actions: Array) -> void:
	if not is_open:
		return

	current_context["text"] = text
	current_context["actions"] = actions

	if dialogue_ui != null and dialogue_ui.has_method("open_dialog"):
		dialogue_ui.open_dialog(current_context)


func return_to_root_dialog(text: String) -> void:
	if not is_open:
		return

	if showing_failed_quest_dialog:
		return

	var restored_context: Dictionary = base_context.duplicate(true)
	restored_context["text"] = text
	current_context = restored_context

	if dialogue_ui != null and dialogue_ui.has_method("open_dialog"):
		dialogue_ui.open_dialog(current_context)


func on_action_selected(action_id: String) -> void:
	if showing_failed_quest_dialog:
		if action_id == "failed_quest_close":
			finish_failed_quest_dialog()
		return

	if current_unit == null:
		fully_close_dialog()
		return

	if not current_unit.has_method("handle_interact_action"):
		fully_close_dialog()
		return

	var result = current_unit.handle_interact_action(action_id)

	if typeof(result) != TYPE_DICTIONARY:
		return

	var result_type: String = String(result.get("type", ""))

	match result_type:
		"update_text":
			set_dialog_text(String(result.get("text", "")))

		"update_dialog":
			update_dialog(
				String(result.get("text", "")),
				result.get("actions", [])
			)

		"return_to_root":
			return_to_root_dialog(String(result.get("text", "")))

		"open_trade_ui":
			_open_trade_ui()

		"close_dialog":
			fully_close_dialog()

		_:
			if result.has("text"):
				set_dialog_text(String(result.get("text", "")))


func _open_trade_ui() -> void:
	if current_player_unit == null or current_unit == null:
		return

	var root = _find_game_root_from_unit(current_player_unit)
	if root == null:
		push_error("TradeUI を開く親ノードが見つかりません")
		return

	if not root.has_method("open_trade_ui"):
		push_error("親ノードに open_trade_ui() がありません")
		return

	root.open_trade_ui(
		current_player_unit,
		current_unit,
		base_context
	)


func _find_game_root_from_unit(unit) -> Node:
	var node: Node = unit
	while node != null:
		if node.has_method("open_trade_ui"):
			return node
		node = node.get_parent()
	return null


func queue_failed_quest_dialog(failed_quest_data: Dictionary) -> void:
	if failed_quest_data.is_empty():
		return

	pending_failed_quest_dialogs.append(failed_quest_data)
	_try_show_failed_quest_dialog()


func _try_show_failed_quest_dialog() -> void:
	if showing_failed_quest_dialog:
		return

	if pending_failed_quest_dialogs.is_empty():
		return

	var failed_data: Dictionary = pending_failed_quest_dialogs.pop_front()
	_force_open_failed_quest_dialog(failed_data)


func _force_open_failed_quest_dialog(failed_data: Dictionary) -> void:
	showing_failed_quest_dialog = true
	fully_close_dialog()

	var root: Node = _find_game_root_for_failed_dialog()
	if root != null:
		if root.has_method("close_trade_ui"):
			root.close_trade_ui()
		if root.has_method("close_inventory_ui"):
			root.close_inventory_ui()
		if root.has_method("close_inventory"):
			root.close_inventory()
		if root.has_method("close_status_ui"):
			root.close_status_ui()

	var giver_unit_id: String = String(failed_data.get("giver_unit_id", ""))
	var giver_unit = _find_unit_by_id(giver_unit_id)

	var player_unit = _find_player_unit()
	current_player_unit = player_unit
	current_unit = giver_unit

	var dialog_context: Dictionary = {}

	if giver_unit != null and giver_unit.has_method("build_talk_context"):
		dialog_context = giver_unit.build_talk_context()
	else:
		dialog_context = {
			"name": String(failed_data.get("giver_display_name", "")),
			"portrait": failed_data.get("giver_portrait", null),
			"text": "",
			"actions": []
		}

	dialog_context["type"] = "failed_quest_dialog"
	dialog_context["failed_data"] = failed_data
	dialog_context["text"] = _build_failed_quest_dialog_text(failed_data)
	dialog_context["actions"] = _build_failed_quest_dialog_actions()

	current_context = dialog_context
	base_context = dialog_context.duplicate(true)
	is_open = true

	if dialogue_ui != null and dialogue_ui.has_method("open_dialog"):
		dialogue_ui.open_dialog(current_context)


func finish_failed_quest_dialog() -> void:
	showing_failed_quest_dialog = false
	fully_close_dialog()
	_try_show_failed_quest_dialog()


func _build_failed_quest_dialog_text(failed_data: Dictionary) -> String:
	var title: String = String(failed_data.get("title", "依頼"))
	var description: String = String(failed_data.get("description", ""))
	var item_id: String = String(failed_data.get("objective_item_id", ""))
	var amount: int = int(failed_data.get("objective_item_amount", 1))
	var item_name: String = _get_item_name(item_id)

	var lines: Array[String] = []
	lines.append("【依頼失敗】")
	lines.append(title)

	if description != "":
		lines.append(description)

	if item_id != "":
		lines.append("必要だったもの: %s x%d" % [item_name, amount])

	lines.append("")
	lines.append("期限までに達成できなかったようですね。")

	return "\n".join(lines)


func _build_failed_quest_dialog_actions() -> Array:
	return [
		{
			"id": "failed_quest_close",
			"label": "戻る"
		}
	]


func _find_unit_by_id(unit_id: String):
	if unit_id == "":
		return null

	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if "unit_id" in unit and String(unit.unit_id) == unit_id:
			return unit

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return null

	return _find_unit_by_id_recursive(scene_root, unit_id)


func _find_unit_by_id_recursive(node: Node, unit_id: String):
	if node == null:
		return null

	if "unit_id" in node:
		if String(node.unit_id) == unit_id:
			return node

	for child in node.get_children():
		var found = _find_unit_by_id_recursive(child, unit_id)
		if found != null:
			return found

	return null


func _find_player_unit():
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if "is_player_unit" in unit and bool(unit.is_player_unit):
			return unit

	return current_player_unit


func _find_game_root_for_failed_dialog() -> Node:
	var player_unit = _find_player_unit()
	if player_unit != null:
		var root_from_unit = _find_game_root_from_unit(player_unit)
		if root_from_unit != null:
			return root_from_unit

	if current_player_unit != null:
		var root_from_current = _find_game_root_from_unit(current_player_unit)
		if root_from_current != null:
			return root_from_current

	return null


func _get_item_name(item_id: String) -> String:
	if item_id == "":
		return ""

	if ItemDatabase == null:
		return item_id

	if not ItemDatabase.exists(item_id):
		return item_id

	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name == "":
		return item_id

	return display_name
