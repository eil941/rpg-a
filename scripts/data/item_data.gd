extends Resource
class_name ItemData

# 使用方法
enum ItemUseFlag {
	USE_SELF = 1,
	USE_UNIT_TARGET = 2,
	USE_THROW_TARGET = 4,
	USE_SPECIAL = 8
}

# 使用対象
enum ItemTargetFlag {
	TARGET_SELF = 1,
	TARGET_ALLY = 2,
	TARGET_ENEMY = 4,
	TARGET_NEUTRAL = 8
}

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: String = "misc"
@export var max_stack: int = 99
@export var usable: bool = false
@export var base_price: int = 0
@export var can_sell: bool = true

# 出現用
@export_range(1, 10, 1) var rarity: int = 1
@export var spawn_weight: int = 100

# 使用方法
@export_flags("Self", "UnitTarget", "ThrowTarget", "Special")
var use_flags: int = 0

@export_flags("Self", "Ally", "Enemy", "Neutral")
var target_flags: int = 0

# 新方式
@export var effects: Array[ItemEffectData] = []

func get_item_type_name() -> String:
	return ItemCategories.normalize(category)

func has_use_flag(flag: int) -> bool:
	return (use_flags & flag) != 0

func has_target_flag(flag: int) -> bool:
	return (target_flags & flag) != 0

func can_use_on_self() -> bool:
	if has_use_flag(ItemUseFlag.USE_SELF):
		return has_target_flag(ItemTargetFlag.TARGET_SELF)
	return false

func can_use_on_other_unit() -> bool:
	if has_use_flag(ItemUseFlag.USE_UNIT_TARGET):
		if has_target_flag(ItemTargetFlag.TARGET_ALLY):
			return true
		if has_target_flag(ItemTargetFlag.TARGET_ENEMY):
			return true
		if has_target_flag(ItemTargetFlag.TARGET_NEUTRAL):
			return true
	return false

func can_throw_to_target() -> bool:
	if has_use_flag(ItemUseFlag.USE_THROW_TARGET):
		if has_target_flag(ItemTargetFlag.TARGET_SELF):
			return true
		if has_target_flag(ItemTargetFlag.TARGET_ALLY):
			return true
		if has_target_flag(ItemTargetFlag.TARGET_ENEMY):
			return true
		if has_target_flag(ItemTargetFlag.TARGET_NEUTRAL):
			return true
	return false

func get_rarity_value() -> int:
	return clampi(int(rarity), 1, 10)

func get_spawn_weight_value() -> int:
	return max(0, int(spawn_weight))
