extends Control

signal inventory_button_pressed
signal status_button_pressed
signal hotbar_slot_pressed(hotbar_index: int)

@export var hotbar_slot_size: Vector2 = Vector2(44, 44)
@export var hotbar_icon_margin: int = 4
@export var hotbar_slot_gap: int = 0
@export var hotbar_slot_background_alpha: float = 0.0
# HotbarArea/PanelContainer の余分な薄灰色背景だけを消す。
# スロット自体の背景・枠は _apply_hotbar_slot_style() 側で維持する。
@export var hotbar_outer_background_alpha: float = 0.0
# HUD action button icons.
# Inspector から差し込めます。未設定なら各ボタン内の FallbackLabel を表示します。
@export var icon_inventory_action: Texture2D
@export var icon_status_action: Texture2D


@export var icon_poison: Texture2D
@export var icon_paralysis: Texture2D
@export var icon_sleep: Texture2D
@export var icon_burning: Texture2D
@export var icon_frostbite: Texture2D
@export var icon_confusion: Texture2D
@export var icon_blind: Texture2D
@export var icon_hallucination: Texture2D
@export var icon_curse: Texture2D
@export var icon_full: Texture2D
@export var icon_hungry: Texture2D
@export var icon_starving: Texture2D
@export var icon_starve_damage: Texture2D
@export var icon_fatigue: Texture2D
@export var icon_exhausted: Texture2D

@export var icon_attack_buff: Texture2D
@export var icon_attack_debuff: Texture2D
@export var icon_defense_buff: Texture2D
@export var icon_defense_debuff: Texture2D
@export var icon_speed_buff: Texture2D
@export var icon_speed_debuff: Texture2D
@export var icon_accuracy_buff: Texture2D
@export var icon_accuracy_debuff: Texture2D
@export var icon_evasion_buff: Texture2D
@export var icon_evasion_debuff: Texture2D
@export var icon_crit_rate_buff: Texture2D
@export var icon_crit_rate_debuff: Texture2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var day_label: Label = $CanvasLayer/TimeArea/PanelContainer/VBoxContainer/DayLabel
@onready var time_label: Label = $CanvasLayer/TimeArea/PanelContainer/VBoxContainer/TimeLabel
@onready var weather_label: Label = $CanvasLayer/TimeArea/PanelContainer/VBoxContainer/WeatherLabel

@onready var player_name_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/NameLabel
@onready var hp_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/HPLabel
@onready var hp_bar: ProgressBar = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/HPBar
@onready var mp_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/MPLabel
@onready var mp_bar: ProgressBar = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/MPBar
@onready var stamina_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/StaminaLabel
@onready var stamina_bar: ProgressBar = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/StaminaBar

@onready var dummy_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/AllyStatusCardDummy/PanelContainer/VBoxContainer/DummyLabel
@onready var minimap_label: Label = $CanvasLayer/MiniMapArea/PanelContainer/MiniMapLabel

@onready var log_title_label: Label = $CanvasLayer/LogArea/PanelContainer/VBoxContainer/LogTitleLabel
@onready var log_label: Label = $CanvasLayer/LogArea/PanelContainer/VBoxContainer/LogLabel

@onready var effect_bar_area: Control = $CanvasLayer/EffectBarArea
@onready var effect_bar_container: HBoxContainer = $CanvasLayer/EffectBarArea/EffectBarContainer
@onready var hotbar_area: Control = get_node_or_null("CanvasLayer/HotbarArea") as Control
@onready var hotbar_panel_container: PanelContainer = get_node_or_null("CanvasLayer/HotbarArea/PanelContainer") as PanelContainer
@onready var hotbar_container: HBoxContainer = $CanvasLayer/HotbarArea/PanelContainer/HotbarContainer

@onready var action_buttons_area: Control = get_node_or_null("CanvasLayer/ActionButtonsArea") as Control
@onready var inventory_action_button: BaseButton = get_node_or_null("CanvasLayer/ActionButtonsArea/ActionButtonContainer/InventoryButton") as BaseButton
@onready var status_action_button: BaseButton = get_node_or_null("CanvasLayer/ActionButtonsArea/ActionButtonContainer/StatusButton") as BaseButton

var current_day: int = 1
var current_time_text: String = "08:30"
var current_weather_text: String = "Sunny"

var player_name: String = "Player"
var current_hp: int = 100
var max_hp: int = 100
var current_mp: int = 0
var max_mp: int = 0
var current_stamina: int = 0
var max_stamina: int = 0

var log_lines: Array[String] = []
var max_log_lines: int = 6

var effect_entries: Array[Dictionary] = []

var tooltip_panel: PanelContainer = null
var tooltip_label: Label = null

var hovered_effect_button: Control = null
var hovered_effect_tooltip_text: String = ""
var hovered_effect_key: String = ""

