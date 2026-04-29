extends CanvasLayer

enum UIMode {
	NORMAL,
	TRADE,
	CHEST
}

# Godotのsize_flags_verticalで、子Controlを親Container内の上側に寄せる値。
# Control.SIZE_SHRINK_BEGIN の値差異/誤指定を避けるため、ここでは明示的に0を使う。
const SIZE_SHRINK_BEGIN_VALUE: int = 0

@onready var root = $Root
@onready var main_hbox = $Root/Overlay/CenterContainer/MainHBox

@onready var trade_panel = $Root/Overlay/CenterContainer/MainHBox/TradePanel
@onready var trade_margin = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer
@onready var trade_vbox = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer/TradeVBox
@onready var trade_title_label = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer/TradeVBox/TitleLabel
@onready var trade_slot_grid = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer/TradeVBox/SlotGrid
@onready var trade_back_button = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer/TradeVBox/BackButton

@onready var inventory_panel = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel
@onready var inventory_margin = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer
@onready var title_label = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/TitleRow/TitleLabel
@onready var close_button = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/TitleRow/CloseButton
@onready var slot_grid = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/SlotGrid
@onready var help_label: Label = get_node_or_null("Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/HelpLabel") as Label

@onready var equipment_panel = $Root/Overlay/CenterContainer/MainHBox/EquipmentPanel
@onready var equipment_margin = $Root/Overlay/CenterContainer/MainHBox/EquipmentPanel/MarginContainer
@onready var equipment_vbox = $Root/Overlay/CenterContainer/MainHBox/EquipmentPanel/MarginContainer/RightVBox/EquipmentVBox

@onready var inventory_bg = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/Background
@onready var equipment_bg = $Root/Overlay/CenterContainer/MainHBox/EquipmentPanel/Background
@onready var trade_bg = $Root/Overlay/CenterContainer/MainHBox/TradePanel/Background

@onready var tooltip_panel = $Root/Overlay/TooltipPanel
@onready var tooltip_name_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipNameLabel
@onready var tooltip_desc_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipDescLabel
@onready var tooltip_meta_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipMetaLabel

@onready var held_item_preview = $Root/Overlay/HeldItemPreview
@onready var held_item_icon = $Root/Overlay/HeldItemPreview/Icon
@onready var held_item_amount_label = $Root/Overlay/HeldItemPreview/AmountLabel

@export var slot_scene: PackedScene
@export var ui_config: InventoryUIConfig
@export var tooltip_delay: float = 0.5
@export var hold_repeat_initial_delay: float = 0.35
@export var hold_repeat_interval: float = 0.08
@export var allow_world_drop_from_inventory_ui: bool = true
@export var allow_world_drop_from_shop_trade_items: bool = false
@export var world_drop_search_radius: int = 5

# マウスで持ち上げたアイテムの表示。
# スロット位置ではなくマウスポインタに追従させる。
@export var held_item_preview_follow_mouse: bool = true
@export var held_item_preview_smooth_speed: float = 28.0
@export var held_item_preview_mouse_offset: Vector2 = Vector2.ZERO
@export var held_item_preview_center_on_mouse: bool = true
@export var held_item_preview_snap_to_mouse_center: bool = true
@export var held_item_preview_clamp_to_viewport: bool = true


# インベントリ/取引グリッドをコンパクト表示する設定。
# スロット間隔を0にし、Panelの固定最小サイズを使わず、スロット数に合わせて枠を縮める。
@export var compact_slot_grid_gap: int = 0
@export var compact_panel_margin: int = 4
@export var fit_inventory_panel_to_slots: bool = true
@export var fit_trade_panel_to_slots: bool = true

# 装備欄の見た目整理用。
# 装備スロットは装備構成が変わる可能性があるため、行自体はコードで生成する。
# ただし、パネルや×ボタンなど固定UIは tscn 側に置く。
@export var equipment_panel_margin: int = 4
@export var equipment_row_gap: int = 0
@export var equipment_column_gap: int = 2
@export var equipment_label_width: int = 58
@export var equipment_show_section_headers: bool = true
@export var equipment_show_slot_placeholder_text: bool = true
@export var equipment_slot_placeholder_font_size: int = 9
@export var equipment_slot_placeholder_color: Color = Color(0.85, 0.85, 0.85, 0.85)

# 装備スロット背景画像。
# Inspectorからスロットごとに設定できます。
# 画像が未設定のスロットは、空欄時に「右手」「胴」などのプレースホルダー文字を表示します。
@export_group("Equipment Slot Backgrounds")
@export var equipment_slot_background_right_hand: Texture2D
@export var equipment_slot_background_left_hand: Texture2D
@export var equipment_slot_background_head: Texture2D
@export var equipment_slot_background_body: Texture2D
@export var equipment_slot_background_hands: Texture2D
@export var equipment_slot_background_waist: Texture2D
@export var equipment_slot_background_feet: Texture2D
@export var equipment_slot_background_accessory_1: Texture2D
@export var equipment_slot_background_accessory_2: Texture2D
@export var equipment_slot_background_accessory_3: Texture2D
@export var equipment_slot_background_accessory_4: Texture2D
@export_group("")


var current_inventory = null
var current_unit = null

var trade_inventory = null
var trade_unit = null
var ui_mode: int = UIMode.NORMAL

var focus_area: String = "inventory"
var selected_index: int = 0

var held_entry: Dictionary = {}
var held_from_area: String = ""
var held_from_index: int = -1
var held_from_slot_name: String = ""

var tooltip_timer = null
var is_building_slots: bool = false

var equipment_slot_order: Array = ["right_hand", "left_hand", "head", "body", "hands", "waist", "feet", "accessory_1", "accessory_2", "accessory_3", "accessory_4"]
var equipment_slot_nodes: Array = []

var trade_session_buy_rate: float = 1.0
var trade_session_sell_rate: float = 1.0
var trade_session_active: bool = false

var hold_repeat_action: StringName = &""
var hold_repeat_is_pressed: bool = false
var hold_repeat_delay_remaining: float = 0.0
var hold_repeat_interval_remaining: float = 0.0
var hold_repeat_secondary_mode: StringName = &""

# マウスでスロット操作している間は、キーボード用のゲーム内カーソル
# （選択枠/押下表示）を非表示にする。
# キーボード操作が入ったら false に戻して選択枠を復活させる。
var mouse_navigation_mode: bool = false

# Inventory 本体が持つホットバー収納領域を、インベントリ画面にも表示する。
# hotbar_items は通常インベントリ items とは別配列。
var hotbar_panel: PanelContainer = null
var hotbar_slot_grid: GridContainer = null
var hotbar_title_label: Label = null

var held_item_preview_position_initialized: bool = false
var held_item_preview_target_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 10
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()

	title_label.text = "Inventory"
	trade_title_label.text = "Trade"

	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = tooltip_delay
	add_child(tooltip_timer)
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

	if trade_back_button != null:
		# TradePanel の高さをスロット枠に合わせるため、旧「戻る」ボタンは表示しない。
		# インベントリ全体の閉じる操作は右上の CloseButton を使う。
		trade_back_button.visible = false
		trade_back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trade_back_button.toggle_mode = true
		trade_back_button.focus_mode = Control.FOCUS_NONE
		if not trade_back_button.pressed.is_connected(_on_trade_back_button_pressed):
			trade_back_button.pressed.connect(_on_trade_back_button_pressed)

	tooltip_panel.hide()
	held_item_preview.hide()
	ensure_mouse_passthrough_for_float_panels()
	setup_inventory_overlay_mouse_passthrough()
	setup_world_drop_frame_input()
	setup_close_button()
	ensure_hotbar_ui_nodes()
	apply_compact_inventory_layout()

	apply_ui_config()
	apply_side_panel_visuals_for_mode()
	update_background_visibility()
	update_trade_panel_visibility()
	set_process(true)


func is_failed_quest_dialog_locked() -> bool:
	if DialogueManager == null:
		return false

	if DialogueManager.has_method("is_input_locked_by_failed_quest_dialog"):
		return DialogueManager.is_input_locked_by_failed_quest_dialog()

	return false


func ensure_mouse_passthrough_for_float_panels() -> void:
	# HeldItemPreview / tooltip are visual overlays only.
	# If they receive mouse input, they cover the slot under the cursor and
	# left-click placement will not reach the slot.
	set_control_tree_mouse_filter_ignore(held_item_preview)
	set_control_tree_mouse_filter_ignore(tooltip_panel)


func set_control_tree_mouse_filter_ignore(node: Node) -> void:
	if node == null:
		return

	if node is Control:
		var control: Control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		set_control_tree_mouse_filter_ignore(child)



func setup_inventory_overlay_mouse_passthrough() -> void:
	# InventoryUI は CanvasLayer 全体を覆うため、背景側Controlがマウス入力を止めると
	# 下にある通常HUDホットバーをクリックできない。
	# そのため、全画面の背景/中央寄せ用ノードは入力を透過し、
	# 実際のInventory/Trade/Equipmentパネルだけが入力を受けるようにする。
	var pass_nodes: Array[Node] = [
		root,
		get_node_or_null("Root/Overlay"),
		get_node_or_null("Root/Overlay/CenterContainer"),
		main_hbox
	]

	for node in pass_nodes:
		if node is Control:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stop_nodes: Array[Node] = [
		inventory_panel,
		trade_panel,
		equipment_panel,
		tooltip_panel,
		held_item_preview
	]

	for node in stop_nodes:
		if node is Control:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_STOP


func setup_world_drop_frame_input() -> void:
	# スロット・ホットバー・装備欄など「置ける枠」以外の、
	# Inventory/Trade/Equipment パネル本体にもドロップ判定を持たせる。
	# これにより、枠部分までマウスで持ち上げたアイテムを表示しながら、
	# 左クリックでワールドへ捨てられる。
	var nodes: Array[Node] = [
		inventory_panel,
		inventory_margin,
		equipment_panel,
		equipment_margin,
		trade_panel,
		trade_margin,
		inventory_bg,
		equipment_bg,
		trade_bg
	]

	for node in nodes:
		if not (node is Control):
			continue

		var control: Control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_STOP

		var callable: Callable = Callable(self, "_on_world_drop_frame_gui_input")
		if not control.gui_input.is_connected(callable):
			control.gui_input.connect(callable)


func _on_world_drop_frame_gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if held_entry.is_empty():
		return

	if is_failed_quest_dialog_locked():
		return

	if not (event is InputEventMouseButton):
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return

	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if try_drop_held_entry_to_world():
			get_viewport().set_input_as_handled()
		return

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if try_drop_held_entry_one_to_world():
			get_viewport().set_input_as_handled()
		return


func apply_transparent_panel_style(panel: PanelContainer) -> void:
	if panel == null:
		return

	var clear_style: StyleBoxFlat = StyleBoxFlat.new()
	clear_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	clear_style.border_width_left = 0
	clear_style.border_width_top = 0
	clear_style.border_width_right = 0
	clear_style.border_width_bottom = 0
	panel.add_theme_stylebox_override("panel", clear_style)


func ensure_hotbar_ui_nodes() -> void:
	if not show_hotbar_panel_in_inventory():
		var existing_panel: Node = get_node_or_null("Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/HotbarPanel")
		if existing_panel is Control:
			(existing_panel as Control).visible = false
		hotbar_panel = null
		hotbar_slot_grid = null
		hotbar_title_label = null
		return

	if hotbar_panel != null and is_instance_valid(hotbar_panel):
		return

	if slot_grid == null:
		return

	var left_vbox: Node = slot_grid.get_parent()
	if left_vbox == null:
		return

	var existing_panel: Node = left_vbox.get_node_or_null("HotbarPanel")
	if existing_panel is PanelContainer:
		hotbar_panel = existing_panel as PanelContainer
		hotbar_slot_grid = hotbar_panel.get_node_or_null("MarginContainer/VBoxContainer/HotbarSlotGrid") as GridContainer
		hotbar_title_label = hotbar_panel.get_node_or_null("MarginContainer/VBoxContainer/HotbarTitleLabel") as Label
		apply_transparent_panel_style(hotbar_panel)
		if hotbar_slot_grid != null:
			hotbar_slot_grid.add_theme_constant_override("h_separation", 0)
			hotbar_slot_grid.add_theme_constant_override("v_separation", 0)
		return

	hotbar_panel = PanelContainer.new()
	hotbar_panel.name = "HotbarPanel"
	hotbar_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hotbar_panel.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE
	apply_transparent_panel_style(hotbar_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", compact_panel_margin)
	margin.add_theme_constant_override("margin_top", compact_panel_margin)
	margin.add_theme_constant_override("margin_right", compact_panel_margin)
	margin.add_theme_constant_override("margin_bottom", compact_panel_margin)
	margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	margin.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE
	hotbar_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE
	margin.add_child(vbox)

	hotbar_title_label = Label.new()
	hotbar_title_label.name = "HotbarTitleLabel"
	hotbar_title_label.text = "ホットバー"
	hotbar_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hotbar_title_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hotbar_title_label)

	hotbar_slot_grid = GridContainer.new()
	hotbar_slot_grid.name = "HotbarSlotGrid"
	hotbar_slot_grid.columns = get_hotbar_slot_columns()
	hotbar_slot_grid.add_theme_constant_override("h_separation", 0)
	hotbar_slot_grid.add_theme_constant_override("v_separation", 0)
	hotbar_slot_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hotbar_slot_grid.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE
	vbox.add_child(hotbar_slot_grid)

	left_vbox.add_child(hotbar_panel)

	# 通常インベントリグリッドの直前に置く。
	left_vbox.move_child(hotbar_panel, slot_grid.get_index())


func show_hotbar_panel_in_inventory() -> bool:
	# インベントリ画面内に専用ホットバー欄は表示しない。
	# ホットバーは通常時に表示されているHUD側のホットバーを直接操作する。
	return false


func setup_close_button() -> void:
	if close_button == null:
		return

	close_button.text = "×"
	close_button.tooltip_text = "閉じる"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.custom_minimum_size = Vector2(22, 22)
	close_button.add_theme_font_size_override("font_size", 13)
	close_button.add_theme_constant_override("h_separation", 0)

	if not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)


func _on_close_button_pressed() -> void:
	close_inventory()


