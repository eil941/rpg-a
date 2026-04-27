extends CanvasLayer
class_name StatusUI

const PAGE_COUNT: int = 4

@export var default_background: Texture2D
@export var page_1_background: Texture2D
@export var page_2_background: Texture2D
@export var page_3_background: Texture2D
@export var page_4_background: Texture2D

@export var page_1_button_texture: Texture2D
@export var page_2_button_texture: Texture2D
@export var page_3_button_texture: Texture2D
@export var page_4_button_texture: Texture2D
@export var close_button_texture: Texture2D

@export var selected_button_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var unselected_button_modulate: Color = Color(0.55, 0.55, 0.55, 1.0)
@export var close_button_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

@onready var root: Control = $Root

@onready var background_texture: TextureRect = $Root/BackgroundTexture
@onready var solid_background: ColorRect = $Root/SolidBackground

@onready var page_label: Label = $Root/MainMargin/MainVBox/ContentPanel/PageHeader/PageLabel
@onready var close_button: Button = $Root/MainMargin/MainVBox/ContentPanel/PageHeader/CloseButton

@onready var content_panel: Panel = $Root/MainMargin/MainVBox/ContentPanel
@onready var page_background_texture: TextureRect = $Root/MainMargin/MainVBox/ContentPanel/PageBackgroundTexture

@onready var page_1_scroll: ScrollContainer = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page1Scroll
@onready var page_2_scroll: ScrollContainer = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page2Scroll
@onready var page_3_scroll: ScrollContainer = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page3Scroll
@onready var page_4_scroll: ScrollContainer = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page4Scroll

@onready var page_2_text: RichTextLabel = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page2Scroll/Page2Content/Page2Text
@onready var page_3_text: RichTextLabel = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page3Scroll/Page3Content/Page3Text
@onready var page_4_text: RichTextLabel = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page4Scroll/Page4Content/Page4Text
@onready var page_4_content: Control = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page4Scroll/Page4Content

@onready var portrait_texture: TextureRect = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page1Scroll/Page1Content/MainVBox/TopRow/PortraitPanel/PortraitTexture
@onready var page1_name_label: Label = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page1Scroll/Page1Content/MainVBox/TopRow/RightVBox/HeaderInfo/NameLabel

@onready var page1_combat_text: RichTextLabel = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page1Scroll/Page1Content/MainVBox/TopRow/RightVBox/StatsRow/CombatPanel/CombatVBox/CombatStatusText
@onready var page1_basic_text: RichTextLabel = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page1Scroll/Page1Content/MainVBox/TopRow/RightVBox/StatsRow/BasicPanel/BasicVBox/BasicStatusText

@onready var equipment_row: BoxContainer = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page1Scroll/Page1Content/MainVBox/EquipmentPanel/EquipmentVBox/EquipmentRow

var equipment_icon_nodes: Dictionary = {}

@onready var page1_notes_text: RichTextLabel = $Root/MainMargin/MainVBox/ContentPanel/PageArea/Page1Scroll/Page1Content/MainVBox/NotesPanel/NotesVBox/NotesText

@onready var bottom_tab_bar: MarginContainer = $Root/MainMargin/MainVBox/BottomTabBar
@onready var page_1_button: Button = $Root/MainMargin/MainVBox/BottomTabBar/TabButtonsWrap/Page1Button
@onready var page_2_button: Button = $Root/MainMargin/MainVBox/BottomTabBar/TabButtonsWrap/Page2Button
@onready var page_3_button: Button = $Root/MainMargin/MainVBox/BottomTabBar/TabButtonsWrap/Page3Button
@onready var page_4_button: Button = $Root/MainMargin/MainVBox/BottomTabBar/TabButtonsWrap/Page4Button

var target_unit = null
var current_page: int = 0

var selected_tab_fallback_style: StyleBoxFlat
var unselected_tab_fallback_style: StyleBoxFlat
var close_button_fallback_style: StyleBoxFlat

var page4_card_list: VBoxContainer = null


