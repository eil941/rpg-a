@tool
extends EditorScript

# 使い方:
# 1. まだ古い EnchantmentDatabase.gd(preload版) の状態でこのスクリプトを実行する
# 2. res://data/master/enchantments.tsv が生成される
# 3. 生成後に EnchantmentDatabase.gd を enchantment_database_tsv_only.gd に置き換える


const OUTPUT_PATH: String = "res://data/master/enchantments.tsv"

const COLUMNS: Array[String] = [
	"enchant_id",
	"display_name",
	"description",
	"effect_type",
	"stat_name",
	"min_value",
	"max_value",
	"weight",
	"allowed_slot_flags",
	"price_bonus_at_min_value",
	"price_bonus_at_max_value",
]


func _run() -> void:
	var enchantments: Array[EnchantmentData] = []

	for enchant_id_variant in EnchantmentDatabase.ENCHANT_RESOURCES.keys():
		var enchant_id: String = str(enchant_id_variant)
		var enchantment: EnchantmentData = EnchantmentDatabase.ENCHANT_RESOURCES.get(enchant_id, null) as EnchantmentData
		if enchantment == null:
			continue
		enchantments.append(enchantment)

	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open: " + OUTPUT_PATH)
		return

	file.store_line("\t".join(COLUMNS))

	var exported_count: int = 0
	for enchantment in enchantments:
		var row: Dictionary = _enchantment_to_row(enchantment)
		var values: Array[String] = []

		for column in COLUMNS:
			values.append(_escape_cell(str(row.get(column, ""))))

		file.store_line("\t".join(values))
		exported_count += 1

	file.flush()
	file.close()

	print("[EnchantmentTSVExporter] source enchantments: ", enchantments.size())
	print("[EnchantmentTSVExporter] exported rows: ", exported_count)
	print("[EnchantmentTSVExporter] output: ", OUTPUT_PATH)


func _enchantment_to_row(enchantment: EnchantmentData) -> Dictionary:
	return {
		"enchant_id": enchantment.enchant_id,
		"display_name": enchantment.display_name,
		"description": enchantment.description,
		"effect_type": int(enchantment.effect_type),
		"stat_name": enchantment.stat_name,
		"min_value": enchantment.min_value,
		"max_value": enchantment.max_value,
		"weight": enchantment.weight,
		"allowed_slot_flags": enchantment.allowed_slot_flags,
		"price_bonus_at_min_value": enchantment.price_bonus_at_min_value,
		"price_bonus_at_max_value": enchantment.price_bonus_at_max_value
	}


func _escape_cell(value: String) -> String:
	return value.replace("\t", " ").replace("\r", "\\n").replace("\n", "\\n")
