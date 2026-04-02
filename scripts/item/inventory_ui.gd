extends CanvasLayer

@onready var root = $Root
@onready var main_hbox = $Root/Overlay/CenterContainer/MainHBox

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

var current_inventory = null
var current_unit = null

var focus_area = "inventory"
var selected_index = 0

var held_entry = {}
var held_from_area = ""
var held_from_index = -1
var held_from_slot_name = ""

var tooltip_timer = null
var is_building_slots = false

var equipment_slot_order = ["weapon", "armor", "accessory"]
var equipment_slot_nodes = []


func _ready() -> void:
	layer = 10
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()

	title_label.text = "Inventory"
	help_label.text = "Enter: 持つ/置く/交換 / 使用キー: 使用 / Iキー: 閉じる"

	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = tooltip_delay
	add_child(tooltip_timer)
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

	tooltip_panel.hide()
	held_item_preview.hide()

	apply_ui_config()
	update_background_visibility()


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

	if ui_config.main_hbox_separation >= 0:
		main_hbox.add_theme_constant_override("separation", ui_config.main_hbox_separation)

	if ui_config.inventory_margin_left >= 0:
		inventory_margin.add_theme_constant_override("margin_left", ui_config.inventory_margin_left)
	if ui_config.inventory_margin_top >= 0:
		inventory_margin.add_theme_constant_override("margin_top", ui_config.inventory_margin_top)
	if ui_config.inventory_margin_right >= 0:
		inventory_margin.add_theme_constant_override("margin_right", ui_config.inventory_margin_right)
	if ui_config.inventory_margin_bottom >= 0:
		inventory_margin.add_theme_constant_override("margin_bottom", ui_config.inventory_margin_bottom)

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

	if equipment_bg != null and ui_config.equipment_background != null:
		equipment_bg.texture = ui_config.equipment_background


func update_background_visibility() -> void:
	if inventory_bg != null:
		inventory_bg.visible = inventory_bg.texture != null

	if equipment_bg != null:
		equipment_bg.visible = equipment_bg.texture != null


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
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

	if event.is_action_pressed("ui_accept"):
		handle_confirm_action()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory_use"):
		use_selected_item()
		get_viewport().set_input_as_handled()
		return


func open_with_inventory(inventory) -> void:
	current_inventory = inventory
	current_unit = null

	if current_inventory != null:
		current_unit = current_inventory.get_parent()

	if current_unit != null and current_unit.has_method("get_equipment_slot_order"):
		equipment_slot_order = current_unit.get_equipment_slot_order()

	apply_ui_config()
	update_background_visibility()

	await rebuild_inventory_slots_if_needed()
	build_equipment_slots()

	focus_area = "inventory"
	selected_index = clamp(selected_index, 0, max(get_inventory_slot_count() - 1, 0))

	refresh()
	show()
	restart_tooltip_timer()


func close_inventory() -> void:
	if not restore_held_entry_on_close():
		return

	hide_tooltip()
	held_item_preview.hide()

	if tooltip_timer != null:
		tooltip_timer.stop()

	hide()


func toggle_with_inventory(inventory) -> void:
	if visible:
		close_inventory()
	else:
		await open_with_inventory(inventory)


func get_inventory_slot_count() -> int:
	if current_inventory == null:
		return 0
	return current_inventory.max_slots


func get_equipment_slot_count() -> int:
	return equipment_slot_order.size()


func rebuild_inventory_slots_if_needed() -> void:
	if current_inventory == null:
		return

	var target_count = current_inventory.max_slots
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
	refresh_inventory_slots()
	refresh_equipment_slots()
	update_help_text()
	update_held_item_preview()


func refresh_inventory_slots() -> void:
	if current_inventory == null:
		return

	var items = current_inventory.get_all_items()
	var child_count = slot_grid.get_child_count()

	for i in range(child_count):
		var slot = slot_grid.get_child(i)
		if slot == null:
			continue

		if i < items.size():
			var entry = items[i]
			var item_id = String(entry.get("item_id", ""))
			var amount = int(entry.get("amount", 0))
			slot.set_slot_data(item_id, amount, ItemDatabase.get_item_icon(item_id))
		else:
			slot.set_slot_data("", 0, null)

		slot.set_selected(focus_area == "inventory" and i == selected_index)


