extends Resource
class_name AttackedBehaviorData

# プレイヤーから右クリックメニューなどで明示的に攻撃された後の設定。
# NpcData / EnemyData のインスペクターでは、このResourceを1つ設定するだけで、
# 敵対化・戦闘スタイル・移動スタイルをまとめて管理できる。

enum AICombatStyle {
	AUTO,
	MELEE,
	MID,
	LONG,
	SUPPORTER,
	HIT_AND_RUN,
	DEFENSIVE
}

enum AIMoveStyle {
	AUTO,
	APPROACH,
	KEEP_DISTANCE,
	FLEE,
	HOLD
}

# 攻撃されたUnitを敵対化するか。
# 通常はtrue推奨。falseにすると、行動だけ変える特殊イベント用に使える。
@export var become_hostile: bool = true

# 攻撃された後にAI行動パターンを変更するか。
# falseなら敵対化だけ行い、既存のcombat_style / move_styleを維持する。
@export var change_behavior: bool = true

@export var override_combat_style: bool = false
@export_enum("AUTO", "MELEE", "MID", "LONG", "SUPPORTER", "HIT_AND_RUN", "DEFENSIVE")
var combat_style: int = AICombatStyle.AUTO

@export var override_move_style: bool = true
@export_enum("AUTO", "APPROACH", "KEEP_DISTANCE", "FLEE", "HOLD")
var move_style: int = AIMoveStyle.FLEE


func apply_to_unit(unit) -> void:
	if unit == null:
		return

	if become_hostile:
		if "faction" in unit:
			unit.faction = "ENEMY"

	if not change_behavior:
		return

	if override_combat_style:
		if "override_combat_style" in unit:
			unit.override_combat_style = true
		if "combat_style" in unit:
			unit.combat_style = combat_style

	if override_move_style:
		if "override_move_style" in unit:
			unit.override_move_style = true
		if "move_style" in unit:
			unit.move_style = move_style
