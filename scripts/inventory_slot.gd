extends PanelContainer

@onready var icon: TextureRect = $MarginContainer/Control/Icon
@onready var amount_label: Label = $MarginContainer/Control/AmountLabel
@onready var select_frame: ColorRect = $MarginContainer/Control/SelectFrame

var item_id: String = ""
var amount: int = 0


func set_slot_data(p_item_id: String, p_amount: int, texture: Texture2D = null) -> void:
	item_id = p_item_id
	amount = p_amount

	if item_id == "" or amount <= 0:
		icon.texture = null
		amount_label.text = ""
		return

	icon.texture = texture
	amount_label.text = "x%d" % amount


func set_selected(value: bool) -> void:
	select_frame.visible = value