func refresh_equipment_slots() -> void:
	for i in range(equipment_slot_nodes.size()):
		var slot = equipment_slot_nodes[i]
		var slot_name = equipment_slot_order[i]

		var entry = get_equipment_entry(slot_name)
		var item_id = String(entry.get("item_id", ""))
		var amount = int(entry.get("amount", 0))

		slot.set_slot_data(item_id, amount, ItemDatabase.get_item_icon(item_id))
		slot.set_selected(focus_area == "equipment" and i == selected_index)


func update_help_text() -> void:
	var text = "Enter: 持つ/置く/交換 / 使用キー: 使用 / Iキー: 閉じる"

	if not held_entry.is_empty():
		var held_name = ItemDatabase.get_display_name(String(held_entry.get("item_id", "")))
		var held_amount = int(held_entry.get("amount", 0))
		text += "\n持ち中: %s x%d" % [held_name, held_amount]

	help_label.text = text


func move_selection(dx: int, dy: int) -> void:
	if is_building_slots:
		return

	if focus_area == "inventory":
		move_inventory_selection(dx, dy)
	else:
		move_equipment_selection(dx, dy)

	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func move_inventory_selection(dx: int, dy: int) -> void:
	var slot_count = get_inventory_slot_count()
	if slot_count <= 0:
		return

	var columns = slot_grid.columns
	if columns <= 0:
		columns = 1

	var row = selected_index / columns
	var col = selected_index % columns

	if dx > 0 and col == columns - 1:
		focus_area = "equipment"
		selected_index = map_inventory_row_to_equipment_index(row)
		return

	col += dx
	row += dy

	if col < 0:
		col = 0
	if col >= columns:
		col = columns - 1

	var max_row = int(ceil(float(slot_count) / float(columns))) - 1
	if row < 0:
		row = 0
	if row > max_row:
		row = max_row

	var new_index = row * columns + col
	if new_index >= slot_count:
		new_index = slot_count - 1

	selected_index = max(new_index, 0)


func move_equipment_selection(dx: int, dy: int) -> void:
	var slot_count = get_equipment_slot_count()
	if slot_count <= 0:
		return

	if dx < 0:
		var target_row = map_equipment_index_to_inventory_row(selected_index)
		var columns = slot_grid.columns
		if columns <= 0:
			columns = 1

		var inventory_index = target_row * columns + (columns - 1)
		inventory_index = min(inventory_index, get_inventory_slot_count() - 1)
		inventory_index = max(inventory_index, 0)

		focus_area = "inventory"
		selected_index = inventory_index
		return

	var new_index = selected_index + dy
	new_index = clamp(new_index, 0, slot_count - 1)
	selected_index = new_index


func map_inventory_row_to_equipment_index(row: int) -> int:
	var inventory_count = get_inventory_slot_count()
	var columns = slot_grid.columns
	if columns <= 0:
		columns = 1

	var inventory_rows = int(ceil(float(inventory_count) / float(columns)))
	var equipment_count = get_equipment_slot_count()

	if equipment_count <= 1 or inventory_rows <= 1:
		return 0

	var ratio = float(row) * float(equipment_count - 1) / float(inventory_rows - 1)
	return clamp(int(round(ratio)), 0, equipment_count - 1)


func map_equipment_index_to_inventory_row(equipment_index: int) -> int:
	var inventory_count = get_inventory_slot_count()
	var columns = slot_grid.columns
	if columns <= 0:
		columns = 1

	var inventory_rows = int(ceil(float(inventory_count) / float(columns)))
	var equipment_count = get_equipment_slot_count()

	if equipment_count <= 1 or inventory_rows <= 1:
		return 0

	var ratio = float(equipment_index) * float(inventory_rows - 1) / float(equipment_count - 1)
	return clamp(int(round(ratio)), 0, inventory_rows - 1)


func handle_confirm_action() -> void:
	if held_entry.is_empty():
		pick_selected_entry()
	else:
		drop_held_entry()

	hide_tooltip()
	refresh()
	restart_tooltip_timer()


