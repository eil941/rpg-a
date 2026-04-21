extends Resource
class_name ItemEffectData

enum EffectType {
	NONE,
	RESTORE_HP,
	CURE_STATUS,
	APPLY_STATUS,
	APPLY_BUFF,
	TELEPORT_RANDOM
}

enum ValueMode {
	FLAT,
	PERCENT,
	FULL
}

@export var effect_type: EffectType = EffectType.NONE
@export var value_mode: ValueMode = ValueMode.FLAT

# 数値系
@export var power_min: int = 0
@export var power_max: int = 0
@export var percent_value: float = 0.0

# 状態異常系
@export var status_id: StringName = &""
@export var duration_seconds: float = 0.0
@export var status_power: int = 0

# バフ系
@export var stat_name: StringName = &""
@export var stat_flat: int = 0
@export var stat_percent: float = 0.0

# テレポート系
@export var teleport_min_range: int = 0
@export var teleport_max_range: int = 999