var hotbar_inventory = null
var hotbar_snapshot_key: String = ""
var hovered_hotbar_button: Control = null
var hovered_hotbar_tooltip_text: String = ""

# インベントリを開いている間だけ、HUDホットバーを「収納操作モード」として見せる。
# 通常時の見た目は変えない。
var inventory_hotbar_edit_mode: bool = false

# InventoryUI の暗い Overlay は CanvasLayer layer 10 にある。
# インベントリ表示中も操作できる HUD 要素だけを、それより上の CanvasLayer に一時退避する。
# これで「操作できるもの」だけがインベントリ本体と同じ明るさで見える。
var inventory_interaction_layer: CanvasLayer = null
var hotbar_area_original_parent: Node = null
var hotbar_area_original_index: int = -1
var action_buttons_area_original_parent: Node = null
var action_buttons_area_original_index: int = -1


func _ready() -> void:
	initialize_hud()
	_setup_inventory_interaction_layer()
	_setup_action_buttons()
	_create_effect_tooltip()


func _process(_delta: float) -> void:
	_update_effect_tooltip_hover_state()


func initialize_hud() -> void:
	log_title_label.text = "Log"
	dummy_label.text = "Ally Slot"
	minimap_label.text = "Mini Map"

	update_time_area()
	update_player_status_area()
	update_log_display()
	rebuild_effect_bar()
	_apply_hotbar_layout()
	rebuild_hotbar()


func _setup_inventory_interaction_layer() -> void:
	if inventory_interaction_layer != null:
		return

	inventory_interaction_layer = get_node_or_null("InventoryInteractionLayer") as CanvasLayer

	if inventory_interaction_layer == null:
		inventory_interaction_layer = CanvasLayer.new()
		inventory_interaction_layer.name = "InventoryInteractionLayer"
		add_child(inventory_interaction_layer)

	# InventoryUI.tscn は layer = 10。
	# それより上に、インベントリ中も操作できるHUDだけを表示する。
	inventory_interaction_layer.layer = 20
	inventory_interaction_layer.visible = true

	if hotbar_area != null and hotbar_area_original_parent == null:
		hotbar_area_original_parent = hotbar_area.get_parent()
		hotbar_area_original_index = hotbar_area.get_index()

	if action_buttons_area != null and action_buttons_area_original_parent == null:
		action_buttons_area_original_parent = action_buttons_area.get_parent()
		action_buttons_area_original_index = action_buttons_area.get_index()


func _set_inventory_interactable_brightness_mode(enabled: bool) -> void:
	_setup_inventory_interaction_layer()

	if enabled:
		_move_inventory_interactable_nodes_above_inventory()
	else:
		_restore_inventory_interactable_nodes_to_hud()

	_force_interactable_hud_brightness()


func _move_inventory_interactable_nodes_above_inventory() -> void:
	if inventory_interaction_layer == null:
		return

	# ホットバーと開閉/状態ボタンだけを InventoryUI の暗いOverlayより上へ移す。
	# Time/Log/Minimap など、インベントリ中に操作しないHUDは暗いままでよい。
	_reparent_runtime_node(action_buttons_area, inventory_interaction_layer, -1)
	_reparent_runtime_node(hotbar_area, inventory_interaction_layer, -1)


func _restore_inventory_interactable_nodes_to_hud() -> void:
	_reparent_runtime_node(action_buttons_area, action_buttons_area_original_parent, action_buttons_area_original_index)
	_reparent_runtime_node(hotbar_area, hotbar_area_original_parent, hotbar_area_original_index)


func _reparent_runtime_node(node: Node, target_parent: Node, target_index: int = -1) -> void:
	if node == null:
		return

	if target_parent == null:
		return

	if node.get_parent() == target_parent:
		if target_index >= 0 and target_index < target_parent.get_child_count():
			target_parent.move_child(node, target_index)
		return

	var old_parent: Node = node.get_parent()
	if old_parent != null:
		old_parent.remove_child(node)

	target_parent.add_child(node)

	if target_index >= 0 and target_index < target_parent.get_child_count():
		target_parent.move_child(node, target_index)


func _force_interactable_hud_brightness() -> void:
	_force_control_tree_brightness(action_buttons_area)
	_force_control_tree_brightness(hotbar_area)


func _force_control_tree_brightness(node: Node) -> void:
	if node == null:
		return

	if node is CanvasItem:
		var canvas_item: CanvasItem = node as CanvasItem
		canvas_item.modulate = Color(1.0, 1.0, 1.0, 1.0)
		canvas_item.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	if node is BaseButton:
		var button: BaseButton = node as BaseButton
		button.disabled = false

	for child in node.get_children():
		_force_control_tree_brightness(child)


