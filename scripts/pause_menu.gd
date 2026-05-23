extends CanvasLayer
class_name PauseMenu

@export_file("*.tscn") var title_scene_path: String = "res://scenes/TitleScreen.tscn"
@export var pause_game_when_open: bool = true

@onready var root_panel: Control = $RootPanel
@onready var status_label: Label = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var settings_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/SettingsButton
@onready var save_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/SaveButton
@onready var title_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/TitleButton
@onready var quit_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/QuitButton
@onready var close_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/CloseButton

var escape_started_on_blocking_ui: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	settings_button.pressed.connect(_on_settings_pressed)
	save_button.pressed.connect(_on_save_pressed)
	title_button.pressed.connect(_on_title_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(close_menu)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			# PauseMenu表示中だけは、PauseMenu自身が最優先で閉じる。
			if visible:
				close_menu()
				get_viewport().set_input_as_handled()
				return

			# 他UIが開いている状態で押されたEscは、PauseMenuを開かない。
			# ここでは入力を消費せず、各UI側のEsc処理に渡す。
			escape_started_on_blocking_ui = _has_blocking_ui_open()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			# Escを押した時点で他UIが開いていた場合、
			# そのUIが同じ入力で閉じた後でもPauseMenuを開かない。
			if escape_started_on_blocking_ui:
				escape_started_on_blocking_ui = false
				get_viewport().set_input_as_handled()
				return

			# 念のため、まだ他UIが開いているならPauseMenuを開かない。
			if _has_blocking_ui_open():
				get_viewport().set_input_as_handled()
				return

			open_menu()
			get_viewport().set_input_as_handled()


func toggle_menu() -> void:
	if visible:
		close_menu()
	else:
		if _has_blocking_ui_open():
			return
		open_menu()

func _has_blocking_ui_open() -> bool:
	var owner_root: Node = _find_owner_root()
	if owner_root == null:
		return false

	var blocking_ui_names: Array[String] = [
		"InventoryUI",
		"DialogueUI",
		"StatusUI",
		"QuestBoardUI",
		"TradeUI",
		"DeathMenu"
	]

	for node_name in blocking_ui_names:
		var ui_node: Node = owner_root.get_node_or_null(node_name)
		if _is_ui_open(ui_node):
			return true

	return false


func _find_owner_root() -> Node:
	var node: Node = get_parent()

	while node != null:
		if node.has_node("CurrentMapContainer"):
			return node

		if node.has_node("InventoryUI") or node.has_node("DialogueUI") or node.has_node("StatusUI"):
			return node

		node = node.get_parent()

	return get_parent()


func _is_ui_open(ui_node: Node) -> bool:
	if ui_node == null:
		return false

	if ui_node == self:
		return false

	if ui_node.has_method("is_dialog_visible"):
		var dialog_visible: Variant = ui_node.call("is_dialog_visible")
		if bool(dialog_visible):
			return true

	if ui_node.has_method("is_ui_open"):
		var ui_open: Variant = ui_node.call("is_ui_open")
		if bool(ui_open):
			return true

	if ui_node is CanvasItem:
		var canvas_item: CanvasItem = ui_node as CanvasItem
		return canvas_item.visible

	return false



func open_menu() -> void:
	visible = true
	status_label.text = ""
	if pause_game_when_open:
		get_tree().paused = true
	close_button.grab_focus()


func close_menu() -> void:
	visible = false
	if pause_game_when_open:
		get_tree().paused = false


func _on_settings_pressed() -> void:
	status_label.text = "設定はまだ未実装です。後で音量・キー設定を追加します。"


func _on_save_pressed() -> void:
	if SaveManager == null:
		status_label.text = "SaveManager がありません。"
		return

	var current_map: Node = _find_current_map()
	var saved: bool = SaveManager.save_current_game(current_map)

	if saved:
		status_label.text = "セーブしました。"
	else:
		status_label.text = "セーブに失敗しました。"


func _on_title_pressed() -> void:
	if SaveManager != null:
		var current_map: Node = _find_current_map()
		SaveManager.save_current_game(current_map)

	get_tree().paused = false

	if title_scene_path.strip_edges() == "":
		push_warning("PauseMenu: title_scene_path が空です")
		return

	var error: Error = get_tree().change_scene_to_file(title_scene_path)
	if error != OK:
		push_error("PauseMenu: タイトル画面へ戻れませんでした: " + title_scene_path)


func _on_quit_pressed() -> void:
	if SaveManager != null:
		var current_map: Node = _find_current_map()
		SaveManager.save_current_game(current_map)

	get_tree().paused = false
	get_tree().quit()


func _find_current_map() -> Node:
	var node: Node = self

	while node != null:
		var value: Variant = node.get("current_map")
		if value != null and value is Node:
			return value

		var container: Node = node.get_node_or_null("CurrentMapContainer")
		if container != null and container.get_child_count() > 0:
			return container.get_child(0)

		node = node.get_parent()

	return null
