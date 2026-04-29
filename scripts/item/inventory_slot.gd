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
var background_texture_rect: TextureRect = null
var placeholder_label: Label = null

var slot_background_texture: Texture2D = null
var slot_placeholder_text: String = ""
var show_placeholder_text: bool = false
var placeholder_font_size: int = 9
var placeholder_color: Color = Color(0.85, 0.85, 0.85, 0.85)


func _ready() -> void:
	_setup_mouse_filter()
	background_texture_rect = _get_or_create_background_texture_rect()
	placeholder_label = _get_or_create_placeholder_label()
	enchant_overlay = _get_or_create_enchant_overlay()

	apply_layout()
	_update_background()
	_update_placeholder()
	_update_enchant_overlay()


func _setup_mouse_filter() -> void:
	# スロット本体だけがクリックを受ける。
	# Icon / Label / Frame などの子Controlはクリックを吸わない。
	mouse_filter = Control.MOUSE_FILTER_STOP

	if slot_root != null and slot_root is Control:
		slot_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if icon != null:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if amount_label != null:
		amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if select_frame != null:
		select_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE


func apply_config(new_slot_size: Vector2, new_icon_margin: int) -> void:
	configured_slot_size = new_slot_size
	configured_icon_margin = new_icon_margin
	apply_layout()


func apply_layout() -> void:
	var target_size: Vector2 = _get_target_size()

	if target_size != Vector2.ZERO:
		custom_minimum_size = target_size
		size = target_size

		if slot_root != null:
			slot_root.custom_minimum_size = target_size
			slot_root.size = target_size

	if icon != null and configured_icon_margin >= 0:
		icon.offset_left = float(configured_icon_margin)
		icon.offset_top = float(configured_icon_margin)
		icon.offset_right = -float(configured_icon_margin)
		icon.offset_bottom = -float(configured_icon_margin)

	if background_texture_rect != null:
		background_texture_rect.position = Vector2.ZERO
		background_texture_rect.size = target_size

	if placeholder_label != null:
		placeholder_label.position = Vector2.ZERO
		placeholder_label.size = target_size

	_update_enchant_overlay()


func _get_target_size() -> Vector2:
	if configured_slot_size != Vector2.ZERO:
		return configured_slot_size

	if custom_minimum_size != Vector2.ZERO:
		return custom_minimum_size

	if slot_root != null and slot_root.size != Vector2.ZERO:
		return slot_root.size

	return Vector2(48, 48)


func set_item_entry(entry: Dictionary, texture: Texture2D = null) -> void:
	item_entry = entry.duplicate(true)
	item_id = String(item_entry.get("item_id", ""))
	amount = int(item_entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		icon.texture = null
		icon.visible = false
		amount_label.text = ""
		_update_placeholder()
		_update_enchant_overlay()
		return

	icon.visible = true
	icon.texture = texture if texture != null else ItemDatabase.get_item_icon(item_id)

	if amount > 1:
		amount_label.text = "x%d" % amount
	else:
		amount_label.text = ""

	_update_placeholder()
	_update_enchant_overlay()


func set_slot_data(p_item_id: String, p_amount: int, texture: Texture2D = null) -> void:
	item_id = p_item_id
	amount = p_amount

	if item_id == "" or amount <= 0:
		item_entry = {}
		icon.texture = null
		icon.visible = false
		amount_label.text = ""
		_update_placeholder()
		_update_enchant_overlay()
		return

	item_entry = {
		"item_id": item_id,
		"amount": amount
	}

	icon.visible = true

	if texture != null:
		icon.texture = texture
	else:
		icon.texture = ItemDatabase.get_item_icon(item_id)

	if amount > 1:
		amount_label.text = "x%d" % amount
	else:
		amount_label.text = ""

	_update_placeholder()
	_update_enchant_overlay()


func set_selected(value: bool) -> void:
	select_frame.visible = value


# =========================
# Equipment slot background / placeholder
# =========================

func set_slot_background(texture: Texture2D) -> void:
	slot_background_texture = texture
	_update_background()
	_update_placeholder()


func set_placeholder_text(text: String, enabled: bool = true) -> void:
	slot_placeholder_text = text
	show_placeholder_text = enabled
	_update_placeholder()


func set_placeholder_style(font_size: int, color: Color) -> void:
	placeholder_font_size = max(1, font_size)
	placeholder_color = color
	_update_placeholder()


func configure_equipment_placeholder(
	background_texture: Texture2D,
	placeholder_text: String,
	enabled: bool = true,
	font_size: int = 9,
	color: Color = Color(0.85, 0.85, 0.85, 0.85)
) -> void:
	slot_background_texture = background_texture
	slot_placeholder_text = placeholder_text
	show_placeholder_text = enabled
	placeholder_font_size = max(1, font_size)
	placeholder_color = color

	_update_background()
	_update_placeholder()


func _get_or_create_background_texture_rect() -> TextureRect:
	var existing: Node = slot_root.get_node_or_null("BackgroundTexture")
	if existing is TextureRect:
		var existing_rect: TextureRect = existing as TextureRect
		existing_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return existing_rect

	var rect: TextureRect = TextureRect.new()
	rect.name = "BackgroundTexture"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.visible = false
	rect.z_index = -1
	slot_root.add_child(rect)
	slot_root.move_child(rect, 0)

	return rect


func _get_or_create_placeholder_label() -> Label:
	var existing: Node = slot_root.get_node_or_null("PlaceholderLabel")
	if existing is Label:
		var existing_label: Label = existing as Label
		existing_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return existing_label

	var label: Label = Label.new()
	label.name = "PlaceholderLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.visible = false
	label.z_index = 0
	slot_root.add_child(label)

	if icon != null:
		slot_root.move_child(label, icon.get_index())

	return label


func _update_background() -> void:
	if background_texture_rect == null:
		return

	background_texture_rect.texture = slot_background_texture
	background_texture_rect.visible = slot_background_texture != null

	var target_size: Vector2 = _get_target_size()
	background_texture_rect.position = Vector2.ZERO
	background_texture_rect.size = target_size


func _update_placeholder() -> void:
	if placeholder_label == null:
		return

	var has_item: bool = item_id != "" and amount > 0
	var has_background: bool = slot_background_texture != null

	placeholder_label.text = slot_placeholder_text
	placeholder_label.add_theme_font_size_override("font_size", placeholder_font_size)
	placeholder_label.add_theme_color_override("font_color", placeholder_color)

	# アイテムがある時は非表示。
	# 背景画像がある時も、画像側で用途が分かるので非表示。
	# 背景画像がない時だけ「右手」「頭」などを表示する。
	placeholder_label.visible = show_placeholder_text and not has_item and not has_background and slot_placeholder_text != ""

	var target_size: Vector2 = _get_target_size()
	placeholder_label.position = Vector2.ZERO
	placeholder_label.size = target_size


# =========================
# Enchantment overlay
# =========================

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
		var existing_rect: ColorRect = existing as ColorRect
		existing_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return existing_rect

	var rect: ColorRect = ColorRect.new()
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

	var target_size: Vector2 = _get_target_size()

	enchant_overlay.position = Vector2.ZERO
	enchant_overlay.size = target_size
	enchant_overlay.visible = _has_enchantments()