func _setup_action_buttons() -> void:
	_setup_action_icon_button(inventory_action_button, icon_inventory_action, "所", "所持品")
	_setup_action_icon_button(status_action_button, icon_status_action, "状", "状態")

	_connect_action_button(inventory_action_button, Callable(self, "_on_inventory_action_button_pressed"))
	_connect_action_button(status_action_button, Callable(self, "_on_status_action_button_pressed"))

	if inventory_hotbar_edit_mode:
		_force_interactable_hud_brightness()


func set_inventory_hotbar_edit_mode(enabled: bool) -> void:
	if inventory_hotbar_edit_mode == enabled:
		return

	inventory_hotbar_edit_mode = enabled
	_set_inventory_interactable_brightness_mode(enabled)

	# 見た目だけを切り替える。通常時は以前のスタイルに戻す。
	_setup_action_buttons()
	rebuild_hotbar()


func is_inventory_hotbar_edit_mode() -> bool:
	return inventory_hotbar_edit_mode


func _setup_action_icon_button(button: BaseButton, icon: Texture2D, fallback_text: String, tooltip_text: String) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.disabled = false
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	button.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(28, 28)
	button.tooltip_text = tooltip_text
	button.clip_contents = true

	var has_icon: bool = false

	if button is TextureButton:
		var texture_button: TextureButton = button as TextureButton

		if icon != null:
			texture_button.texture_normal = icon
			texture_button.texture_hover = icon
			texture_button.texture_pressed = icon
			texture_button.texture_disabled = icon
			has_icon = true
		elif texture_button.texture_normal != null:
			has_icon = true

		# TextureButton は StyleBox を持てないため、アイコン未設定時は子 Label を表示する。
		# 本番では下の tscn 修正版のように Button ノードにしておく方がきれい。
		_update_action_button_fallback_label(button, fallback_text, not has_icon)
		return

	if button is Button:
		var normal_button: Button = button as Button

		if icon != null:
			normal_button.icon = icon
			normal_button.text = ""
			normal_button.flat = true
			_apply_clear_button_style(normal_button)
			has_icon = true
		else:
			normal_button.icon = null
			normal_button.text = fallback_text
			normal_button.add_theme_font_size_override("font_size", 13)
			normal_button.flat = false
			_apply_action_fallback_icon_style(normal_button)

		_update_action_button_fallback_label(button, fallback_text, false)
		return

	_update_action_button_fallback_label(button, fallback_text, not has_icon)


func _update_action_button_fallback_label(button: BaseButton, fallback_text: String, show_label: bool) -> void:
	if button == null:
		return

	var fallback_label: Label = button.get_node_or_null("FallbackLabel") as Label
	if fallback_label == null:
		return

	fallback_label.text = fallback_text
	fallback_label.visible = show_label
	fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_font_size_override("font_size", 13)


func _apply_action_fallback_icon_style(button: Button) -> void:
	if button == null:
		return

	# アイコン未設定時は、状態異常アイコンの文字表示と同じ考え方の小さいボタンにする。
	var bg_color: Color = Color(0.25, 0.25, 0.25, 0.95)
	var font_color: Color = Color(1.0, 1.0, 1.0, 1.0)

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.15, 0.15, 0.15, 0.9)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.12)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.08)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)

	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)


func _apply_clear_button_style(button: Button) -> void:
	if button == null:
		return

	var clear_style: StyleBoxFlat = StyleBoxFlat.new()
	clear_style.bg_color = Color(0, 0, 0, 0)
	clear_style.border_width_left = 0
	clear_style.border_width_top = 0
	clear_style.border_width_right = 0
	clear_style.border_width_bottom = 0

	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", clear_style)
	button.add_theme_stylebox_override("pressed", clear_style)
	button.add_theme_stylebox_override("focus", clear_style)


func _make_inventory_mode_clear_stylebox() -> StyleBoxFlat:
	var clear_style: StyleBoxFlat = StyleBoxFlat.new()
	clear_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	clear_style.border_width_left = 0
	clear_style.border_width_top = 0
	clear_style.border_width_right = 0
	clear_style.border_width_bottom = 0
	return clear_style


func _apply_inventory_mode_clear_button_style(button: Button) -> void:
	if button == null:
		return

	button.flat = true
	button.disabled = false
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	button.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	var clear_style: StyleBoxFlat = _make_inventory_mode_clear_stylebox()
	var hover_style: StyleBoxFlat = clear_style.duplicate()
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.06)

	var pressed_style: StyleBoxFlat = clear_style.duplicate()
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.10)

	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", clear_style)

	var font_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", font_color)


func _apply_inventory_mode_action_button_style(button: Button) -> void:
	# インベントリ表示中だけ、開閉ボタンが disabled/灰色に見えないようにする。
	# 通常時のスタイルは _apply_action_fallback_icon_style() 側に任せる。
	_apply_inventory_mode_clear_button_style(button)


