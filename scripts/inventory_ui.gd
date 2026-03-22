extends CanvasLayer

@onready var root: Control = $Root
@onready var overlay: ColorRect = $Root/Overlay
@onready var panel: PanelContainer = $Root/Overlay/CenterContainer/Panel
@onready var title_label: Label = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var item_list: RichTextLabel = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/ItemList
@onready var help_label: Label = $Root/Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/HelpLabel
var current_inventory: Inventory = null

func _ready() -> void:
	layer = 10
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()

	title_label.text = "Inventory"
	help_label.text = "Iキーで閉じる"
	item_list.text = ""

func open_with_inventory(inventory: Inventory) -> void:
	current_inventory = inventory
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
	if current_inventory == null:
		item_list.text = "所持品なし"
		return

	var items = current_inventory.get_all_items()
	if items.is_empty():
		item_list.text = "所持品なし"
		return

	var lines: Array[String] = []
	for entry in items:
		var item_id := String(entry.get("item_id", ""))
		var amount := int(entry.get("amount", 0))
		lines.append("%s x%d" % [item_id, amount])

	item_list.text = "\n".join(lines)