func apply_ui_config() -> void:
	if ui_config == null:
		return

	# スロット総数・列数・段数は Inventory.gd 側の slot_columns / slot_rows を本体にする。
	# InventoryUI 側では inventory_max_slots で実データ数を変更しない。

	if fit_inventory_panel_to_slots:
		inventory_panel.custom_minimum_size = Vector2.ZERO
	elif ui_config.inventory_panel_size != Vector2.ZERO:
		inventory_panel.custom_minimum_size = ui_config.inventory_panel_size

	if ui_config.equipment_panel_size != Vector2.ZERO:
		equipment_panel.custom_minimum_size = ui_config.equipment_panel_size

	sync_slot_grid_columns_from_inventories()

	if ui_config.main_hbox_separation >= 0:
		main_hbox.add_theme_constant_override("separation", ui_config.main_hbox_separation)

	if ui_config.inventory_margin_left >= 0:
		inventory_margin.add_theme_constant_override("margin_left", ui_config.inventory_margin_left)
		trade_margin.add_theme_constant_override("margin_left", ui_config.inventory_margin_left)
	if ui_config.inventory_margin_top >= 0:
		inventory_margin.add_theme_constant_override("margin_top", ui_config.inventory_margin_top)
		trade_margin.add_theme_constant_override("margin_top", ui_config.inventory_margin_top)
	if ui_config.inventory_margin_right >= 0:
		inventory_margin.add_theme_constant_override("margin_right", ui_config.inventory_margin_right)
		trade_margin.add_theme_constant_override("margin_right", ui_config.inventory_margin_right)
	if ui_config.inventory_margin_bottom >= 0:
		inventory_margin.add_theme_constant_override("margin_bottom", ui_config.inventory_margin_bottom)
		trade_margin.add_theme_constant_override("margin_bottom", ui_config.inventory_margin_bottom)

	if ui_config.equipment_margin_left >= 0:
		equipment_margin.add_theme_constant_override("margin_left", ui_config.equipment_margin_left)
	if ui_config.equipment_margin_top >= 0:
		equipment_margin.add_theme_constant_override("margin_top", ui_config.equipment_margin_top)
	if ui_config.equipment_margin_right >= 0:
		equipment_margin.add_theme_constant_override("margin_right", ui_config.equipment_margin_right)
	if ui_config.equipment_margin_bottom >= 0:
		equipment_margin.add_theme_constant_override("margin_bottom", ui_config.equipment_margin_bottom)

	apply_compact_inventory_layout()

	if inventory_bg != null and ui_config.inventory_background != null:
		inventory_bg.texture = ui_config.inventory_background
	if trade_bg != null and ui_config.inventory_background != null:
		trade_bg.texture = ui_config.inventory_background
	if equipment_bg != null and ui_config.equipment_background != null:
		equipment_bg.texture = ui_config.equipment_background


func apply_compact_inventory_layout() -> void:
	var grid_gap: int = max(0, compact_slot_grid_gap)
	var frame_margin: int = max(0, compact_panel_margin)

	if slot_grid != null:
		slot_grid.add_theme_constant_override("h_separation", grid_gap)
		slot_grid.add_theme_constant_override("v_separation", grid_gap)
		slot_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		slot_grid.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE

	if trade_vbox != null:
		# TradePanel も InventoryPanel と同じく、タイトル + スロットグリッドの高さに寄せる。
		trade_vbox.add_theme_constant_override("separation", 4)
		trade_vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		trade_vbox.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE

	if trade_slot_grid != null:
		trade_slot_grid.add_theme_constant_override("h_separation", grid_gap)
		trade_slot_grid.add_theme_constant_override("v_separation", grid_gap)
		trade_slot_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		trade_slot_grid.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE

	if hotbar_slot_grid != null:
		hotbar_slot_grid.add_theme_constant_override("h_separation", 0)
		hotbar_slot_grid.add_theme_constant_override("v_separation", 0)
		hotbar_slot_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		hotbar_slot_grid.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE

	if hotbar_panel != null:
		hotbar_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		hotbar_panel.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE
		apply_transparent_panel_style(hotbar_panel)

	if fit_inventory_panel_to_slots and inventory_panel != null:
		inventory_panel.custom_minimum_size = Vector2.ZERO

	if trade_panel != null:
		# HBoxContainer内で、装備欄や画面高さに合わせて縦に引き伸ばされないようにする。
		trade_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		trade_panel.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE
		if fit_trade_panel_to_slots:
			trade_panel.custom_minimum_size = Vector2.ZERO

	if inventory_margin != null:
		inventory_margin.add_theme_constant_override("margin_left", frame_margin)
		inventory_margin.add_theme_constant_override("margin_top", frame_margin)
		inventory_margin.add_theme_constant_override("margin_right", frame_margin)
		inventory_margin.add_theme_constant_override("margin_bottom", frame_margin)

	if trade_margin != null:
		trade_margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		trade_margin.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE
		trade_margin.add_theme_constant_override("margin_left", frame_margin)
		trade_margin.add_theme_constant_override("margin_top", frame_margin)
		trade_margin.add_theme_constant_override("margin_right", frame_margin)
		trade_margin.add_theme_constant_override("margin_bottom", frame_margin)

	if equipment_margin != null:
		var eq_margin: int = max(0, equipment_panel_margin)
		equipment_margin.add_theme_constant_override("margin_left", eq_margin)
		equipment_margin.add_theme_constant_override("margin_top", eq_margin)
		equipment_margin.add_theme_constant_override("margin_right", eq_margin)
		equipment_margin.add_theme_constant_override("margin_bottom", eq_margin)

	if equipment_panel != null:
		equipment_panel.custom_minimum_size = Vector2.ZERO

	if equipment_vbox != null:
		equipment_vbox.add_theme_constant_override("separation", max(0, equipment_row_gap))

	# CloseButton を TitleRow の右端に押し出すため、タイトルは横方向に広げる。
	if title_label != null:
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	apply_top_aligned_inventory_panels()


func force_trade_panel_fit_to_slots() -> void:
	if trade_panel == null:
		return

	apply_top_aligned_inventory_panels()

	trade_panel.custom_minimum_size = Vector2.ZERO

	# Containerの最小サイズ計算を更新する。
	trade_panel.update_minimum_size()
	if inventory_panel != null:
		inventory_panel.update_minimum_size()
	if equipment_panel != null:
		equipment_panel.update_minimum_size()


func apply_top_aligned_inventory_panels() -> void:
	# トレード画面では Merchant 側と Player 側のインベントリ枠の上端を揃える。
	# HBoxContainer 内で size_flags_vertical が SHRINK_CENTER になると、
	# Player 側だけ中央寄せになって上下位置がズレるため、明示的に上寄せに固定する。
	if main_hbox != null:
		main_hbox.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE

	var top_aligned_controls: Array = [
		trade_panel,
		trade_margin,
		trade_vbox,
		trade_slot_grid,
		inventory_panel,
		inventory_margin,
		slot_grid,
		equipment_panel,
		equipment_margin,
		equipment_vbox
	]

	for control in top_aligned_controls:
		if control == null:
			continue
		if control is Control:
			control.size_flags_vertical = SIZE_SHRINK_BEGIN_VALUE


func get_inventory_slot_visual_size() -> Vector2:
	if ui_config != null and ui_config.inventory_slot_size != Vector2.ZERO:
		return ui_config.inventory_slot_size

	return Vector2(48, 48)


func get_inventory_grid_pixel_width() -> float:
	var columns: int = get_inventory_slot_columns()

	var slot_size: Vector2 = get_inventory_slot_visual_size()
	var gap: int = max(0, compact_slot_grid_gap)
	return slot_size.x * float(columns) + float(gap * max(columns - 1, 0))


func get_chest_ui_data() -> ChestData:
	if ui_mode != UIMode.CHEST:
		return null

	if trade_unit == null:
		return null

	if "chest_data" in trade_unit:
		return trade_unit.chest_data

	return null


func apply_side_panel_visuals_for_mode() -> void:
	sync_slot_grid_columns_from_inventories()

	if ui_mode == UIMode.CHEST:
		var chest_data: ChestData = get_chest_ui_data()

		if chest_data != null:
			# スロット列数は基本的に chest_inventory.get_slot_columns() を優先。
			# 旧ChestDataの表示列数は、Inventory側に列情報がない時の保険としてだけ使う。
			if trade_inventory == null or not trade_inventory.has_method("get_slot_columns"):
				if trade_slot_grid != null and chest_data.ui_slot_columns > 0:
					trade_slot_grid.columns = chest_data.ui_slot_columns

			if trade_panel != null:
				if fit_trade_panel_to_slots:
					trade_panel.custom_minimum_size = Vector2.ZERO
				elif chest_data.ui_panel_min_size != Vector2.ZERO:
					trade_panel.custom_minimum_size = chest_data.ui_panel_min_size

			if trade_bg != null and chest_data.ui_background != null:
				trade_bg.texture = chest_data.ui_background
		else:
			if ui_config != null:
				if trade_panel != null:
					if fit_trade_panel_to_slots:
						trade_panel.custom_minimum_size = Vector2.ZERO
					elif ui_config.inventory_panel_size != Vector2.ZERO:
						trade_panel.custom_minimum_size = ui_config.inventory_panel_size
				if trade_bg != null and ui_config.inventory_background != null:
					trade_bg.texture = ui_config.inventory_background
	else:
		if ui_config != null:
			if trade_panel != null:
				if fit_trade_panel_to_slots:
					trade_panel.custom_minimum_size = Vector2.ZERO
				elif ui_config.inventory_panel_size != Vector2.ZERO:
					trade_panel.custom_minimum_size = ui_config.inventory_panel_size

			if trade_bg != null and ui_config.inventory_background != null:
				trade_bg.texture = ui_config.inventory_background


func get_trade_slot_visual_size() -> Vector2:
	if ui_mode == UIMode.CHEST:
		var chest_data: ChestData = get_chest_ui_data()
		if chest_data != null and chest_data.ui_slot_size != Vector2.ZERO:
			return chest_data.ui_slot_size

	if ui_config != null and ui_config.inventory_slot_size != Vector2.ZERO:
		return ui_config.inventory_slot_size

	return Vector2(48, 48)


func update_background_visibility() -> void:
	if inventory_bg != null:
		inventory_bg.visible = inventory_bg.texture != null
	if trade_bg != null:
		trade_bg.visible = trade_bg.texture != null
	if equipment_bg != null:
		equipment_bg.visible = equipment_bg.texture != null


func update_trade_panel_visibility() -> void:
	var side_visible: bool = is_side_mode()

	if trade_panel != null:
		trade_panel.visible = side_visible
		if side_visible:
			force_trade_panel_fit_to_slots()

	if trade_back_button != null:
		# 高さ合わせのため、TradePanel 内の戻るボタンは常に非表示。
		trade_back_button.visible = false
		trade_back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func begin_trade_session() -> void:
	trade_session_active = true
	trade_session_buy_rate = TradePriceCalculator.get_trade_buy_rate_snapshot(current_unit, trade_unit)
	trade_session_sell_rate = TradePriceCalculator.get_trade_sell_rate_snapshot(current_unit, trade_unit)


func end_trade_session() -> void:
	trade_session_active = false
	trade_session_buy_rate = 1.0
	trade_session_sell_rate = 1.0


func is_side_mode() -> bool:
	return ui_mode == UIMode.TRADE or ui_mode == UIMode.CHEST


func is_game_cursor_visible() -> bool:
	return not mouse_navigation_mode


func enter_mouse_navigation_mode() -> void:
	if mouse_navigation_mode:
		return

	mouse_navigation_mode = true
	refresh()