func _ready() -> void:
	visible = true
	layer = 100

	if root != null:
		root.visible = false
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.focus_mode = Control.FOCUS_ALL

	page_label.text = ""

	close_button.pressed.connect(_on_close_button_pressed)
	page_1_button.pressed.connect(_on_page_1_button_pressed)
	page_2_button.pressed.connect(_on_page_2_button_pressed)
	page_3_button.pressed.connect(_on_page_3_button_pressed)
	page_4_button.pressed.connect(_on_page_4_button_pressed)

	_build_fallback_styles()
	_apply_base_button_settings(page_1_button)
	_apply_base_button_settings(page_2_button)
	_apply_base_button_settings(page_3_button)
	_apply_base_button_settings(page_4_button)
	_apply_close_button_style()
	_apply_label_styles()
	_build_page_1_equipment_icons()
	_setup_page_4_quest_cards()

	set_page(0)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return

	if event.is_action_pressed("status") or event.is_action_pressed("ui_cancel"):
		close_ui()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left"):
		set_page(current_page - 1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_right"):
		set_page(current_page + 1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		scroll_current_page(-get_scroll_step())
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		scroll_current_page(get_scroll_step())
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_current_page(-get_wheel_scroll_step())
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_current_page(get_wheel_scroll_step())
			get_viewport().set_input_as_handled()
			return


func open_for_unit(unit_node) -> void:
	target_unit = unit_node
	refresh_view()
	set_page(current_page)

	if root != null:
		root.visible = true
		root.grab_focus()


func close_ui() -> void:
	if root != null:
		root.visible = false


func is_open() -> bool:
	if root == null:
		return false
	return root.visible


func refresh_view() -> void:
	if target_unit == null:
		page1_name_label.text = "名前: 対象なし"
		page1_combat_text.text = ""
		page1_basic_text.text = ""
		_clear_page_1_equipment_icons()
		page1_notes_text.text = ""
		portrait_texture.texture = null

		page_2_text.text = ""
		page_3_text.text = ""
		page_4_text.text = ""
		refresh_page_4_quest_cards()
		return

	var stats = target_unit.stats
	var skills = target_unit.skills

	refresh_page_1_layout(target_unit, stats)
	page_2_text.text = build_page_2_text(target_unit, skills)
	page_3_text.text = build_page_3_text(stats)
	page_4_text.text = ""
	refresh_page_4_quest_cards()

	reset_all_scrolls()
	update_text_min_heights()


func refresh_page_1_layout(unit_node, stats) -> void:
	if unit_node == null or stats == null:
		page1_name_label.text = "名前: 対象なし"
		page1_combat_text.text = ""
		page1_basic_text.text = ""
		_clear_page_1_equipment_icons()
		page1_notes_text.text = ""
		portrait_texture.texture = null
		return

	page1_name_label.text = "名前: %s" % String(unit_node.name)

	if "talk_portrait" in unit_node:
		portrait_texture.texture = unit_node.talk_portrait
	else:
		portrait_texture.texture = null

	page1_combat_text.text = build_page_1_combat_text(unit_node, stats)
	page1_basic_text.text = build_page_1_basic_text(unit_node, stats)
	refresh_page_1_equipment(unit_node)
	page1_notes_text.text = build_page_1_notes_text(unit_node)


func refresh_page_1_equipment(unit_node) -> void:
	if equipment_icon_nodes.is_empty():
		_build_page_1_equipment_icons()

	_clear_page_1_equipment_icons()

	if unit_node == null:
		return

	var slot_order: Array = [
		"right_hand", "left_hand", "head", "body", "hands", "waist", "feet",
		"accessory_1", "accessory_2", "accessory_3", "accessory_4"
	]

	if unit_node.has_method("get_equipment_slot_order"):
		slot_order = unit_node.get_equipment_slot_order()

	for raw_slot_name in slot_order:
		var slot_name: String = String(raw_slot_name)
		var icon_node: TextureRect = equipment_icon_nodes.get(slot_name)
		if icon_node == null:
			continue

		var resource = null
		if unit_node.has_method("get_equipped_resource"):
			resource = unit_node.get_equipped_resource(slot_name)
		elif slot_name == "right_hand" and "equipped_weapon" in unit_node:
			resource = unit_node.equipped_weapon
		elif slot_name == "body" and "equipped_armor" in unit_node:
			resource = unit_node.equipped_armor
		elif slot_name == "accessory_1" and "equipped_accessory" in unit_node:
			resource = unit_node.equipped_accessory

		icon_node.texture = get_equipment_icon(resource)


func _build_page_1_equipment_icons() -> void:
	equipment_icon_nodes.clear()

	if equipment_row == null:
		return

	for child in equipment_row.get_children():
		equipment_row.remove_child(child)
		child.queue_free()

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	equipment_row.add_child(row)

	var slot_order: Array[String] = [
		"right_hand", "left_hand", "head", "body", "hands", "waist", "feet",
		"accessory_1", "accessory_2", "accessory_3", "accessory_4"
	]

	for slot_name in slot_order:
		var panel: Panel = Panel.new()
		panel.custom_minimum_size = Vector2(64, 64)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		var black_bg: ColorRect = ColorRect.new()
		black_bg.anchor_right = 1.0
		black_bg.anchor_bottom = 1.0
		black_bg.offset_left = 1.0
		black_bg.offset_top = 1.0
		black_bg.offset_right = -1.0
		black_bg.offset_bottom = -1.0
		black_bg.color = Color(0.0, 0.0, 0.0, 1.0)

		var icon: TextureRect = TextureRect.new()
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 1.0
		icon.offset_top = 1.0
		icon.offset_right = -1.0
		icon.offset_bottom = -1.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		panel.add_child(black_bg)
		panel.add_child(icon)
		row.add_child(panel)

		equipment_icon_nodes[slot_name] = icon


func _clear_page_1_equipment_icons() -> void:
	if equipment_icon_nodes.is_empty():
		_build_page_1_equipment_icons()

	for icon_node in equipment_icon_nodes.values():
		if icon_node is TextureRect:
			icon_node.texture = null


func _get_equipment_slot_short_label(slot_name: String) -> String:
	match slot_name:
		"right_hand":
			return "右"
		"left_hand":
			return "左"
		"head":
			return "頭"
		"body":
			return "胴"
		"hands":
			return "手"
		"waist":
			return "腰"
		"feet":
			return "足"
		"accessory_1":
			return "飾1"
		"accessory_2":
			return "飾2"
		"accessory_3":
			return "飾3"
		"accessory_4":
			return "飾4"
		_:
			return slot_name


func set_page(page_index: int) -> void:
	current_page = clamp(page_index, 0, PAGE_COUNT - 1)

	page_1_scroll.visible = current_page == 0
	page_2_scroll.visible = current_page == 1
	page_3_scroll.visible = current_page == 2
	page_4_scroll.visible = current_page == 3

	page_label.text = ""

	update_tab_visuals()
	update_background_for_page()


func update_tab_visuals() -> void:
	_apply_tab_state(page_1_button, current_page == 0, page_1_button_texture)
	_apply_tab_state(page_2_button, current_page == 1, page_2_button_texture)
	_apply_tab_state(page_3_button, current_page == 2, page_3_button_texture)
	_apply_tab_state(page_4_button, current_page == 3, page_4_button_texture)


func update_background_for_page() -> void:
	if background_texture != null:
		background_texture.texture = default_background
		background_texture.visible = default_background != null

	if page_background_texture == null:
		return

	var tex: Texture2D = null

	match current_page:
		0:
			tex = page_1_background
		1:
			tex = page_2_background
		2:
			tex = page_3_background
		3:
			tex = page_4_background

	page_background_texture.texture = tex
	page_background_texture.visible = tex != null


func get_current_scroll_container() -> ScrollContainer:
	match current_page:
		0:
			return page_1_scroll
		1:
			return page_2_scroll
		2:
			return page_3_scroll
		3:
			return page_4_scroll
	return page_1_scroll


func get_scroll_step() -> int:
	var scroll: ScrollContainer = get_current_scroll_container()
	if scroll == null:
		return 48

	var viewport_height: float = scroll.size.y
	if viewport_height <= 0.0:
		return 48

	return max(int(viewport_height * 0.12), 24)


func get_wheel_scroll_step() -> int:
	var scroll: ScrollContainer = get_current_scroll_container()
	if scroll == null:
		return 72

	var viewport_height: float = scroll.size.y
	if viewport_height <= 0.0:
		return 72

	return max(int(viewport_height * 0.18), 36)


func scroll_current_page(amount: int) -> void:
	var scroll: ScrollContainer = get_current_scroll_container()
	if scroll == null:
		return

	var new_value: int = scroll.scroll_vertical + amount
	scroll.scroll_vertical = max(new_value, 0)


func reset_all_scrolls() -> void:
	if page_1_scroll != null:
		page_1_scroll.scroll_vertical = 0
	if page_2_scroll != null:
		page_2_scroll.scroll_vertical = 0
	if page_3_scroll != null:
		page_3_scroll.scroll_vertical = 0
	if page_4_scroll != null:
		page_4_scroll.scroll_vertical = 0


func update_text_min_heights() -> void:
	await get_tree().process_frame

	_update_rich_text_min_height(page1_combat_text)
	_update_rich_text_min_height(page1_basic_text)
	_update_rich_text_min_height(page1_notes_text)

	_update_one_text_min_height(page_2_text, page_2_scroll)
	_update_one_text_min_height(page_3_text, page_3_scroll)

	if page4_card_list != null:
		page4_card_list.custom_minimum_size = Vector2(0, max(page4_card_list.size.y, page_4_scroll.size.y))


func _update_rich_text_min_height(text_label: RichTextLabel) -> void:
	if text_label == null:
		return

	var content_height: float = text_label.get_content_height()
	text_label.custom_minimum_size = Vector2(0, max(content_height + 4.0, 72.0))


func _update_one_text_min_height(text_label: RichTextLabel, scroll: ScrollContainer) -> void:
	if text_label == null or scroll == null:
		return

	var content_height: float = text_label.get_content_height()
	var viewport_height: float = scroll.size.y
	var target_height: float = max(content_height + 8.0, viewport_height)

	text_label.custom_minimum_size = Vector2(0, target_height)


func _build_fallback_styles() -> void:
	selected_tab_fallback_style = StyleBoxFlat.new()
	selected_tab_fallback_style.bg_color = Color(1.0, 0.92, 0.45, 1.0)
	selected_tab_fallback_style.border_color = Color(0.20, 0.18, 0.10, 1.0)
	selected_tab_fallback_style.border_width_left = 2
	selected_tab_fallback_style.border_width_top = 2
	selected_tab_fallback_style.border_width_right = 2
	selected_tab_fallback_style.border_width_bottom = 2

	unselected_tab_fallback_style = StyleBoxFlat.new()
	unselected_tab_fallback_style.bg_color = Color(0.72, 0.72, 0.76, 1.0)
	unselected_tab_fallback_style.border_color = Color(0.20, 0.20, 0.22, 1.0)
	unselected_tab_fallback_style.border_width_left = 2
	unselected_tab_fallback_style.border_width_top = 2
	unselected_tab_fallback_style.border_width_right = 2
	unselected_tab_fallback_style.border_width_bottom = 2

	close_button_fallback_style = StyleBoxFlat.new()
	close_button_fallback_style.bg_color = Color(0.87, 0.87, 0.90, 1.0)
	close_button_fallback_style.border_color = Color(0.20, 0.20, 0.22, 1.0)
	close_button_fallback_style.border_width_left = 2
	close_button_fallback_style.border_width_top = 2
	close_button_fallback_style.border_width_right = 2
	close_button_fallback_style.border_width_bottom = 2


func _apply_base_button_settings(button: Button) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.flat = false


func _apply_tab_state(button: Button, is_selected: bool, button_texture: Texture2D) -> void:
	if button == null:
		return

	button.disabled = false

	var style := _make_button_style(
		button_texture,
		selected_tab_fallback_style if is_selected else unselected_tab_fallback_style
	)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

	if is_selected:
		button.modulate = selected_button_modulate
		button.add_theme_color_override("font_color", Color(0.12, 0.10, 0.02, 1.0))
	else:
		button.modulate = unselected_button_modulate
		button.add_theme_color_override("font_color", Color(0.14, 0.14, 0.16, 1.0))


func _apply_close_button_style() -> void:
	if close_button == null:
		return

	close_button.focus_mode = Control.FOCUS_NONE
	close_button.modulate = close_button_modulate
	close_button.add_theme_color_override("font_color", Color(0.08, 0.08, 0.10, 1.0))

	var style = _make_button_style(close_button_texture, close_button_fallback_style)

	close_button.add_theme_stylebox_override("normal", style)
	close_button.add_theme_stylebox_override("hover", style)
	close_button.add_theme_stylebox_override("pressed", style)
	close_button.add_theme_stylebox_override("focus", style)


func _make_button_style(texture: Texture2D, fallback_style: StyleBoxFlat) -> StyleBox:
	if texture != null:
		var style_tex := StyleBoxTexture.new()
		style_tex.texture = texture
		style_tex.texture_margin_left = 0
		style_tex.texture_margin_top = 0
		style_tex.texture_margin_right = 0
		style_tex.texture_margin_bottom = 0
		style_tex.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		style_tex.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		return style_tex

	return fallback_style


func _apply_label_styles() -> void:
	page_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98, 1.0))


