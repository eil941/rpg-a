extends Node
class_name Skills

# =========================
# スキル
# =========================

# 探索系
@export var gathering: int = 0       # 採取
@export var investigation: int = 0   # 調査
@export var stealth: int = 0         # 隠密
@export var trap_disarm: int = 0     # 罠解除
@export var fishing: int = 0         # 釣り
@export var appraisal: int = 0       # 鑑定

# 生活・生産系
@export var cooking: int = 0         # 料理
@export var repair: int = 0          # 修理
@export var smithing: int = 0        # 鍛冶
@export var alchemy: int = 0         # 錬金

# 社会系
@export var negotiation: int = 0     # 交渉
@export var speech: int = 0          # 話術

# 知識・補助系
@export var medical: int = 0         # 医療

# スキル習得状態
var learned_skills: Dictionary = {
	"gathering": false,
	"investigation": false,
	"stealth": false,
	"trap_disarm": false,
	"fishing": false,
	"appraisal": false,
	"cooking": false,
	"repair": false,
	"smithing": false,
	"alchemy": false,
	"negotiation": false,
	"speech": false,
	"medical": false
}

# スキル成長
@export var skill_growth_threshold: int = 40

var skill_growth_points: Dictionary = {
	"gathering": 0,
	"investigation": 0,
	"stealth": 0,
	"trap_disarm": 0,
	"fishing": 0,
	"appraisal": 0,
	"cooking": 0,
	"repair": 0,
	"smithing": 0,
	"alchemy": 0,
	"negotiation": 0,
	"speech": 0,
	"medical": 0
}

func is_skill_learned(skill_name: String) -> bool:
	if learned_skills.has(skill_name):
		return bool(learned_skills[skill_name])

	push_warning("未知のスキルです: %s" % skill_name)
	return false

func learn_skill(skill_name: String) -> void:
	if not learned_skills.has(skill_name):
		push_warning("未知のスキルです: %s" % skill_name)
		return

	learned_skills[skill_name] = true

	if get_skill_value(skill_name) < 1:
		set_skill_value(skill_name, 1)

func forget_skill(skill_name: String) -> void:
	if not learned_skills.has(skill_name):
		push_warning("未知のスキルです: %s" % skill_name)
		return

	learned_skills[skill_name] = false
	set_skill_value(skill_name, 0)

	if skill_growth_points.has(skill_name):
		skill_growth_points[skill_name] = 0

func gain_skill_growth(skill_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	if not skill_growth_points.has(skill_name):
		push_warning("未知のスキルです: %s" % skill_name)
		return

	if not is_skill_learned(skill_name):
		return

	skill_growth_points[skill_name] += amount
	apply_skill_growth(skill_name)

func apply_skill_growth(skill_name: String) -> void:
	if not skill_growth_points.has(skill_name):
		push_warning("未知のスキルです: %s" % skill_name)
		return

	if not is_skill_learned(skill_name):
		return

	while skill_growth_points[skill_name] >= skill_growth_threshold:
		skill_growth_points[skill_name] -= skill_growth_threshold
		increase_skill(skill_name, 1)

func increase_skill(skill_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	if not is_skill_learned(skill_name):
		return

	var current_value: int = get_skill_value(skill_name)
	set_skill_value(skill_name, current_value + amount)

	on_skill_increased(skill_name, amount)

func on_skill_increased(skill_name: String, amount: int) -> void:
	print(skill_name, " が ", amount, " 上がりました")

func get_skill_value(skill_name: String) -> int:
	match skill_name:
		"gathering":
			return gathering
		"investigation":
			return investigation
		"stealth":
			return stealth
		"trap_disarm":
			return trap_disarm
		"fishing":
			return fishing
		"appraisal":
			return appraisal
		"cooking":
			return cooking
		"repair":
			return repair
		"smithing":
			return smithing
		"alchemy":
			return alchemy
		"negotiation":
			return negotiation
		"speech":
			return speech
		"medical":
			return medical
		_:
			push_warning("未知のスキルです: %s" % skill_name)
			return 0

func set_skill_value(skill_name: String, value: int) -> void:
	value = max(value, 0)

	match skill_name:
		"gathering":
			gathering = value
		"investigation":
			investigation = value
		"stealth":
			stealth = value
		"trap_disarm":
			trap_disarm = value
		"fishing":
			fishing = value
		"appraisal":
			appraisal = value
		"cooking":
			cooking = value
		"repair":
			repair = value
		"smithing":
			smithing = value
		"alchemy":
			alchemy = value
		"negotiation":
			negotiation = value
		"speech":
			speech = value
		"medical":
			medical = value
		_:
			push_warning("未知のスキルです: %s" % skill_name)

func get_skill_growth_point(skill_name: String) -> int:
	if skill_growth_points.has(skill_name):
		return int(skill_growth_points[skill_name])

	push_warning("未知のスキルです: %s" % skill_name)
	return 0

func get_skills_data() -> Dictionary:
	return {
		"gathering": gathering,
		"investigation": investigation,
		"stealth": stealth,
		"trap_disarm": trap_disarm,
		"fishing": fishing,
		"appraisal": appraisal,
		"cooking": cooking,
		"repair": repair,
		"smithing": smithing,
		"alchemy": alchemy,
		"negotiation": negotiation,
		"speech": speech,
		"medical": medical,
		"learned_skills": learned_skills.duplicate(true),
		"skill_growth_threshold": skill_growth_threshold,
		"skill_growth_points": skill_growth_points.duplicate(true)
	}

func apply_skills_data(data: Dictionary) -> void:
	if data.has("gathering"):
		gathering = int(data["gathering"])
	if data.has("investigation"):
		investigation = int(data["investigation"])
	if data.has("stealth"):
		stealth = int(data["stealth"])
	if data.has("trap_disarm"):
		trap_disarm = int(data["trap_disarm"])
	if data.has("fishing"):
		fishing = int(data["fishing"])
	if data.has("appraisal"):
		appraisal = int(data["appraisal"])
	if data.has("cooking"):
		cooking = int(data["cooking"])
	if data.has("repair"):
		repair = int(data["repair"])
	if data.has("smithing"):
		smithing = int(data["smithing"])
	if data.has("alchemy"):
		alchemy = int(data["alchemy"])
	if data.has("negotiation"):
		negotiation = int(data["negotiation"])
	if data.has("speech"):
		speech = int(data["speech"])
	if data.has("medical"):
		medical = int(data["medical"])
	if data.has("learned_skills"):
		learned_skills = data["learned_skills"].duplicate(true)
	if data.has("skill_growth_threshold"):
		skill_growth_threshold = int(data["skill_growth_threshold"])
	if data.has("skill_growth_points"):
		skill_growth_points = data["skill_growth_points"].duplicate(true)
