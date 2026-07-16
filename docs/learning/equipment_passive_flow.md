# Equipment Passive Flow
## 1. このページで理解すること
このページは、装備している間だけ能力値へ反映される装備パッシブ効果の入口です。
装備攻撃効果は扱いません。
読んだあとに、次を関数名つきで説明できる状態を目指します。
- `equipment.tsv` の固定bonus
- `item_effects.tsv` の `apply_modifier`
- 固定bonusと `apply_modifier` は別の仕組みであること
- 装備中effectを `Unit` が集めること
- 合計stat計算時に反映されること
- 装備を外すと次の計算から戻ること
- `ItemEffectManager` が中心ではない理由
- 装備しても能力値が上がらない時の確認順

## 2. 最初に全体像
装備パッシブには大きく2つの流れがあります。
```text
equipment.tsv の固定bonus
↓ EquipmentData
↓ Unit.get_all_equipped_resources()
↓ Unit.get_total_attack() など
↓ 合計値
```
```text
item_effects.tsv の apply_modifier
↓ item_effect_links.tsv
↓ EquipmentData.effects
↓ Unit.get_equipped_item_effects()
↓ Unit._get_total_equipment_effect_modifier()
↓ Unit._apply_equipment_effect_modifier()
↓ 合計値
```
どちらも「装備した瞬間に `stats.attack += bonus` する」方式ではありません。
必要な時に `get_total_attack()` などの合計関数が、現在の装備状態を見て値を返します。

## 3. 対象スクリプト
最低限見るファイル:
- `scripts/core/unit.gd`
- `scripts/item/item_database.gd`
- `scripts/item/inventory.gd`
- `scripts/data/equipment_data.gd`
- `scripts/data/item_effect_data.gd`
- `scripts/data/game_data_registry.gd`
詳細docs:
- [equipment_item_effect_execution_path](../systems/equipment_item_effect_execution_path.md)
- [unit_lifecycle_deep_dive](../systems/unit_lifecycle_deep_dive.md)
- [script_responsibility_map](../architecture/script_responsibility_map.md)
- [Equipment Attack Effect Flow](equipment_attack_effect_flow.md)
- [Database And Manager Roles](database_and_manager_roles.md)

## 4. 固定bonus
対象TSV: `data/master/equipment.tsv`
主な列:
- `max_hp_bonus`
- `attack_bonus`
- `defense_bonus`
- `speed_bonus`
これらは `EquipmentData` に入り、`Unit.get_total_*()` が装備中リソースを集計する時に足されます。
例:
- `power_ring`: `attack_bonus=20`
- `sample_copper_guard_ring`: `max_hp_bonus=3`
固定bonusは、effectを実行するものではありません。
装備している間だけ、合計値計算に加算されます。

## 5. apply_modifier
対象TSV:
- `data/master/item_effects.tsv`
- `data/master/item_effect_links.tsv`
主な列:
- `effect_type=apply_modifier`
- `modifier_kind`
- `stat_name`
- `stat_flat`
- `stat_percent`
`apply_modifier` は、装備中 item の `effects` に入っている時だけ、`Unit` の合計stat計算で参照されます。
通常アイテムの一時buffとは入口が違います。
装備パッシブでは、毎回 `ItemEffectManager.apply_item_effect()` を呼びません。
中心は `Unit._get_total_equipment_effect_modifier()` です。

## 6. Unit
対象ファイル: `scripts/core/unit.gd`
中心関数:
- `get_equipped_item_effects()`
- `_get_total_equipment_effect_modifier()`
- `_apply_equipment_effect_modifier()`
- `get_total_attack()`
- `get_total_defense()`
- `get_total_max_hp()`
- `get_total_speed()`
`Unit` は装備状態を持ち、装備中itemのeffectを集めます。
固定bonusは `get_all_equipped_resources()` から集計されます。
`apply_modifier` は `get_equipped_item_effects()` から集計されます。
その後、statごとに必要なmodifierだけを合算し、固定bonusと合わせた値を返します。

## 7. ItemDatabaseと読み込み
`ItemDatabase.get_equipment_resource(item_id)` は、登録済み item data が `EquipmentData` なら返します。
TSVを読むのは `ItemDatabase` ではありません。
`GameDataRegistry._load_equipment()` が `equipment.tsv` を読み、既存の `ItemData` を `EquipmentData` に置き換えます。
`GameDataRegistry._apply_item_effect_links()` が `item_effect_links.tsv` を適用し、装備itemの `effects` に `ItemEffectData` を入れます。
その結果、`Unit` は装備entryから `EquipmentData` と effects を取れるようになります。