func pick_selected_entry() -> void:
	var entry = get_selected_entry()
	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return

	held_entry = entry.duplicate(true)
	held_from_area = focus_area
	held_from_index = -1
	held_from_slot_name = ""

	if focus_area == "inventory":
		held_from_index = selected_index
		current_inventory.clear_slot(selected_index)
	else:
		held_from_slot_name = equipment_slot_order[selected_index]
		clear_equipment_entry(held_from_slot_name)
		notify_message("%s を外した" % ItemDatabase.get_display_name(item_id))
		refresh_status_ui()
		
	update_held_item_preview()

func drop_held_entry() -> void:
	if focus_area == "inventory":
		drop_held_entry_to_inventory(selected_index)
	else:
		drop_held_entry_to_equipment(equipment_slot_order[selected_index])


func drop_held_entry_to_inventory(target_index: int) -> void:
	var target_entry = current_inventory.get_item_data_at(target_index)

	if is_empty_entry(target_entry):
		current_inventory.set_item_data_at(target_index, held_entry)
		clear_held_state()
		return

	if can_merge_entries(held_entry, target_entry):
		var remaining = merge_entries(held_entry, target_entry)
		current_inventory.set_item_data_at(target_index, target_entry)

		if remaining <= 0:
			clear_held_state()
		else:
			held_entry["amount"] = remaining
		return

	if not can_return_entry_to_origin(target_entry):
		notify_message("そこには置けない")
		return

	var origin_area = held_from_area
	var origin_index = held_from_index
	var origin_slot_name = held_from_slot_name

	current_inventory.set_item_data_at(target_index, held_entry)

	if origin_area == "inventory":
		current_inventory.set_item_data_at(origin_index, target_entry)
	else:
		set_equipment_entry(origin_slot_name, target_entry)
		notify_message("%s を装備した" % ItemDatabase.get_display_name(String(target_entry.get("item_id", ""))))
		refresh_status_ui()

	clear_held_state()


func drop_held_entry_to_equipment(slot_name: String) -> void:
	if not can_place_entry_in_equipment_slot(held_entry, slot_name):
		notify_message("そこには装備できない")
		return

	var target_entry = get_equipment_entry(slot_name)
	var equipped_item_id = String(held_entry.get("item_id", ""))

	if is_empty_entry(target_entry):
		set_equipment_entry(slot_name, held_entry)
		notify_message("%s を装備した" % ItemDatabase.get_display_name(equipped_item_id))
		clear_held_state()
		refresh_status_ui()
		return

	if not can_return_entry_to_origin(target_entry):
		notify_message("交換できない")
		return

	var removed_item_id = String(target_entry.get("item_id", ""))

	var origin_area = held_from_area
	var origin_index = held_from_index
	var origin_slot_name = held_from_slot_name

	set_equipment_entry(slot_name, held_entry)

	if origin_area == "inventory":
		current_inventory.set_item_data_at(origin_index, target_entry)
	else:
		set_equipment_entry(origin_slot_name, target_entry)

	notify_message("%s を装備した" % ItemDatabase.get_display_name(equipped_item_id))

	if removed_item_id != "":
		notify_message("%s を外した" % ItemDatabase.get_display_name(removed_item_id))

	clear_held_state()
	refresh_status_ui()


func restore_held_entry_on_close() -> bool:
	if held_entry.is_empty():
		return true

	if held_from_area == "inventory":
		if current_inventory.is_slot_empty(held_from_index):
			current_inventory.set_item_data_at(held_from_index, held_entry)
			clear_held_state()
			return true

		var empty_index = current_inventory.find_first_empty_slot()
		if empty_index >= 0:
			current_inventory.set_item_data_at(empty_index, held_entry)
			clear_held_state()
			return true

		notify_message("空きスロットがないため閉じられない")
		return false

	if held_from_area == "equipment":
		var origin_entry = get_equipment_entry(held_from_slot_name)

		if is_empty_entry(origin_entry) and can_place_entry_in_equipment_slot(held_entry, held_from_slot_name):
			set_equipment_entry(held_from_slot_name, held_entry)
			clear_held_state()
			refresh_status_ui()
			return true

		var empty_inventory_index = current_inventory.find_first_empty_slot()
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
	var source_id = String(source_entry.get("item_id", ""))
	var target_id = String(target_entry.get("item_id", ""))

	if source_id == "" or target_id == "":
		return false

	if source_id != target_id:
		return false

	if ItemDatabase.is_equipment(source_id):
		return false

	return ItemDatabase.get_max_stack(source_id) > 1


