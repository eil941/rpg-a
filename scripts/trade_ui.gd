extends CanvasLayer
class_name TradeUI

const NPC_GRID_COLUMNS: int = 8
const PLAYER_GRID_COLUMNS: int = 8
const NPC_SLOT_COUNT: int = 16
const PLAYER_SLOT_COUNT: int = 32

@onready var root_panel: Control = $RootPanel
@onready var title_label: Label = $RootPanel/TitleLabel

@onready var npc_title_label: Label = $RootPanel/NpcTitleLabel
@onready var npc_grid: GridContainer = $RootPanel/NpcPanel/NpcItemGrid

@onready var player_title_label: Label = $RootPanel/PlayerTitleLabel
@onready var player_grid: GridContainer = $RootPanel/PlayerPanel/PlayerItemGrid

@onready var equipment_title_label: Label = $RootPanel/EquipmentTitleLabel
@onready var equipment_list: VBoxContainer = $RootPanel/EquipmentPanel/EquipmentList

@onready var side_panel: Panel = $RootPanel/SidePanel
@onready var merchant_name_label: Label = $RootPanel/SidePanel/MerchantNameLabel
@onready var trade_info_label: RichTextLabel = $RootPanel/SidePanel/TradeInfoLabel
@onready var hint_label: Label = $RootPanel/SidePanel/HintLabel
@onready var back_button: Button = $RootPanel/SidePanel/BackButton

var is_open: bool = false
var player_unit = null
var merchant_unit = null


func _ready() -> void:
	visible = false
	back_button.pressed.connect(_on_back_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		close_trade_ui()
		get_viewport().set_input_as_handled()


func open_trade_ui(p_player_unit, p_merchant_unit) -> void:
	player_unit = p_player_unit
	merchant_unit = p_merchant_unit
	is_open = true
	visible = true

	title_label.text = "売買"
	npc_title_label.text = "NPC の商品"
	player_title_label.text = "プレイヤーのインベントリ"
	equipment_title_label.text = "そうび"
	merchant_name_label.text = _get_merchant_display_name()

	trade_info_label.text = (
		"[center]"
		+ "取引画面\n\n"
		+ "今後は\n"
		+ "NPC → プレイヤー = 買う\n"
		+ "プレイヤー → NPC = 売る\n"
		+ "の形に拡張予定"
		+ "[/center]"
	)

	hint_label.text = "Esc: 戻る"
	_refresh_all_views()


func close_trade_ui() -> void:
	is_open = false
	visible = false

	player_unit = null
	merchant_unit = null

	_clear_grid(npc_grid)
	_clear_grid(player_grid)
	_clear_box(equipment_list)

	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.has_method("on_trade_ui_closed"):
		parent_node.on_trade_ui_closed()


func is_trade_open() -> bool:
	return is_open


func _on_back_button_pressed() -> void:
	close_trade_ui()


func _refresh_all_views() -> void:
	_refresh_npc_grid()
	_refresh_player_grid()
	_refresh_equipment_list()


func _refresh_npc_grid() -> void:
	var entries: Array = []

	_clear_grid(npc_grid)

	if merchant_unit != null and merchant_unit.inventory != null:
		entries = _get_inventory_entries(merchant_unit.inventory)

	_fill_grid_with_entries(npc_grid, entries, NPC_SLOT_COUNT)


func _refresh_player_grid() -> void:
	var entries: Array = []

	_clear_grid(player_grid)

	if player_unit != null and player_unit.inventory != null:
		entries = _get_inventory_entries(player_unit.inventory)

	_fill_grid_with_entries(player_grid, entries, PLAYER_SLOT_COUNT)


func _refresh_equipment_list() -> void:
	var slot_order: Array = []
	var slot_name: String = ""
	var entry: Dictionary = {}

	_clear_box(equipment_list)

	if player_unit == null:
		equipment_list.add_child(_build_equipment_row("ぶき", {}))
		equipment_list.add_child(_build_equipment_row("よろい", {}))
		equipment_list.add_child(_build_equipment_row("アクセサリ", {}))
		return

	if player_unit.has_method("get_equipment_slot_order"):
		slot_order = player_unit.get_equipment_slot_order()
	else:
		slot_order = ["weapon", "armor", "accessory"]

	for raw_slot_name in slot_order:
		slot_name = String(raw_slot_name)

		if player_unit.has_method("get_equipped_item_entry"):
			entry = player_unit.get_equipped_item_entry(slot_name)
		else:
			entry = {}

		equipment_list.add_child(_build_equipment_row(_get_equipment_slot_label(slot_name), entry))


func _get_inventory_entries(inventory) -> Array:
	var result: Variant = null

	if inventory == null:
		return []

	if inventory.has_method("get_all_items"):
		result = inventory.get_all_items()
		if result is Array:
			return result

	return []


func _fill_grid_with_entries(target_grid: GridContainer, entries: Array, slot_count: int) -> void:
	var index: int = 0
	var entry: Dictionary = {}

	for raw_entry in entries:
		if index >= slot_count:
			break

		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue

		entry = raw_entry

		if int(entry.get("amount", 0)) <= 0:
			continue

		target_grid.add_child(_build_item_slot(entry))
		index += 1

	while index < slot_count:
		target_grid.add_child(_build_empty_slot())
		index += 1


func _build_item_slot(entry: Dictionary) -> Control:
	var panel: Panel = Panel.new()
	var margin: MarginContainer = MarginContainer.new()
	var vbox: VBoxContainer = VBoxContainer.new()
	var item_name_label: Label = Label.new()
	var amount_label: Label = Label.new()

	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))
	var display_name: String = item_id

	panel.custom_minimum_size = Vector2(84, 64)

	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 6.0
	margin.offset_top = 4.0
	margin.offset_right = -6.0
	margin.offset_bottom = -4.0

	item_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name_label.clip_text = true
	item_name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	if item_id != "":
		display_name = ItemDatabase.get_display_name(item_id)

	item_name_label.text = display_name
	amount_label.text = "x%d" % amount

	vbox.add_child(item_name_label)
	vbox.add_spacer(false)
	vbox.add_child(amount_label)

	margin.add_child(vbox)
	panel.add_child(margin)
	return panel