func _connect_action_button(button: BaseButton, callback: Callable) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_inventory_action_button_pressed() -> void:
	inventory_button_pressed.emit()


func _on_status_action_button_pressed() -> void:
	status_button_pressed.emit()


func _create_effect_tooltip() -> void:
	if canvas_layer == null:
		return

	tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 99
	tooltip_panel.custom_minimum_size = Vector2(220, 0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.8, 0.8, 0.8, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	tooltip_panel.add_theme_stylebox_override("panel", style)

	tooltip_label = Label.new()
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_label.custom_minimum_size = Vector2(220, 0)
	tooltip_label.add_theme_font_size_override("font_size", 14)

	tooltip_panel.add_child(tooltip_label)
	canvas_layer.add_child(tooltip_panel)


func update_time_area() -> void:
	day_label.text = "Day %d" % current_day
	time_label.text = current_time_text
	weather_label.text = current_weather_text


func update_player_status_area() -> void:
	player_name_label.text = player_name

	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	mp_label.text = "MP: %d / %d" % [current_mp, max_mp]
	mp_bar.max_value = max_mp
	mp_bar.value = current_mp

	stamina_label.text = "STM: %d / %d" % [current_stamina, max_stamina]
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina


func add_log(text: String) -> void:
	log_lines.append(text)

	while log_lines.size() > max_log_lines:
		log_lines.pop_front()

	update_log_display()


func update_log_display() -> void:
	log_label.text = "\n".join(log_lines)


func set_time_info(p_day: int, p_time_text: String, p_weather_text: String) -> void:
	current_day = p_day
	current_time_text = p_time_text
	current_weather_text = p_weather_text
	update_time_area()


func set_player_status(
	p_name: String,
	p_hp: int,
	p_max_hp: int,
	p_mp: int,
	p_max_mp: int,
	p_stamina: int,
	p_max_stamina: int
) -> void:
	player_name = p_name
	current_hp = p_hp
	max_hp = p_max_hp
	current_mp = p_mp
	max_mp = p_max_mp
	current_stamina = p_stamina
	max_stamina = p_max_stamina
	update_player_status_area()


func set_effect_entries(entries: Array) -> void:
	var new_entries: Array[Dictionary] = []

	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant as Dictionary
		new_entries.append(entry.duplicate(true))

	if _are_effect_entries_equal(effect_entries, new_entries):
		if hovered_effect_key != "":
			var updated_entry: Dictionary = _find_entry_by_hover_key(effect_entries, hovered_effect_key)
			if not updated_entry.is_empty():
				hovered_effect_tooltip_text = _build_effect_tooltip(updated_entry)
		return

	effect_entries = new_entries
	rebuild_effect_bar()


func rebuild_effect_bar() -> void:
	if effect_bar_container == null:
		return

	for child in effect_bar_container.get_children():
		child.queue_free()

	var previous_hover_key: String = hovered_effect_key

	hovered_effect_button = null
	hovered_effect_tooltip_text = ""

	if effect_bar_area != null:
		effect_bar_area.visible = not effect_entries.is_empty()

	if effect_entries.is_empty():
		hovered_effect_key = ""
		_hide_effect_tooltip()
		return

	for entry in effect_entries:
		var hover_key: String = String(entry.get("hover_key", ""))
		var effect_tooltip_text: String = _build_effect_tooltip(entry)
		var texture: Texture2D = _get_effect_texture(entry)

		var icon_root: Control = null

		if texture != null:
			var icon_button: Button = Button.new()
			icon_button.custom_minimum_size = Vector2(34, 34)
			icon_button.focus_mode = Control.FOCUS_NONE
			icon_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			icon_button.mouse_filter = Control.MOUSE_FILTER_STOP
			icon_button.flat = true
			icon_button.set_meta("hover_key", hover_key)

			var clear_style: StyleBoxFlat = StyleBoxFlat.new()
			clear_style.bg_color = Color(0, 0, 0, 0)
			clear_style.border_width_left = 0
			clear_style.border_width_top = 0
			clear_style.border_width_right = 0
			clear_style.border_width_bottom = 0

			icon_button.add_theme_stylebox_override("normal", clear_style)
			icon_button.add_theme_stylebox_override("hover", clear_style)
			icon_button.add_theme_stylebox_override("pressed", clear_style)
			icon_button.add_theme_stylebox_override("focus", clear_style)

			var texture_rect: TextureRect = TextureRect.new()
			texture_rect.texture = texture
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			texture_rect.offset_left = 0.0
			texture_rect.offset_top = 0.0
			texture_rect.offset_right = 0.0
			texture_rect.offset_bottom = 0.0

			icon_button.add_child(texture_rect)

			icon_button.mouse_entered.connect(_on_effect_icon_mouse_entered.bind(icon_button, effect_tooltip_text, hover_key))
			icon_button.mouse_exited.connect(_on_effect_icon_mouse_exited.bind(icon_button))
			icon_button.gui_input.connect(_on_effect_icon_gui_input.bind(icon_button, effect_tooltip_text, hover_key))

			icon_root = icon_button
		else:
			var icon_button: Button = Button.new()
			icon_button.custom_minimum_size = Vector2(34, 34)
			icon_button.text = _build_effect_icon_text(entry)
			icon_button.focus_mode = Control.FOCUS_NONE
			icon_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			icon_button.mouse_filter = Control.MOUSE_FILTER_STOP
			icon_button.flat = false
			icon_button.add_theme_font_size_override("font_size", 13)
			icon_button.set_meta("hover_key", hover_key)

			_apply_effect_icon_style(icon_button, entry)

			icon_button.mouse_entered.connect(_on_effect_icon_mouse_entered.bind(icon_button, effect_tooltip_text, hover_key))
			icon_button.mouse_exited.connect(_on_effect_icon_mouse_exited.bind(icon_button))
			icon_button.gui_input.connect(_on_effect_icon_gui_input.bind(icon_button, effect_tooltip_text, hover_key))

			icon_root = icon_button

		effect_bar_container.add_child(icon_root)

		if previous_hover_key != "" and hover_key == previous_hover_key:
			hovered_effect_button = icon_root
			hovered_effect_tooltip_text = effect_tooltip_text
			hovered_effect_key = hover_key

	if hovered_effect_button != null:
		_show_effect_tooltip(hovered_effect_tooltip_text)
	else:
		hovered_effect_key = ""
		_hide_effect_tooltip()


func set_hotbar_inventory(inventory) -> void:
	# Hotbar は Inventory.hotbar_items を表示する。
	# 通常インベントリ items の先頭9スロットではない。
	hotbar_inventory = inventory
	refresh_hotbar_if_changed()


func refresh_hotbar_if_changed() -> void:
	var next_snapshot_key: String = _build_hotbar_snapshot_key()

	if next_snapshot_key == hotbar_snapshot_key:
		return

	hotbar_snapshot_key = next_snapshot_key
	rebuild_hotbar()


func rebuild_hotbar() -> void:
	_apply_hotbar_layout()

	if hotbar_container == null:
		return

	for child in hotbar_container.get_children():
		child.queue_free()

	var slot_count: int = get_hotbar_slot_count()

	for i in range(slot_count):
		var entry: Dictionary = _get_hotbar_inventory_entry(i)
		var slot_button: Button = _create_hotbar_slot_button(i, entry)
		hotbar_container.add_child(slot_button)

	if inventory_hotbar_edit_mode:
		_force_interactable_hud_brightness()


func refresh_hotbar() -> void:
	hotbar_snapshot_key = ""
	rebuild_hotbar()


func get_hotbar_slot_count() -> int:
	if hotbar_inventory != null and hotbar_inventory.has_method("get_hotbar_slot_count"):
		return max(1, int(hotbar_inventory.get_hotbar_slot_count()))

	if hotbar_inventory != null and "hotbar_slot_count" in hotbar_inventory:
		return max(1, int(hotbar_inventory.hotbar_slot_count))

	return 9


func _build_hotbar_snapshot_key() -> String:
	var parts: Array[String] = []
	var slot_count: int = get_hotbar_slot_count()
	parts.append(str(slot_count))

	for i in range(slot_count):
		var entry: Dictionary = _get_hotbar_inventory_entry(i)
		var item_id: String = String(entry.get("item_id", ""))
		var amount: int = int(entry.get("amount", 0))
		var instance_data: String = ""

		if entry.has("instance_data"):
			instance_data = str(entry.get("instance_data"))

		parts.append("%d:%s:%d:%s" % [i, item_id, amount, instance_data])

	return "|".join(parts)


func _get_hotbar_inventory_entry(hotbar_index: int) -> Dictionary:
	if hotbar_inventory == null:
		return {}

	if hotbar_inventory.has_method("get_hotbar_item_data_at"):
		var entry: Dictionary = hotbar_inventory.get_hotbar_item_data_at(hotbar_index)
		return entry.duplicate(true)

	if "hotbar_items" in hotbar_inventory:
		var items: Array = hotbar_inventory.hotbar_items
		if hotbar_index >= 0 and hotbar_index < items.size():
			var raw_entry: Variant = items[hotbar_index]
			if typeof(raw_entry) == TYPE_DICTIONARY:
				return (raw_entry as Dictionary).duplicate(true)

	return {}


func _apply_hotbar_layout() -> void:
	if hotbar_container != null:
		hotbar_container.add_theme_constant_override("separation", max(0, hotbar_slot_gap))
		hotbar_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		hotbar_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	# HotbarArea/PanelContainer に付いている余分な薄灰色背景だけを消す。
	# 各ホットバースロットの背景・枠は通常通り残す。
	_apply_hotbar_outer_background_style()


func _apply_hotbar_outer_background_style() -> void:
	if hotbar_panel_container == null:
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, clamp(hotbar_outer_background_alpha, 0.0, 1.0))
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0

	hotbar_panel_container.add_theme_stylebox_override("panel", style)
	hotbar_panel_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hotbar_panel_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _create_hotbar_slot_button(display_index: int, entry: Dictionary) -> Button:
	var slot_button: Button = Button.new()
	slot_button.custom_minimum_size = hotbar_slot_size
	slot_button.focus_mode = Control.FOCUS_NONE
	slot_button.disabled = false
	slot_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	slot_button.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	slot_button.mouse_filter = Control.MOUSE_FILTER_STOP
	slot_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot_button.clip_contents = true
	slot_button.set_meta("hotbar_index", display_index)

	_apply_hotbar_slot_style(slot_button)

	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))
	var has_item: bool = item_id != "" and amount > 0

	if has_item:
		var texture: Texture2D = ItemDatabase.get_item_icon(item_id)
		if texture != null:
			var icon_rect: TextureRect = TextureRect.new()
			icon_rect.texture = texture
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.offset_left = float(hotbar_icon_margin)
			icon_rect.offset_top = float(hotbar_icon_margin)
			icon_rect.offset_right = -float(hotbar_icon_margin)
			icon_rect.offset_bottom = -float(hotbar_icon_margin)
			slot_button.add_child(icon_rect)
		else:
			slot_button.text = _build_hotbar_fallback_item_text(item_id)
	else:
		slot_button.text = str(display_index + 1)

	if has_item and amount > 1:
		var amount_label: Label = Label.new()
		amount_label.text = "x%d" % amount
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		amount_label.add_theme_font_size_override("font_size", 11)
		amount_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		amount_label.offset_left = 0.0
		amount_label.offset_top = 0.0
		amount_label.offset_right = -3.0
		amount_label.offset_bottom = -1.0
		slot_button.add_child(amount_label)

	var tooltip_text: String = _build_hotbar_tooltip_text(display_index, entry)
	slot_button.mouse_entered.connect(_on_hotbar_slot_mouse_entered.bind(slot_button, tooltip_text))
	slot_button.mouse_exited.connect(_on_hotbar_slot_mouse_exited.bind(slot_button))
	slot_button.gui_input.connect(_on_hotbar_slot_gui_input.bind(slot_button, tooltip_text))
	slot_button.pressed.connect(_on_hotbar_slot_pressed.bind(display_index))

	return slot_button


