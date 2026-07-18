# Item Use Flow
## 1. このページで理解すること
このページは、`healing_potion` のような通常アイテム、つまり consume 系アイテムを使ったときの処理入口です。
対象指定アイテム、装備攻撃効果、装備パッシブは扱いません。
読んだあとに、次を関数名つきで説明できる状態を目指します。
- ポーション使用時の処理順
- `Inventory` が担当する範囲
- `ItemDatabase` が使われる理由
- `ItemEffectManager` が担当する処理
- HPなどの数値は `Stats` 側で変わること
- item が減るタイミング
- 効果失敗時に消費されるかどうか
- 不具合時の確認順
前提として、[Start Here](start_here.md)、[Database And Manager Roles](database_and_manager_roles.md)、[Excel To Game Flow](excel_to_game_flow.md) を読んでいる想定です。
## 2. 最初に全体像
通常アイテム使用の大まかな地図です。厳密な全処理経路ではなく、最初に迷子にならないための見取り図として見てください。
```text
Inventory.use_item_at() / Inventory.use_hotbar_item_at()
↓ ItemDatabase.is_usable()
↓ ItemEffectManager.apply_item_effect()
↓ ItemDatabase.get_item_data()
↓ ItemEffectManager.apply_item_effects()
↓ ItemEffectManager.apply_single_effect()
↓ ItemEffectManager._apply_restore_resource()
↓ Stats の hp を変更
↓ Inventory で item を1個消費
↓ InventoryUI が refresh() / refresh_status_ui()
```
重要: 現行コードの `restore_resource` は `Stats.heal()` を直接呼びません。
`_apply_restore_resource()` から `_apply_resource_restore()` へ進み、`stats.hp` を更新します。
ただし、HPという数値を持つ場所は `Stats` なので、「回復は Stats 側の値を変える」と理解してください。
## 3. 使用開始
対象ファイル: `scripts/item/inventory.gd`
通常の袋スロットから使う入口は `use_item_at(index)` です。
ホットバーから使う入口は `use_hotbar_item_at(index)` です。
どちらも、対象スロットが `items[index]` か `hotbar_items[index]` か以外はほぼ同じ流れです。
### `use_item_at()`
- 入力: bag の `index`
- 確認: index が有効か、空スロットでないか、個体装備でないか
- item取得: `items[index]` から `item_id` と `amount`
- usable判定: `ItemDatabase.is_usable(item_id)`
- 効果実行: `ItemEffectManager.apply_item_effect(owner_unit, item_id)`
- 成功判定: 効果実行が true なら続行、false なら失敗終了
- 消費: 成功後にだけ `amount -= 1`
- UI更新: `Inventory` の成功結果を受けて `InventoryUI` が更新
### `use_hotbar_item_at()`
- 入力: hotbar の `index`
- 確認: hotbar index が有効か、空でないか、個体装備でないか
- item取得: `hotbar_items[index]` から `item_id` と `amount`
- 以降は `use_item_at()` と同じく、usable判定、効果実行、成功後消費へ進む
- 違い: 減らす対象が `items` ではなく `hotbar_items`
### UI更新
`Inventory` は画面を直接描き替えません。
`InventoryUI.use_selected_item()` が戻り値の `success` を確認し、成功時だけ `refresh()` と `refresh_status_ui()` を呼びます。
## 4. ItemDatabase
対象ファイル: `scripts/item/item_database.gd`
`ItemDatabase` は、item_id から登録済みの item data を取るための窓口です。
`Inventory` が `ItemDatabase` を見る理由は、所持品スロットには主に `item_id` と `amount` しかないからです。
「この item は使えるのか」「どんな効果を持つのか」は、スロットではなく登録済み data 側にあります。
`Inventory` が TSV を直接読まない理由:
- TSV 読み込みは `GameDataRegistry` の責務
- 実行時には TSV 行ではなく `ItemData` として登録済み
- `Inventory` は所持品と個数の管理に集中する
- item 定義の検索は `ItemDatabase` に任せる
`ItemDatabase` は正本ではありません。正本は `master_data.xlsx`、実行時入力は TSV、実行中の保持場所は `GameDataRegistry` です。
## 5. ItemEffectManager
対象ファイル: `scripts/item/item_effect_manager.gd`
`ItemEffectManager` は、item に設定された効果を実行します。
今回見る中心関数は `apply_item_effect()`、`apply_item_effects()`、`apply_single_effect()` です。
### `apply_item_effect()`
`Inventory` からは主に `ItemEffectManager.apply_item_effect(owner_unit, item_id)` で呼ばれます。
item_id を受け取った場合、`ItemDatabase.get_item_data(item_id)` で `ItemData` を取得します。
target が指定されていない場合、target は user 自身になります。
通常ポーションでは「自分に使う」流れです。
### `apply_item_effects()`
`ItemData.effects` に入っている効果配列を順に実行します。
`item_effect_links.tsv` の order によって並べられた効果がここで処理されます。
1つでも成功した効果があれば `applied_any=true` になり、最後に true を返します。
全効果が失敗、または効果が空なら false です。
### `apply_single_effect()`
1つの `ItemEffectData` を見て、`effect_type` ごとの handler へ分岐します。
現行コードでは `match effect.effect_type` です。
`healing_potion_restore_hp` は `restore_resource` なので、`_apply_restore_resource()` に進みます。
handler の戻り値 bool が、その effect の成功失敗になります。
## 6. `restore_resource`
今回詳しく見る効果は `restore_resource` だけです。
対象関数: `_apply_restore_resource()`
この関数は、target の `Stats` を探し、resource_type に応じた数値を回復します。
`healing_potion_restore_hp` の場合:
- target: user 自身
- resource_type: hp
- amount: `effect.get_rolled_power()` の結果
- 現行TSVでは 30
- 変更対象: `stats.hp`
- 上限: `target.get_total_max_hp()` または `stats.max_hp`
現行コードでは、ここで `Stats.heal()` は直接呼ばれません。
`_apply_resource_restore()` が `stats.hp` を上限つきで更新し、成功したら true を返します。
false になる主な条件は、target がない、Stats がない、resource_type が不明、Stats に対象 property がない場合です。
## 7. Stats
対象ファイル: `scripts/core/stats.gd`
`Stats` は HP などの数値を持つ場所です。
通常ポーションの現行経路では `Stats.heal()` は直接呼ばれません。
ただし、`heal()` は HP回復の基本的な考え方を見るために重要です。
`heal()` は amount を0以上にし、最大HPを更新し、`hp` に回復量を足し、`max_hp` を超えたら丸めます。
戻り値は `void` です。
`ItemEffectManager.apply_item_effect()` 系は bool を返しますが、`Stats.heal()` は bool を返しません。
## 8. 具体例: `healing_potion`
現行TSVで確認した内容:
- `data/master/items.tsv`: `healing_potion`、`usable=true`
- `data/master/item_effects.tsv`: `healing_potion_restore_hp`
- `data/master/item_effect_links.tsv`: `healing_potion -> healing_potion_restore_hp`
`healing_potion_restore_hp` は `effect_type=restore_resource`、`resource_type=hp`、`power_min=30`、`power_max=30` です。
```text
Inventory
↓ ItemDatabase
↓ ItemData
↓ ItemEffectManager
↓ healing_potion_restore_hp
↓ restore_resource
↓ Stats の hp を30回復、最大HPを超えない
↓ 成功
↓ Inventoryで1個減る
```
## 9. 実コード
全文ではなく、流れを理解するための重要部分だけを引用します。
### Inventory: `use_item_at()`
対象: `scripts/item/inventory.gd` / 関数: `use_item_at()` / 理由: usable判定と効果実行を見るため。
```gdscript
if not ItemDatabase.is_usable(item_id):
	return {
		"success": false,
		"item_id": item_id,
		"message": "このアイテムは使用できない"
	}
var owner_unit = get_parent()
```
読む点: 使えるかを `ItemDatabase` で確認し、owner の Unit を取ります。
入力: `item_id` / 結果: usable=falseなら失敗 / 次: `ItemEffectManager.apply_item_effect()`
### Inventory: 消費タイミング
対象: `scripts/item/inventory.gd` / 関数: `use_item_at()` / 理由: itemがいつ減るかを見るため。
```gdscript
if not ItemEffectManager.apply_item_effect(owner_unit, item_id):
	return {
		"success": false,
		"item_id": item_id,
		"message": "使用失敗"
	}
amount -= 1
```
読む点: 効果実行が true の後にだけ `amount -= 1` へ進みます。
入力: `owner_unit`, `item_id` / 結果: 成功後に個数を減らす / 次: slot 書き戻し。
### ItemDatabase: `get_item_data()`
対象: `scripts/item/item_database.gd` / 関数: `get_item_data()` / 理由: 登録済み data 取得の窓口を見るため。
```gdscript
static func get_item_resource(item_id: String):
	if item_id == "":
		return null
	if GameData == null:
		return null
	return GameData.get_item(item_id)
static func get_item_data(item_id: String):
	return get_item_resource(item_id)
```
読む点: TSVを読まず、`GameData.get_item(item_id)` から取ります。
入力: `item_id` / 結果: `ItemData` または null / 次: `apply_item_effects()`
### ItemEffectManager: `apply_item_effect()`
対象: `scripts/item/item_effect_manager.gd` / 関数: `apply_item_effect()` / 理由: item_id が ItemData に変わる場所を見るため。
```gdscript
if arg2 is String:
	user = arg1
	target = arg3
	if target == null:
		target = user
	item_data = ItemDatabase.get_item_data(String(arg2))
	if item_data == null:
		return false
```
読む点: target未指定なら user 自身になり、item_id から `ItemData` を取ります。
入力: `owner_unit`, `item_id` / 結果: dataなしなら false / 次: `apply_item_effects()`
### ItemEffectManager: `apply_item_effects()`
対象: `scripts/item/item_effect_manager.gd` / 関数: `apply_item_effects()` / 理由: effects配列が順番に処理される場所を見るため。
```gdscript
for effect in item_data.effects:
	if effect == null:
		continue
	var applied: bool = apply_single_effect(user, target, item_data, effect, use_flag_override)
	if applied:
		applied_any = true
```
読む点: 各 effect を `apply_single_effect()` に渡し、1つでも成功したら true へ近づきます。
入力: user, target, item_data / 結果: `applied_any` / 次: `apply_single_effect()`
### ItemEffectManager: `apply_single_effect()`
対象: `scripts/item/item_effect_manager.gd` / 関数: `apply_single_effect()` / 理由: `restore_resource` の分岐先を見るため。
```gdscript
match effect.effect_type:
	ItemEffectData.EffectType.NONE:
		return false
	ItemEffectData.EffectType.RESTORE_RESOURCE:
		return _apply_restore_resource(user, target, effect)
	ItemEffectData.EffectType.CURE_STATUS:
```
読む点: `RESTORE_RESOURCE` なら `_apply_restore_resource()` を呼びます。
入力: `ItemEffectData` / 結果: handler の bool / 次: `_apply_restore_resource()`
### ItemEffectManager: `_apply_restore_resource()`
対象: `scripts/item/item_effect_manager.gd` / 関数: `_apply_restore_resource()` / 理由: target、Stats、amount の扱いを見るため。
```gdscript
static func _apply_restore_resource(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false
	var stats = _get_stats_node(target)
	if stats == null:
		return false
	var amount: int = effect.get_rolled_power()
```
読む点: target と Stats がないと失敗し、effect から回復量を決めます。
入力: user, target, effect / 結果: 前提不足なら false / 次: `_apply_resource_restore()`
### ItemEffectManager: `_apply_resource_restore()`
対象: `scripts/item/item_effect_manager.gd` / 関数: `_apply_resource_restore()` / 理由: 現行コードで実際に `stats.hp` を更新する場所を見るため。
```gdscript
else:
	new_value = min(max_value, current_value + float(amount))
if typeof(current_value_variant) == TYPE_FLOAT or typeof(max_value_variant) == TYPE_FLOAT:
	stats.set(current_property, new_value)
else:
	stats.set(current_property, int(round(new_value)))
return true
```
読む点: 最大値を超えない値を計算し、`stats.set("hp", value)` のように書き換えます。
入力: stats, property, amount / 結果: Stats値更新と true / 次: 呼び出し元へ戻る。
### Stats: `heal()`
対象: `scripts/core/stats.gd` / 関数: `heal()` / 理由: HP回復の基本形と戻り値を見るため。
```gdscript
func heal(amount: int) -> void:
	var final_heal: int = max(0, amount)
	refresh_derived_max_hp(false)
	hp += final_heal
	if hp > max_hp:
		hp = max_hp
```
読む点: HPを増やし、最大HPを超えないようにします。
入力: 回復量 / 結果: `hp` 更新、戻り値は `void` / 次: なし。
## 10. 成功時
成功時の時系列です。
```text
use_item_at()
↓ スロット確認
↓ item_id / amount取得
↓ ItemDatabase.is_usable()
↓ ItemEffectManager.apply_item_effect()
↓ ItemDatabase.get_item_data()
↓ apply_item_effects()
↓ apply_single_effect()
↓ _apply_restore_resource()
↓ stats.hp 更新
↓ true が戻る
↓ Inventory が amount を1減らす
↓ InventoryUI が refresh() / refresh_status_ui()
```
大事なのは、item 消費が効果実行の後にあることです。
効果が false なら、通常は消費まで進みません。
## 11. 失敗時
| 状況 | どこで止まるか | item消費 |
| --- | --- | --- |
| itemが存在しない | `Inventory` が空スロットとして失敗 | 減らない |
| `usable=false` | `ItemDatabase.is_usable()` 後に `Inventory` が失敗 | 減らない |
| effect無し | `apply_item_effects()` が false | 減らない |
| restore失敗 | `_apply_restore_resource()` が false | 減らない |
| target無し | 通常は target=user。userも取れない場合は restore 側で false | 減らない |
## 12. デバッグ
| 症状 | 最初に見る場所 | 次に見る場所 | 理由 |
| --- | --- | --- | --- |
| ポーションが使えない | `inventory.gd` の `use_item_at()` / `use_hotbar_item_at()` | `item_database.gd` の `is_usable()`、`items.tsv` | 使用開始の guard と usable 判定を見るため |
| ポーションは使えるが回復しない | `item_effect_manager.gd` の `apply_item_effect()` 系 | `item_effects.tsv`、`item_effect_links.tsv` | effect が取得され restore に分岐しているかを見るため |
| HPは増えるがアイテムが減らない | `inventory.gd` の `amount -= 1` | `inventory_ui.gd` の `refresh()` | effect成功後の消費と表示更新を見るため |
| アイテムは減るがHPが増えない | `_apply_restore_resource()` / `_apply_resource_restore()` | `unit.gd` の `get_stats_node()`、`stats.gd` | true が返っているのに数値が変わらない原因を見るため |
| エフェクトだけ出る | `apply_single_effect()` | `item_effects.tsv` | 別の effect_type に分岐していないかを見るため |
| `item_effect_links`を書いたのに効かない | `item_effect_links.tsv` | `item_effects.tsv`、`game_data_registry.gd` の link 適用 | link は接続で、effect本体ではないため |
## 13. よくある勘違い
- `Inventory` が回復する: 違います。`Inventory` は使用開始、使用可否、消費を担当します。
- `ItemDatabase` が回復する: 違います。登録済み data を返すだけです。
- `Stats` が item を減らす: 違います。item を減らすのは `Inventory` です。
- `ItemEffectManager` が個数管理する: 違います。効果実行が担当です。
- `restore_resource` が Inventory を触る: 違います。target の `Stats` を変更します。
## 14. このページでは扱わない
このページでは、次は扱いません。
- 対象指定アイテム
- `CombatManager`
- 装備攻撃効果
- 装備パッシブ
- 状態異常
- Teleport
- Damage
- Death
## 15. 詳細docs
さらに詳しく確認する場合は、次を見ます。
- [equipment_item_effect_execution_path](../systems/equipment_item_effect_execution_path.md)
- [script_responsibility_map](../architecture/script_responsibility_map.md)
- [game_data_registry_loader_map](../systems/data/game_data_registry_loader_map.md)
このページは詳細 docs を置き換えるものではありません。
まず流れをつかみ、必要になったら詳細 docs に進みます。
## 16. 理解度チェック
1. HP回復アイテムを bag slot から使う入口はどの関数か。
2. hotbar から使う入口はどの関数か。
3. `Inventory` は通常アイテム使用でどこまで担当するか。
4. `ItemDatabase.is_usable()` が false の場合、item は減るか。
5. `ItemDatabase.get_item_data()` は何を返すか。
6. `ItemEffectManager.apply_item_effect()` が item_id を受け取った後、何を取得するか。
7. `apply_item_effects()` は複数 effect の成功失敗をどうまとめるか。
8. `restore_resource` で target が null の場合、どうなるか。
9. 現行コードの `restore_resource` は `Stats.heal()` を直接呼ぶか。
10. `Stats.heal()` の戻り値は bool か。
11. HPが増えない場合、`Inventory` の次に見る中心ファイルはどれか。
12. `item_effect_links.tsv` を書いたのに効かない場合、link 以外にどの TSV を見るか。
---
## 回答例
1. `scripts/item/inventory.gd` の `use_item_at()`。
2. `scripts/item/inventory.gd` の `use_hotbar_item_at()`。
3. スロット確認、使用可否確認、`ItemEffectManager` 呼び出し、成功時の個数消費、結果返却。
4. 減らない。`ItemEffectManager` へ進まず、失敗で返る。
5. `GameData` に登録済みの `ItemData`、または見つからなければ null。
6. `ItemDatabase.get_item_data(item_id)` で `ItemData` を取得する。
7. 各 effect を順に実行し、1つでも成功したら `applied_any=true` として true を返す。
8. `_apply_restore_resource()` が false を返す。
9. 直接呼ばない。現行コードでは `_apply_resource_restore()` が `stats.hp` を更新する。
10. bool ではない。`void`。
11. `scripts/item/item_effect_manager.gd`。
12. `data/master/item_effects.tsv`。effect 本体があるか確認する。
## 17. このページを読んだら説明できること
- [ ] ポーション使用時は `Inventory.use_item_at()` または `use_hotbar_item_at()` から始まる。
- [ ] `Inventory` は item_id と amount を見て、使えるか確認する。
- [ ] `Inventory` は `ItemDatabase.is_usable()` で usable を確認する。
- [ ] `Inventory` は効果実行を `ItemEffectManager.apply_item_effect()` に任せる。
- [ ] `ItemDatabase` は item_id から登録済み `ItemData` を返す。
- [ ] `ItemEffectManager` は `ItemData.effects` を順に実行する。
- [ ] `restore_resource` は target の `Stats` を探して、HPなどの値を更新する。
- [ ] 現行コードの `restore_resource` は `Stats.heal()` を直接呼ばない。
- [ ] item は効果が成功した後に `Inventory` で1個減る。
- [ ] 効果が失敗した場合、通常は item は減らない。
- [ ] UI更新は成功後に `InventoryUI` 側で行われる。
- [ ] 不具合時は、使用開始なら `Inventory`、効果なら `ItemEffectManager`、数値なら `Stats` を見る。
