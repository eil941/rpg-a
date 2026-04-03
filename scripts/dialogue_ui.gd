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

var base_action_panel_bottom_y: float = 0.0
var base_action_panel_height: float = 0.0

const ACTION_BUTTON_HEIGHT: float = 44.0
const ACTION_PANEL_PADDING_TOP: float = 12.0
const ACTION_PANEL_PADDING_BOTTOM: float = 12.0
const ACTION_PANEL_SIDE_PADDING: float = 12.0
const FALLBACK_BUTTON_SEPARATION: int = 8


func _ready() -> void:
	visible = false
	DialogueManager.register_ui(self)
	call_deferred("_cache_base_layout")


func _cache_base_layout() -> void:
	base_action_panel_height = action_panel.size.y
	base_action_panel_bottom_y = action_panel.position.y + action_panel.size.y


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

	set_actions(context.get("actions", []))


func close_dialog() -> void:
	clear_action_buttons()
	adjust_action_layout()
	visible = false
	is_open = false
	current_selected_index = 0


func is_dialog_visible() -> bool:
	return is_open


func set_dialog_text(text: String) -> void:
	top_text_label.text = text


func set_actions(actions: Array) -> void:
	clear_action_buttons()

	for action in actions:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, ACTION_BUTTON_HEIGHT)
		button.text = String(action.get("label", ""))
		button.set_meta("action_id", String(action.get("id", "")))
		button.pressed.connect(_on_action_button_pressed.bind(button))
		action_list.add_child(button)

	current_selected_index = 0

	# remove_child 済みなので await は必須ではないが、
	# レイアウト更新を1フレーム待つとさらに安定する
	await get_tree().process_frame

	adjust_action_layout()
	refresh_action_selection()


func move_selection(delta: int) -> void:
	var count := action_list.get_child_count()
	if count <= 0:
		current_selected_index = 0
		return

	current_selected_index = posmod(current_selected_index + delta, count)
	refresh_action_selection()


func confirm_selection() -> void:
	var count := action_list.get_child_count()
	if count <= 0:
		return

	if current_selected_index < 0 or current_selected_index >= count:
		current_selected_index = 0

	var button = action_list.get_child(current_selected_index)
	if button == null:
		return

	var action_id := String(button.get_meta("action_id", ""))
	DialogueManager.on_action_selected(action_id)


func refresh_action_selection() -> void:
	var count := action_list.get_child_count()
	if count <= 0:
		current_selected_index = 0
		return

	if current_selected_index < 0 or current_selected_index >= count:
		current_selected_index = 0

	for i in range(count):
		var button = action_list.get_child(i)
		if button is Button:
			button.button_pressed = (i == current_selected_index)


func clear_action_buttons() -> void:
	var children := action_list.get_children()
	for child in children:
		action_list.remove_child(child)
		child.queue_free()


func _on_action_button_pressed(button: Button) -> void:
	var count := action_list.get_child_count()
	for i in range(count):
		if action_list.get_child(i) == button:
			current_selected_index = i
			break

	refresh_action_selection()
	confirm_selection()


func adjust_action_layout() -> void:
	if base_action_panel_bottom_y == 0.0:
		_cache_base_layout()

	var count := action_list.get_child_count()
	var separation := _get_action_list_separation()

	var buttons_height := count * ACTION_BUTTON_HEIGHT
	var gaps_height := maxi(0, count - 1) * separation
	var list_needed_height := buttons_height + gaps_height

	var panel_needed_height := list_needed_height + ACTION_PANEL_PADDING_TOP + ACTION_PANEL_PADDING_BOTTOM
	var new_panel_height := maxf(base_action_panel_height, panel_needed_height)

	action_panel.custom_minimum_size.y = new_panel_height
	action_panel.size.y = new_panel_height
	action_panel.position.y = base_action_panel_bottom_y - new_panel_height

	var new_list_width := maxf(0.0, action_panel.size.x - ACTION_PANEL_SIDE_PADDING * 2.0)
	action_list.custom_minimum_size = Vector2(new_list_width, list_needed_height)
	action_list.size = Vector2(new_list_width, list_needed_height)
	action_list.position = Vector2(
		ACTION_PANEL_SIDE_PADDING,
		new_panel_height - ACTION_PANEL_PADDING_BOTTOM - list_needed_height
	)


func _get_action_list_separation() -> int:
	var separation := 0

	if action_list != null:
		separation = action_list.get_theme_constant("separation")

	if separation <= 0:
		separation = FALLBACK_BUTTON_SEPARATION

	return separation