func restore_game_cursor_from_keyboard() -> void:
	if not mouse_navigation_mode:
		return

	mouse_navigation_mode = false
	refresh()
	restart_tooltip_timer()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if is_failed_quest_dialog_locked():
		stop_hold_repeat()
		hide_tooltip()
		return

	if event.is_action_pressed("ui_cancel"):
		restore_game_cursor_from_keyboard()
		close_inventory()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_right"):
		restore_game_cursor_from_keyboard()
		move_selection(1, 0)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left"):
		restore_game_cursor_from_keyboard()
		move_selection(-1, 0)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		restore_game_cursor_from_keyboard()
		move_selection(0, 1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		restore_game_cursor_from_keyboard()
		move_selection(0, -1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_quick_move_primary"):
		restore_game_cursor_from_keyboard()
		handle_quick_move_primary_action()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_quick_move_secondary"):
		restore_game_cursor_from_keyboard()
		handle_quick_move_secondary_action()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_secondary_action"):
		restore_game_cursor_from_keyboard()
		if held_entry.is_empty():
			handle_split_pick_action()
			stop_hold_repeat()
		else:
			handle_put_one_action()
			if held_entry.is_empty():
				stop_hold_repeat()
			else:
				start_hold_repeat(&"inventory_secondary_action", &"put_one")
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("inventory_secondary_action"):
		if hold_repeat_action == &"inventory_secondary_action":
			stop_hold_repeat()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("inventory_primary_action"):
		restore_game_cursor_from_keyboard()
		handle_confirm_action()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_use"):
		restore_game_cursor_from_keyboard()
		use_selected_item()
		get_viewport().set_input_as_handled()
		return



func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if held_entry.is_empty():
		return

	if is_failed_quest_dialog_locked():
		return

	if not (event is InputEventMouseButton):
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return

	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if try_drop_held_entry_to_world():
			get_viewport().set_input_as_handled()
		return

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if try_drop_held_entry_one_to_world():
			get_viewport().set_input_as_handled()
		return


func try_drop_held_entry_one_to_world() -> bool:
	return try_drop_partial_held_entry_to_world(1)


func try_drop_partial_held_entry_to_world(drop_amount: int) -> bool:
	if held_entry.is_empty():
		return false

	if drop_amount <= 0:
		return false

	if not allow_world_drop_from_inventory_ui:
		return false

	# ショップの相手側アイテムは、支払い前に外へ捨てられると破綻するので禁止。
	# チェストモードの trade 側は「箱の中身」なので許可する。
	if ui_mode == UIMode.TRADE and held_from_area == "trade" and not allow_world_drop_from_shop_trade_items:
		notify_message("売買中の相手側アイテムはその場に捨てられない")
		return true

	if current_unit == null:
		notify_message("捨てる対象のUnitが見つからない")
		return true

	var held_amount: int = int(held_entry.get("amount", 0))
	if held_amount <= 0:
		return false

	var actual_drop_amount: int = min(drop_amount, held_amount)
	var dropped_entry: Dictionary = held_entry.duplicate(true)
	dropped_entry["amount"] = actual_drop_amount

	if not ItemDropHelper.drop_entry_near_unit(dropped_entry, current_unit, world_drop_search_radius):
		notify_message("ここには捨てられない")
		return true

	var item_id: String = String(dropped_entry.get("item_id", ""))
	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name == "":
		display_name = item_id

	if actual_drop_amount > 1:
		notify_message("%s x%d を捨てた" % [display_name, actual_drop_amount])
	else:
		notify_message("%s を1個捨てた" % display_name)

	consume_held_amount(actual_drop_amount)
	update_held_item_preview()
	hide_tooltip()
	refresh()
	refresh_status_ui()
	return true


func try_drop_held_entry_to_world() -> bool:
	if held_entry.is_empty():
		return false

	if not allow_world_drop_from_inventory_ui:
		return false

	# ショップの相手側アイテムは、支払い前に外へ捨てられると破綻するので禁止。
	# チェストモードの trade 側は「箱の中身」なので許可する。
	if ui_mode == UIMode.TRADE and held_from_area == "trade" and not allow_world_drop_from_shop_trade_items:
		notify_message("売買中の相手側アイテムはその場に捨てられない")
		return true

	if current_unit == null:
		notify_message("捨てる対象のUnitが見つからない")
		return true

	var dropped_entry: Dictionary = held_entry.duplicate(true)
	if not ItemDropHelper.drop_entry_near_unit(dropped_entry, current_unit, world_drop_search_radius):
		notify_message("ここには捨てられない")
		return true

	var item_id: String = String(dropped_entry.get("item_id", ""))
	var amount: int = int(dropped_entry.get("amount", 0))
	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name == "":
		display_name = item_id

	if amount > 1:
		notify_message("%s x%d を捨てた" % [display_name, amount])
	else:
		notify_message("%s を捨てた" % display_name)

	clear_held_state()
	update_held_item_preview()
	hide_tooltip()
	refresh()
	refresh_status_ui()
	return true
func _process(delta: float) -> void:
	if is_failed_quest_dialog_locked():
		stop_hold_repeat()
		hide_tooltip()
		held_item_preview.hide()
		return

	if visible:
		refresh()
		update_held_item_preview_motion(delta)

	if hold_repeat_action == &"":
		return

	if not visible:
		stop_hold_repeat()
		return

	if not hold_repeat_is_pressed:
		stop_hold_repeat()
		return

	if hold_repeat_delay_remaining > 0.0:
		hold_repeat_delay_remaining -= delta
		if hold_repeat_delay_remaining > 0.0:
			return
		hold_repeat_interval_remaining = 0.0

	hold_repeat_interval_remaining -= delta
	while hold_repeat_interval_remaining <= 0.0:
		perform_hold_repeat_action()
		hold_repeat_interval_remaining += max(hold_repeat_interval, 0.01)


func start_hold_repeat(action_name: StringName, secondary_mode: StringName = &"") -> void:
	hold_repeat_action = action_name
	hold_repeat_secondary_mode = secondary_mode
	hold_repeat_is_pressed = true
	hold_repeat_delay_remaining = max(hold_repeat_initial_delay, 0.0)
	hold_repeat_interval_remaining = max(hold_repeat_interval, 0.01)


func stop_hold_repeat() -> void:
	hold_repeat_action = &""
	hold_repeat_secondary_mode = &""
	hold_repeat_is_pressed = false
	hold_repeat_delay_remaining = 0.0
	hold_repeat_interval_remaining = 0.0


func perform_hold_repeat_action() -> void:
	if hold_repeat_action == &"inventory_secondary_action":
		if hold_repeat_secondary_mode == &"put_one":
			if held_entry.is_empty():
				stop_hold_repeat()
				return
			handle_put_one_action()
			if held_entry.is_empty():
				stop_hold_repeat()
			return
		stop_hold_repeat()
		return


func _on_trade_back_button_pressed() -> void:
	close_inventory()


func open_with_inventory(inventory) -> void:
	current_inventory = inventory
	current_unit = null
	trade_inventory = null
	trade_unit = null
	ui_mode = UIMode.NORMAL
	end_trade_session()

	if current_inventory != null:
		current_unit = current_inventory.get_parent()

	if current_unit != null and current_unit.has_method("get_equipment_slot_order"):
		equipment_slot_order = current_unit.get_equipment_slot_order()

	apply_ui_config()
	apply_side_panel_visuals_for_mode()
	update_background_visibility()
	update_trade_panel_visibility()

	await rebuild_hotbar_slots_if_needed()
	await rebuild_inventory_slots_if_needed()
	await rebuild_trade_slots_if_needed()
	build_equipment_slots()

	focus_area = "inventory"
	selected_index = clamp(selected_index, 0, max(get_inventory_slot_count() - 1, 0))

	refresh()
	show()
	restart_tooltip_timer()


func open_trade_mode(player_inventory, player_unit, merchant_inventory, merchant_owner) -> void:
	current_inventory = player_inventory
	current_unit = player_unit
	trade_inventory = merchant_inventory
	trade_unit = merchant_owner
	ui_mode = UIMode.TRADE

	if current_unit != null and current_unit.has_method("get_equipment_slot_order"):
		equipment_slot_order = current_unit.get_equipment_slot_order()

	title_label.text = "Player"
	trade_title_label.text = "Merchant"

	apply_ui_config()
	apply_side_panel_visuals_for_mode()
	update_background_visibility()
	update_trade_panel_visibility()

	await rebuild_hotbar_slots_if_needed()
	await rebuild_inventory_slots_if_needed()
	await rebuild_trade_slots_if_needed()
	build_equipment_slots()

	begin_trade_session()

	focus_area = "inventory"
	selected_index = clamp(selected_index, 0, max(get_inventory_slot_count() - 1, 0))

	refresh()
	show()
	restart_tooltip_timer()


func open_chest_mode(player_inventory, player_unit, chest_inventory, chest_owner) -> void:
	current_inventory = player_inventory
	current_unit = player_unit
	trade_inventory = chest_inventory
	trade_unit = chest_owner
	ui_mode = UIMode.CHEST

	if current_unit != null and current_unit.has_method("get_equipment_slot_order"):
		equipment_slot_order = current_unit.get_equipment_slot_order()

	title_label.text = "Player"

	if trade_unit != null and trade_unit.has_method("get_inventory_title"):
		trade_title_label.text = String(trade_unit.get_inventory_title())
	else:
		trade_title_label.text = "Chest"

	apply_ui_config()
	apply_side_panel_visuals_for_mode()
	update_background_visibility()
	update_trade_panel_visibility()

	await rebuild_hotbar_slots_if_needed()
	await rebuild_inventory_slots_if_needed()
	await rebuild_trade_slots_if_needed()
	build_equipment_slots()

	end_trade_session()

	focus_area = "inventory"
	selected_index = clamp(selected_index, 0, max(get_inventory_slot_count() - 1, 0))

	refresh()
	show()
	restart_tooltip_timer()


func is_trade_mode_open() -> bool:
	return visible and ui_mode == UIMode.TRADE


func close_inventory() -> void:
	stop_hold_repeat()
	if not restore_held_entry_on_close():
		return

	hide_tooltip()
	held_item_preview.hide()

	if tooltip_timer != null:
		tooltip_timer.stop()

	var was_side_mode: bool = is_side_mode()
	if was_side_mode:
		end_trade_session()

	hide()

	current_inventory = null
	current_unit = null
	trade_inventory = null
	trade_unit = null
	ui_mode = UIMode.NORMAL
	focus_area = "inventory"
	selected_index = 0
	title_label.text = "Inventory"
	trade_title_label.text = "Trade"

	apply_ui_config()
	apply_side_panel_visuals_for_mode()
	update_background_visibility()
	update_trade_panel_visibility()

	if was_side_mode:
		var node: Node = self
		while node != null:
			if node.has_method("on_trade_ui_closed"):
				node.on_trade_ui_closed()
				break
			node = node.get_parent()


func toggle_with_inventory(inventory) -> void:
	if visible:
		close_inventory()
	else:
		await open_with_inventory(inventory)


func get_inventory_slot_columns() -> int:
	if current_inventory != null:
		if current_inventory.has_method("get_slot_columns"):
			return max(1, int(current_inventory.get_slot_columns()))
		if "slot_columns" in current_inventory:
			return max(1, int(current_inventory.slot_columns))

	if slot_grid != null and slot_grid.columns > 0:
		return max(1, int(slot_grid.columns))

	if ui_config != null and ui_config.inventory_columns > 0:
		return max(1, int(ui_config.inventory_columns))

	return 9


func get_inventory_slot_rows() -> int:
	if current_inventory != null:
		if current_inventory.has_method("get_slot_rows"):
			return max(1, int(current_inventory.get_slot_rows()))
		if "slot_rows" in current_inventory:
			return max(1, int(current_inventory.slot_rows))

	var count: int = get_inventory_slot_count()
	var columns: int = get_inventory_slot_columns()
	return max(1, int(ceil(float(count) / float(columns))))


func get_trade_slot_columns() -> int:
	if trade_inventory != null:
		if trade_inventory.has_method("get_slot_columns"):
			return max(1, int(trade_inventory.get_slot_columns()))
		if "slot_columns" in trade_inventory:
			return max(1, int(trade_inventory.slot_columns))

	if ui_mode == UIMode.CHEST:
		var chest_data: ChestData = get_chest_ui_data()
		if chest_data != null and chest_data.ui_slot_columns > 0:
			return max(1, int(chest_data.ui_slot_columns))

	if trade_slot_grid != null and trade_slot_grid.columns > 0:
		return max(1, int(trade_slot_grid.columns))

	if ui_config != null and ui_config.inventory_columns > 0:
		return max(1, int(ui_config.inventory_columns))

	return 9


func get_trade_slot_rows() -> int:
	if trade_inventory != null:
		if trade_inventory.has_method("get_slot_rows"):
			return max(1, int(trade_inventory.get_slot_rows()))
		if "slot_rows" in trade_inventory:
			return max(1, int(trade_inventory.slot_rows))

	var count: int = get_trade_slot_count()
	var columns: int = get_trade_slot_columns()
	return max(1, int(ceil(float(count) / float(columns))))


func sync_slot_grid_columns_from_inventories() -> void:
	if slot_grid != null:
		slot_grid.columns = get_inventory_slot_columns()

	if trade_slot_grid != null:
		trade_slot_grid.columns = get_trade_slot_columns()

	if hotbar_slot_grid != null:
		hotbar_slot_grid.columns = get_hotbar_slot_columns()


func get_inventory_slot_count() -> int:
	if current_inventory == null:
		return 0

	if current_inventory.has_method("get_slot_count"):
		return max(0, int(current_inventory.get_slot_count()))

	if "max_slots" in current_inventory:
		return max(0, int(current_inventory.max_slots))

	return 0


func get_trade_slot_count() -> int:
	if trade_inventory == null:
		return 0

	if trade_inventory.has_method("get_slot_count"):
		return max(0, int(trade_inventory.get_slot_count()))

	if "max_slots" in trade_inventory:
		return max(0, int(trade_inventory.max_slots))

	return 0


func get_equipment_slot_count() -> int:
	return equipment_slot_order.size()


func get_hotbar_slot_count() -> int:
	if current_inventory == null:
		return 0

	if current_inventory.has_method("get_hotbar_slot_count"):
		return max(0, int(current_inventory.get_hotbar_slot_count()))

	if "hotbar_slot_count" in current_inventory:
		return max(0, int(current_inventory.hotbar_slot_count))

	return 0


func get_hotbar_slot_columns() -> int:
	var count: int = get_hotbar_slot_count()
	if count > 0:
		return count

	return 9


func get_hotbar_slot_rows() -> int:
	var count: int = get_hotbar_slot_count()
	var columns: int = get_hotbar_slot_columns()

	if count <= 0 or columns <= 0:
		return 1

	return max(1, int(ceil(float(count) / float(columns))))


# =========================
# Mouse Slot Input
# =========================
# インベントリ / ショップ / チェスト / 装備スロットをマウス操作に対応させる。
# 新しいアイテム移動処理は作らず、既存の handle_confirm_action()
# handle_split_pick_action() / handle_put_one_action() / use_selected_item()
# に流す。
#
# 左クリック:
# - 持つ / 置く / 交換
#
# 右クリック:
# - 何も持っていない時: 半分持つ
# - 何か持っている時: 1個置く
#
# 左ダブルクリック:
# - 使用にはしない。通常の左クリックと同じく持つ/置く/交換。
#
# マウスホバー:
# - 選択位置をそのスロットへ移動し、ツールチップ対象も更新する。

func bind_mouse_input_to_slot(slot: Node, area: String, index: int) -> void:
	if slot == null:
		return

	# slot_scene の中に TextureRect / Label / Panel などの子Controlがある場合、
	# root の gui_input だけではクリックが届かないことがある。
	# そのため、スロットrootだけでなく子Controlにも同じ入力を接続する。
	bind_mouse_input_to_control_tree(slot, area, index)


func bind_mouse_input_to_control_tree(node: Node, area: String, index: int) -> void:
	if node == null:
		return

	if node is Control:
		var control: Control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_STOP

		var gui_callable: Callable = Callable(self, "_on_inventory_slot_gui_input").bind(area, index)
		if not control.gui_input.is_connected(gui_callable):
			control.gui_input.connect(gui_callable)

		var mouse_entered_callable: Callable = Callable(self, "_on_inventory_slot_mouse_entered").bind(area, index)
		if not control.mouse_entered.is_connected(mouse_entered_callable):
			control.mouse_entered.connect(mouse_entered_callable)

	for child in node.get_children():
		bind_mouse_input_to_control_tree(child, area, index)


func _on_inventory_slot_mouse_entered(area: String, index: int) -> void:
	if not visible:
		return

	if is_building_slots:
		return

	if is_failed_quest_dialog_locked():
		return

	enter_mouse_navigation_mode()
	set_mouse_focus_slot(area, index)
	restart_tooltip_timer()


func _on_inventory_slot_gui_input(event: InputEvent, area: String, index: int) -> void:
	if not visible:
		return

	if is_building_slots:
		return

	if is_failed_quest_dialog_locked():
		return

	if not (event is InputEventMouseButton):
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton

	if not mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if hold_repeat_action == &"inventory_secondary_action":
				stop_hold_repeat()
				get_viewport().set_input_as_handled()
		return

	enter_mouse_navigation_mode()
	set_mouse_focus_slot(area, index)

	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		# ダブルクリックでも使用せず、通常の左クリックと同じく
		# 持つ / 置く / 交換 のみを行う。
		handle_confirm_action()
		get_viewport().set_input_as_handled()
		return

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if held_entry.is_empty():
			handle_split_pick_action()
			stop_hold_repeat()
		else:
			handle_put_one_action()

			if held_entry.is_empty():
				stop_hold_repeat()
			else:
				start_hold_repeat(&"inventory_secondary_action", &"put_one")

		get_viewport().set_input_as_handled()
		return

	if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
		try_mouse_use_selected_item()
		get_viewport().set_input_as_handled()
		return


func set_mouse_focus_slot(area: String, index: int) -> void:
	if area == "trade":
		if not is_side_mode():
			return

		var count: int = get_trade_slot_count()
		if count <= 0:
			return

		focus_area = "trade"
		selected_index = clamp(index, 0, count - 1)

	elif area == "hotbar":
		var count: int = get_hotbar_slot_count()
		if count <= 0:
			return

		focus_area = "hotbar"
		selected_index = clamp(index, 0, count - 1)

	elif area == "inventory":
		var count: int = get_inventory_slot_count()
		if count <= 0:
			return

		focus_area = "inventory"
		selected_index = clamp(index, 0, count - 1)

	elif area == "equipment":
		var count: int = get_equipment_slot_count()
		if count <= 0:
			return

		focus_area = "equipment"
		selected_index = clamp(index, 0, count - 1)

	elif area == "trade_back":
		# trade_back は非表示化したため、マウスフォーカス対象にしない。
		return

	else:
		return

	hide_tooltip()
	refresh()


func try_mouse_use_selected_item() -> void:
	if ui_mode != UIMode.NORMAL:
		return

	if focus_area != "inventory" and focus_area != "hotbar":
		return

	if not held_entry.is_empty():
		return

	use_selected_item()


func rebuild_hotbar_slots_if_needed() -> void:
	ensure_hotbar_ui_nodes()

	if current_inventory == null:
		return

	if hotbar_slot_grid == null:
		return

	sync_slot_grid_columns_from_inventories()

	var target_count: int = get_hotbar_slot_count()
	if hotbar_slot_grid.get_child_count() == target_count:
		return

	is_building_slots = true
	hide_tooltip()

	if tooltip_timer != null:
		tooltip_timer.stop()

	if slot_scene == null:
		push_error("InventoryUI: slot_scene が未設定です")
		is_building_slots = false
		return

	for child in hotbar_slot_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	for i in range(target_count):
		var slot = slot_scene.instantiate()

		if ui_config != null and slot.has_method("apply_config"):
			slot.apply_config(
				ui_config.inventory_slot_size,
				ui_config.inventory_icon_margin
			)

		hotbar_slot_grid.add_child(slot)
		bind_mouse_input_to_slot(slot, "hotbar", i)

	await get_tree().process_frame
	apply_compact_inventory_layout()
	force_trade_panel_fit_to_slots()

	is_building_slots = false


func rebuild_inventory_slots_if_needed() -> void:
	if current_inventory == null:
		return

	sync_slot_grid_columns_from_inventories()

	var target_count: int = get_inventory_slot_count()
	if slot_grid.get_child_count() == target_count:
		return

	is_building_slots = true
	hide_tooltip()

	if tooltip_timer != null:
		tooltip_timer.stop()

	if slot_scene == null:
		push_error("InventoryUI: slot_scene が未設定です")
		is_building_slots = false
		return

	for child in slot_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	for i in range(target_count):
		var slot = slot_scene.instantiate()

		if ui_config != null and slot.has_method("apply_config"):
			slot.apply_config(
				ui_config.inventory_slot_size,
				ui_config.inventory_icon_margin
			)

		slot_grid.add_child(slot)
		bind_mouse_input_to_slot(slot, "inventory", i)

	await get_tree().process_frame
	apply_compact_inventory_layout()
	force_trade_panel_fit_to_slots()

	is_building_slots = false


func rebuild_trade_slots_if_needed() -> void:
	if trade_inventory == null:
		for child in trade_slot_grid.get_children():
			child.queue_free()
		await get_tree().process_frame
		return

	sync_slot_grid_columns_from_inventories()

	var target_count: int = get_trade_slot_count()
	if trade_slot_grid.get_child_count() == target_count:
		return

	is_building_slots = true
	hide_tooltip()

	if tooltip_timer != null:
		tooltip_timer.stop()

	if slot_scene == null:
		push_error("InventoryUI: slot_scene が未設定です")
		is_building_slots = false
		return

	for child in trade_slot_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	var trade_slot_visual_size: Vector2 = get_trade_slot_visual_size()
	var trade_icon_margin: int = 0
	if ui_config != null:
		trade_icon_margin = ui_config.inventory_icon_margin

	for i in range(target_count):
		var slot = slot_scene.instantiate()

		if slot.has_method("apply_config"):
			slot.apply_config(
				trade_slot_visual_size,
				trade_icon_margin
			)

		trade_slot_grid.add_child(slot)
		bind_mouse_input_to_slot(slot, "trade", i)

	await get_tree().process_frame
	apply_compact_inventory_layout()
	force_trade_panel_fit_to_slots()

	is_building_slots = false


func get_equipment_slot_display_name(slot_name: String) -> String:
	match slot_name:
		"right_hand":
			return "右手"
		"left_hand":
			return "左手"
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
			return "装飾1"
		"accessory_2":
			return "装飾2"
		"accessory_3":
			return "装飾3"
		"accessory_4":
			return "装飾4"
		_:
			return slot_name.capitalize()


func get_equipment_slot_section_id(slot_name: String) -> StringName:
	match slot_name:
		"right_hand", "left_hand":
			return &"weapon"
		"head", "body", "hands", "waist", "feet":
			return &"armor"
		"accessory_1", "accessory_2", "accessory_3", "accessory_4":
			return &"accessory"
		_:
			return &"other"


func get_equipment_section_label(section_id: StringName) -> String:
	match section_id:
		&"weapon":
			return "武器"
		&"armor":
			return "防具"
		&"accessory":
			return "装飾品"
		_:
			return "その他"



func get_equipment_slot_background_texture(slot_name: String) -> Texture2D:
	match slot_name:
		"right_hand":
			return equipment_slot_background_right_hand
		"left_hand":
			return equipment_slot_background_left_hand
		"head":
			return equipment_slot_background_head
		"body":
			return equipment_slot_background_body
		"hands":
			return equipment_slot_background_hands
		"waist":
			return equipment_slot_background_waist
		"feet":
			return equipment_slot_background_feet
		"accessory_1":
			return equipment_slot_background_accessory_1
		"accessory_2":
			return equipment_slot_background_accessory_2
		"accessory_3":
			return equipment_slot_background_accessory_3
		"accessory_4":
			return equipment_slot_background_accessory_4
		_:
			return null


func get_equipment_slot_placeholder_text(slot_name: String) -> String:
	# スロット内に収まりやすい短い表示。
	# 左側のスロット名ラベルは表示しないため、
	# 背景画像が未設定の時はここで「何を装備する枠か」を表示する。
	match slot_name:
		"right_hand":
			return "右手"
		"left_hand":
			return "左手"
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
			return "装1"
		"accessory_2":
			return "装2"
		"accessory_3":
			return "装3"
		"accessory_4":
			return "装4"
		_:
			return get_equipment_slot_display_name(slot_name)


func get_slot_root_control(slot: Node) -> Control:
	if slot == null:
		return null

	var slot_root: Node = slot.get_node_or_null("SlotRoot")
	if slot_root is Control:
		return slot_root as Control

	if slot is Control:
		return slot as Control

	return null


func setup_equipment_slot_visual(slot: Node, slot_name: String) -> void:
	if slot == null:
		return

	var slot_root: Control = get_slot_root_control(slot)
	if slot_root == null:
		return

	var background_texture: Texture2D = get_equipment_slot_background_texture(slot_name)

	var background: TextureRect = slot_root.get_node_or_null("EquipmentSlotBackground") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "EquipmentSlotBackground"
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.anchors_preset = Control.PRESET_FULL_RECT
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0
		background.grow_horizontal = Control.GROW_DIRECTION_BOTH
		background.grow_vertical = Control.GROW_DIRECTION_BOTH
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.z_index = -1
		slot_root.add_child(background)

	background.texture = background_texture
	background.visible = background_texture != null
	slot_root.move_child(background, 0)

	var placeholder: Label = slot_root.get_node_or_null("EquipmentSlotPlaceholder") as Label
	if placeholder == null:
		placeholder = Label.new()
		placeholder.name = "EquipmentSlotPlaceholder"
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placeholder.anchors_preset = Control.PRESET_FULL_RECT
		placeholder.anchor_right = 1.0
		placeholder.anchor_bottom = 1.0
		placeholder.grow_horizontal = Control.GROW_DIRECTION_BOTH
		placeholder.grow_vertical = Control.GROW_DIRECTION_BOTH
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		placeholder.z_index = 0
		slot_root.add_child(placeholder)

	placeholder.text = get_equipment_slot_placeholder_text(slot_name)
	placeholder.add_theme_font_size_override("font_size", equipment_slot_placeholder_font_size)
	placeholder.modulate = equipment_slot_placeholder_color

	if slot_root.get_child_count() > 1:
		slot_root.move_child(placeholder, 1)

	update_equipment_slot_placeholder(slot, slot_name, true)


func update_equipment_slot_placeholder(slot: Node, slot_name: String, is_empty: bool) -> void:
	if slot == null:
		return

	var slot_root: Control = get_slot_root_control(slot)
	if slot_root == null:
		return

	var background_texture: Texture2D = get_equipment_slot_background_texture(slot_name)

	var background: TextureRect = slot_root.get_node_or_null("EquipmentSlotBackground") as TextureRect
	if background != null:
		background.texture = background_texture
		background.visible = background_texture != null

	var placeholder: Label = slot_root.get_node_or_null("EquipmentSlotPlaceholder") as Label
	if placeholder == null:
		return

	placeholder.text = get_equipment_slot_placeholder_text(slot_name)
	placeholder.add_theme_font_size_override("font_size", equipment_slot_placeholder_font_size)
	placeholder.modulate = equipment_slot_placeholder_color

	# 背景画像がある場合は、画像そのものを「何を装備するか」の表示として扱う。
	# 背景画像がない場合だけ、空スロットに文字を出す。
	placeholder.visible = equipment_show_slot_placeholder_text and is_empty and background_texture == null

func add_equipment_section_header(section_label: String) -> void:
	if not equipment_show_section_headers:
		return

	var label: Label = Label.new()
	label.text = section_label
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	equipment_vbox.add_child(label)


func get_equipment_left_column_slot_names() -> Array:
	return [
		"right_hand",
		"left_hand",
		"head",
		"body",
		"hands",
		"waist",
		"feet"
	]


func get_equipment_right_column_slot_names() -> Array:
	return [
		"accessory_1",
		"accessory_2",
		"accessory_3",
		"accessory_4"
	]


func get_equipment_two_column_slot_lists(source_order: Array) -> Dictionary:
	var left_names: Array = get_equipment_left_column_slot_names()
	var right_names: Array = get_equipment_right_column_slot_names()

	var left_slots: Array = []
	var right_slots: Array = []
	var used: Dictionary = {}

	for slot_name in left_names:
		if source_order.has(slot_name):
			left_slots.append(slot_name)
			used[String(slot_name)] = true

	for slot_name in right_names:
		if source_order.has(slot_name):
			right_slots.append(slot_name)
			used[String(slot_name)] = true

	# 未知の装備スロットが将来追加された場合は、消さずに左列へ逃がす。
	for raw_slot_name in source_order:
		var slot_name: String = String(raw_slot_name)
		if used.has(slot_name):
			continue
		left_slots.append(slot_name)
		used[slot_name] = true

	var display_order: Array = []
	for slot_name in left_slots:
		display_order.append(slot_name)
	for slot_name in right_slots:
		display_order.append(slot_name)

	return {
		"left": left_slots,
		"right": right_slots,
		"order": display_order
	}


func add_equipment_slot_to_column(column: VBoxContainer, slot_name: String) -> void:
	var slot = slot_scene.instantiate()

	if ui_config != null and slot.has_method("apply_config"):
		slot.apply_config(
			ui_config.equipment_slot_size,
			ui_config.equipment_icon_margin
		)

	setup_equipment_slot_visual(slot, slot_name)

	if slot is Control:
		var slot_control: Control = slot as Control
		slot_control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		slot_control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	column.add_child(slot)
	bind_mouse_input_to_slot(slot, "equipment", equipment_slot_nodes.size())
	equipment_slot_nodes.append(slot)


func build_equipment_slots() -> void:
	equipment_slot_nodes.clear()

	for child in equipment_vbox.get_children():
		child.queue_free()

	# 装備欄は2列表示。
	# 左列: 右手 / 左手 / 頭 / 胴 / 手 / 腰 / 足
	# 右列: アクセサリー1〜4
	# 左側のスロット名ラベルと「武器/防具/装飾品」の区切り見出しは表示しない。
	var slot_lists: Dictionary = get_equipment_two_column_slot_lists(equipment_slot_order)
	var left_slots: Array = slot_lists.get("left", [])
	var right_slots: Array = slot_lists.get("right", [])
	equipment_slot_order = slot_lists.get("order", [])

	var columns_row: HBoxContainer = HBoxContainer.new()
	columns_row.name = "EquipmentSlotColumns"
	columns_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	columns_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	columns_row.add_theme_constant_override("separation", max(0, equipment_column_gap))
	equipment_vbox.add_child(columns_row)

	var left_column: VBoxContainer = VBoxContainer.new()
	left_column.name = "EquipmentLeftColumn"
	left_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_column.add_theme_constant_override("separation", max(0, equipment_row_gap))
	columns_row.add_child(left_column)

	var right_column: VBoxContainer = VBoxContainer.new()
	right_column.name = "EquipmentAccessoryColumn"
	right_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	right_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_column.add_theme_constant_override("separation", max(0, equipment_row_gap))
	columns_row.add_child(right_column)

	for slot_name in left_slots:
		add_equipment_slot_to_column(left_column, String(slot_name))

	for slot_name in right_slots:
		add_equipment_slot_to_column(right_column, String(slot_name))
func _get_hallucination_controller() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("get_hallucinated_texture"):
			return node
		node = node.get_parent()
	return null


func _get_display_item_icon(item_id: String) -> Texture2D:
	var base_icon: Texture2D = ItemDatabase.get_item_icon(item_id)
	var controller: Node = _get_hallucination_controller()
	if controller != null:
		return controller.get_hallucinated_texture(base_icon)
	return base_icon


func refresh() -> void:
	refresh_trade_slots()
	refresh_hotbar_slots()
	refresh_inventory_slots()
	refresh_equipment_slots()
	refresh_trade_back_button()
	update_help_text()
	update_held_item_preview()


func refresh_trade_slots() -> void:
	if trade_inventory == null:
		return

	var items = trade_inventory.get_all_items()
	var child_count: int = trade_slot_grid.get_child_count()

	for i in range(child_count):
		var slot = trade_slot_grid.get_child(i)
		if slot == null:
			continue

		if i < items.size():
			var entry: Dictionary = items[i]
			var item_id: String = String(entry.get("item_id", ""))
			if slot.has_method("set_item_entry"):
				slot.set_item_entry(entry, _get_display_item_icon(item_id))
			else:
				var amount: int = int(entry.get("amount", 0))
				slot.set_slot_data(item_id, amount, _get_display_item_icon(item_id))
		else:
			if slot.has_method("set_item_entry"):
				slot.set_item_entry({}, null)
			else:
				slot.set_slot_data("", 0, null)

		slot.set_selected(is_game_cursor_visible() and focus_area == "trade" and i == selected_index)


func refresh_hotbar_slots() -> void:
	if current_inventory == null:
		return

	if hotbar_slot_grid == null:
		return

	var items: Array = []
	if current_inventory.has_method("get_all_hotbar_items"):
		items = current_inventory.get_all_hotbar_items()
	else:
		for i in range(get_hotbar_slot_count()):
			if current_inventory.has_method("get_hotbar_item_data_at"):
				items.append(current_inventory.get_hotbar_item_data_at(i))
			else:
				items.append({})

	var child_count: int = hotbar_slot_grid.get_child_count()

	for i in range(child_count):
		var slot = hotbar_slot_grid.get_child(i)
		if slot == null:
			continue

		if i < items.size():
			var entry: Dictionary = items[i]
			var item_id: String = String(entry.get("item_id", ""))
			if slot.has_method("set_item_entry"):
				slot.set_item_entry(entry, _get_display_item_icon(item_id))
			else:
				var amount: int = int(entry.get("amount", 0))
				slot.set_slot_data(item_id, amount, _get_display_item_icon(item_id))
		else:
			if slot.has_method("set_item_entry"):
				slot.set_item_entry({}, null)
			else:
				slot.set_slot_data("", 0, null)

		slot.set_selected(is_game_cursor_visible() and focus_area == "hotbar" and i == selected_index)


func refresh_inventory_slots() -> void:
	if current_inventory == null:
		return

	var items = current_inventory.get_all_items()
	var child_count: int = slot_grid.get_child_count()

	for i in range(child_count):
		var slot = slot_grid.get_child(i)
		if slot == null:
			continue

		if i < items.size():
			var entry: Dictionary = items[i]
			var item_id: String = String(entry.get("item_id", ""))
			if slot.has_method("set_item_entry"):
				slot.set_item_entry(entry, _get_display_item_icon(item_id))
			else:
				var amount: int = int(entry.get("amount", 0))
				slot.set_slot_data(item_id, amount, _get_display_item_icon(item_id))
		else:
			if slot.has_method("set_item_entry"):
				slot.set_item_entry({}, null)
			else:
				slot.set_slot_data("", 0, null)

		slot.set_selected(is_game_cursor_visible() and focus_area == "inventory" and i == selected_index)


func refresh_equipment_slots() -> void:
	for i in range(equipment_slot_nodes.size()):
		var slot = equipment_slot_nodes[i]
		var slot_name: String = String(equipment_slot_order[i])

		var entry: Dictionary = get_equipment_entry(slot_name)
		var item_id: String = String(entry.get("item_id", ""))

		if slot.has_method("set_item_entry"):
			slot.set_item_entry(entry, _get_display_item_icon(item_id))
		else:
			var amount: int = int(entry.get("amount", 0))
			slot.set_slot_data(item_id, amount, _get_display_item_icon(item_id))

		slot.set_selected(is_game_cursor_visible() and focus_area == "equipment" and i == selected_index)
		update_equipment_slot_placeholder(slot, slot_name, item_id == "")


func refresh_trade_back_button() -> void:
	# TradePanel の高さをスロット枠に合わせるため、旧「戻る」ボタンは使わない。
	if trade_back_button != null:
		trade_back_button.visible = false
		trade_back_button.button_pressed = false


func update_help_text() -> void:
	# 下部の操作説明文は表示しない。
	# InventoryUI.tscn から HelpLabel も削除済み。
	return

func move_selection(dx: int, dy: int) -> void:
	if is_building_slots:
		return

	if focus_area == "trade":
		move_trade_selection(dx, dy)
	elif focus_area == "hotbar":
		move_hotbar_selection(dx, dy)
	elif focus_area == "inventory":
		move_inventory_selection(dx, dy)
	elif focus_area == "equipment":
		move_equipment_selection(dx, dy)
	else:
		# trade_back は非表示化したため、選択が迷子になったら inventory に戻す。
		focus_area = "inventory"
		selected_index = clamp(selected_index, 0, max(get_inventory_slot_count() - 1, 0))

	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func move_hotbar_selection(dx: int, dy: int) -> void:
	var slot_count: int = get_hotbar_slot_count()
	if slot_count <= 0:
		focus_area = "inventory"
		selected_index = clamp(selected_index, 0, max(get_inventory_slot_count() - 1, 0))
		return

	var columns: int = get_hotbar_slot_columns()
	if columns <= 0:
		columns = 1

	var col: int = selected_index % columns

	if dy > 0:
		focus_area = "inventory"
		selected_index = clamp(col, 0, max(get_inventory_slot_count() - 1, 0))
		return

	col += dx
	col = clamp(col, 0, slot_count - 1)
	selected_index = col


func move_trade_selection(dx: int, dy: int) -> void:
	var slot_count: int = get_trade_slot_count()
	if slot_count <= 0:
		if dx > 0:
			focus_area = "inventory"
			selected_index = 0
		elif dy > 0:
			# 旧 trade_back ボタンは非表示なので、下方向では選択を移動しない。
			selected_index = 0
		return

	var columns: int = trade_slot_grid.columns
	if columns <= 0:
		columns = 1

	var row: int = selected_index / columns
	var col: int = selected_index % columns
	var max_row: int = int(ceil(float(slot_count) / float(columns))) - 1

	var row_start: int = row * columns
	var row_end: int = min(row_start + columns - 1, slot_count - 1)
	var row_last_col: int = row_end - row_start

	if dx > 0 and col >= row_last_col:
		focus_area = "inventory"
		selected_index = map_trade_row_to_inventory_index(row)
		return

	if dy > 0 and row == max_row:
		# 旧 trade_back ボタンは非表示なので、下方向では最下段に留まる。
		return

	col += dx
	row += dy

	if row < 0:
		row = 0
	if row > max_row:
		row = max_row

	row_start = row * columns
	row_end = min(row_start + columns - 1, slot_count - 1)
	row_last_col = row_end - row_start

	if col < 0:
		col = 0
	if col > row_last_col:
		col = row_last_col

	var new_index: int = row * columns + col
	new_index = clamp(new_index, 0, slot_count - 1)

	selected_index = new_index


func move_inventory_selection(dx: int, dy: int) -> void:
	var slot_count: int = get_inventory_slot_count()
	if slot_count <= 0:
		return

	var columns: int = slot_grid.columns
	if columns <= 0:
		columns = 1

	var row: int = selected_index / columns
	var col: int = selected_index % columns
	var max_row: int = int(ceil(float(slot_count) / float(columns))) - 1

	var row_start: int = row * columns
	var row_end: int = min(row_start + columns - 1, slot_count - 1)
	var row_last_col: int = row_end - row_start

	# インベントリ画面内の専用ホットバー欄は廃止したため、
	# キーボード上移動で hotbar へフォーカスしない。

	if dx < 0 and col == 0 and is_side_mode():
		focus_area = "trade"
		selected_index = map_inventory_row_to_trade_index(row)
		return

	if dx > 0 and col >= row_last_col:
		focus_area = "equipment"
		selected_index = map_inventory_row_to_equipment_index(row)
		return

	col += dx
	row += dy

	if row < 0:
		row = 0
	if row > max_row:
		row = max_row

	row_start = row * columns
	row_end = min(row_start + columns - 1, slot_count - 1)
	row_last_col = row_end - row_start

	if col < 0:
		col = 0
	if col > row_last_col:
		col = row_last_col

	var new_index: int = row * columns + col
	new_index = clamp(new_index, 0, slot_count - 1)

	selected_index = new_index


func move_equipment_selection(dx: int, dy: int) -> void:
	var slot_count: int = get_equipment_slot_count()
	if slot_count <= 0:
		return

	selected_index = clamp(selected_index, 0, slot_count - 1)

	var slot_lists: Dictionary = get_equipment_two_column_slot_lists(equipment_slot_order)
	var left_slots: Array = slot_lists.get("left", [])
	var right_slots: Array = slot_lists.get("right", [])
	var current_slot_name: String = String(equipment_slot_order[selected_index])

	var in_right_column: bool = right_slots.has(current_slot_name)
	var current_column: Array = right_slots if in_right_column else left_slots
	var current_row: int = current_column.find(current_slot_name)
	if current_row < 0:
		current_row = 0

	if dx < 0:
		if in_right_column:
			if left_slots.size() <= 0:
				return

			var left_row: int = clamp(current_row, 0, left_slots.size() - 1)
			var left_slot_name: String = String(left_slots[left_row])
			var left_index: int = equipment_slot_order.find(left_slot_name)
			if left_index >= 0:
				selected_index = left_index
			return

		var target_row: int = map_equipment_index_to_inventory_row(selected_index)
		var columns: int = slot_grid.columns
		if columns <= 0:
			columns = 1

		var inventory_index: int = target_row * columns + (columns - 1)
		inventory_index = min(inventory_index, get_inventory_slot_count() - 1)
		inventory_index = max(inventory_index, 0)

		focus_area = "inventory"
		selected_index = inventory_index
		return

	if dx > 0:
		if in_right_column:
			return

		if right_slots.size() <= 0:
			return

		var right_row: int = clamp(current_row, 0, right_slots.size() - 1)
		var right_slot_name: String = String(right_slots[right_row])
		var right_index: int = equipment_slot_order.find(right_slot_name)
		if right_index >= 0:
			selected_index = right_index
		return

	if dy != 0:
		if current_column.size() <= 0:
			return

		var next_row: int = clamp(current_row + dy, 0, current_column.size() - 1)
		var next_slot_name: String = String(current_column[next_row])
		var next_index: int = equipment_slot_order.find(next_slot_name)
		if next_index >= 0:
			selected_index = next_index
func move_trade_back_selection(dx: int, dy: int) -> void:
	# TradePanel の戻るボタンは非表示。
	# 古い focus_area が残っていた場合は inventory へ戻す。
	focus_area = "inventory"
	selected_index = clamp(selected_index, 0, max(get_inventory_slot_count() - 1, 0))


func map_trade_row_to_inventory_index(row: int) -> int:
	var inventory_count: int = get_inventory_slot_count()
	var columns: int = slot_grid.columns
	if columns <= 0:
		columns = 1

	var inventory_rows: int = int(ceil(float(inventory_count) / float(columns)))
	if inventory_rows <= 0:
		return 0

	row = clamp(row, 0, inventory_rows - 1)
	return clamp(row * columns, 0, max(inventory_count - 1, 0))


func map_inventory_row_to_trade_index(row: int) -> int:
	var trade_count: int = get_trade_slot_count()
	var columns: int = trade_slot_grid.columns
	if columns <= 0:
		columns = 1

	var trade_rows: int = int(ceil(float(trade_count) / float(columns)))
	if trade_rows <= 0:
		return 0

	row = clamp(row, 0, trade_rows - 1)
	return clamp(row * columns + (columns - 1), 0, max(trade_count - 1, 0))


func map_inventory_row_to_equipment_index(row: int) -> int:
	var inventory_count: int = get_inventory_slot_count()
	var columns: int = slot_grid.columns
	if columns <= 0:
		columns = 1

	var inventory_rows: int = int(ceil(float(inventory_count) / float(columns)))
	var equipment_count: int = get_equipment_slot_count()

	if equipment_count <= 1 or inventory_rows <= 1:
		return 0

	var ratio: float = float(row) * float(equipment_count - 1) / float(inventory_rows - 1)
	return clamp(int(round(ratio)), 0, equipment_count - 1)


func map_equipment_index_to_inventory_row(equipment_index: int) -> int:
	var inventory_count: int = get_inventory_slot_count()
	var columns: int = slot_grid.columns
	if columns <= 0:
		columns = 1

	var inventory_rows: int = int(ceil(float(inventory_count) / float(columns)))
	var equipment_count: int = get_equipment_slot_count()

	if equipment_count <= 1 or inventory_rows <= 1:
		return 0

	var ratio: float = float(equipment_index) * float(inventory_rows - 1) / float(equipment_count - 1)
	return clamp(int(round(ratio)), 0, inventory_rows - 1)


func handle_confirm_action() -> void:
	if focus_area == "trade_back":
		close_inventory()
		return

	if held_entry.is_empty():
		pick_selected_entry()
	else:
		drop_held_entry()

	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func handle_quick_move_primary_action() -> void:
	pass


func handle_quick_move_secondary_action() -> void:
	pass


func handle_secondary_action() -> void:
	if held_entry.is_empty():
		handle_split_pick_action()
	else:
		handle_put_one_action()


func handle_split_pick_action() -> void:
	if focus_area == "trade_back":
		return

	if not held_entry.is_empty():
		return

	pick_selected_entry_half()
	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func handle_take_one_action() -> void:
	if focus_area == "trade_back":
		return

	if not held_entry.is_empty():
		var selected_entry: Dictionary = get_selected_entry()
		if can_merge_entries(held_entry, selected_entry):
			pick_selected_entry_one()

		hide_tooltip()
		refresh()
		restart_tooltip_timer()
		return

	pick_selected_entry_one()
	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func handle_put_one_action() -> void:
	if focus_area == "trade_back":
		return

	if held_entry.is_empty():
		return

	var selected_entry: Dictionary = get_selected_entry()
	if focus_area == "equipment":
		return

	if is_empty_entry(selected_entry) or can_merge_entries(held_entry, selected_entry):
		drop_held_entry_one()

	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func pick_selected_entry() -> void:
	var entry: Dictionary = get_selected_entry()
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return

	held_entry = entry.duplicate(true)
	held_from_area = focus_area
	held_from_index = -1
	held_from_slot_name = ""

	if focus_area == "inventory":
		held_from_index = selected_index
		current_inventory.clear_slot(selected_index)
	elif focus_area == "hotbar":
		held_from_index = selected_index
		current_inventory.clear_hotbar_slot(selected_index)
	elif focus_area == "trade":
		held_from_index = selected_index
		trade_inventory.clear_slot(selected_index)
	else:
		held_from_slot_name = String(equipment_slot_order[selected_index])
		clear_equipment_entry(held_from_slot_name)
		notify_message("%s を外した" % ItemDatabase.get_display_name(item_id))
		refresh_status_ui()

	update_held_item_preview()


func pick_selected_entry_half() -> void:
	var entry: Dictionary = get_selected_entry()
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return

	if focus_area == "equipment":
		pick_selected_entry()
		return

	if not held_entry.is_empty():
		return

	var pickup_amount: int = int(ceil(float(amount) / 2.0))
	pickup_amount = clamp(pickup_amount, 1, amount)

	held_entry = entry.duplicate(true)
	held_entry["amount"] = pickup_amount
	held_from_area = focus_area
	held_from_index = selected_index
	held_from_slot_name = ""

	var remaining_amount: int = amount - pickup_amount
	if remaining_amount <= 0:
		if focus_area == "inventory":
			current_inventory.clear_slot(selected_index)
		elif focus_area == "hotbar":
			current_inventory.clear_hotbar_slot(selected_index)
		else:
			trade_inventory.clear_slot(selected_index)
	else:
		entry["amount"] = remaining_amount
		if focus_area == "inventory":
			current_inventory.set_item_data_at(selected_index, entry)
		elif focus_area == "hotbar":
			current_inventory.set_hotbar_item_data_at(selected_index, entry)
		else:
			trade_inventory.set_item_data_at(selected_index, entry)

	update_held_item_preview()


func pick_selected_entry_one() -> void:
	var entry: Dictionary = get_selected_entry()
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return

	if focus_area == "equipment":
		pick_selected_entry()
		return

	if held_entry.is_empty():
		held_entry = entry.duplicate(true)
		held_entry["amount"] = 1
		held_from_area = focus_area
		held_from_index = selected_index
		held_from_slot_name = ""

		if amount <= 1:
			if focus_area == "inventory":
				current_inventory.clear_slot(selected_index)
			elif focus_area == "hotbar":
				current_inventory.clear_hotbar_slot(selected_index)
			else:
				trade_inventory.clear_slot(selected_index)
		else:
			entry["amount"] = amount - 1
			if focus_area == "inventory":
				current_inventory.set_item_data_at(selected_index, entry)
			elif focus_area == "hotbar":
				current_inventory.set_hotbar_item_data_at(selected_index, entry)
			else:
				trade_inventory.set_item_data_at(selected_index, entry)

		update_held_item_preview()
		return

	if can_merge_entries(held_entry, entry):
		var max_stack: int = ItemDatabase.get_max_stack(item_id)
		var held_amount: int = int(held_entry.get("amount", 0))
		if held_amount >= max_stack:
			return

		held_entry["amount"] = held_amount + 1

		if amount <= 1:
			if focus_area == "inventory":
				current_inventory.clear_slot(selected_index)
			elif focus_area == "hotbar":
				current_inventory.clear_hotbar_slot(selected_index)
			else:
				trade_inventory.clear_slot(selected_index)
		else:
			entry["amount"] = amount - 1
			if focus_area == "inventory":
				current_inventory.set_item_data_at(selected_index, entry)
			elif focus_area == "hotbar":
				current_inventory.set_hotbar_item_data_at(selected_index, entry)
			else:
				trade_inventory.set_item_data_at(selected_index, entry)

		update_held_item_preview()
		return

	pick_selected_entry()


func drop_held_entry() -> void:
	if focus_area == "inventory":
		drop_held_entry_to_inventory(selected_index)
	elif focus_area == "hotbar":
		drop_held_entry_to_hotbar(selected_index)
	elif focus_area == "trade":
		drop_held_entry_to_trade(selected_index)
	else:
		drop_held_entry_to_equipment(String(equipment_slot_order[selected_index]))


func drop_held_entry_one() -> void:
	if focus_area == "inventory":
		drop_held_entry_one_to_inventory(selected_index)
	elif focus_area == "hotbar":
		drop_held_entry_one_to_hotbar(selected_index)
	elif focus_area == "trade":
		drop_held_entry_one_to_trade(selected_index)
	else:
		drop_held_entry()


func set_held_origin(area: String, index: int = -1, slot_name: String = "") -> void:
	held_from_area = area
	held_from_index = index
	held_from_slot_name = slot_name


func get_player_gold_amount() -> int:
	if current_inventory == null:
		return 0

	if not current_inventory.has_method("get_total_amount"):
		return 0

	return int(current_inventory.get_total_amount("gold"))


func try_spend_player_gold(amount: int) -> bool:
	if amount <= 0:
		return true

	if current_inventory == null:
		return false

	if not current_inventory.has_method("consume_item_amount"):
		return false

	return bool(current_inventory.consume_item_amount("gold", amount))


func give_player_gold(amount: int) -> bool:
	if amount <= 0:
		return true

	if current_inventory == null:
		return false

	if current_inventory.has_method("force_add_item_amount"):
		return bool(current_inventory.force_add_item_amount("gold", amount))

	if current_inventory.has_method("add_item"):
		return bool(current_inventory.add_item("gold", amount))

	return false


func get_entry_buy_price(entry: Dictionary) -> int:
	if typeof(entry) != TYPE_DICTIONARY:
		return 0

	if entry.has("trade_buy_price"):
		return int(entry.get("trade_buy_price", 0))

	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return 0

	return TradePriceCalculator.get_buy_price_with_rate(item_id, trade_session_buy_rate)


func get_entry_sell_price(entry: Dictionary) -> int:
	if typeof(entry) != TYPE_DICTIONARY:
		return 0

	if entry.has("trade_sell_price"):
		return int(entry.get("trade_sell_price", 0))

	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return 0

	return TradePriceCalculator.get_sell_price_with_rate(item_id, trade_session_sell_rate)


func apply_trade_price_to_entry(target_entry: Dictionary, source_entry: Dictionary) -> void:
	if typeof(target_entry) != TYPE_DICTIONARY:
		return
	if typeof(source_entry) != TYPE_DICTIONARY:
		return

	if source_entry.has("trade_buy_price"):
		target_entry["trade_buy_price"] = int(source_entry.get("trade_buy_price", 0))

	if source_entry.has("trade_sell_price"):
		target_entry["trade_sell_price"] = int(source_entry.get("trade_sell_price", 0))


func drop_held_entry_one_to_inventory(target_index: int) -> void:
	var target_entry: Dictionary = current_inventory.get_item_data_at(target_index)

	if is_empty_entry(held_entry):
		return

	if is_empty_entry(target_entry):
		drop_partial_held_entry_to_inventory(target_index, 1)
		return

	if can_merge_entries(held_entry, target_entry):
		drop_partial_held_entry_to_inventory(target_index, 1)
		return

	drop_held_entry_to_inventory(target_index)


func drop_held_entry_to_inventory(target_index: int) -> void:
	var target_entry: Dictionary = current_inventory.get_item_data_at(target_index)
	var source_area_before_swap: String = held_from_area
	var moved_entry: Dictionary = held_entry.duplicate(true)

	if is_empty_entry(target_entry):
		if not notify_trade_transfer_if_needed("inventory", moved_entry, source_area_before_swap):
			return

		current_inventory.set_item_data_at(target_index, movedEntryFix(moved_entry))
		clear_held_state()
		return

	if can_merge_entries(held_entry, target_entry):
		if not notify_trade_transfer_if_needed("inventory", moved_entry, source_area_before_swap):
			return

		apply_trade_price_to_entry(target_entry, moved_entry)

		var remaining: int = merge_entries(held_entry, target_entry)
		current_inventory.set_item_data_at(target_index, target_entry)

		if remaining <= 0:
			clear_held_state()
		else:
			held_entry["amount"] = remaining
		return

	if not notify_trade_transfer_if_needed("inventory", moved_entry, source_area_before_swap):
		return

	var old_target_entry: Dictionary = target_entry.duplicate(true)
	current_inventory.set_item_data_at(target_index, moved_entry)

	held_entry = old_target_entry
	set_held_origin("inventory", target_index, "")
	update_held_item_preview()


func drop_held_entry_one_to_hotbar(target_index: int) -> void:
	var target_entry: Dictionary = current_inventory.get_hotbar_item_data_at(target_index)

	if is_empty_entry(held_entry):
		return

	if is_empty_entry(target_entry):
		drop_partial_held_entry_to_hotbar(target_index, 1)
		return

	if can_merge_entries(held_entry, target_entry):
		drop_partial_held_entry_to_hotbar(target_index, 1)
		return

	drop_held_entry_to_hotbar(target_index)


func drop_held_entry_to_hotbar(target_index: int) -> void:
	var target_entry: Dictionary = current_inventory.get_hotbar_item_data_at(target_index)
	var source_area_before_swap: String = held_from_area
	var moved_entry: Dictionary = held_entry.duplicate(true)

	if is_empty_entry(target_entry):
		if not notify_trade_transfer_if_needed("hotbar", moved_entry, source_area_before_swap):
			return

		current_inventory.set_hotbar_item_data_at(target_index, movedEntryFix(moved_entry))
		clear_held_state()
		return

	if can_merge_entries(held_entry, target_entry):
		if not notify_trade_transfer_if_needed("hotbar", moved_entry, source_area_before_swap):
			return

		apply_trade_price_to_entry(target_entry, moved_entry)

		var remaining: int = merge_entries(held_entry, target_entry)
		current_inventory.set_hotbar_item_data_at(target_index, target_entry)

		if remaining <= 0:
			clear_held_state()
		else:
			held_entry["amount"] = remaining
		return

	if not notify_trade_transfer_if_needed("hotbar", moved_entry, source_area_before_swap):
		return

	var old_target_entry: Dictionary = target_entry.duplicate(true)
	current_inventory.set_hotbar_item_data_at(target_index, moved_entry)

	held_entry = old_target_entry
	set_held_origin("hotbar", target_index, "")
	update_held_item_preview()


func drop_partial_held_entry_to_hotbar(target_index: int, move_amount: int) -> void:
	if current_inventory == null:
		return

	var moved_entry: Dictionary = create_partial_held_entry(move_amount)
	if moved_entry.is_empty():
		return

	var source_area_before_swap: String = held_from_area
	var target_entry: Dictionary = current_inventory.get_hotbar_item_data_at(target_index)

	if is_empty_entry(target_entry):
		if not notify_trade_transfer_if_needed("hotbar", moved_entry, source_area_before_swap):
			return

		current_inventory.set_hotbar_item_data_at(target_index, movedEntryFix(moved_entry))
		consume_held_amount(move_amount)
		return

	if can_merge_entries(moved_entry, target_entry):
		if not notify_trade_transfer_if_needed("hotbar", moved_entry, source_area_before_swap):
			return

		apply_trade_price_to_entry(target_entry, moved_entry)
		var remaining: int = merge_entries(moved_entry, target_entry)
		current_inventory.set_hotbar_item_data_at(target_index, target_entry)
		consume_held_amount(move_amount - remaining)
		return


func drop_held_entry_one_to_trade(target_index: int) -> void:
	var target_entry: Dictionary = trade_inventory.get_item_data_at(target_index)

	if is_empty_entry(held_entry):
		return

	if is_empty_entry(target_entry):
		drop_partial_held_entry_to_trade(target_index, 1)
		return

	if can_merge_entries(held_entry, target_entry):
		drop_partial_held_entry_to_trade(target_index, 1)
		return

	drop_held_entry_to_trade(target_index)


func drop_held_entry_to_trade(target_index: int) -> void:
	var target_entry: Dictionary = trade_inventory.get_item_data_at(target_index)
	var source_area_before_swap: String = held_from_area
	var moved_entry: Dictionary = held_entry.duplicate(true)

	if is_empty_entry(target_entry):
		if not notify_trade_transfer_if_needed("trade", moved_entry, source_area_before_swap):
			return

		trade_inventory.set_item_data_at(target_index, moved_entry)
		clear_held_state()
		return

	if can_merge_entries(held_entry, target_entry):
		if not notify_trade_transfer_if_needed("trade", moved_entry, source_area_before_swap):
			return

		apply_trade_price_to_entry(target_entry, moved_entry)

		var remaining: int = merge_entries(held_entry, target_entry)
		trade_inventory.set_item_data_at(target_index, target_entry)

		if remaining <= 0:
			clear_held_state()
		else:
			held_entry["amount"] = remaining
		return

	if not notify_trade_transfer_if_needed("trade", moved_entry, source_area_before_swap):
		return

	var old_target_entry: Dictionary = target_entry.duplicate(true)
	trade_inventory.set_item_data_at(target_index, moved_entry)

	held_entry = old_target_entry
	set_held_origin("trade", target_index, "")
	update_held_item_preview()


func drop_held_entry_to_equipment(slot_name: String) -> void:
	var target_entry: Dictionary = get_equipment_entry(slot_name)

	if is_empty_entry(held_entry):
		return

	if not can_place_entry_in_equipment_slot(held_entry, slot_name):
		notify_message("そこには装備できない")
		return

	var moved_entry: Dictionary = held_entry.duplicate(true)
	var held_item_id: String = String(moved_entry.get("item_id", ""))
	var held_item_name: String = ItemDatabase.get_display_name(held_item_id)
	var source_area_before_swap: String = held_from_area

	if is_empty_entry(target_entry):
		if not notify_trade_transfer_if_needed("equipment", moved_entry, source_area_before_swap):
			return

		set_equipment_entry(slot_name, moved_entry)
		notify_message("%s を装備した" % held_item_name)
		clear_held_state()
		refresh_status_ui()
		return

	if not notify_trade_transfer_if_needed("equipment", moved_entry, source_area_before_swap):
		return

	var old_target_entry: Dictionary = target_entry.duplicate(true)
	var removed_item_id: String = String(old_target_entry.get("item_id", ""))
	var removed_item_name: String = ItemDatabase.get_display_name(removed_item_id)

	set_equipment_entry(slot_name, moved_entry)

	notify_message("%s を装備した" % held_item_name)
	if removed_item_id != "":
		notify_message("%s を外した" % removed_item_name)

	held_entry = old_target_entry
	set_held_origin("equipment", -1, slot_name)
	refresh_status_ui()
	update_held_item_preview()


func drop_partial_held_entry_to_inventory(target_index: int, move_amount: int) -> void:
	if current_inventory == null:
		return

	var moved_entry: Dictionary = create_partial_held_entry(move_amount)
	if moved_entry.is_empty():
		return

	var source_area_before_swap: String = held_from_area
	var target_entry: Dictionary = current_inventory.get_item_data_at(target_index)

	if is_empty_entry(target_entry):
		if not notify_trade_transfer_if_needed("inventory", moved_entry, source_area_before_swap):
			return

		current_inventory.set_item_data_at(target_index, movedEntryFix(moved_entry))
		consume_held_amount(move_amount)
		return

	if can_merge_entries(moved_entry, target_entry):
		if not notify_trade_transfer_if_needed("inventory", moved_entry, source_area_before_swap):
			return

		apply_trade_price_to_entry(target_entry, moved_entry)
		var remaining: int = merge_entries(moved_entry, target_entry)
		current_inventory.set_item_data_at(target_index, target_entry)
		consume_held_amount(move_amount - remaining)
		return


func drop_partial_held_entry_to_trade(target_index: int, move_amount: int) -> void:
	if trade_inventory == null:
		return

	var moved_entry: Dictionary = create_partial_held_entry(move_amount)
	if moved_entry.is_empty():
		return

	var source_area_before_swap: String = held_from_area
	var target_entry: Dictionary = trade_inventory.get_item_data_at(target_index)

	if is_empty_entry(target_entry):
		if not notify_trade_transfer_if_needed("trade", moved_entry, source_area_before_swap):
			return

		trade_inventory.set_item_data_at(target_index, moved_entry)
		consume_held_amount(move_amount)
		return

	if can_merge_entries(moved_entry, target_entry):
		if not notify_trade_transfer_if_needed("trade", moved_entry, source_area_before_swap):
			return

		apply_trade_price_to_entry(target_entry, moved_entry)
		var remaining: int = merge_entries(moved_entry, target_entry)
		trade_inventory.set_item_data_at(target_index, target_entry)
		consume_held_amount(move_amount - remaining)
		return


func create_partial_held_entry(move_amount: int) -> Dictionary:
	if is_empty_entry(held_entry):
		return {}

	var amount: int = int(held_entry.get("amount", 0))
	if amount <= 0:
		return {}

	var result: Dictionary = held_entry.duplicate(true)
	result["amount"] = min(move_amount, amount)
	return result


func consume_held_amount(amount: int) -> void:
	if amount <= 0:
		return

	var held_amount: int = int(held_entry.get("amount", 0))
	held_amount -= amount

	if held_amount <= 0:
		clear_held_state()
	else:
		held_entry["amount"] = held_amount
		update_held_item_preview()


func notify_trade_transfer_if_needed(target_area: String, moved_entry: Dictionary, source_area: String = "") -> bool:
	if typeof(moved_entry) != TYPE_DICTIONARY:
		return true

	var item_id: String = String(moved_entry.get("item_id", ""))
	if item_id == "":
		return true

	var amount: int = int(moved_entry.get("amount", 0))
	if amount <= 0:
		return true

	var actual_source_area: String = source_area
	if actual_source_area == "":
		actual_source_area = held_from_area

	if ui_mode == UIMode.CHEST:
		if trade_unit != null:
			if actual_source_area == "trade":
				if target_area == "inventory" or target_area == "hotbar" or target_area == "equipment":
					if trade_unit.has_method("can_player_take_item"):
						if not bool(trade_unit.can_player_take_item(item_id)):
							notify_message("このチェストからは取り出せない")
							return false

			if actual_source_area == "inventory" or actual_source_area == "hotbar" or actual_source_area == "equipment":
				if target_area == "trade":
					if trade_unit.has_method("can_player_put_item"):
						if not bool(trade_unit.can_player_put_item(item_id)):
							notify_message("このチェストには入れられない")
							return false

		return true

	if ui_mode != UIMode.TRADE:
		return true

	if actual_source_area == "trade":
		if target_area == "inventory" or target_area == "hotbar" or target_area == "equipment":
			var unit_buy_price: int = get_entry_buy_price(moved_entry)
			var total_buy_price: int = unit_buy_price * amount

			if not try_spend_player_gold(total_buy_price):
				notify_message("お金が足りない")
				return false

			moved_entry["trade_buy_price"] = unit_buy_price
			moved_entry["trade_sell_price"] = unit_buy_price

			notify_message("%s x%d を買った（%dG）" % [
				ItemDatabase.get_display_name(item_id),
				amount,
				total_buy_price
			])
			refresh()
			return true

	if actual_source_area == "inventory" or actual_source_area == "hotbar" or actual_source_area == "equipment":
		if target_area == "trade":
			if not ItemDatabase.can_sell(item_id):
				notify_message("そのアイテムは売れない")
				return false

			var unit_sell_price: int = get_entry_sell_price(moved_entry)
			var total_sell_price: int = unit_sell_price * amount

			if not give_player_gold(total_sell_price):
				notify_message("ゴールドを追加できない")
				return false

			moved_entry["trade_buy_price"] = unit_sell_price
			moved_entry["trade_sell_price"] = unit_sell_price

			notify_message("%s x%d を売った（%dG）" % [
				ItemDatabase.get_display_name(item_id),
				amount,
				total_sell_price
			])
			refresh()
			return true

	return true



# =========================
# External HUD Hotbar Bridge
# =========================
# インベントリ画面内のホットバー欄は作らず、
# 通常時に表示されているHUDホットバーを直接操作するための入口。
# GameAndHud から、HUDホットバークリック時に呼ぶ。

func has_held_entry() -> bool:
	return not held_entry.is_empty()


func handle_external_hotbar_slot_pressed(hotbar_index: int) -> bool:
	if not visible:
		return false

	if current_inventory == null:
		return false

	if not current_inventory.has_method("get_hotbar_slot_count"):
		return false

	var slot_count: int = int(current_inventory.get_hotbar_slot_count())
	if hotbar_index < 0 or hotbar_index >= slot_count:
		return false

	enter_mouse_navigation_mode()
	focus_area = "hotbar"
	selected_index = hotbar_index

	if held_entry.is_empty():
		var entry: Dictionary = current_inventory.get_hotbar_item_data_at(hotbar_index)
		if is_empty_entry(entry):
			return true
		pick_selected_entry()
	else:
		drop_held_entry_to_hotbar(hotbar_index)

	hide_tooltip()
	refresh()
	restart_tooltip_timer()
	return true


func handle_external_hotbar_slot_secondary_pressed(hotbar_index: int) -> bool:
	if not visible:
		return false

	if current_inventory == null:
		return false

	if not current_inventory.has_method("get_hotbar_slot_count"):
		return false

	var slot_count: int = int(current_inventory.get_hotbar_slot_count())
	if hotbar_index < 0 or hotbar_index >= slot_count:
		return false

	enter_mouse_navigation_mode()
	focus_area = "hotbar"
	selected_index = hotbar_index

	if held_entry.is_empty():
		pick_selected_entry_half()
	else:
		drop_held_entry_one_to_hotbar(hotbar_index)

	hide_tooltip()
	refresh()
	restart_tooltip_timer()
	return true


func restore_held_entry_on_close() -> bool:
	if held_entry.is_empty():
		return true

	if held_from_area == "hotbar":
		if current_inventory.has_method("is_hotbar_slot_empty") and current_inventory.is_hotbar_slot_empty(held_from_index):
			current_inventory.set_hotbar_item_data_at(held_from_index, held_entry)
			clear_held_state()
			return true

		if current_inventory.has_method("find_first_empty_hotbar_slot"):
			var empty_hotbar_index: int = current_inventory.find_first_empty_hotbar_slot()
			if empty_hotbar_index >= 0:
				current_inventory.set_hotbar_item_data_at(empty_hotbar_index, held_entry)
				clear_held_state()
				return true

		var empty_inventory_index_for_hotbar: int = current_inventory.find_first_empty_slot()
		if empty_inventory_index_for_hotbar >= 0:
			current_inventory.set_item_data_at(empty_inventory_index_for_hotbar, held_entry)
			clear_held_state()
			return true

		notify_message("空きスロットがないため閉じられない")
		return false

	if held_from_area == "inventory":
		if current_inventory.is_slot_empty(held_from_index):
			current_inventory.set_item_data_at(held_from_index, held_entry)
			clear_held_state()
			return true

		var empty_index: int = current_inventory.find_first_empty_slot()
		if empty_index >= 0:
			current_inventory.set_item_data_at(empty_index, held_entry)
			clear_held_state()
			return true

		notify_message("空きスロットがないため閉じられない")
		return false

	if held_from_area == "trade":
		if trade_inventory != null and trade_inventory.is_slot_empty(held_from_index):
			trade_inventory.set_item_data_at(held_from_index, held_entry)
			clear_held_state()
			return true

		if trade_inventory != null:
			var trade_empty_index: int = trade_inventory.find_first_empty_slot()
			if trade_empty_index >= 0:
				trade_inventory.set_item_data_at(trade_empty_index, held_entry)
				clear_held_state()
				return true

		notify_message("相手側に空きがないため閉じられない")
		return false

	if held_from_area == "equipment":
		var origin_entry: Dictionary = get_equipment_entry(held_from_slot_name)

		if is_empty_entry(origin_entry) and can_place_entry_in_equipment_slot(held_entry, held_from_slot_name):
			set_equipment_entry(held_from_slot_name, held_entry)
			clear_held_state()
			refresh_status_ui()
			return true

		var empty_inventory_index: int = current_inventory.find_first_empty_slot()
		if empty_inventory_index >= 0:
			current_inventory.set_item_data_at(empty_inventory_index, held_entry)
			clear_held_state()
			refresh_status_ui()
			return true

		notify_message("空きスロットがないため閉じられない")
		return false

	return true


func clear_held_state() -> void:
	held_entry = {}
	held_from_area = ""
	held_from_index = -1
	held_from_slot_name = ""


func can_merge_entries(source_entry: Dictionary, target_entry: Dictionary) -> bool:
	var source_id: String = String(source_entry.get("item_id", ""))
	var target_id: String = String(target_entry.get("item_id", ""))

	if source_id == "" or target_id == "":
		return false

	if source_id != target_id:
		return false

	if ItemDatabase.is_equipment(source_id):
		return false

	var source_buy_price: int = int(source_entry.get("trade_buy_price", -1))
	var target_buy_price: int = int(target_entry.get("trade_buy_price", -1))
	var source_sell_price: int = int(source_entry.get("trade_sell_price", -1))
	var target_sell_price: int = int(target_entry.get("trade_sell_price", -1))

	if source_buy_price != target_buy_price:
		return false
	if source_sell_price != target_sell_price:
		return false

	return ItemDatabase.get_max_stack(source_id) > 1


func merge_entries(source_entry: Dictionary, target_entry: Dictionary) -> int:
	var item_id: String = String(source_entry.get("item_id", ""))
	var source_amount: int = int(source_entry.get("amount", 0))
	var target_amount: int = int(target_entry.get("amount", 0))
	var max_stack: int = ItemDatabase.get_max_stack(item_id)

	var addable: int = min(max_stack - target_amount, source_amount)
	target_entry["amount"] = target_amount + addable

	return source_amount - addable


func can_place_entry_in_equipment_slot(entry: Dictionary, slot_name: String) -> bool:
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return false

	if amount != 1:
		return false

	if not ItemDatabase.is_equipment(item_id):
		return false

	if current_unit != null and current_unit.has_method("can_equip_item_id_to_slot"):
		return current_unit.can_equip_item_id_to_slot(item_id, slot_name)

	var item_slot: String = ItemDatabase.get_equipment_slot(item_id)

	if item_slot == "hand":
		return slot_name == "right_hand" or slot_name == "left_hand"

	if item_slot == "accessory":
		return slot_name.begins_with("accessory_")

	return item_slot == slot_name


func get_selected_entry() -> Dictionary:
	if focus_area == "inventory":
		return current_inventory.get_item_data_at(selected_index)

	if focus_area == "hotbar":
		return current_inventory.get_hotbar_item_data_at(selected_index)

	if focus_area == "trade":
		return trade_inventory.get_item_data_at(selected_index)

	var slot_name: String = String(equipment_slot_order[selected_index])
	return get_equipment_entry(slot_name)


func get_equipment_entry(slot_name: String) -> Dictionary:
	if current_unit == null:
		return {}

	if current_unit.has_method("get_equipped_item_entry"):
		return current_unit.get_equipped_item_entry(slot_name)

	return {}


func set_equipment_entry(slot_name: String, entry: Dictionary) -> bool:
	if current_unit == null:
		return false

	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		if current_unit.has_method("clear_equipment_slot"):
			current_unit.clear_equipment_slot(slot_name)
			return true
		return false

	if current_unit.has_method("set_equipped_entry"):
		return current_unit.set_equipped_entry(slot_name, entry)

	if current_unit.has_method("set_equipped_item_entry"):
		return current_unit.set_equipped_item_entry(slot_name, entry)

	if current_unit.has_method("set_equipped_item_by_id"):
		return current_unit.set_equipped_item_by_id(slot_name, item_id)

	return false


func clear_equipment_entry(slot_name: String) -> void:
	if current_unit != null and current_unit.has_method("clear_equipment_slot"):
		current_unit.clear_equipment_slot(slot_name)


func is_empty_entry(entry: Dictionary) -> bool:
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))
	return item_id == "" or amount <= 0


