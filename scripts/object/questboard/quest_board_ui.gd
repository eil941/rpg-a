extends CanvasLayer
class_name QuestBoardUI

@export var board_background_color: Color = Color(0.12, 0.10, 0.08, 0.96)
@export var card_background_color: Color = Color(0.22, 0.19, 0.15, 0.96)
@export var card_selected_background_color: Color = Color(0.38, 0.31, 0.21, 0.98)
@export var close_button_background_color: Color = Color(0.30, 0.18, 0.18, 0.98)
@export var detail_panel_background_color: Color = Color(0.08, 0.08, 0.08, 0.96)
@export var detail_button_normal_color: Color = Color(0.10, 0.10, 0.10, 0.96)
@export var detail_button_selected_color: Color = Color(0.30, 0.24, 0.12, 0.98)

@export var board_background_texture: Texture2D
@export var card_background_texture: Texture2D
@export var card_selected_background_texture: Texture2D
@export var close_button_background_texture: Texture2D
@export var detail_panel_background_texture: Texture2D

@onready var root: Control = $Root
@onready var main_panel: Panel = $Root/MainPanel
@onready var board_background_rect: TextureRect = $Root/MainPanel/BoardBackground
@onready var close_button: Button = $Root/MainPanel/CloseButton
@onready var close_button_bg: TextureRect = $Root/MainPanel/CloseButton/Background
@onready var scroll_container: ScrollContainer = $Root/MainPanel/ScrollContainer
@onready var list_vbox: VBoxContainer = $Root/MainPanel/ScrollContainer/ListVBox

@onready var detail_panel: Panel = $Root/MainPanel/DetailPanel
@onready var detail_bg: TextureRect = $Root/MainPanel/DetailPanel/Background
@onready var detail_portrait: TextureRect = $Root/MainPanel/DetailPanel/Portrait
@onready var detail_title: Label = $Root/MainPanel/DetailPanel/TitleLabel
@onready var detail_desc: RichTextLabel = $Root/MainPanel/DetailPanel/DescriptionText
@onready var detail_action_button: Button = $Root/MainPanel/DetailPanel/ButtonArea/ActionButton
@onready var detail_back_button: Button = $Root/MainPanel/DetailPanel/ButtonArea/BackButton

var current_board: QuestBoard = null
var current_player_unit = null
var board_entries: Array = []
var selected_index: int = 0
var is_detail_mode: bool = false
var detail_button_index: int = 0


func _ready() -> void:
	hide()

	_apply_inspector_styles()

	if QuestBoardManager != null and QuestBoardManager.has_method("register_ui"):
		QuestBoardManager.register_ui(self)

	close_button.pressed.connect(_on_close_pressed)
	detail_action_button.pressed.connect(_on_detail_action_pressed)
	detail_back_button.pressed.connect(_on_detail_back_pressed)

	set_process_input(true)


func _apply_inspector_styles() -> void:
	var board_style := StyleBoxFlat.new()
	board_style.bg_color = board_background_color
	board_style.corner_radius_top_left = 12
	board_style.corner_radius_top_right = 12
	board_style.corner_radius_bottom_left = 12
	board_style.corner_radius_bottom_right = 12
	main_panel.add_theme_stylebox_override("panel", board_style)

	board_background_rect.texture = board_background_texture
	board_background_rect.visible = board_background_texture != null

	var close_style := StyleBoxFlat.new()
	close_style.bg_color = close_button_background_color
	close_style.corner_radius_top_left = 8
	close_style.corner_radius_top_right = 8
	close_style.corner_radius_bottom_left = 8
	close_style.corner_radius_bottom_right = 8
	close_style.draw_center = close_button_background_texture == null

	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", close_style)
	close_button.add_theme_stylebox_override("pressed", close_style)
	close_button.add_theme_stylebox_override("focus", close_style)

	close_button_bg.texture = close_button_background_texture
	close_button_bg.visible = close_button_background_texture != null

	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = detail_panel_background_color
	detail_style.corner_radius_top_left = 12
	detail_style.corner_radius_top_right = 12
	detail_style.corner_radius_bottom_left = 12
	detail_style.corner_radius_bottom_right = 12
	detail_style.draw_center = detail_panel_background_texture == null
	detail_panel.add_theme_stylebox_override("panel", detail_style)

	detail_bg.texture = detail_panel_background_texture
	detail_bg.visible = detail_panel_background_texture != null

	_apply_detail_button_styles()