func _setup_page_4_quest_cards() -> void:
	if page_4_text != null:
		page_4_text.visible = false

	if page_4_content == null:
		return

	if page4_card_list != null and is_instance_valid(page4_card_list):
		return

	page4_card_list = VBoxContainer.new()
	page4_card_list.name = "Page4QuestCardList"
	page4_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page4_card_list.add_theme_constant_override("separation", 12)
	page4_card_list.position = Vector2.ZERO
	page4_card_list.custom_minimum_size = Vector2(0, 0)
	page_4_content.add_child(page4_card_list)


func refresh_page_4_quest_cards() -> void:
	_setup_page_4_quest_cards()

	if page4_card_list == null:
		return

	for child in page4_card_list.get_children():
		page4_card_list.remove_child(child)
		child.queue_free()

	if target_unit == null:
		var label := Label.new()
		label.text = "対象なし"
		page4_card_list.add_child(label)
		return

	if not ("is_player_unit" in target_unit and bool(target_unit.is_player_unit)):
		var label := Label.new()
		label.text = "プレイヤー以外は表示対象外です。"
		page4_card_list.add_child(label)
		return

	if QuestManager == null:
		var label := Label.new()
		label.text = "QuestManager が見つかりません。"
		page4_card_list.add_child(label)
		return

	var active_quests: Array = QuestManager.get_active_quest_list()
	if active_quests.is_empty():
		var label := Label.new()
		label.text = "受注中のクエストはありません。"
		label.custom_minimum_size = Vector2(0, 80)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page4_card_list.add_child(label)
		return

	for raw_data in active_quests:
		if typeof(raw_data) != TYPE_DICTIONARY:
			continue
		var card: Control = _create_active_quest_card(raw_data)
		page4_card_list.add_child(card)


