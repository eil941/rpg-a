extends CanvasLayer

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var slot_grid: GridContainer = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/SlotGrid
@onready var help_label: Label = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/HelpLabel

@export var slot_scene: PackedScene
@export var slot_count: int = 20

var current_inventory: Inventory = null
var selected_index: int = 0


func _ready() -> void:
	layer = 10
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()

	title_label.text = "Inventory"
	help_label.text = "Iキーで閉じる / 矢印で選択 / 決定で使用"

	build_slots_once()
	refresh()


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


func build_slots_once() -> void:
	if slot_scene == null:
		push_error("InventoryUI: slot_scene が未設定です")
		return

	for child in slot_grid.get_children():
		child.queue_free()

	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		slot_grid.add_child(slot)


func open_with_inventory(inventory: Inventory) -> void:
	current_inventory = inventory
	selected_index = clamp(selected_index, 0, max(slot_count - 1, 0))
	refresh()
	show()


func close_inventory() -> void:
	hide()


func toggle_with_inventory(inventory: Inventory) -> void:
	if visible:
		close_inventory()
	else:
		open_with_inventory(inventory)


func refresh() -> void:
	var items: Array = []

	if current_inventory != null:
		items = current_inventory.get_all_items()

	for i in range(slot_grid.get_child_count()):
		var slot = slot_grid.get_child(i)

		if i < items.size():
			var entry = items[i]
			var item_id := String(entry.get("item_id", ""))
			var amount := int(entry.get("amount", 0))
			var icon_texture = ItemDatabase.get_item_icon(item_id)
			slot.set_slot_data(item_id, amount, icon_texture)
		else:
			slot.set_slot_data("", 0, null)

		slot.set_selected(i == selected_index)


func move_selection(dx: int, dy: int) -> void:
	if slot_grid.get_child_count() == 0:
		return

	var columns := slot_grid.columns
	if columns <= 0:
		columns = 1

	var row := selected_index / columns
	var col := selected_index % columns

	col += dx
	row += dy

	if col < 0:
		col = 0
	if col >= columns:
		col = columns - 1

	var max_row := int(ceil(float(slot_count) / float(columns))) - 1
	if row < 0:
		row = 0
	if row > max_row:
		row = max_row

	var new_index := row * columns + col
	if new_index >= slot_count:
		new_index = slot_count - 1

	selected_index = new_index
	refresh()


func use_selected_item() -> void:
	if current_inventory == null:
		return

	var result: Dictionary = current_inventory.use_item_at(selected_index)
	if not bool(result.get("success", false)):
		return

	refresh()

	var node: Node = self
	while node != null:
		if node.has_method("update_hud_player_status"):
			node.update_hud_player_status()
			node.refresh_hud()
		node = node.get_parent()
	
