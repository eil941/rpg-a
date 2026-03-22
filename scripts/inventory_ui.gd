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
	hide()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.text = "Inventory"
	help_label.text = "Iキーで閉じる / 矢印で選択"
	build_empty_slots()


func build_empty_slots() -> void:
	for child in slot_grid.get_children():
		child.queue_free()

	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		slot_grid.add_child(slot)
		slot.set_slot_data("", 0, null)
		slot.set_selected(i == selected_index)


func open_with_inventory(inventory: Inventory) -> void:
	current_inventory = inventory
	selected_index = 0
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
	build_empty_slots()

	if current_inventory == null:
		return

	var items = current_inventory.get_all_items()

	for i in range(min(items.size(), slot_grid.get_child_count())):
		var entry = items[i]
		var item_id := String(entry.get("item_id", ""))
		var amount := int(entry.get("amount", 0))

		var slot = slot_grid.get_child(i)
		slot.set_slot_data(item_id, amount, null)
		slot.set_selected(i == selected_index)