func _create_active_quest_card(data: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 180)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.16, 0.13, 0.10, 0.95)
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_left = 10
	card_style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(top_row)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = data.get("giver_portrait", null)
	top_row.add_child(portrait)

	var text_area := VBoxContainer.new()
	text_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_area.add_theme_constant_override("separation", 6)
	top_row.add_child(text_area)

	var title_row := HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 12)
	text_area.add_child(title_row)

	var title_label := Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.text = String(data.get("title", "名称不明のクエスト"))
	title_row.add_child(title_label)

	var time_label := Label.new()
	time_label.custom_minimum_size = Vector2(240, 0)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.text = _build_active_quest_time_text(data)
	title_row.add_child(time_label)

	var abandon_button := Button.new()
	abandon_button.text = "×"
	abandon_button.custom_minimum_size = Vector2(40, 40)
	abandon_button.focus_mode = Control.FOCUS_NONE
	var abandon_style := StyleBoxFlat.new()
	abandon_style.bg_color = Color(0.38, 0.18, 0.18, 0.95)
	abandon_style.corner_radius_top_left = 8
	abandon_style.corner_radius_top_right = 8
	abandon_style.corner_radius_bottom_left = 8
	abandon_style.corner_radius_bottom_right = 8
	abandon_button.add_theme_stylebox_override("normal", abandon_style)
	abandon_button.add_theme_stylebox_override("hover", abandon_style)
	abandon_button.add_theme_stylebox_override("pressed", abandon_style)
	abandon_button.add_theme_stylebox_override("focus", abandon_style)
	abandon_button.pressed.connect(func() -> void:
		var quest_id: String = String(data.get("quest_id", ""))
		var result: Dictionary = QuestManager.abandon_quest(quest_id)
		if bool(result.get("success", false)):
			refresh_page_4_quest_cards()
	)
	title_row.add_child(abandon_button)

	var desc_label := Label.new()
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.text = String(data.get("description", ""))
	text_area.add_child(desc_label)

	var progress_label := Label.new()
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_label.add_theme_font_size_override("font_size", 18)
	progress_label.text = _build_active_quest_progress_text(data)
	text_area.add_child(progress_label)

	var bottom_row := HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_theme_constant_override("separation", 12)
	text_area.add_child(bottom_row)

	var reward_label := Label.new()
	reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label.add_theme_font_size_override("font_size", 18)
	reward_label.text = _build_active_quest_reward_text(data)
	bottom_row.add_child(reward_label)

	var state_label := Label.new()
	state_label.custom_minimum_size = Vector2(200, 0)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state_label.add_theme_font_size_override("font_size", 18)
	state_label.text = "進行中"
	bottom_row.add_child(state_label)

	return card


