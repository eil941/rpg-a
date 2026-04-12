extends Resource
class_name QuestData

enum ObjectiveType {
	NONE,
	DELIVER_ITEM
}

@export var quest_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export_multiline var title_template: String = ""
@export_multiline var description_template: String = ""

@export var objective_type: ObjectiveType = ObjectiveType.DELIVER_ITEM

# 固定依頼用
@export var objective_item_id: String = ""
@export var objective_item_amount: int = 1

# ランダム依頼用
# 1. candidate_item_ids が入っていれば、その中から1つ選ぶ
# 2. candidate_categories が入っていれば、そのカテゴリ群から候補を作って1つ選ぶ
@export var candidate_item_ids: Array[String] = []
@export var candidate_categories: Array[String] = []

# 個数
@export var amount_min: int = 1
@export var amount_max: int = 3

# 時間制限
# 0以下なら無期限
@export var time_limit_seconds: float = 0.0

# 報酬
@export var reward_gold: int = 0
@export var random_reward_use_sell_price: bool = true
@export var reward_bonus_rate_min: float = 1.1
@export var reward_bonus_rate_max: float = 1.5
@export var reward_item_ids: Array[String] = []
@export var reward_item_amounts: Array[int] = []

# 汎用依頼抽選用
# 0 なら誰でも出せる
@export_flags(
	"VILLAGER",
	"MERCHANT",
	"GUARD",
	"RECRUIT",
	"QUEST_GIVER",
	"ENEMY_BOSS"
) var allowed_unit_role_flags: int = 0

@export var weight: int = 100
@export var repeatable: bool = true

@export_multiline var accept_text: String = "ありがとうございます。"
@export_multiline var progress_text: String = "進み具合はどうでしょうか。"
@export_multiline var ready_to_complete_text: String = "条件を満たしているようですね。"
@export_multiline var completed_text: String = "助かりました。"
@export_multiline var failed_text: String = "もう期限を過ぎています。"