## 8. ItemEffectManagerとの違い
通常アイテムや一時buffでは、`ItemEffectManager.apply_item_effect()` が効果を実行します。
装備パッシブでは、装備している間に毎回 `apply_item_effect()` を呼ぶわけではありません。
`Unit` が現在の装備状態を見て、合計statを計算する時に反映します。
つまり、装備パッシブの中心は `Unit` の合計stat関数です。
`trigger_chance` も装備パッシブでは使いません。
`trigger_chance` は装備攻撃効果の発動判定で使います。

## 9. 具体例: `sample_copper_guard_ring`
現行TSVで確認した例:
- `items.tsv`: `sample_copper_guard_ring` は equipment
- `equipment.tsv`: `max_hp_bonus=3`
- `item_effects.tsv`: `sample_copper_guard_ring_defense_bonus`
- `effect_type=apply_modifier`
- `modifier_kind=buff`
- `stat_name=defense`
- `stat_flat=1`
- `item_effect_links.tsv`: item と effect を order 1 で接続
この指輪は、固定bonusとして最大HPを増やし、`apply_modifier` として defense を+1します。
流れ:
```text
sample_copper_guard_ring を装備
↓ EquipmentData.max_hp_bonus
↓ get_total_max_hp()
↓ 最大HPに +3
```
```text
sample_copper_guard_ring_defense_bonus
↓ get_equipped_item_effects()
↓ _get_total_equipment_effect_modifier("defense")
↓ get_total_defense()
↓ defense に +1
```

## 10. 実コード
### Unit: effect収集
対象: `scripts/core/unit.gd` / 関数: `get_equipped_item_effects()` / 理由: 装備中effectを集める場所を見るため。
```gdscript
func get_equipped_item_effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var using_hotbar_override: bool = _is_using_hotbar_hand_override_slot()

	for slot_name in equipment_slot_order:
		if using_hotbar_override and (slot_name == "right_hand" or slot_name == "left_hand"):
			continue
```
ここで装備スロットを順に確認します。
入力: 現在の装備状態 / 結果: effect entry配列 / 次: modifier集計。

### Unit: apply_modifier集計
対象: `scripts/core/unit.gd` / 関数: `_get_total_equipment_effect_modifier()` / 理由: `apply_modifier` だけを拾う場所を見るため。
```gdscript
for effect_entry in get_equipped_item_effects():
	var effect: ItemEffectData = effect_entry.get("effect") as ItemEffectData
	if effect == null:
		continue
	if effect.effect_type != ItemEffectData.EffectType.APPLY_MODIFIER:
		continue
	if String(effect.stat_name) != stat_key:
		continue
```
ここで装備effectの中から対象statの `apply_modifier` だけを集めます。
入力: stat名 / 結果: flatとpercent / 次: `_apply_equipment_effect_modifier()`。

### Unit: modifier適用
対象: `scripts/core/unit.gd` / 関数: `_apply_equipment_effect_modifier()` / 理由: flatとpercentを合計値へ反映する場所を見るため。
```gdscript
var modifier: Dictionary = _get_total_equipment_effect_modifier(stat_name, context)
var flat_bonus: int = int(modifier.get("flat", 0))
var percent_bonus: float = float(modifier.get("percent", 0.0))
var multiplier: float = max(0.0, 1.0 + percent_bonus)
var modified_value: int = int(round((float(base_value) + float(flat_bonus)) * multiplier))
```
ここで固定値加算と割合補正を計算します。
入力: base_value / 結果: modified value / 次: final valueを返す。

### Unit: attack合計
対象: `scripts/core/unit.gd` / 関数: `get_total_attack()` / 理由: 固定bonusとmodifierの合流を見るため。
```gdscript
for equipment in get_all_equipped_resources():
	total += equipment.attack_bonus

total += _get_total_enchantment_bonus("attack")

total = _apply_equipment_effect_modifier(&"attack", max(total, 0), 0)
```
固定bonus、enchantment、apply_modifierが順に合流します。
入力: statsと装備 / 結果: 合計attack / 次: 戦闘やUIが利用。

### ItemDatabase: 装備取得
対象: `scripts/item/item_database.gd` / 関数: `get_equipment_resource()` / 理由: item_idからEquipmentDataを取る場所を見るため。
```gdscript
static func get_equipment_resource(item_id: String):
	var data = get_item_resource(item_id)
	if data is EquipmentData:
		return data

	return null
```
ここでは登録済みdataが装備なら返します。
入力: item_id / 結果: `EquipmentData` または null / 次: Unit装備処理。

