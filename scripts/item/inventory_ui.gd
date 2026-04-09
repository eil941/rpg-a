extends CanvasLayer

enum UIMode {
	NORMAL,
	TRADE,
	CHEST
}

@onready var root = $Root
@onready var main_hbox = $Root/Overlay/CenterContainer/MainHBox

@onready var trade_panel = $Root/Overlay/CenterContainer/MainHBox/TradePanel
@onready var trade_margin = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer
@onready var trade_title_label = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer/TradeVBox/TitleLabel
@onready var trade_slot_grid = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer/TradeVBox/SlotGrid
@onready var trade_back_button = $Root/Overlay/CenterContainer/MainHBox/TradePanel/MarginContainer/TradeVBox/BackButton

@onready var inventory_panel = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel
@onready var inventory_margin = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer
@onready var title_label = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/TitleLabel
@onready var slot_grid = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/SlotGrid
@onready var help_label = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/HelpLabel

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


func _ready() -> void:
	layer = 10
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()

	title_label.text = "Inventory"
	trade_title_label.text = "Trade"
	help_label.text = "主操作: 全部持つ/置く/交換 / 副操作: 半分持つ・1個置く / 使用キー: 使用 / Esc: 閉じる"

	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = tooltip_delay
	add_child(tooltip_timer)
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

	if trade_back_button != null:
		trade_back_button.toggle_mode = true
		trade_back_button.focus_mode = Control.FOCUS_NONE
		trade_back_button.pressed.connect(_on_trade_back_button_pressed)

	tooltip_panel.hide()
	held_item_preview.hide()

	apply_ui_config()
	apply_side_panel_visuals_for_mode()
	update_background_visibility()
	update_trade_panel_visibility()
	set_process(true)


func apply_ui_config() -> void:
	if ui_config == null:
		return

	if ui_config.inventory_max_slots > 0 and current_inventory != null:
		if current_inventory.has_method("resize_inventory"):
			current_inventory.resize_inventory(ui_config.inventory_max_slots)
		else:
			current_inventory.max_slots = ui_config.inventory_max_slots

	if ui_config.inventory_panel_size != Vector2.ZERO:
		inventory_panel.custom_minimum_size = ui_config.inventory_panel_size

	if ui_config.equipment_panel_size != Vector2.ZERO:
		equipment_panel.custom_minimum_size = ui_config.equipment_panel_size

	if ui_config.inventory_columns > 0:
		slot_grid.columns = ui_config.inventory_columns
		trade_slot_grid.columns = ui_config.inventory_columns

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

	if inventory_bg != null and ui_config.inventory_background != null:
		inventory_bg.texture = ui_config.inventory_background
	if trade_bg != null and ui_config.inventory_background != null:
		trade_bg.texture = ui_config.inventory_background
	if equipment_bg != null and ui_config.equipment_background != null:
		equipment_bg.texture = ui_config.equipment_background


func get_chest_ui_data() -> ChestData:
	if ui_mode != UIMode.CHEST:
		return null

	if trade_unit == null:
		return null

	if "chest_data" in trade_unit:
		return trade_unit.chest_data

	return null


