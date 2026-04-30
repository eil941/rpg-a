extends Resource
class_name InitialInventoryEntry


# 生成時にInventoryへ入れるアイテム1枠分の設定。
# EnemyData / NpcData の initial_inventory_items にこのResourceを並べる。
#
# 例:
# item_id = "apple"
# amount_min = 1
# amount_max = 3
# chance = 0.5
#
# これで apple が50%の確率で1〜3個生成される。

@export var enabled: bool = true
@export var item_id: String = ""

@export_range(0.0, 1.0, 0.01)
var chance: float = 1.0

@export var amount_min: int = 1
@export var amount_max: int = 1

# 装備品を生成する場合、trueならItemDatabase.build_random_equipment_entry()を使う。
# これにより、装備のエンチャント抽選も通常のランダム装備生成と同じ経路に乗る。
@export var roll_equipment_enchantments: bool = true


func build_entries(rng: RandomNumberGenerator) -> Array:
	var result: Array = []

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	if not should_generate(rng):
		return result

	if item_id == "":
		return result

	if not ItemDatabase.exists(item_id):
		push_warning("InitialInventoryEntry: ItemDatabaseに存在しないitem_idです: %s" % item_id)
		return result

	var amount: int = get_random_amount(rng)

	# 装備は基本スタックしない。
	# amountが2以上の場合も、1個ずつ別エントリとしてInventoryへ入れる。
	if ItemDatabase.is_equipment(item_id):
		for i in range(amount):
			if roll_equipment_enchantments:
				result.append(ItemDatabase.build_random_equipment_entry(item_id, rng))
			else:
				result.append({
					"item_id": item_id,
					"amount": 1
				})
		return result

	result.append({
		"item_id": item_id,
		"amount": amount
	})
	return result


func should_generate(rng: RandomNumberGenerator) -> bool:
	if not enabled:
		return false

	if item_id == "":
		return false

	var safe_chance: float = clamp(chance, 0.0, 1.0)

	if safe_chance <= 0.0:
		return false

	if safe_chance >= 1.0:
		return true

	return rng.randf() <= safe_chance


func get_random_amount(rng: RandomNumberGenerator) -> int:
	var safe_min: int = max(1, amount_min)
	var safe_max: int = max(safe_min, amount_max)
	return rng.randi_range(safe_min, safe_max)
