extends Node
class_name TradePriceCalculator


static func get_buy_price(player_unit, merchant_unit, item_id: String) -> int:
	var rate: float = get_trade_buy_rate_snapshot(player_unit, merchant_unit, item_id)
	return get_buy_price_with_rate(item_id, rate)


static func get_sell_price(player_unit, merchant_unit, item_id: String) -> int:
	var rate: float = get_trade_sell_rate_snapshot(player_unit, merchant_unit, item_id)
	return get_sell_price_with_rate(item_id, rate)


static func get_buy_price_for_entry(player_unit, merchant_unit, entry: Dictionary) -> int:
	var rate: float = get_trade_buy_rate_snapshot(
		player_unit,
		merchant_unit,
		String(entry.get("item_id", ""))
	)
	var base_price: int = get_entry_base_price(entry)
	var final_price: int = max(1, int(round(float(base_price) * rate)))

	print("[PRICE][BUY] entry = ", entry)
	print("[PRICE][BUY] base_price = ", base_price, " rate = ", rate, " final_price = ", final_price)

	return final_price


static func get_sell_price_for_entry(player_unit, merchant_unit, entry: Dictionary) -> int:
	var rate: float = get_trade_sell_rate_snapshot(
		player_unit,
		merchant_unit,
		String(entry.get("item_id", ""))
	)
	var base_price: int = get_entry_base_price(entry)
	var final_price: int = max(1, int(round(float(base_price) * rate)))

	print("[PRICE][SELL] entry = ", entry)
	print("[PRICE][SELL] base_price = ", base_price, " rate = ", rate, " final_price = ", final_price)

	return final_price


static func get_trade_buy_rate_snapshot(player_unit, merchant_unit, item_id: String = "") -> float:
	var rate: float = 1.0

	rate *= _get_friendliness_buy_rate(merchant_unit)
	rate *= _get_player_trade_skill_buy_rate(player_unit)
	rate *= _get_sale_rate(merchant_unit, item_id)

	return max(rate, 0.01)


static func get_trade_sell_rate_snapshot(player_unit, merchant_unit, item_id: String = "") -> float:
	var rate: float = 1.0

	rate *= 0.5
	rate *= _get_friendliness_sell_rate(merchant_unit)
	rate *= _get_player_trade_skill_sell_rate(player_unit)
	rate *= _get_sale_rate(merchant_unit, item_id)

	return max(rate, 0.01)


static func get_buy_price_with_rate(item_id: String, rate: float) -> int:
	var base_price: int = ItemDatabase.get_base_price(item_id)
	if base_price <= 0:
		return 0

	return max(1, int(round(float(base_price) * rate)))


static func get_sell_price_with_rate(item_id: String, rate: float) -> int:
	var base_price: int = ItemDatabase.get_base_price(item_id)
	if base_price <= 0:
		return 0

	return max(1, int(round(float(base_price) * rate)))


static func get_buy_price_with_rate_for_entry(entry: Dictionary, rate: float) -> int:
	var base_price: int = get_entry_base_price(entry)
	if base_price <= 0:
		return 0

	return max(1, int(round(float(base_price) * rate)))


static func get_sell_price_with_rate_for_entry(entry: Dictionary, rate: float) -> int:
	var base_price: int = get_entry_base_price(entry)
	if base_price <= 0:
		return 0

	return max(1, int(round(float(base_price) * rate)))


static func get_entry_base_price(entry: Dictionary) -> int:
	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return 0

	var base_price: int = ItemDatabase.get_base_price(item_id)
	var enchant_bonus: int = get_enchantment_price_bonus(entry)
	var total: int = max(0, base_price + enchant_bonus)

	print("[PRICE][BASE] item_id = ", item_id, " item_base = ", base_price, " enchant_bonus = ", enchant_bonus, " total = ", total)

	return total


static func get_enchantment_price_bonus(entry: Dictionary) -> int:
	if entry.is_empty():
		return 0

	var instance_data: Variant = entry.get("instance_data", {})
	if typeof(instance_data) != TYPE_DICTIONARY:
		print("[PRICE][ENCHANT] no instance_data entry = ", entry)
		return 0

	var enchantments: Variant = instance_data.get("enchantments", [])
	if not (enchantments is Array):
		print("[PRICE][ENCHANT] enchantments not array instance_data = ", instance_data)
		return 0

	var total_bonus: int = 0
	print("[PRICE][ENCHANT] enchantments = ", enchantments)

	for raw_data in enchantments:
		if typeof(raw_data) != TYPE_DICTIONARY:
			continue

		var enchant_id: String = String(raw_data.get("id", ""))
		var value: int = int(raw_data.get("value", 0))
		var enchant_data: EnchantmentData = EnchantmentDatabase.get_enchantment(enchant_id)

		print("[PRICE][ENCHANT] enchant_id = ", enchant_id, " value = ", value, " enchant_data = ", enchant_data)

		if enchant_data == null:
			continue

		print("[PRICE][ENCHANT] min_value = ", enchant_data.min_value)
		print("[PRICE][ENCHANT] max_value = ", enchant_data.max_value)
		print("[PRICE][ENCHANT] price_min = ", enchant_data.price_bonus_at_min_value)
		print("[PRICE][ENCHANT] price_max = ", enchant_data.price_bonus_at_max_value)
		print("[PRICE][ENCHANT] allowed_flags = ", enchant_data.allowed_slot_flags)

		var bonus: int = enchant_data.get_price_bonus_for_value(value)
		print("[PRICE][ENCHANT] bonus = ", bonus)

		total_bonus += bonus

	print("[PRICE][ENCHANT] total_bonus = ", total_bonus)
	return total_bonus


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