func apply_side_panel_visuals_for_mode() -> void:
	if ui_mode == UIMode.CHEST:
		var chest_data: ChestData = get_chest_ui_data()

		if chest_data != null:
			if trade_slot_grid != null and chest_data.ui_slot_columns > 0:
				trade_slot_grid.columns = chest_data.ui_slot_columns

			if trade_panel != null and chest_data.ui_panel_min_size != Vector2.ZERO:
				trade_panel.custom_minimum_size = chest_data.ui_panel_min_size

			if trade_bg != null and chest_data.ui_background != null:
				trade_bg.texture = chest_data.ui_background
		else:
			if ui_config != null:
				if ui_config.inventory_columns > 0 and trade_slot_grid != null:
					trade_slot_grid.columns = ui_config.inventory_columns
				if ui_config.inventory_panel_size != Vector2.ZERO and trade_panel != null:
					trade_panel.custom_minimum_size = ui_config.inventory_panel_size
				if trade_bg != null and ui_config.inventory_background != null:
					trade_bg.texture = ui_config.inventory_background
	else:
		if ui_config != null:
			if ui_config.inventory_columns > 0 and trade_slot_grid != null:
				trade_slot_grid.columns = ui_config.inventory_columns

			if ui_config.inventory_panel_size != Vector2.ZERO and trade_panel != null:
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

	if trade_back_button != null:
		trade_back_button.visible = side_visible


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


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_right"):
		move_selection(1, 0)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left"):
		move_selection(-1, 0)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		move_selection(0, 1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		move_selection(0, -1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_quick_move_primary"):
		handle_quick_move_primary_action()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_quick_move_secondary"):
		handle_quick_move_secondary_action()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_secondary_action"):
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
		handle_confirm_action()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_use"):
		use_selected_item()
		get_viewport().set_input_as_handled()
		return


func _process(delta: float) -> void:
	if visible:
		refresh()

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


func get_inventory_slot_count() -> int:
	if current_inventory == null:
		return 0
	return current_inventory.max_slots


func get_trade_slot_count() -> int:
	if trade_inventory == null:
		return 0
	return trade_inventory.max_slots


func get_equipment_slot_count() -> int:
	return equipment_slot_order.size()


func rebuild_inventory_slots_if_needed() -> void:
	if current_inventory == null:
		return

	var target_count: int = current_inventory.max_slots
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

	await get_tree().process_frame

	is_building_slots = false


func rebuild_trade_slots_if_needed() -> void:
	if trade_inventory == null:
		for child in trade_slot_grid.get_children():
			child.queue_free()
		await get_tree().process_frame
		return

	var target_count: int = trade_inventory.max_slots
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

	await get_tree().process_frame

	is_building_slots = false


func build_equipment_slots() -> void:
	equipment_slot_nodes.clear()

	for child in equipment_vbox.get_children():
		child.queue_free()

	for slot_name in equipment_slot_order:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 8)

		var label = Label.new()
		label.custom_minimum_size = Vector2(72, 0)
		label.text = slot_name.capitalize()

		var slot = slot_scene.instantiate()

		if ui_config != null and slot.has_method("apply_config"):
			slot.apply_config(
				ui_config.equipment_slot_size,
				ui_config.equipment_icon_margin
			)

		row.add_child(label)
		row.add_child(slot)

		equipment_vbox.add_child(row)
		equipment_slot_nodes.append(slot)


func refresh() -> void:
	refresh_trade_slots()
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
				slot.set_item_entry(entry, ItemDatabase.get_item_icon(item_id))
			else:
				var amount: int = int(entry.get("amount", 0))
				slot.set_slot_data(item_id, amount, ItemDatabase.get_item_icon(item_id))
		else:
			if slot.has_method("set_item_entry"):
				slot.set_item_entry({}, null)
			else:
				slot.set_slot_data("", 0, null)

		slot.set_selected(focus_area == "trade" and i == selected_index)


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
				slot.set_item_entry(entry, ItemDatabase.get_item_icon(item_id))
			else:
				var amount: int = int(entry.get("amount", 0))
				slot.set_slot_data(item_id, amount, ItemDatabase.get_item_icon(item_id))
		else:
			if slot.has_method("set_item_entry"):
				slot.set_item_entry({}, null)
			else:
				slot.set_slot_data("", 0, null)

		slot.set_selected(focus_area == "inventory" and i == selected_index)


func refresh_equipment_slots() -> void:
	for i in range(equipment_slot_nodes.size()):
		var slot = equipment_slot_nodes[i]
		var slot_name: String = String(equipment_slot_order[i])

		var entry: Dictionary = get_equipment_entry(slot_name)
		var item_id: String = String(entry.get("item_id", ""))

		if slot.has_method("set_item_entry"):
			slot.set_item_entry(entry, ItemDatabase.get_item_icon(item_id))
		else:
			var amount: int = int(entry.get("amount", 0))
			slot.set_slot_data(item_id, amount, ItemDatabase.get_item_icon(item_id))

		slot.set_selected(focus_area == "equipment" and i == selected_index)


func refresh_trade_back_button() -> void:
	if trade_back_button == null:
		return

	if not is_side_mode():
		trade_back_button.button_pressed = false
		return

	trade_back_button.button_pressed = (focus_area == "trade_back")


func update_help_text() -> void:
	var text: String = "Enter: 持つ/置く/交換 / Shift+Enter: 1個持つ / Ctrl+Enter: 1個置く / 使用キー: 使用 / Esc: 閉じる"

	if ui_mode == UIMode.TRADE:
		text = "Enter: 持つ/置く/交換 / Shift+Enter: 1個持つ / Ctrl+Enter: 1個置く / 使用不可 / Esc: 閉じる"
		text += "\n所持金: %dG" % get_player_gold_amount()
	elif ui_mode == UIMode.CHEST:
		text = "Enter: 持つ/置く/交換 / Shift+Enter: 1個持つ / Ctrl+Enter: 1個置く / 使用不可 / Esc: 閉じる"

	if not held_entry.is_empty():
		var held_name: String = ItemDatabase.get_display_name(String(held_entry.get("item_id", "")))
		var held_amount: int = int(held_entry.get("amount", 0))
		text += "\n持ち中: %s x%d" % [held_name, held_amount]

	help_label.text = text


func move_selection(dx: int, dy: int) -> void:
	if is_building_slots:
		return

	if focus_area == "trade":
		move_trade_selection(dx, dy)
	elif focus_area == "inventory":
		move_inventory_selection(dx, dy)
	elif focus_area == "equipment":
		move_equipment_selection(dx, dy)
	else:
		move_trade_back_selection(dx, dy)

	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func move_trade_selection(dx: int, dy: int) -> void:
	var slot_count: int = get_trade_slot_count()
	if slot_count <= 0:
		if dx > 0:
			focus_area = "inventory"
			selected_index = 0
		elif dy > 0:
			focus_area = "trade_back"
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
		focus_area = "trade_back"
		selected_index = 0
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

	if dx < 0:
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

	var new_index: int = selected_index + dy
	new_index = clamp(new_index, 0, slot_count - 1)
	selected_index = new_index


func move_trade_back_selection(dx: int, dy: int) -> void:
	if not is_side_mode():
		return

	if dy < 0:
		var trade_count: int = get_trade_slot_count()
		if trade_count <= 0:
			focus_area = "trade"
			selected_index = 0
			return

		var columns: int = trade_slot_grid.columns
		if columns <= 0:
			columns = 1

		var max_row: int = int(ceil(float(trade_count) / float(columns))) - 1
		var target_index: int = max_row * columns
		target_index = clamp(target_index, 0, max(trade_count - 1, 0))

		focus_area = "trade"
		selected_index = target_index
		return


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
		else:
			trade_inventory.clear_slot(selected_index)
	else:
		entry["amount"] = remaining_amount
		if focus_area == "inventory":
			current_inventory.set_item_data_at(selected_index, entry)
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
			else:
				trade_inventory.clear_slot(selected_index)
		else:
			entry["amount"] = amount - 1
			if focus_area == "inventory":
				current_inventory.set_item_data_at(selected_index, entry)
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
			else:
				trade_inventory.clear_slot(selected_index)
		else:
			entry["amount"] = amount - 1
			if focus_area == "inventory":
				current_inventory.set_item_data_at(selected_index, entry)
			else:
				trade_inventory.set_item_data_at(selected_index, entry)

		update_held_item_preview()
		return

	pick_selected_entry()


func drop_held_entry() -> void:
	if focus_area == "inventory":
		drop_held_entry_to_inventory(selected_index)
	elif focus_area == "trade":
		drop_held_entry_to_trade(selected_index)
	else:
		drop_held_entry_to_equipment(String(equipment_slot_order[selected_index]))


func drop_held_entry_one() -> void:
	if focus_area == "inventory":
		drop_held_entry_one_to_inventory(selected_index)
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
				if target_area == "inventory" or target_area == "equipment":
					if trade_unit.has_method("can_player_take_item"):
						if not bool(trade_unit.can_player_take_item(item_id)):
							notify_message("このチェストからは取り出せない")
							return false

			if actual_source_area == "inventory" or actual_source_area == "equipment":
				if target_area == "trade":
					if trade_unit.has_method("can_player_put_item"):
						if not bool(trade_unit.can_player_put_item(item_id)):
							notify_message("このチェストには入れられない")
							return false

		return true

	if ui_mode != UIMode.TRADE:
		return true

	if actual_source_area == "trade":
		if target_area == "inventory" or target_area == "equipment":
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

	if actual_source_area == "inventory" or actual_source_area == "equipment":
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


func restore_held_entry_on_close() -> bool:
	if held_entry.is_empty():
		return true

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

	if focus_area != "inventory":
		return

	if current_inventory == null:
		return

	if not held_entry.is_empty():
		return

	var result: Dictionary = current_inventory.use_item_at(selected_index)

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

	var effect_type: String = ItemDatabase.get_effect_type(item_id)
	var effect_value: int = ItemDatabase.get_effect_value(item_id)

	match effect_type:
		"heal_hp":
			lines.append("効果: HPを%d回復" % effect_value)
		"log_only":
			pass
		_:
			if effect_type != "":
				lines.append("効果: %s (%d)" % [effect_type, effect_value])

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

	var rect := ColorRect.new()
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

	if held_entry.is_empty():
		if enchant_overlay != null:
			enchant_overlay.visible = false
		held_item_preview.hide()
		return

	var item_id: String = String(held_entry.get("item_id", ""))
	var amount: int = int(held_entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		if enchant_overlay != null:
			enchant_overlay.visible = false
		held_item_preview.hide()
		return

	var icon_texture: Texture2D = ItemDatabase.get_item_icon(item_id)
	held_item_icon.texture = icon_texture
	held_item_icon.modulate = Color(1, 1, 1, 0.9)
	held_item_amount_label.modulate = Color(1, 1, 1, 1)

	var base_size: Vector2 = get_selected_slot_visual_size()
	var preview_size: Vector2 = base_size * 0.9

	if preview_size.x < 16.0:
		preview_size.x = 16.0
	if preview_size.y < 16.0:
		preview_size.y = 16.0

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

	var slot = get_selected_slot_node()
	if slot == null:
		if enchant_overlay != null:
			enchant_overlay.visible = false
		held_item_preview.hide()
		return

	var slot_rect = slot.get_global_rect()

	var preview_pos: Vector2 = Vector2(
		slot_rect.position.x + (slot_rect.size.x - preview_size.x) * 0.5,
		slot_rect.position.y + (slot_rect.size.y - preview_size.y) * 0.5 - 6.0
	)

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()

	if preview_pos.x + preview_size.x > viewport_rect.position.x + viewport_rect.size.x:
		preview_pos.x = viewport_rect.position.x + viewport_rect.size.x - preview_size.x - 8.0

	if preview_pos.y < viewport_rect.position.y + 8.0:
		preview_pos.y = viewport_rect.position.y + 8.0

	held_item_preview.global_position = preview_pos
	held_item_preview.show()


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
		return trade_back_button

	return null


func hide_tooltip() -> void:
	if tooltip_panel != null:
		tooltip_panel.hide()


func _on_tooltip_timer_timeout() -> void:
	if not visible:
		return

	await show_tooltip_for_selected()


func notify_message(text: String) -> void:
	if current_unit != null and current_unit.has_method("notify_hud_log"):
		current_unit.notify_hud_log(text)
	else:
		print(text)


func movedEntryFix(entry: Dictionary) -> Dictionary:
	return entry