func _build_empty_slot() -> Control:
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(84, 64)
	return panel


func _build_equipment_row(slot_label: String, entry: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	var slot_name_label: Label = Label.new()
	var slot_panel: Panel = Panel.new()
	var margin: MarginContainer = MarginContainer.new()
	var item_label: Label = Label.new()

	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))
	var display_text: String = "なし"

	row.custom_minimum_size = Vector2(0, 56)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	slot_name_label.custom_minimum_size = Vector2(88, 0)
	slot_name_label.text = slot_label

	slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_panel.custom_minimum_size = Vector2(0, 52)

	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 8.0
	margin.offset_top = 6.0
	margin.offset_right = -8.0
	margin.offset_bottom = -6.0

	if item_id != "" and amount > 0:
		display_text = ItemDatabase.get_display_name(item_id)

	item_label.text = display_text
	item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_label.clip_text = true

	margin.add_child(item_label)
	slot_panel.add_child(margin)

	row.add_child(slot_name_label)
	row.add_child(slot_panel)
	return row


func _get_equipment_slot_label(slot_name: String) -> String:
	match slot_name:
		"weapon":
			return "ぶき"
		"armor":
			return "よろい"
		"accessory":
			return "アクセサリ"
		_:
			return slot_name


func _clear_grid(target_grid: GridContainer) -> void:
	var children: Array = target_grid.get_children()

	for child in children:
		target_grid.remove_child(child)
		child.queue_free()


func _clear_box(target_box: VBoxContainer) -> void:
	var children: Array = target_box.get_children()

	for child in children:
		target_box.remove_child(child)
		child.queue_free()


func _get_merchant_display_name() -> String:
	if merchant_unit == null:
		return "商人"

	if merchant_unit.has_method("get_talk_name"):
		return merchant_unit.get_talk_name()

	return String(merchant_unit.name)