func use_selected_item() -> void:
	if ui_mode == UIMode.TRADE or ui_mode == UIMode.CHEST:
		return

	if focus_area != "inventory" and focus_area != "hotbar":
		return

	if current_inventory == null:
		return

	if not held_entry.is_empty():
		return

	var result: Dictionary = {}
	if focus_area == "hotbar" and current_inventory.has_method("use_hotbar_item_at"):
		result = current_inventory.use_hotbar_item_at(selected_index)
	else:
		result = current_inventory.use_item_at(selected_index)

	if not bool(result.get("success", false)):
		return

	hide_tooltip()
	refresh()
	restart_tooltip_timer()
	refresh_status_ui()


func refresh_status_ui() -> void:
	var node: Node = self
	while node != null:
		if node.has_method("update_hud_player_status"):
			node.update_hud_player_status()

		if node.has_method("refresh_hud"):
			node.refresh_hud()

		node = node.get_parent()


func _get_slot_display_name(slot_name: String) -> String:
	match slot_name:
		"hand":
			return "手"
		"right_hand":
			return "右手"
		"left_hand":
			return "左手"
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
		"accessory":
			return "アクセサリー"
		_:
			return slot_name


func build_enchantment_tooltip_lines(entry: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var instance_data: Variant = entry.get("instance_data", {})
	if typeof(instance_data) != TYPE_DICTIONARY:
		return lines

	var enchantments: Variant = (instance_data as Dictionary).get("enchantments", [])
	if not (enchantments is Array):
		return lines

	for raw_data in enchantments:
		if typeof(raw_data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = raw_data
		var enchant_id: String = String(data.get("id", ""))
		var value: int = int(data.get("value", 0))
		match enchant_id:
			"atk_up_small":
				lines.append("エンチャント: 攻撃 +%d" % value)
			"def_up_small":
				lines.append("エンチャント: 防御 +%d" % value)
			"hp_up_small":
				lines.append("エンチャント: 最大HP +%d" % value)
			_:
				lines.append("エンチャント: %s +%d" % [enchant_id, value])

	return lines


func build_item_tooltip_lines(entry: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return lines

	if ItemDatabase.is_equipment(item_id):
		var eq = ItemDatabase.get_equipment_resource(item_id)
		if eq == null:
			return lines

		var slot_name: String = eq.get_slot_name()
		if slot_name != "":
			lines.append("部位: %s" % _get_slot_display_name(slot_name))

		if int(eq.attack_bonus) != 0:
			lines.append("攻撃 %s%d" % ["+" if eq.attack_bonus > 0 else "", eq.attack_bonus])

		if int(eq.defense_bonus) != 0:
			lines.append("防御 %s%d" % ["+" if eq.defense_bonus > 0 else "", eq.defense_bonus])

		if int(eq.max_hp_bonus) != 0:
			lines.append("最大HP %s%d" % ["+" if eq.max_hp_bonus > 0 else "", eq.max_hp_bonus])

		if int(eq.speed_bonus) != 0:
			lines.append("速度 %s%d" % ["+" if eq.speed_bonus > 0 else "", eq.speed_bonus])

		if slot_name == "hand" or slot_name == "right_hand" or slot_name == "left_hand":
			lines.append("射程 %d-%d" % [eq.attack_min_range, eq.attack_max_range])

		for line in build_enchantment_tooltip_lines(entry):
			lines.append(line)

		return lines

	for effect_line in ItemDatabase.get_effect_summary_lines(item_id):
		lines.append("効果: " + effect_line)

	return lines


func get_trade_price_lines(entry: Dictionary) -> Array[String]:
	var lines: Array[String] = []

	if typeof(entry) != TYPE_DICTIONARY:
		return lines

	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return lines

	if focus_area == "trade":
		var buy_price: int = get_entry_buy_price(entry)
		lines.append("買値: %dG" % buy_price)

	elif focus_area == "inventory" or focus_area == "equipment":
		if not ItemDatabase.can_sell(item_id):
			lines.append("売却不可")
		else:
			var sell_price: int = get_entry_sell_price(entry)
			lines.append("売値: %dG" % sell_price)

	return lines


func restart_tooltip_timer() -> void:
	hide_tooltip()

	if tooltip_timer == null:
		return

	if is_failed_quest_dialog_locked():
		return

	tooltip_timer.stop()

	if not visible:
		return

	if is_building_slots:
		return

	if not held_entry.is_empty():
		return

	if focus_area == "trade_back":
		return

	var entry: Dictionary = get_selected_entry()
	if is_empty_entry(entry):
		return

	tooltip_timer.start()


func show_tooltip_for_selected() -> void:
	if is_failed_quest_dialog_locked():
		hide_tooltip()
		return

	if not held_entry.is_empty():
		hide_tooltip()
		return

	if focus_area == "trade_back":
		hide_tooltip()
		return

	var entry: Dictionary = get_selected_entry()
	if is_empty_entry(entry):
		hide_tooltip()
		return

	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	tooltip_name_label.text = "%s x%d" % [ItemDatabase.get_display_name(item_id), amount]

	var desc: String = ItemDatabase.get_description(item_id)
	var extra_lines: Array[String] = build_item_tooltip_lines(entry)

	if ui_mode == UIMode.TRADE:
		var price_lines: Array[String] = get_trade_price_lines(entry)
		for line in price_lines:
			extra_lines.append(line)

	if extra_lines.is_empty():
		tooltip_desc_label.text = desc
	else:
		if desc == "":
			tooltip_desc_label.text = "\n".join(extra_lines)
		else:
			tooltip_desc_label.text = desc + "\n" + "\n".join(extra_lines)

	var usable_text: String = "使用可能" if ItemDatabase.is_usable(item_id) else "使用不可"
	if ui_mode == UIMode.TRADE:
		usable_text = "取引中は使用不可"

	tooltip_meta_label.text = "種別: %s / %s" % [ItemDatabase.get_item_type(item_id), usable_text]

	var slot = get_selected_slot_node()
	if slot == null:
		hide_tooltip()
		return

	var slot_rect = slot.get_global_rect()

	tooltip_panel.reset_size()
	await get_tree().process_frame

	var panel_size: Vector2 = tooltip_panel.size
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()

	var target_x: float = slot_rect.position.x + slot_rect.size.x + 12.0
	var target_y: float = slot_rect.position.y

	if target_x + panel_size.x > viewport_rect.position.x + viewport_rect.size.x:
		target_x = slot_rect.position.x - panel_size.x - 12.0

	if target_y + panel_size.y > viewport_rect.position.y + viewport_rect.size.y:
		target_y = viewport_rect.position.y + viewport_rect.size.y - panel_size.y - 12.0

	if target_y < viewport_rect.position.y + 12.0:
		target_y = viewport_rect.position.y + 12.0

	tooltip_panel.global_position = Vector2(target_x, target_y)
	tooltip_panel.show()


func _held_entry_has_enchantments() -> bool:
	if held_entry.is_empty():
		return false

	var instance_data: Variant = held_entry.get("instance_data", {})
	if typeof(instance_data) != TYPE_DICTIONARY:
		return false

	var enchantments: Variant = (instance_data as Dictionary).get("enchantments", [])
	return enchantments is Array and not enchantments.is_empty()


func _get_or_create_held_enchant_overlay() -> ColorRect:
	if held_item_preview == null:
		return null

	var existing: Node = held_item_preview.get_node_or_null("EnchantOverlay")
	if existing is ColorRect:
		return existing

	var rect: ColorRect = ColorRect.new()
	rect.name = "EnchantOverlay"
	rect.color = Color(0.7, 0.35, 0.95, 0.28)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	held_item_preview.add_child(rect)
	if held_item_icon != null:
		held_item_preview.move_child(rect, held_item_icon.get_index() + 1)
	return rect


func update_held_item_preview() -> void:
	if held_item_preview == null:
		return

	var enchant_overlay: ColorRect = _get_or_create_held_enchant_overlay()
	ensure_mouse_passthrough_for_float_panels()

	if is_failed_quest_dialog_locked():
		if enchant_overlay != null:
			enchant_overlay.visible = false
		held_item_preview.hide()
		held_item_preview_position_initialized = false
		return

	if held_entry.is_empty():
		if enchant_overlay != null:
			enchant_overlay.visible = false
		held_item_preview.hide()
		held_item_preview_position_initialized = false
		return

	var item_id: String = String(held_entry.get("item_id", ""))
	var amount: int = int(held_entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		if enchant_overlay != null:
			enchant_overlay.visible = false
		held_item_preview.hide()
		held_item_preview_position_initialized = false
		return

	var icon_texture: Texture2D = _get_display_item_icon(item_id)
	held_item_icon.texture = icon_texture
	held_item_icon.modulate = Color(1, 1, 1, 0.9)
	held_item_amount_label.modulate = Color(1, 1, 1, 1)

	var base_size: Vector2 = get_selected_slot_visual_size()
	var preview_size: Vector2 = base_size * 0.9

	if preview_size.x < 16.0:
		preview_size.x = 16.0
	if preview_size.y < 16.0:
		preview_size.y = 16.0

	held_item_preview.custom_minimum_size = preview_size
	held_item_preview.size = preview_size

	held_item_icon.custom_minimum_size = preview_size
	held_item_icon.size = preview_size
	held_item_icon.offset_left = 0.0
	held_item_icon.offset_top = 0.0
	held_item_icon.offset_right = preview_size.x
	held_item_icon.offset_bottom = preview_size.y

	if enchant_overlay != null:
		enchant_overlay.position = Vector2.ZERO
		enchant_overlay.size = preview_size
		enchant_overlay.visible = _held_entry_has_enchantments()

	if amount > 1:
		held_item_amount_label.text = "x%d" % amount
	else:
		held_item_amount_label.text = ""

	held_item_amount_label.offset_left = max(0.0, preview_size.x - 30.0)
	held_item_amount_label.offset_top = max(0.0, preview_size.y - 22.0)
	held_item_amount_label.offset_right = preview_size.x + 12.0
	held_item_amount_label.offset_bottom = preview_size.y + 4.0

	held_item_preview_target_global_position = get_held_item_preview_target_position(preview_size)

	if not held_item_preview.visible or not held_item_preview_position_initialized:
		held_item_preview.global_position = held_item_preview_target_global_position
		held_item_preview_position_initialized = true

	held_item_preview.show()


func update_held_item_preview_motion(delta: float) -> void:
	if held_item_preview == null:
		return

	if not held_item_preview.visible:
		return

	if held_entry.is_empty():
		return

	var preview_size: Vector2 = held_item_preview.size
	if preview_size == Vector2.ZERO:
		preview_size = get_selected_slot_visual_size() * 0.9

	held_item_preview_target_global_position = get_held_item_preview_target_position(preview_size)

	if not held_item_preview_follow_mouse:
		held_item_preview.global_position = held_item_preview_target_global_position
		return

	if held_item_preview_snap_to_mouse_center:
		held_item_preview.global_position = held_item_preview_target_global_position
		return

	var speed: float = max(1.0, held_item_preview_smooth_speed)
	var weight: float = clamp(delta * speed, 0.0, 1.0)
	held_item_preview.global_position = held_item_preview.global_position.lerp(held_item_preview_target_global_position, weight)


func get_held_item_preview_target_position(preview_size: Vector2) -> Vector2:
	var target_position: Vector2

	if held_item_preview_follow_mouse:
		# CanvasLayer上のControlなので、viewport座標をそのままglobal_positionとして使う。
		# アイテムの中心がマウスポインターに重なるようにする。
		var mouse_position: Vector2 = get_viewport().get_mouse_position()
		if held_item_preview_center_on_mouse:
			target_position = mouse_position - preview_size * 0.5 + held_item_preview_mouse_offset
		else:
			target_position = mouse_position + held_item_preview_mouse_offset
	else:
		# 保険: マウス追従を切った場合だけ、最後に選択しているスロット位置へ置く。
		var slot = get_selected_slot_node()
		if slot == null:
			var mouse_position: Vector2 = get_viewport().get_mouse_position()
			if held_item_preview_center_on_mouse:
				target_position = mouse_position - preview_size * 0.5 + held_item_preview_mouse_offset
			else:
				target_position = mouse_position + held_item_preview_mouse_offset
		else:
			var slot_rect: Rect2 = slot.get_global_rect()
			target_position = Vector2(
				slot_rect.position.x + (slot_rect.size.x - preview_size.x) * 0.5,
				slot_rect.position.y + (slot_rect.size.y - preview_size.y) * 0.5 - 6.0
			)

	if held_item_preview_clamp_to_viewport:
		var viewport_rect: Rect2 = get_viewport().get_visible_rect()
		target_position.x = clamp(
			target_position.x,
			viewport_rect.position.x + 4.0,
			viewport_rect.position.x + viewport_rect.size.x - preview_size.x - 4.0
		)
		target_position.y = clamp(
			target_position.y,
			viewport_rect.position.y + 4.0,
			viewport_rect.position.y + viewport_rect.size.y - preview_size.y - 4.0
		)

	return target_position

func get_selected_slot_visual_size() -> Vector2:
	var slot = get_selected_slot_node()
	if slot == null:
		return Vector2(48, 48)

	var rect: Rect2 = slot.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		if slot is Control:
			var control_slot: Control = slot as Control
			if control_slot.size.x > 0.0 and control_slot.size.y > 0.0:
				return control_slot.size
			if control_slot.custom_minimum_size.x > 0.0 and control_slot.custom_minimum_size.y > 0.0:
				return control_slot.custom_minimum_size
		return Vector2(48, 48)

	return rect.size


func get_selected_slot_node():
	if focus_area == "trade":
		if selected_index < 0 or selected_index >= trade_slot_grid.get_child_count():
			return null
		return trade_slot_grid.get_child(selected_index)

	if focus_area == "inventory":
		if selected_index < 0 or selected_index >= slot_grid.get_child_count():
			return null
		return slot_grid.get_child(selected_index)

	if focus_area == "equipment":
		if selected_index < 0 or selected_index >= equipment_slot_nodes.size():
			return null
		return equipment_slot_nodes[selected_index]

	if focus_area == "trade_back":
		return null

	return null


func hide_tooltip() -> void:
	if tooltip_panel != null:
		tooltip_panel.hide()


func _on_tooltip_timer_timeout() -> void:
	if not visible:
		return

	if is_failed_quest_dialog_locked():
		hide_tooltip()
		return

	await show_tooltip_for_selected()


func notify_message(text: String) -> void:
	if current_unit != null and current_unit.has_method("notify_hud_log"):
		current_unit.notify_hud_log(text)
	else:
		print(text)


func movedEntryFix(entry: Dictionary) -> Dictionary:
	return entry
