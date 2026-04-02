extends PanelContainer

@onready var slot_root = $SlotRoot
@onready var icon = $SlotRoot/Icon
@onready var amount_label = $SlotRoot/AmountLabel
@onready var select_frame = $SlotRoot/SelectFrame

var item_id: String = ""
var amount: int = 0

var configured_slot_size: Vector2 = Vector2.ZERO
var configured_icon_margin: int = -1


func _ready() -> void:
	apply_layout()


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


func set_slot_data(p_item_id: String, p_amount: int, texture: Texture2D = null) -> void:
	item_id = p_item_id
	amount = p_amount

	if item_id == "" or amount <= 0:
		icon.texture = null
		icon.visible = false
		amount_label.text = ""
		return

	icon.visible = true
	icon.texture = texture

	if amount > 1:
		amount_label.text = "x%d" % amount
	else:
		amount_label.text = ""


func set_selected(value: bool) -> void:
	select_frame.visible = value