func _apply_detail_button_styles() -> void:
	var action_style := StyleBoxFlat.new()
	action_style.bg_color = detail_button_selected_color if detail_button_index == 0 else detail_button_normal_color
	action_style.corner_radius_top_left = 6
	action_style.corner_radius_top_right = 6
	action_style.corner_radius_bottom_left = 6
	action_style.corner_radius_bottom_right = 6

	var back_style := StyleBoxFlat.new()
	back_style.bg_color = detail_button_selected_color if detail_button_index == 1 else detail_button_normal_color
	back_style.corner_radius_top_left = 6
	back_style.corner_radius_top_right = 6
	back_style.corner_radius_bottom_left = 6
	back_style.corner_radius_bottom_right = 6

	detail_action_button.add_theme_stylebox_override("normal", action_style)
	detail_action_button.add_theme_stylebox_override("hover", action_style)
	detail_action_button.add_theme_stylebox_override("pressed", action_style)
	detail_action_button.add_theme_stylebox_override("focus", action_style)

	detail_back_button.add_theme_stylebox_override("normal", back_style)
	detail_back_button.add_theme_stylebox_override("hover", back_style)
	detail_back_button.add_theme_stylebox_override("pressed", back_style)
	detail_back_button.add_theme_stylebox_override("focus", back_style)


func open_with_board(board, player_unit) -> void:
	current_board = board
	current_player_unit = player_unit
	selected_index = 0
	is_detail_mode = false
	detail_button_index = 0

	reload_entries()
	refresh_view()
	show()


func close_ui() -> void:
	hide()
	current_board = null
	current_player_unit = null
	board_entries.clear()
	selected_index = 0
	is_detail_mode = false
	detail_button_index = 0


func reload_entries() -> void:
	board_entries.clear()

	if current_board == null:
		return

	board_entries = QuestManager.get_board_quests(current_board.linked_unit_ids, current_player_unit)

	if selected_index >= board_entries.size():
		selected_index = max(board_entries.size() - 1, 0)


func refresh_view() -> void:
	_refresh_list()
	_refresh_detail_panel()
	_ensure_selected_item_visible()


func _refresh_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()

	if board_entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "依頼なし"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(0, 140)
		empty_label.add_theme_font_size_override("font_size", 30)
		list_vbox.add_child(empty_label)
		return

	for i in range(board_entries.size()):
		var entry: Dictionary = board_entries[i]
		var card: Button = _create_entry_card(entry, i)
		list_vbox.add_child(card)


func _create_entry_card(entry: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 190)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_selected: bool = index == selected_index
	var bg_texture: Texture2D = card_selected_background_texture if is_selected else card_background_texture
	var bg_color: Color = card_selected_background_color if is_selected else card_background_color

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = bg_color
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_left = 10
	card_style.corner_radius_bottom_right = 10
	card_style.draw_center = bg_texture == null

	button.add_theme_stylebox_override("normal", card_style)
	button.add_theme_stylebox_override("hover", card_style)
	button.add_theme_stylebox_override("pressed", card_style)
	button.add_theme_stylebox_override("focus", card_style)

	if is_detail_mode and not is_selected:
		button.modulate = Color(0.75, 0.75, 0.75, 1.0)
	else:
		button.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var bg_rect := TextureRect.new()
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.texture = bg_texture
	bg_rect.visible = bg_texture != null
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(bg_rect)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 14
	margin.offset_top = 14
	margin.offset_right = -14
	margin.offset_bottom = -14
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(110, 110)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = entry.get("giver_portrait", null)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)

	var text_area := VBoxContainer.new()
	text_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_area.add_theme_constant_override("separation", 8)
	text_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_area)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 12)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_area.add_child(top_row)

	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 26)
	title.text = String(entry.get("quest_title", ""))
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(title)

	var time_label := Label.new()
	time_label.custom_minimum_size = Vector2(260, 0)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 22)
	time_label.text = String(entry.get("remaining_time_text", ""))
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(time_label)

	var desc := Label.new()
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 22)

	var detail_text: String = String(entry.get("detail_text", "")).replace("\n", " ")
	if detail_text.length() > 90:
		detail_text = detail_text.substr(0, 90) + "..."
	desc.text = detail_text
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_area.add_child(desc)

	var progress := Label.new()
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress.add_theme_font_size_override("font_size", 20)
	progress.text = String(entry.get("progress_text", ""))
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_area.add_child(progress)

	var bottom_row := HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_theme_constant_override("separation", 12)
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_area.add_child(bottom_row)

	var reward := Label.new()
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward.add_theme_font_size_override("font_size", 20)
	reward.text = String(entry.get("reward_text", ""))
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(reward)

	var state_label := Label.new()
	state_label.custom_minimum_size = Vector2(260, 0)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state_label.add_theme_font_size_override("font_size", 20)
	state_label.text = String(entry.get("state_text", ""))
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(state_label)

	button.pressed.connect(func() -> void:
		selected_index = index
		is_detail_mode = true
		detail_button_index = 0
		refresh_view()
	)

	return button