func _apply_inventory_mode_hotbar_slot_style(button: Button) -> void:
	if button == null:
		return

	button.flat = true
	button.disabled = false
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	button.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(1.0, 1.0, 1.0, 0.25)
	normal_style.corner_radius_top_left = 3
	normal_style.corner_radius_top_right = 3
	normal_style.corner_radius_bottom_left = 3
	normal_style.corner_radius_bottom_right = 3

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	hover_style.border_color = Color(1.0, 0.9, 0.35, 1.0)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	pressed_style.border_color = Color(1.0, 0.9, 0.35, 1.0)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", normal_style)

	var font_color: Color = Color(1.0, 1.0, 1.0, 0.95)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", font_color)
	button.add_theme_font_size_override("font_size", 13)


func _apply_hotbar_slot_style(button: Button) -> void:
	# インベントリ表示中も通常時と同じ見た目を維持する。
	# 操作可能にするため disabled=false / modulate=白は維持するが、
	# 背景や枠のStyleBoxは通常時と同じものを使う。
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.0, 0.0, 0.0, clamp(hotbar_slot_background_alpha, 0.0, 1.0))
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.45, 0.45, 0.45, 0.55)
	normal_style.corner_radius_top_left = 3
	normal_style.corner_radius_top_right = 3
	normal_style.corner_radius_bottom_left = 3
	normal_style.corner_radius_bottom_right = 3

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	hover_style.border_color = Color(1.0, 0.9, 0.35, 1.0)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	pressed_style.border_color = Color(1.0, 0.9, 0.35, 1.0)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_font_size_override("font_size", 13)

