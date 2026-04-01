extends CanvasLayer

@onready var root = $Root
@onready var title_label = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var slot_grid = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/SlotGrid
@onready var help_label = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/HelpLabel

@onready var tooltip_panel = $Root/Overlay/TooltipPanel
@onready var tooltip_name_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipNameLabel
@onready var tooltip_desc_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipDescLabel
@onready var tooltip_meta_label = $Root/Overlay/TooltipPanel/MarginContainer/TooltipVBox/TooltipMetaLabel

@export var slot_scene: PackedScene
@export var tooltip_delay: float = 0.5

var current_inventory = null
var selected_index = 0
var tooltip_timer = null
var is_building_slots = false


func _ready() -> void:
	layer = 10
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()

	title_label.text = "Inventory"
	help_label.text = "Iキーで閉じる / 矢印で選択 / 決定で使用"

	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = tooltip_delay
	add_child(tooltip_timer)
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

	tooltip_panel.hide()


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

	if event.is_action_pressed("inventory_use"):
		use_selected_item()
		get_viewport().set_input_as_handled()
		return


func open_with_inventory(inventory) -> void:
	current_inventory = inventory
	await rebuild_slots_if_needed()

	var slot_count = get_slot_count()
	selected_index = clamp(selected_index, 0, max(slot_count - 1, 0))

	refresh()
	show()
	restart_tooltip_timer()


func close_inventory() -> void:
	hide_tooltip()

	if tooltip_timer != null:
		tooltip_timer.stop()

	hide()


func toggle_with_inventory(inventory) -> void:
	if visible:
		close_inventory()
	else:
		await open_with_inventory(inventory)


func get_slot_count() -> int:
	if current_inventory == null:
		return 0

	return current_inventory.max_slots


func rebuild_slots_if_needed() -> void:
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


func refresh() -> void:
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
			var icon_texture = ItemDatabase.get_item_icon(item_id)
			slot.set_slot_data(item_id, amount, icon_texture)
		else:
			slot.set_slot_data("", 0, null)

		slot.set_selected(i == selected_index)


func move_selection(dx: int, dy: int) -> void:
	if is_building_slots:
		return

	var slot_count = get_slot_count()
	if slot_count <= 0:
		return

	var columns = slot_grid.columns
	if columns <= 0:
		columns = 1

	var row = selected_index / columns
	var col = selected_index % columns

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

	if new_index < 0:
		new_index = 0

	if new_index == selected_index:
		return

	selected_index = new_index
	refresh()
	restart_tooltip_timer()


func has_item_at_selected() -> bool:
	if current_inventory == null:
		return false

	if selected_index < 0:
		return false

	if selected_index >= get_slot_count():
		return false

	var entry = current_inventory.get_item_data_at(selected_index)
	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	return item_id != "" and amount > 0


func restart_tooltip_timer() -> void:
	hide_tooltip()

	if tooltip_timer == null:
		return

	tooltip_timer.stop()

	if not visible:
		return

	if is_building_slots:
		return

	if not has_item_at_selected():
		return

	if selected_index < 0:
		return

	if slot_grid.get_child_count() <= selected_index:
		return

	tooltip_timer.start()


func show_tooltip_for_selected() -> void:
	if current_inventory == null:
		hide_tooltip()
		return

	if is_building_slots:
		hide_tooltip()
		return

	if selected_index < 0 or selected_index >= get_slot_count():
		hide_tooltip()
		return

	if slot_grid.get_child_count() <= selected_index:
		hide_tooltip()
		return

	var slot = slot_grid.get_child(selected_index)
	if slot == null:
		hide_tooltip()
		return

	var entry = current_inventory.get_item_data_at(selected_index)
	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		hide_tooltip()
		return

	var display_name = ItemDatabase.get_display_name(item_id)
	var description = ItemDatabase.get_description(item_id)
	var usable_text = "使用可能" if ItemDatabase.is_usable(item_id) else "使用不可"
	var item_type = ItemDatabase.get_item_type(item_id)

	tooltip_name_label.text = "%s x%d" % [display_name, amount]
	tooltip_desc_label.text = description
	tooltip_meta_label.text = "種別: %s / %s" % [item_type, usable_text]

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


func hide_tooltip() -> void:
	if tooltip_panel != null:
		tooltip_panel.hide()


func _on_tooltip_timer_timeout() -> void:
	if not visible:
		return

	if is_building_slots:
		return

	if not has_item_at_selected():
		return

	await show_tooltip_for_selected()


func use_selected_item() -> void:
	if current_inventory == null:
		return

	if selected_index < 0 or selected_index >= get_slot_count():
		return

	var result = current_inventory.use_item_at(selected_index)

	if not bool(result.get("success", false)):
		return

	hide_tooltip()
	refresh()
	restart_tooltip_timer()

	var node = self
	while node != null:
		if node.has_method("update_hud_player_status"):
			node.update_hud_player_status()

		if node.has_method("refresh_hud"):
			node.refresh_hud()

		node = node.get_parent()
