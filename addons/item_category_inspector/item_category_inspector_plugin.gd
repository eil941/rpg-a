@tool
extends EditorInspectorPlugin

const ItemCategoryEditorPropertyScript = preload("res://addons/item_category_inspector/item_category_editor_property.gd")

const ItemDataScript = preload("res://data/items/item_data.gd")
const LootCategoryEntryScript = preload("res://data/loot/loot_category_entry.gd")


func _can_handle(object: Object) -> bool:
	if object == null:
		return false

	if object.get_script() == ItemDataScript:
		return true

	if object.get_script() == LootCategoryEntryScript:
		return true

	return false


func _parse_property(
	object: Object,
	type: Variant.Type,
	name: String,
	hint_type: PropertyHint,
	hint_string: String,
	usage_flags: int,
	wide: bool
) -> bool:
	if object == null:
		return false

	if object.get_script() == ItemDataScript and name == "category":
		var editor: EditorProperty = ItemCategoryEditorPropertyScript.new()
		editor.setup(name)
		add_property_editor(name, editor)
		print("Item Category Inspector: override ItemData.category")
		return true

	if object.get_script() == LootCategoryEntryScript and name == "item_type":
		var editor: EditorProperty = ItemCategoryEditorPropertyScript.new()
		editor.setup(name)
		add_property_editor(name, editor)
		print("Item Category Inspector: override LootCategoryEntry.item_type")
		return true

	return false