func merge_entries(source_entry: Dictionary, target_entry: Dictionary) -> int:
	var item_id = String(source_entry.get("item_id", ""))
	var source_amount = int(source_entry.get("amount", 0))
	var target_amount = int(target_entry.get("amount", 0))
	var max_stack = ItemDatabase.get_max_stack(item_id)

	var addable = min(max_stack - target_amount, source_amount)
	target_entry["amount"] = target_amount + addable

	return source_amount - addable


func can_return_entry_to_origin(entry: Dictionary) -> bool:
	if held_from_area == "inventory":
		return true

	if held_from_area == "equipment":
		return can_place_entry_in_equipment_slot(entry, held_from_slot_name)

	return false


func can_place_entry_in_equipment_slot(entry: Dictionary, slot_name: String) -> bool:
	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return false

	if amount != 1:
		return false

	if not ItemDatabase.is_equipment(item_id):
		return false

	if ItemDatabase.get_equipment_slot(item_id) != slot_name:
		return false

	if current_unit != null and current_unit.has_method("can_equip_item_id_to_slot"):
		return current_unit.can_equip_item_id_to_slot(item_id, slot_name)

	return true


func get_selected_entry() -> Dictionary:
	if focus_area == "inventory":
		return current_inventory.get_item_data_at(selected_index)

	var slot_name = equipment_slot_order[selected_index]
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

	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		if current_unit.has_method("clear_equipment_slot"):
			current_unit.clear_equipment_slot(slot_name)
			return true
		return false

	if current_unit.has_method("set_equipped_item_by_id"):
		return current_unit.set_equipped_item_by_id(slot_name, item_id)

	return false


func clear_equipment_entry(slot_name: String) -> void:
	if current_unit != null and current_unit.has_method("clear_equipment_slot"):
		current_unit.clear_equipment_slot(slot_name)


func is_empty_entry(entry: Dictionary) -> bool:
	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))
	return item_id == "" or amount <= 0


func use_selected_item() -> void:
	if focus_area != "inventory":
		return

	if current_inventory == null:
		return

	if not held_entry.is_empty():
		return

	var result = current_inventory.use_item_at(selected_index)

	if not bool(result.get("success", false)):
		return

	hide_tooltip()
	refresh()
	restart_tooltip_timer()
	refresh_status_ui()


func refresh_status_ui() -> void:
	var node = self
	while node != null:
		if node.has_method("update_hud_player_status"):
			node.update_hud_player_status()

		if node.has_method("refresh_hud"):
			node.refresh_hud()

		node = node.get_parent()


func build_item_tooltip_lines(item_id: String) -> Array[String]:
	var lines: Array[String] = []

	if ItemDatabase.is_equipment(item_id):
		var eq = ItemDatabase.get_equipment_resource(item_id)
		if eq == null:
			return lines

		var slot_name = eq.get_slot_name()
		if slot_name != "":
			lines.append("部位: %s" % slot_name)

		if int(eq.attack_bonus) != 0:
			lines.append("攻撃 %s%d" % ["+" if eq.attack_bonus > 0 else "", eq.attack_bonus])

		if int(eq.defense_bonus) != 0:
			lines.append("防御 %s%d" % ["+" if eq.defense_bonus > 0 else "", eq.defense_bonus])

		if int(eq.max_hp_bonus) != 0:
			lines.append("最大HP %s%d" % ["+" if eq.max_hp_bonus > 0 else "", eq.max_hp_bonus])

		if int(eq.speed_bonus) != 0:
			lines.append("速度 %s%d" % ["+" if eq.speed_bonus > 0 else "", eq.speed_bonus])

		if slot_name == "weapon":
			lines.append("射程 %d-%d" % [eq.attack_min_range, eq.attack_max_range])

		return lines

	var effect_type = ItemDatabase.get_effect_type(item_id)
	var effect_value = ItemDatabase.get_effect_value(item_id)

	match effect_type:
		"heal_hp":
			lines.append("効果: HPを%d回復" % effect_value)
		"log_only":
			pass
		_:
			if effect_type != "":
				lines.append("効果: %s (%d)" % [effect_type, effect_value])

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

	var entry = get_selected_entry()
	if is_empty_entry(entry):
		return

	tooltip_timer.start()