func _build_hotbar_fallback_item_text(item_id: String) -> String:
	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name == "":
		return "?"

	if display_name.length() >= 2:
		return display_name.substr(0, 2)

	return display_name


func _build_hotbar_tooltip_text(_display_index: int, entry: Dictionary) -> String:
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	# 空のホットバーにはホバー表示を出さない。
	if item_id == "" or amount <= 0:
		return ""

	var lines: Array[String] = []
	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name != "":
		lines.append(display_name)
	else:
		lines.append(item_id)

	var description: String = ItemDatabase.get_description(item_id)
	if description != "":
		lines.append(description)

	if amount > 1:
		lines.append("所持数: %d" % amount)

	return "\n".join(lines)

func _on_hotbar_slot_pressed(hotbar_index: int) -> void:
	hotbar_slot_pressed.emit(hotbar_index)


func _on_hotbar_slot_mouse_entered(button: Control, tooltip_text: String) -> void:
	if tooltip_text == "":
		hovered_hotbar_button = null
		hovered_hotbar_tooltip_text = ""
		_hide_effect_tooltip()
		return

	hovered_hotbar_button = button
	hovered_hotbar_tooltip_text = tooltip_text
	_show_effect_tooltip(tooltip_text)


func _on_hotbar_slot_mouse_exited(button: Control) -> void:
	if hovered_hotbar_button == button:
		hovered_hotbar_button = null
		hovered_hotbar_tooltip_text = ""
		_hide_effect_tooltip()


