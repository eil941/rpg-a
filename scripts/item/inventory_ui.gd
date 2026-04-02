extends CanvasLayer

@onready var root = $Root
@onready var title_label = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/TitleLabel
@onready var slot_grid = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/SlotGrid
@onready var help_label = $Root/Overlay/CenterContainer/MainHBox/InventoryPanel/MarginContainer/LeftVBox/HelpLabel
@onready var equipment_vbox = $Root/Overlay/CenterContainer/MainHBox/EquipmentPanel/MarginContainer/RightVBox/EquipmentVBox

@onready var tooltip_panel = $Root/Overlay/TooltipPanel
@onready var tooltip_name_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipNameLabel
@onready var tooltip_desc_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipDescLabel
@onready var tooltip_meta_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipMetaLabel

@onready var held_item_preview = $Root/Overlay/HeldItemPreview
@onready var held_item_icon = $Root/Overlay/HeldItemPreview/Icon
@onready var held_item_amount_label = $Root/Overlay/HeldItemPreview/AmountLabel

@export var slot_scene: PackedScene
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

	clear_held_state()


func drop_held_entry_to_equipment(slot_name: String) -> void:
	if not can_place_entry_in_equipment_slot(held_entry, slot_name):
		notify_message("そこには装備できない")
		return

	var target_entry = get_equipment_entry(slot_name)

	if is_empty_entry(target_entry):
		set_equipment_entry(slot_name, held_entry)
		clear_held_state()
		refresh_status_ui()
		return

	if not can_return_entry_to_origin(target_entry):
		notify_message("交換できない")
		return

	var origin_area = held_from_area
	var origin_index = held_from_index
	var origin_slot_name = held_from_slot_name

	set_equipment_entry(slot_name, held_entry)

	if origin_area == "inventory":
		current_inventory.set_item_data_at(origin_index, target_entry)
	else:
		set_equipment_entry(origin_slot_name, target_entry)

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
	tooltip_desc_label.text = ItemDatabase.get_description(item_id)

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

	if amount > 1:
		held_item_amount_label.text = "x%d" % amount
	else:
		held_item_amount_label.text = ""

	var slot = get_selected_slot_node()
	if slot == null:
		held_item_preview.hide()
		return

	var slot_rect = slot.get_global_rect()
	var preview_pos = Vector2(
		slot_rect.position.x + 10.0,
		slot_rect.position.y - 10.0
	)

	var viewport_rect = get_viewport().get_visible_rect()

	if preview_pos.x + 48.0 > viewport_rect.position.x + viewport_rect.size.x:
		preview_pos.x = viewport_rect.position.x + viewport_rect.size.x - 56.0

	if preview_pos.y < viewport_rect.position.y + 8.0:
		preview_pos.y = slot_rect.position.y + 8.0

	held_item_preview.global_position = preview_pos
	held_item_preview.show()


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