func _build_active_quest_progress_text(data: Dictionary) -> String:
	var objective_type: int = int(data.get("objective_type", 0))

	match objective_type:
		QuestData.ObjectiveType.DELIVER_ITEM:
			var item_id: String = String(data.get("objective_item_id", ""))
			var need_amount: int = int(data.get("objective_item_amount", 1))
			var current_amount: int = 0

			if target_unit != null and target_unit.has_node("Inventory"):
				var inv = target_unit.get_node("Inventory")
				if inv != null and inv.has_method("get_total_amount_ignore_instance"):
					current_amount = int(inv.get_total_amount_ignore_instance(item_id))

			return "必要: %s x%d    所持: %d / %d" % [
				get_item_display_name(item_id),
				need_amount,
				current_amount,
				need_amount
			]

	return ""


func _build_active_quest_time_text(data: Dictionary) -> String:
	var deadline_at: float = float(data.get("deadline_at", -1.0))
	if deadline_at <= 0.0:
		return "制限時間: なし"

	var remain: float = maxf(0.0, deadline_at - TimeManager.world_time_seconds)
	return "制限時間: %s" % QuestManager.format_seconds_to_limit_text(remain)


func _build_active_quest_reward_text(data: Dictionary) -> String:
	var reward_gold: int = int(data.get("reward_gold", 0))
	return "報酬: %s" % format_active_quest_reward_text(data, reward_gold)


