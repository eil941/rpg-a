extends Resource
class_name ItemEffectData

# 効果の大分類
enum EffectType {
	NONE,

	# 回復
	RESTORE_RESOURCE,

	# 状態異常
	CURE_STATUS,
	APPLY_STATUS,

	# 能力変化
	APPLY_MODIFIER,

	# ダメージ
	DEAL_DAMAGE,

	# 取得
	GRANT_ITEM,
	GRANT_CURRENCY,

	# 移動
	TELEPORT,

	# 成長
	PERMANENT_STAT_GROWTH,

	# 習得・解放
	LEARN_SKILL,
	UNLOCK_RECIPE,
	IDENTIFY_ITEM,

	# 読み物
	READ_DOCUMENT,

	# 設置
	SPAWN_OBJECT
}

# 数値の扱い
enum ValueMode {
	FLAT,
	PERCENT,
	FULL
}

# 持続時間の扱い
enum DurationType {
	NONE,
	TIME,
	TURN,
	ACTION
}

# modifier の種類
enum ModifierKind {
	BUFF,
	DEBUFF
}

# 回復対象
enum ResourceType {
	HP,
	MP,
	STAMINA,
	HUNGER
}

# テレポートの種類
enum TeleportMode {
	RANDOM,
	POINT,
	HOME,
	DUNGEON_EXIT
}

@export var effect_type: EffectType = EffectType.NONE

# 共通
@export var value_mode: ValueMode = ValueMode.FLAT

# 数値系
@export var power_min: int = 0
@export var power_max: int = 0
@export var percent_value: float = 0.0

# 回復系
@export var resource_type: ResourceType = ResourceType.HP

# 状態異常系
@export var status_id: StringName = &""
@export var status_power: int = 0

# バフ/デバフ系
@export var modifier_kind: ModifierKind = ModifierKind.BUFF
@export var stat_name: StringName = &""
@export var stat_flat: int = 0
@export var stat_percent: float = 0.0

# 持続
@export var duration_type: DurationType = DurationType.NONE
@export var duration_value: float = 0.0

# テレポート系
@export var teleport_mode: TeleportMode = TeleportMode.RANDOM
@export var teleport_min_range: int = 0
@export var teleport_max_range: int = 999
@export var warp_point_id: StringName = &""

# 取得系
@export var grant_item_id: String = ""
@export var grant_item_amount: int = 1
@export var grant_currency_amount: int = 0

# 習得/解放系
@export var skill_id: StringName = &""
@export var recipe_id: StringName = &""

# 鑑定
@export var identify_all: bool = false

# 読み物
@export_multiline var document_text: String = ""

# 設置
@export var spawn_object_id: StringName = &""

func get_effect_type_name() -> String:
	match effect_type:
		EffectType.NONE:
			return "none"
		EffectType.RESTORE_RESOURCE:
			return "restore_resource"
		EffectType.CURE_STATUS:
			return "cure_status"
		EffectType.APPLY_STATUS:
			return "apply_status"
		EffectType.APPLY_MODIFIER:
			return "apply_modifier"
		EffectType.DEAL_DAMAGE:
			return "deal_damage"
		EffectType.GRANT_ITEM:
			return "grant_item"
		EffectType.GRANT_CURRENCY:
			return "grant_currency"
		EffectType.TELEPORT:
			return "teleport"
		EffectType.PERMANENT_STAT_GROWTH:
			return "permanent_stat_growth"
		EffectType.LEARN_SKILL:
			return "learn_skill"
		EffectType.UNLOCK_RECIPE:
			return "unlock_recipe"
		EffectType.IDENTIFY_ITEM:
			return "identify_item"
		EffectType.READ_DOCUMENT:
			return "read_document"
		EffectType.SPAWN_OBJECT:
			return "spawn_object"
		_:
			return "unknown"

func get_resource_type_name() -> String:
	match resource_type:
		ResourceType.HP:
			return "hp"
		ResourceType.MP:
			return "mp"
		ResourceType.STAMINA:
			return "stamina"
		ResourceType.HUNGER:
			return "hunger"
		_:
			return ""

func get_modifier_kind_name() -> String:
	match modifier_kind:
		ModifierKind.BUFF:
			return "buff"
		ModifierKind.DEBUFF:
			return "debuff"
		_:
			return ""

func get_teleport_mode_name() -> String:
	match teleport_mode:
		TeleportMode.RANDOM:
			return "random"
		TeleportMode.POINT:
			return "point"
		TeleportMode.HOME:
			return "home"
		TeleportMode.DUNGEON_EXIT:
			return "dungeon_exit"
		_:
			return ""

func get_rolled_power() -> int:
	var min_value: int = power_min
	var max_value: int = max(power_max, min_value)

	if min_value == max_value:
		return min_value

	return randi_range(min_value, max_value)

func has_duration() -> bool:
	return duration_type != DurationType.NONE and duration_value > 0.0

func uses_status_id() -> bool:
	return effect_type == EffectType.CURE_STATUS or effect_type == EffectType.APPLY_STATUS

func uses_modifier_fields() -> bool:
	return effect_type == EffectType.APPLY_MODIFIER or effect_type == EffectType.PERMANENT_STAT_GROWTH

func uses_resource_type() -> bool:
	return effect_type == EffectType.RESTORE_RESOURCE

func uses_teleport_fields() -> bool:
	return effect_type == EffectType.TELEPORT

func uses_grant_item_fields() -> bool:
	return effect_type == EffectType.GRANT_ITEM

func uses_grant_currency_fields() -> bool:
	return effect_type == EffectType.GRANT_CURRENCY

func uses_skill_id() -> bool:
	return effect_type == EffectType.LEARN_SKILL

func uses_recipe_id() -> bool:
	return effect_type == EffectType.UNLOCK_RECIPE

func uses_document_text() -> bool:
	return effect_type == EffectType.READ_DOCUMENT

func uses_spawn_object_id() -> bool:
	return effect_type == EffectType.SPAWN_OBJECT
