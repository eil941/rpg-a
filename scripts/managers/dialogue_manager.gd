extends Node

var dialogue_ui = null
var current_unit = null
var current_player_unit = null
var current_context: Dictionary = {}
var base_context: Dictionary = {}
var is_open: bool = false


func register_ui(ui) -> void:
	dialogue_ui = ui


func open_unit_dialog(target_unit, player_unit) -> void:
	if target_unit == null:
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

	var restored_context: Dictionary = base_context.duplicate(true)
	restored_context["text"] = text
	current_context = restored_context

	if dialogue_ui != null and dialogue_ui.has_method("open_dialog"):
		dialogue_ui.open_dialog(current_context)


func on_action_selected(action_id: String) -> void:
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