func build_page_1_basic_text(unit_node, stats) -> String:
	var lines: PackedStringArray = []

	lines.append("筋力: %d" % _get_unit_total_stat(unit_node, &"strength", int(stats.strength)))
	lines.append("体力: %d" % _get_unit_total_stat(unit_node, &"vitality", int(stats.vitality)))
	lines.append("敏捷: %d" % _get_unit_total_stat(unit_node, &"agility", int(stats.agility)))
	lines.append("器用さ: %d" % _get_unit_total_stat(unit_node, &"dexterity", int(stats.dexterity)))
	lines.append("知力: %d" % _get_unit_total_stat(unit_node, &"intelligence", int(stats.intelligence)))
	lines.append("精神力: %d" % _get_unit_total_stat(unit_node, &"spirit", int(stats.spirit)))
	lines.append("感覚: %d" % _get_unit_total_stat(unit_node, &"sense", int(stats.sense)))
	lines.append("魅力: %d" % _get_unit_total_stat(unit_node, &"charm", int(stats.charm)))
	lines.append("運: %d" % _get_unit_total_stat(unit_node, &"luck", int(stats.luck)))

	return "\n".join(lines)


func build_page_1_combat_text(unit_node, stats) -> String:
	var lines: PackedStringArray = []

	if stats == null:
		lines.append("ステータスデータなし")
		return "\n".join(lines)

	var combat_stats: Dictionary = {}

	# 戦闘ステータス表示の入口は Unit 側に統一する。
	# Unit.get_total_combat_stats() は、基礎ステータス由来の値に
	# 装備・エンチャント・一時補正を反映した最終値を返す。
	if unit_node != null and unit_node.has_method("get_total_combat_stats"):
		combat_stats = unit_node.get_total_combat_stats()
	else:
		# Unit が取れない場合だけ Stats 側の派生値にフォールバックする。
		# stats.attack / stats.defense などの旧デバッグ値は最後の保険としてだけ使う。
		var fallback_max_hp: int = int(stats.max_hp)
		var fallback_attack: int = int(stats.attack)
		var fallback_defense: int = int(stats.defense)
		var fallback_speed: float = float(stats.speed)
		var fallback_accuracy: float = float(stats.accuracy)
		var fallback_evasion: float = float(stats.evasion)
		var fallback_crit_rate: float = float(stats.crit_rate)
		var fallback_crit_damage: float = float(stats.crit_damage)
		var fallback_luck: int = int(stats.luck)

		if stats.has_method("get_effective_max_hp"):
			fallback_max_hp = int(stats.get_effective_max_hp())

		if stats.has_method("get_effective_attack"):
			fallback_attack = int(round(stats.get_effective_attack()))

		if stats.has_method("get_effective_defense"):
			fallback_defense = int(round(stats.get_effective_defense()))

		if stats.has_method("get_effective_speed"):
			fallback_speed = float(stats.get_effective_speed())

		if stats.has_method("get_effective_accuracy"):
			fallback_accuracy = float(stats.get_effective_accuracy())

		if stats.has_method("get_effective_evasion"):
			fallback_evasion = float(stats.get_effective_evasion())

		if stats.has_method("get_effective_crit_rate"):
			fallback_crit_rate = float(stats.get_effective_crit_rate())

		if stats.has_method("get_effective_crit_damage"):
			fallback_crit_damage = float(stats.get_effective_crit_damage())

		if stats.has_method("get_effective_luck"):
			fallback_luck = int(stats.get_effective_luck())

		combat_stats = {
			"hp": int(stats.hp),
			"max_hp": fallback_max_hp,
			"attack": fallback_attack,
			"defense": fallback_defense,
			"speed": fallback_speed,
			"accuracy": fallback_accuracy,
			"evasion": fallback_evasion,
			"crit_rate": fallback_crit_rate,
			"crit_damage": fallback_crit_damage,
			"luck": fallback_luck,
			"element": String(stats.element)
		}

	lines.append("HP: %d / %d" % [int(combat_stats.get("hp", int(stats.hp))), int(combat_stats.get("max_hp", 1))])
	lines.append("攻撃力: %d" % int(combat_stats.get("attack", 0)))
	lines.append("防御力: %d" % int(combat_stats.get("defense", 0)))
	lines.append("速度: %.2f" % float(combat_stats.get("speed", 1.0)))
	lines.append("命中率: %d%%" % int(round(float(combat_stats.get("accuracy", 0.0)) * 100.0)))
	lines.append("回避率: %d%%" % int(round(float(combat_stats.get("evasion", 0.0)) * 100.0)))
	lines.append("クリティカル率: %d%%" % int(round(float(combat_stats.get("crit_rate", 0.0)) * 100.0)))
	lines.append("クリティカルダメージ: %.2f" % float(combat_stats.get("crit_damage", 1.5)))
	lines.append("運: %d" % int(combat_stats.get("luck", 0)))
	lines.append("属性: %s" % String(combat_stats.get("element", String(stats.element))))

	return "\n".join(lines)