func _refresh_detail_panel() -> void:
	if not is_detail_mode or board_entries.is_empty():
		detail_panel.visible = false
		return

	var entry: Dictionary = board_entries[selected_index]
	var can_complete: bool = bool(entry.get("can_complete", false))
	var can_accept: bool = bool(entry.get("can_accept", false))

	detail_panel.visible = true
	detail_portrait.texture = entry.get("giver_portrait", null)
	detail_title.text = String(entry.get("quest_title", ""))

	var detail_lines: Array[String] = []
	detail_lines.append(String(entry.get("detail_text", "")))
	detail_lines.append("")
	detail_lines.append(String(entry.get("progress_text", "")))
	detail_lines.append(String(entry.get("remaining_time_text", "")))
	detail_lines.append(String(entry.get("reward_text", "")))
	detail_lines.append(String(entry.get("state_text", "")))
	detail_desc.text = "\n".join(detail_lines)

	if can_complete:
		detail_action_button.text = "達成報告"
		detail_action_button.disabled = false
		detail_action_button.visible = true
	elif can_accept:
		detail_action_button.text = "受注する"
		detail_action_button.disabled = false
		detail_action_button.visible = true
	else:
		detail_action_button.text = "受注不可"
		detail_action_button.disabled = true
		detail_action_button.visible = true

	detail_back_button.text = "戻る"
	detail_back_button.visible = true
	_apply_detail_button_styles()


func _ensure_selected_item_visible() -> void:
	if list_vbox.get_child_count() == 0:
		return
	if selected_index < 0 or selected_index >= list_vbox.get_child_count():
		return

	await get_tree().process_frame

	if not is_instance_valid(list_vbox):
		return
	if not is_instance_valid(scroll_container):
		return
	if selected_index < 0 or selected_index >= list_vbox.get_child_count():
		return

	var item: Control = list_vbox.get_child(selected_index) as Control
	if item == null or not is_instance_valid(item):
		return

	var item_top: float = item.position.y
	var item_bottom: float = item.position.y + item.size.y
	var view_top: float = scroll_container.scroll_vertical
	var view_bottom: float = view_top + scroll_container.size.y

	if item_top < view_top:
		scroll_container.scroll_vertical = int(item_top)
	elif item_bottom > view_bottom:
		scroll_container.scroll_vertical = int(item_bottom - scroll_container.size.y)


func _move_selection(delta: int) -> void:
	if board_entries.is_empty():
		return

	selected_index += delta
	selected_index = clamp(selected_index, 0, board_entries.size() - 1)
	refresh_view()


func _toggle_detail_button_selection() -> void:
	detail_button_index = 1 - detail_button_index
	_apply_detail_button_styles()


func _on_close_pressed() -> void:
	if QuestBoardManager != null and QuestBoardManager.has_method("close_board"):
		QuestBoardManager.close_board()


func _on_detail_action_pressed() -> void:
	_execute_selected_action()


func _on_detail_back_pressed() -> void:
	is_detail_mode = false
	detail_button_index = 0
	refresh_view()


func _execute_selected_action() -> void:
	if board_entries.is_empty():
		return

	var entry: Dictionary = board_entries[selected_index]
	var quest: QuestData = entry.get("quest", null)
	var giver_unit = entry.get("giver_unit", null)

	if quest == null or giver_unit == null:
		return

	var can_complete: bool = bool(entry.get("can_complete", false))
	var can_accept: bool = bool(entry.get("can_accept", false))

	if can_complete:
		QuestManager.complete_quest_from_board(quest.quest_id, giver_unit, current_player_unit)
	elif can_accept:
		QuestManager.accept_quest_from_board(quest, giver_unit, current_player_unit)

	reload_entries()

	if board_entries.is_empty():
		selected_index = 0
		is_detail_mode = false
	else:
		selected_index = clamp(selected_index, 0, board_entries.size() - 1)
		is_detail_mode = false

	detail_button_index = 0
	refresh_view()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if is_detail_mode:
			is_detail_mode = false
			detail_button_index = 0
			refresh_view()
		else:
			_on_close_pressed()
		return

	if board_entries.is_empty():
		return

	if is_detail_mode:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()
			_toggle_detail_button_selection()
			return

		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			if detail_button_index == 0:
				_execute_selected_action()
			else:
				_on_detail_back_pressed()
			return

		return

	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_move_selection(-1)
		return

	if event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_move_selection(1)
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		is_detail_mode = true
		detail_button_index = 0
		refresh_view()
		return
