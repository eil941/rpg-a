@tool
extends EditorProperty

const ItemCategoriesScript = preload("res://scripts/data/item_categories.gd")

var property_name: String = ""
var option_button: OptionButton


func setup(p_property_name: String) -> void:
	property_name = p_property_name

	option_button = OptionButton.new()
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(option_button)
	add_focusable(option_button)

	option_button.item_selected.connect(_on_item_selected)

	_refresh_items()


func _update_property() -> void:
	if option_button == null:
		return

	_refresh_items()

	var edited_object: Object = get_edited_object()
	if edited_object == null:
		return

	var current_value: String = str(edited_object.get(property_name))
	var normalized_value: String = ItemCategoriesScript.normalize(current_value)

	var categories: Array[String] = ItemCategoriesScript.get_all_as_strings()
	for i in range(categories.size()):
		if categories[i] == normalized_value:
			option_button.select(i)
			return

	if categories.size() > 0:
		option_button.select(0)


func _refresh_items() -> void:
	if option_button == null:
		return

	var previous_text: String = ""
	if option_button.get_item_count() > 0 and option_button.selected >= 0:
		previous_text = option_button.get_item_text(option_button.selected)

	option_button.clear()

	var categories: Array[String] = ItemCategoriesScript.get_all_as_strings()
	for i in range(categories.size()):
		option_button.add_item(categories[i], i)

	if previous_text != "":
		for i in range(option_button.get_item_count()):
			if option_button.get_item_text(i) == previous_text:
				option_button.select(i)
				return

	if option_button.get_item_count() > 0:
		option_button.select(0)


func _on_item_selected(index: int) -> void:
	var categories: Array[String] = ItemCategoriesScript.get_all_as_strings()
	if index < 0 or index >= categories.size():
		return

	var value: String = categories[index]
	emit_changed(property_name, value)