func build_page_1_notes_text(unit_node) -> String:
	var lines: PackedStringArray = []

	lines.append("ロールプレイ用情報")
	lines.append("生年月日 / 年齢 / 身長 / 体重 / 経歴 など")

	if unit_node != null:
		if "talk_greeting_text" in unit_node:
			var greeting: String = String(unit_node.talk_greeting_text)
			if greeting != "":
				lines.append("")
				lines.append("ひとこと:")
				lines.append(greeting)

	return "\n".join(lines)


func build_page_2_text(unit_node, skills) -> String:
	var lines: PackedStringArray = []

	lines.append("名前: %s" % String(unit_node.name))
	lines.append("")
	lines.append("[スキル]")

	if skills == null:
		lines.append("スキルデータなし")
	else:
		lines.append("採取: %d" % int(skills.gathering))
		lines.append("調査: %d" % int(skills.investigation))
		lines.append("隠密: %d" % int(skills.stealth))
		lines.append("罠解除: %d" % int(skills.trap_disarm))
		lines.append("釣り: %d" % int(skills.fishing))
		lines.append("鑑定: %d" % int(skills.appraisal))
		lines.append("料理: %d" % int(skills.cooking))
		lines.append("修理: %d" % int(skills.repair))
		lines.append("鍛冶: %d" % int(skills.smithing))
		lines.append("錬金: %d" % int(skills.alchemy))
		lines.append("交渉: %d" % int(skills.negotiation))
		lines.append("話術: %d" % int(skills.speech))
		lines.append("医療: %d" % int(skills.medical))

	return "\n".join(lines)