func _on_hotbar_slot_gui_input(event: InputEvent, button: Control, tooltip_text: String) -> void:
	if event is InputEventMouseMotion:
		if tooltip_text == "":
			hovered_hotbar_button = null
			hovered_hotbar_tooltip_text = ""
			_hide_effect_tooltip()
			return

		hovered_hotbar_button = button
		hovered_hotbar_tooltip_text = tooltip_text
		_show_effect_tooltip(tooltip_text)

func _build_effect_icon_text(entry: Dictionary) -> String:
	var icon_text: String = String(entry.get("icon_text", ""))
	if icon_text != "":
		return icon_text

	var short_name: String = String(entry.get("short_name", ""))
	if short_name != "":
		return short_name

	var name_text: String = String(entry.get("name", "効果"))
	if name_text.length() >= 2:
		return name_text.substr(0, 2)

	return name_text


func _build_effect_tooltip(entry: Dictionary) -> String:
	var lines: Array[String] = []

	var name_text: String = String(entry.get("name", "効果"))
	lines.append(name_text)

	var type_text: String = String(entry.get("type_text", ""))
	if type_text != "":
		lines.append("種類: " + type_text)

	var description: String = String(entry.get("description", ""))
	if description != "":
		lines.append(description)

	var remaining_time_text: String = String(entry.get("remaining_time_text", ""))
	if remaining_time_text != "":
		lines.append("残り時間: " + remaining_time_text)

	var remaining_turn_text: String = String(entry.get("remaining_turn_text", ""))
	if remaining_turn_text != "":
		lines.append("残りターン: " + remaining_turn_text)

	return "\n".join(lines)


func _apply_effect_icon_style(button: Button, entry: Dictionary) -> void:
	var bg_color: Color = _get_effect_background_color(entry)
	var font_color: Color = _get_effect_font_color(entry)

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.15, 0.15, 0.15, 0.9)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.12)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.08)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)

	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)


func _get_effect_background_color(entry: Dictionary) -> Color:
	var kind: String = String(entry.get("kind", ""))

	match kind:
		"status":
			return Color(0.45, 0.20, 0.20, 0.95)
		"buff":
			return Color(0.18, 0.40, 0.22, 0.95)
		"debuff":
			return Color(0.50, 0.32, 0.10, 0.95)
		"condition":
			return Color(0.20, 0.28, 0.42, 0.95)
		_:
			return Color(0.25, 0.25, 0.25, 0.95)


func _get_effect_font_color(_entry: Dictionary) -> Color:
	return Color(1.0, 1.0, 1.0, 1.0)


func _get_effect_texture(entry: Dictionary) -> Texture2D:
	var type_text: String = String(entry.get("type_text", ""))
	var name_text: String = String(entry.get("name", ""))

	if type_text == "状態異常":
		match name_text:
			"毒":
				return icon_poison
			"麻痺":
				return icon_paralysis
			"睡眠":
				return icon_sleep
			"炎上":
				return icon_burning
			"凍傷":
				return icon_frostbite
			"混乱":
				return icon_confusion
			"盲目":
				return icon_blind
			"幻覚":
				return icon_hallucination
			"呪い":
				return icon_curse

	if type_text == "バフ" or type_text == "デバフ":
		var is_debuff: bool = type_text == "デバフ"

		match name_text:
			"攻撃上昇", "攻撃低下":
				return icon_attack_debuff if is_debuff else icon_attack_buff
			"防御上昇", "防御低下":
				return icon_defense_debuff if is_debuff else icon_defense_buff
			"速度上昇", "速度低下":
				return icon_speed_debuff if is_debuff else icon_speed_buff
			"命中上昇", "命中低下":
				return icon_accuracy_debuff if is_debuff else icon_accuracy_buff
			"回避上昇", "回避低下":
				return icon_evasion_debuff if is_debuff else icon_evasion_buff
			"会心上昇", "会心低下":
				return icon_crit_rate_debuff if is_debuff else icon_crit_rate_buff

	if type_text == "コンディション":
		match name_text:
			"満腹":
				return icon_full
			"空腹":
				return icon_hungry
			"飢餓":
				return icon_starving
			"餓死":
				return icon_starve_damage
			"疲労":
				return icon_fatigue
			"過労":
				return icon_exhausted

	return null


