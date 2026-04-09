extends Resource
class_name EnchantmentData

enum EffectType {
	STAT
}

enum AllowedSlot {
	NONE = 0,
	HAND = 1,
	HEAD = 2,
	BODY = 4,
	HANDS = 8,
	WAIST = 16,
	FEET = 32,
	ACCESSORY = 64
}

@export var enchant_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var effect_type: EffectType = EffectType.STAT

@export_enum("attack", "defense", "max_hp", "speed")
var stat_name: String = "attack"

@export var min_value: int = 1
@export var max_value: int = 3
@export var weight: int = 10

@export_flags(
	"HAND",
	"HEAD",
	"BODY",
	"HANDS",
	"WAIST",
	"FEET",
	"ACCESSORY"
)
var allowed_slot_flags: int = (
	AllowedSlot.HAND |
	AllowedSlot.HEAD |
	AllowedSlot.BODY |
	AllowedSlot.HANDS |
	AllowedSlot.WAIST |
	AllowedSlot.FEET |
	AllowedSlot.ACCESSORY
)

# 値幅に応じて価格補正を線形補間する。
# min_value時の補正額とmax_value時の補正額をInspectorから設定する。
# 例: min=1, max=3, min_bonus=30, max_bonus=90 の場合
# +1 -> 30, +2 -> 60, +3 -> 90
# 逆にしたければ min_bonus/max_bonus を逆転させればよい。
@export var price_bonus_at_min_value: int = 30
@export var price_bonus_at_max_value: int = 90


func get_slot_flag_from_name(slot_name: String) -> int:
	match slot_name:
		"hand", "right_hand", "left_hand":
			return AllowedSlot.HAND
		"head":
			return AllowedSlot.HEAD
		"body":
			return AllowedSlot.BODY
		"hands":
			return AllowedSlot.HANDS
		"waist":
			return AllowedSlot.WAIST
		"feet":
			return AllowedSlot.FEET
		"accessory", "accessory_1", "accessory_2", "accessory_3", "accessory_4":
			return AllowedSlot.ACCESSORY
		_:
			return AllowedSlot.NONE


func allows_slot_name(slot_name: String) -> bool:
	var slot_flag: int = get_slot_flag_from_name(slot_name)
	if slot_flag == AllowedSlot.NONE:
		return false

	return (allowed_slot_flags & slot_flag) != 0


func get_price_bonus_for_value(value: int) -> int:
	if max_value <= min_value:
		return price_bonus_at_min_value

	var clamped_value: int = clampi(value, min_value, max_value)
	var t: float = float(clamped_value - min_value) / float(max_value - min_value)

	return int(round(lerpf(
		float(price_bonus_at_min_value),
		float(price_bonus_at_max_value),
		t
	)))
