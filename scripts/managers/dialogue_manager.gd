extends Node

var dialogue_ui: CanvasLayer = null
var current_target_unit = null
var current_player_unit = null


func register_ui(ui: CanvasLayer) -> void:
	dialogue_ui = ui


func is_dialog_open() -> bool:
	if dialogue_ui == null:
		return false
	if dialogue_ui.has_method("is_dialog_visible"):
		return dialogue_ui.is_dialog_visible()
	return dialogue_ui.visible


func open_unit_dialog(target_unit, player_unit) -> void:
	current_target_unit = target_unit
	current_player_unit = player_unit

	if dialogue_ui == null:
		push_error("DialogueUI が未登録です")
		return

	if not target_unit.has_method("build_talk_context"):
		push_error("target_unit に build_talk_context() がありません")
		return

	var context: Dictionary = target_unit.build_talk_context()
	dialogue_ui.open_dialog(context)


func close_dialog() -> void:
	if dialogue_ui != null and dialogue_ui.has_method("close_dialog"):
		dialogue_ui.close_dialog()

	current_target_unit = null
	current_player_unit = null


func set_dialog_text(text: String) -> void:
	if dialogue_ui != null and dialogue_ui.has_method("set_dialog_text"):
		dialogue_ui.set_dialog_text(text)


func on_action_selected(action_id: String) -> void:
	if current_target_unit == null:
		close_dialog()
		return

	if current_target_unit.has_method("handle_interact_action"):
		current_target_unit.handle_interact_action(action_id)
		return

	if action_id == "bye":
		close_dialog()
