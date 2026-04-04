extends Node
class_name TradePriceCalculator


static func get_buy_price(player_unit, merchant_unit, item_id: String) -> int:
	var base_price: int = ItemDatabase.get_base_price(item_id)
	if base_price <= 0:
		return 0

	var price: float = float(base_price)

	price *= _get_friendliness_buy_rate(merchant_unit)
	price *= _get_player_trade_skill_buy_rate(player_unit)
	price *= _get_sale_rate(merchant_unit, item_id)

	return max(1, int(round(price)))


static func get_sell_price(player_unit, merchant_unit, item_id: String) -> int:
	var base_price: int = ItemDatabase.get_base_price(item_id)
	if base_price <= 0:
		return 0

	var price: float = float(base_price)

	# 基本は買値より安くなる想定
	price *= 0.5
	price *= _get_friendliness_sell_rate(merchant_unit)
	price *= _get_player_trade_skill_sell_rate(player_unit)
	price *= _get_sale_rate(merchant_unit, item_id)

	return max(1, int(round(price)))


static func _get_friendliness_buy_rate(merchant_unit) -> float:
	if merchant_unit == null:
		return 1.0

	var friendliness: int = 0
	if "friendliness" in merchant_unit:
		friendliness = int(merchant_unit.friendliness)

	if friendliness >= 80:
		return 0.80
	elif friendliness >= 50:
		return 0.90
	elif friendliness >= 20:
		return 0.95
	elif friendliness <= -50:
		return 1.20

	return 1.0


static func _get_friendliness_sell_rate(merchant_unit) -> float:
	if merchant_unit == null:
		return 1.0

	var friendliness: int = 0
	if "friendliness" in merchant_unit:
		friendliness = int(merchant_unit.friendliness)

	if friendliness >= 80:
		return 1.20
	elif friendliness >= 50:
		return 1.10
	elif friendliness >= 20:
		return 1.05
	elif friendliness <= -50:
		return 0.80

	return 1.0


static func _get_player_trade_skill_buy_rate(player_unit) -> float:
	# 将来的にプレイヤーの交渉スキル等を参照
	return 1.0


static func _get_player_trade_skill_sell_rate(player_unit) -> float:
	# 将来的にプレイヤーの交渉スキル等を参照
	return 1.0


static func _get_sale_rate(merchant_unit, item_id: String) -> float:
	# 将来的にセールや商人個体補正を参照
	return 1.0
