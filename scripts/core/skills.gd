extends Node
class_name Skills

# =========================
# 非戦闘能力 = スキル
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
		"medical": medical
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
