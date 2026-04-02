extends CanvasLayer

@onready var root_panel: Control = $RootPanel
@onready var portrait_rect: TextureRect = $RootPanel/PortraitFrame/Portrait
@onready var left_info_label: Label = $RootPanel/LeftInfoLabel
@onready var name_label: Label = $RootPanel/NameLabel
@onready var top_text_label: RichTextLabel = $RootPanel/TopTextLabel
@onready var action_panel: Panel = $RootPanel/ActionPanel
@onready var action_list: VBoxContainer = $RootPanel/ActionPanel/ActionList
@onready var hint_label: Label = $RootPanel/HintLabel

var is_open: bool = false
var current_selected_index: int = 0


func _ready() -> void:
	visible = false
	DialogueManager.register_ui(self)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed("ui_down"):
		move_selection(1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		move_selection(-1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept"):
		confirm_selection()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		DialogueManager.close_dialog()
		get_viewport().set_input_as_handled()
		return


func open_dialog(context: Dictionary) -> void:
	visible = true
	is_open = true
	current_selected_index = 0

	name_label.text = String(context.get("name", ""))
	top_text_label.text = String(context.get("text", ""))
	left_info_label.text = String(context.get("left_info", ""))
	hint_label.text = "↑↓: 選択  Enter: 決定  Esc: 閉じる"

	var portrait = context.get("portrait", null)
	portrait_rect.texture = portrait

	clear_action_buttons()

	var actions: Array = context.get("actions", [])
	for action in actions:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 44)
		button.text = String(action.get("label", ""))
		button.set_meta("action_id", String(action.get("id", "")))
		button.pressed.connect(_on_action_button_pressed.bind(button))
		action_list.add_child(button)

	refresh_action_selection()


func close_dialog() -> void:
	clear_action_buttons()
	visible = false
	is_open = false
	current_selected_index = 0


func is_dialog_visible() -> bool:
	return is_open


func set_dialog_text(text: String) -> void:
	top_text_label.text = text


func move_selection(delta: int) -> void:
	var count := action_list.get_child_count()
	if count <= 0:
		return

	current_selected_index = posmod(current_selected_index + delta, count)
	refresh_action_selection()


func confirm_selection() -> void:
	var count := action_list.get_child_count()
	if count <= 0:
		return

	var button = action_list.get_child(current_selected_index)
	if button == null:
		return

	var action_id := String(button.get_meta("action_id", ""))
	DialogueManager.on_action_selected(action_id)


func refresh_action_selection() -> void:
	for i in range(action_list.get_child_count()):
		var button = action_list.get_child(i)
		if button is Button:
			button.button_pressed = (i == current_selected_index)


func clear_action_buttons() -> void:
	for child in action_list.get_children():
		child.queue_free()


func _on_action_button_pressed(button: Button) -> void:
	for i in range(action_list.get_child_count()):
		if action_list.get_child(i) == button:
			current_selected_index = i
			break
	refresh_action_selection()
	confirm_selection()
