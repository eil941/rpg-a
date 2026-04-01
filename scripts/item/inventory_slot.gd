extends PanelContainer

@onready var icon = $SlotRoot/Icon
@onready var amount_label = $SlotRoot/AmountLabel
@onready var select_frame = $SlotRoot/SelectFrame

var item_id = ""
var amount = 0


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