func _on_effect_icon_mouse_entered(button: Control, effect_tooltip_text: String, hover_key: String) -> void:
	hovered_effect_button = button
	hovered_effect_tooltip_text = effect_tooltip_text
	hovered_effect_key = hover_key
	_show_effect_tooltip(effect_tooltip_text)


func _on_effect_icon_mouse_exited(button: Control) -> void:
	if hovered_effect_button == button:
		pass


func _on_effect_icon_gui_input(event: InputEvent, button: Control, effect_tooltip_text: String, hover_key: String) -> void:
	if event is InputEventMouseMotion:
		hovered_effect_button = button
		hovered_effect_tooltip_text = effect_tooltip_text
		hovered_effect_key = hover_key
		_show_effect_tooltip(effect_tooltip_text)


func _update_effect_tooltip_hover_state() -> void:
	if tooltip_panel == null:
		return

	if hovered_hotbar_button != null and is_instance_valid(hovered_hotbar_button):
		var hotbar_mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var hotbar_rect: Rect2 = hovered_hotbar_button.get_global_rect()

		if hotbar_rect.has_point(hotbar_mouse_pos):
			if hovered_hotbar_tooltip_text != "":
				_show_effect_tooltip(hovered_hotbar_tooltip_text)
			else:
				_hide_effect_tooltip()
			return

		hovered_hotbar_button = null
		hovered_hotbar_tooltip_text = ""

	if hovered_effect_button == null:
		_hide_effect_tooltip()
		return

	if not is_instance_valid(hovered_effect_button):
		hovered_effect_button = null
		hovered_effect_tooltip_text = ""
		hovered_effect_key = ""
		_hide_effect_tooltip()
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var rect: Rect2 = hovered_effect_button.get_global_rect()

	if rect.has_point(mouse_pos):
		var updated_entry: Dictionary = _find_entry_by_hover_key(effect_entries, hovered_effect_key)
		if not updated_entry.is_empty():
			hovered_effect_tooltip_text = _build_effect_tooltip(updated_entry)
		_show_effect_tooltip(hovered_effect_tooltip_text)
		return

	hovered_effect_button = null
	hovered_effect_tooltip_text = ""
	hovered_effect_key = ""
	_hide_effect_tooltip()

func _show_effect_tooltip(effect_tooltip_text: String) -> void:
	if tooltip_panel == null or tooltip_label == null:
		return

	if effect_tooltip_text == "":
		_hide_effect_tooltip()
		return

	tooltip_label.text = effect_tooltip_text
	tooltip_panel.visible = true

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var target_pos: Vector2 = mouse_pos + Vector2(18, -6)

	var panel_size: Vector2 = tooltip_panel.get_combined_minimum_size()
	var viewport_rect: Rect2 = get_viewport_rect()

	if target_pos.x + panel_size.x > viewport_rect.size.x - 8.0:
		target_pos.x = viewport_rect.size.x - panel_size.x - 8.0

	if target_pos.y + panel_size.y > viewport_rect.size.y - 8.0:
		target_pos.y = viewport_rect.size.y - panel_size.y - 8.0

	if target_pos.y < 8.0:
		target_pos.y = 8.0

	tooltip_panel.position = target_pos


func _hide_effect_tooltip() -> void:
	if tooltip_panel == null:
		return

	tooltip_panel.visible = false


func _are_effect_entries_equal(a: Array[Dictionary], b: Array[Dictionary]) -> bool:
	if a.size() != b.size():
		return false

	for i in range(a.size()):
		if a[i] != b[i]:
			return false

	return true


func _find_entry_by_hover_key(entries: Array[Dictionary], hover_key: String) -> Dictionary:
	if hover_key == "":
		return {}

	for entry in entries:
		if String(entry.get("hover_key", "")) == hover_key:
			return entry

	return {}


func _find_effect_button_by_hover_key(hover_key: String) -> Control:
	if hover_key == "":
		return null

	for child in effect_bar_container.get_children():
		if child == null:
			continue
		if String(child.get_meta("hover_key", "")) == hover_key:
			return child

	return null