### GameDataRegistry: link適用
対象: `scripts/data/game_data_registry.gd` / 関数: `_apply_item_effect_links()` / 理由: effectが装備dataに入る場所を見るため。
```gdscript
var links: Array = item_effect_links[item_id]
links.sort_custom(func(a, b): return int(a["order"]) < int(b["order"]))

item.effects.clear()

for link in links:
	var effect_id := String(link["effect_id"])
```
ここで `item_effect_links.tsv` の順番に effects が接続されます。
入力: item_id/effect_id/order / 結果: `item.effects` / 次: Unitが参照。

## 11. 成功時
装備して値が上がる流れ:
```text
装備slotへentryが入る
↓ Unitが装備中itemを参照
↓ fixed bonusを加算
↓ get_equipped_item_effects()
↓ apply_modifierを集計
↓ get_total_attack() などが新しい値を返す
↓ UIや戦闘が合計値を使う
```
装備を外した時:
```text
装備slotからentryが外れる
↓ 次の合計値計算で対象外
↓ base statは直接書き換えられていない
↓ 値が元に戻る
```

## 12. デバッグ
| 症状 | 最初に見る場所 | 次に見る場所 | 理由 |
| --- | --- | --- | --- |
| 装備できない | 装備slotへ入れる処理 | `ItemDatabase.get_equipment_resource()` | 装備として認識されているか見るため |
| 固定bonusが反映されない | `get_total_attack()` など | `equipment.tsv` | 固定bonus列が集計されるか見るため |
| `apply_modifier` が反映されない | `_get_total_equipment_effect_modifier()` | `item_effects.tsv` / `item_effect_links.tsv` | effect接続とstat名を見るため |
| 外しても値が戻らない | 装備slot状態 | `get_total_*()` 呼び出し元 | base statを直接変えていないか見るため |
| UI表示だけ変わらない | UI更新処理 | `get_total_*()` | 内部値と表示の差を分けるため |
| effectが重複して見える | `get_equipped_item_effects()` | hotbar hand override | 有効装備が二重に集計されていないか見るため |
| 想定装備が使われない | `_is_using_hotbar_hand_override_slot()` | selected hotbar entry | 手装備が一時的に無視される場合があるため |

## 13. よくある勘違い
- 装備時に `stats.attack += bonus` する: 違います。合計関数で計算します。
- 装備解除時に減算する: 違います。次の合計計算から外れます。
- 装備パッシブは `ItemEffectManager` が実行する: 違います。中心は `Unit` です。
- 固定bonusと `apply_modifier` は同じ: 違います。TSV列も計算経路も別です。
- `trigger_chance` が装備パッシブにも使われる: 現行では使いません。
- `equipment_effect_links.tsv` を使う: 現行では `item_effect_links.tsv` を使います。
- `item_effect_links.tsv` を書けば自動で攻撃時効果になる: typeと使われる文脈で変わります。

## 14. このページでは扱わない
- 装備攻撃効果
- 通常アイテムの一時buff
- 状態異常
- enchantの詳細
- 装備UIの全state machine
- Save/Load
- Trade/Chest

## 15. 理解度チェック
1. 固定bonusはどのTSVにあるか。
2. `apply_modifier` はどのTSVで定義されるか。
3. itemとeffectをつなぐTSVは何か。
4. 装備中effectを集める関数は何か。
5. 対象statのmodifierだけを集める関数は何か。
6. `get_total_attack()` はbase statだけを返すか。
7. 装備を外した時、base statを書き戻す必要があるか。
8. 装備パッシブで `ItemEffectManager.apply_item_effect()` を毎回呼ぶか。
9. `trigger_chance` は装備パッシブで使うか。
10. `sample_copper_guard_ring` の modifier stat は何か。
---
## 回答例
1. `equipment.tsv`。
2. `item_effects.tsv`。
3. `item_effect_links.tsv`。
4. `Unit.get_equipped_item_effects()`。
5. `_get_total_equipment_effect_modifier()`。
6. 返さない。装備bonusやmodifierを含める。
7. 不要。次の合計計算から対象外になる。
8. 呼ばない。
9. 使わない。
10. `defense`。

## 16. 自己確認チェックリスト
- [ ] 固定bonusと `apply_modifier` の違いを説明できる。
- [ ] 装備パッシブの中心が `Unit` だと説明できる。
- [ ] `ItemEffectManager` が中心ではない理由を説明できる。
- [ ] `get_total_attack()` などが合計値を返すと説明できる。
- [ ] 装備解除時にbase statを戻す方式ではないと説明できる。
- [ ] `trigger_chance` は装備攻撃効果側だと説明できる。
- [ ] 不具合時に `Unit`、TSV、UIを分けて確認できる。
