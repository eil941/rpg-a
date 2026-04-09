extends PanelContainer

@onready var slot_root = $SlotRoot
@onready var icon = $SlotRoot/Icon
@onready var amount_label = $SlotRoot/AmountLabel
@onready var select_frame = $SlotRoot/SelectFrame

var item_id: String = ""
var amount: int = 0
var item_entry: Dictionary = {}

var configured_slot_size: Vector2 = Vector2.ZERO
var configured_icon_margin: int = -1

var enchant_overlay: ColorRect = null


func _ready() -> void:
	enchant_overlay = _get_or_create_enchant_overlay()
	apply_layout()
	_update_enchant_overlay()


func apply_config(new_slot_size: Vector2, new_icon_margin: int) -> void:
	configured_slot_size = new_slot_size
	configured_icon_margin = new_icon_margin
	apply_layout()


func apply_layout() -> void:
	if configured_slot_size != Vector2.ZERO:
		custom_minimum_size = configured_slot_size
		size = configured_slot_size

		if slot_root != null:
			slot_root.custom_minimum_size = configured_slot_size
			slot_root.size = configured_slot_size

	if icon != null and configured_icon_margin >= 0:
		icon.offset_left = float(configured_icon_margin)
		icon.offset_top = float(configured_icon_margin)
		icon.offset_right = -float(configured_icon_margin)
		icon.offset_bottom = -float(configured_icon_margin)

	_update_enchant_overlay()


func set_item_entry(entry: Dictionary, texture: Texture2D = null) -> void:
	item_entry = entry.duplicate(true)
	item_id = String(item_entry.get("item_id", ""))
	amount = int(item_entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		icon.texture = null
		icon.visible = false
		amount_label.text = ""
		_update_enchant_overlay()
		return

	icon.visible = true
	icon.texture = texture if texture != null else ItemDatabase.get_item_icon(item_id)

	if amount > 1:
		amount_label.text = "x%d" % amount
	else:
		amount_label.text = ""

	_update_enchant_overlay()


func set_slot_data(p_item_id: String, p_amount: int, texture: Texture2D = null) -> void:
	item_id = p_item_id
	amount = p_amount

	if item_id == "" or amount <= 0:
		item_entry = {}
		icon.texture = null
		icon.visible = false
		amount_label.text = ""
		_update_enchant_overlay()
		return

	item_entry = {
		"item_id": item_id,
		"amount": amount
	}

	icon.visible = true
	icon.texture = texture

	if amount > 1:
		amount_label.text = "x%d" % amount
	else:
		amount_label.text = ""

	_update_enchant_overlay()


func set_selected(value: bool) -> void:
	select_frame.visible = value


func _has_enchantments() -> bool:
	if item_entry.is_empty():
		return false

	var instance_data: Variant = item_entry.get("instance_data", {})
	if typeof(instance_data) != TYPE_DICTIONARY:
		return false

	var enchantments: Variant = instance_data.get("enchantments", [])
	if not (enchantments is Array):
		return false

	return not enchantments.is_empty()


func _get_or_create_enchant_overlay() -> ColorRect:
	var existing: Node = slot_root.get_node_or_null("EnchantOverlay")
	if existing is ColorRect:
		return existing

	var rect := ColorRect.new()
	rect.name = "EnchantOverlay"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0.70, 0.35, 0.95, 0.22)
	rect.visible = false
	rect.z_index = 1
	slot_root.add_child(rect)

	if icon != null:
		slot_root.move_child(rect, icon.get_index())

	return rect


func _update_enchant_overlay() -> void:
	if enchant_overlay == null:
		return

	var target_size: Vector2 = configured_slot_size
	if target_size == Vector2.ZERO:
		target_size = custom_minimum_size
	if target_size == Vector2.ZERO and slot_root != null:
		target_size = slot_root.size
	if target_size == Vector2.ZERO:
		target_size = Vector2(48, 48)

	enchant_overlay.position = Vector2.ZERO
	enchant_overlay.size = target_size
	enchant_overlay.visible = _has_enchantments()
