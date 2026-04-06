@tool
extends EditorPlugin

const ITEM_DATA_SCRIPT_PATH: String = "res://scripts/data/item_data.gd"
const LOOT_CATEGORY_ENTRY_SCRIPT_PATH: String = "res://scripts/data/loot_category_entry.gd"
const ITEM_CATEGORIES_SCRIPT_PATH: String = "res://scripts/data/item_categories.gd"


class CategoryEditorProperty extends EditorProperty:
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
		var normalized_value: String = _normalize_category(current_value)

		var categories: Array[String] = _get_all_categories()
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

		var categories: Array[String] = _get_all_categories()
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
		var categories: Array[String] = _get_all_categories()
		if index < 0 or index >= categories.size():
			return

		var value: String = categories[index]
		emit_changed(property_name, value)

	func _get_item_categories_script():
		return load(ITEM_CATEGORIES_SCRIPT_PATH)

	func _get_all_categories() -> Array[String]:
		var script_resource = _get_item_categories_script()
		if script_resource == null:
			return ["consumable", "material", "equipment", "misc"]

		if script_resource.has_method("get_all_as_strings"):
			return script_resource.get_all_as_strings()

		return ["consumable", "material", "equipment", "misc"]

	func _normalize_category(value: String) -> String:
		var script_resource = _get_item_categories_script()
		if script_resource == null:
			return value.strip_edges().to_lower()

		if script_resource.has_method("normalize"):
			return script_resource.normalize(value)

		return value.strip_edges().to_lower()


class CategoryInspectorPlugin extends EditorInspectorPlugin:
	func _can_handle(object: Object) -> bool:
		if object == null:
			return false

		var script_resource = object.get_script()
		if script_resource == null:
			return false

		var script_path: String = String(script_resource.resource_path)
		return script_path == ITEM_DATA_SCRIPT_PATH or script_path == LOOT_CATEGORY_ENTRY_SCRIPT_PATH

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

		var script_resource = object.get_script()
		if script_resource == null:
			return false

		var script_path: String = String(script_resource.resource_path)

		if script_path == ITEM_DATA_SCRIPT_PATH and name == "category":
			var editor := CategoryEditorProperty.new()
			editor.setup(name)
			add_property_editor(name, editor)
			print("Item Category Inspector: override ItemData.category")
			return true

		if script_path == LOOT_CATEGORY_ENTRY_SCRIPT_PATH and name == "item_type":
			var editor := CategoryEditorProperty.new()
			editor.setup(name)
			add_property_editor(name, editor)
			print("Item Category Inspector: override LootCategoryEntry.item_type")
			return true

		return false


var inspector_plugin: CategoryInspectorPlugin = null


func _enter_tree() -> void:
	inspector_plugin = CategoryInspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)
	print("Item Category Inspector: enabled")


func _exit_tree() -> void:
	if inspector_plugin != null:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null
	print("Item Category Inspector: disabled")