func build_page_3_text(stats) -> String:
	var lines: PackedStringArray = []

	lines.append("[属性耐性]")
	if stats == null:
		lines.append("耐性データなし")
		return "\n".join(lines)

	if stats.element_resistances == null or stats.element_resistances.is_empty():
		lines.append("耐性データなし")
	else:
		var keys: Array = stats.element_resistances.keys()
		keys.sort()

		for key in keys:
			var rate = stats.element_resistances[key]
			var rate_text: String = "%.2f" % float(rate)
			lines.append("%s: %s" % [String(key), rate_text])

	lines.append("")
	lines.append("[今後追加予定]")
	lines.append("・状態異常耐性")
	lines.append("・特殊耐性")
	lines.append("・属性相性詳細")

	return "\n".join(lines)


func build_page_4_quest_text(unit_node) -> String:
	return ""


func format_active_quest_reward_text(data: Dictionary, reward_gold: int) -> String:
	var parts: Array[String] = []

	if reward_gold > 0:
		if ItemDatabase.exists("gold"):
			parts.append("gold x%d" % reward_gold)
		else:
			parts.append("%dG" % reward_gold)

	var reward_item_ids: Array = data.get("reward_item_ids", [])
	var reward_item_amounts: Array = data.get("reward_item_amounts", [])
	var count: int = min(reward_item_ids.size(), reward_item_amounts.size())

	for i in range(count):
		var item_id: String = String(reward_item_ids[i])
		var amount: int = int(reward_item_amounts[i])
		if item_id == "" or amount <= 0:
			continue
		parts.append("%s x%d" % [get_item_display_name(item_id), amount])

	if parts.is_empty():
		return "なし"

	return " / ".join(parts)


func _get_unit_total_stat(unit_node, stat_name: StringName, base_value: int) -> int:
	if unit_node == null:
		return base_value

	if unit_node.has_method("get_total_stat_value"):
		return int(unit_node.get_total_stat_value(stat_name, base_value))

	if unit_node.has_method("get_modified_stat_value"):
		return int(unit_node.get_modified_stat_value(stat_name, base_value))

	match String(stat_name):
		"luck":
			if unit_node.has_method("get_total_luck"):
				return int(unit_node.get_total_luck())
		"max_hp":
			if unit_node.has_method("get_total_max_hp"):
				return int(unit_node.get_total_max_hp())

	return base_value


func get_item_display_name(item_id: String) -> String:
	if item_id == "":
		return ""

	if not ItemDatabase.exists(item_id):
		return item_id

	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name == "":
		return item_id

	return display_name


func get_equipment_icon(equipment_resource) -> Texture2D:
	if equipment_resource == null:
		return null

	if "icon" in equipment_resource:
		var icon_tex: Texture2D = equipment_resource.icon
		if icon_tex != null:
			return icon_tex

	if "texture" in equipment_resource:
		var texture_tex: Texture2D = equipment_resource.texture
		if texture_tex != null:
			return texture_tex

	return null


func _on_close_button_pressed() -> void:
	close_ui()


func _on_page_1_button_pressed() -> void:
	set_page(0)
	if root != null:
		root.grab_focus()


func _on_page_2_button_pressed() -> void:
	set_page(1)
	if root != null:
		root.grab_focus()


func _on_page_3_button_pressed() -> void:
	set_page(2)
	if root != null:
		root.grab_focus()


func _on_page_4_button_pressed() -> void:
	set_page(3)
	refresh_page_4_quest_cards()
	if root != null:
		root.grab_focus()