func show_tooltip_for_selected() -> void:
	if not held_entry.is_empty():
		hide_tooltip()
		return

	var entry = get_selected_entry()
	if is_empty_entry(entry):
		hide_tooltip()
		return

	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	tooltip_name_label.text = "%s x%d" % [ItemDatabase.get_display_name(item_id), amount]

	var desc = ItemDatabase.get_description(item_id)
	var extra_lines = build_item_tooltip_lines(item_id)

	if extra_lines.is_empty():
		tooltip_desc_label.text = desc
	else:
		if desc == "":
			tooltip_desc_label.text = "\n".join(extra_lines)
		else:
			tooltip_desc_label.text = desc + "\n" + "\n".join(extra_lines)

	var usable_text = "使用可能" if ItemDatabase.is_usable(item_id) else "使用不可"
	tooltip_meta_label.text = "種別: %s / %s" % [ItemDatabase.get_item_type(item_id), usable_text]

	var slot = get_selected_slot_node()
	if slot == null:
		hide_tooltip()
		return

	var slot_rect = slot.get_global_rect()

	tooltip_panel.reset_size()
	await get_tree().process_frame

	var panel_size = tooltip_panel.size
	var viewport_rect = get_viewport().get_visible_rect()

	var target_x = slot_rect.position.x + slot_rect.size.x + 12.0
	var target_y = slot_rect.position.y

	if target_x + panel_size.x > viewport_rect.position.x + viewport_rect.size.x:
		target_x = slot_rect.position.x - panel_size.x - 12.0

	if target_y + panel_size.y > viewport_rect.position.y + viewport_rect.size.y:
		target_y = viewport_rect.position.y + viewport_rect.size.y - panel_size.y - 12.0

	if target_y < viewport_rect.position.y + 12.0:
		target_y = viewport_rect.position.y + 12.0

	tooltip_panel.global_position = Vector2(target_x, target_y)
	tooltip_panel.show()


func update_held_item_preview() -> void:
	if held_item_preview == null:
		return

	if held_entry.is_empty():
		held_item_preview.hide()
		return

	var item_id = String(held_entry.get("item_id", ""))
	var amount = int(held_entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		held_item_preview.hide()
		return

	var icon_texture = ItemDatabase.get_item_icon(item_id)
	held_item_icon.texture = icon_texture
	held_item_icon.modulate = Color(1, 1, 1, 0.9)
	held_item_amount_label.modulate = Color(1, 1, 1, 1)

	var base_size = get_selected_slot_visual_size()
	var preview_size = base_size * 0.9

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
		held_item_preview.hide()
		return

	var slot_rect = slot.get_global_rect()

	# 最初から常に「少し上」に表示する
	var preview_pos = Vector2(
		slot_rect.position.x + (slot_rect.size.x - preview_size.x) * 0.5,
		slot_rect.position.y + (slot_rect.size.y - preview_size.y) * 0.5 - 6.0
	)

	var viewport_rect = get_viewport().get_visible_rect()

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

	var rect = slot.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		if slot is Control:
			var control_slot = slot as Control
			if control_slot.size.x > 0.0 and control_slot.size.y > 0.0:
				return control_slot.size
			if control_slot.custom_minimum_size.x > 0.0 and control_slot.custom_minimum_size.y > 0.0:
				return control_slot.custom_minimum_size
		return Vector2(48, 48)

	return rect.size


func get_selected_slot_node():
	if focus_area == "inventory":
		if selected_index < 0 or selected_index >= slot_grid.get_child_count():
			return null
		return slot_grid.get_child(selected_index)

	if selected_index < 0 or selected_index >= equipment_slot_nodes.size():
		return null
	return equipment_slot_nodes[selected_index]


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
