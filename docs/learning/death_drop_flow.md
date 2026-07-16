# Death Drop Flow
このページは、死亡時ドロップだけを学ぶ入口です。
攻撃、ダメージ、HP0、死亡入口までは [combat_damage_death_flow](combat_damage_death_flow.md) を先に読むと追いやすくなります。
ここでは `Unit.handle_death()` に入ったあと、所持品が地面に落ち、保存されるまでを扱います。
## 1. このページで理解すること
- 死亡時ドロップは `Unit` から始まる
- drop対象はdrop tableではなく実際の所持品から集める
- bag、hotbar、equipmentで集め方と消し方が違う
- 地面pickup生成と保存は `ItemDropHelper` が担当する
- drop成功後にだけ元slotが消える
- map再訪で消える問題はWorldState保存まで見る
## 2. 最初に全体像
```text
Stats / CombatManager などでHPが0になる
↓
Unit.handle_death()
↓
Unit.drop_inventory_items_on_death_if_needed()
↓
Unit._collect_inventory_drop_targets()
↓
ItemDropHelper.drop_entry_near_unit()
↓
ItemPickup生成または既存stackへmerge
↓
WorldStateへpickup状態を保存
↓
成功したdrop元slotをclear
↓
Inventory / equipment更新
```
これは厳密な全分岐ではなく、最初に把握する地図です。
死亡時に `initial_inventory_entries.tsv` を読み直しているわけではありません。
死亡時ドロップは、そのUnitがその時点で持っているbag、hotbar、equipmentを見ます。
## 3. 死亡入口
この関数は死亡処理本体です。
二重死亡を止め、HPを0以下にそろえ、死亡時ドロップを呼びます。
### コード引用
死亡時ドロップがどこから始まるかを確認するためです。
```gdscript
func handle_death(cause: String = "") -> void:
		return

	death_handled = true

	if stats != null and _stats_has_property(stats, "hp"):
		stats.hp = min(int(stats.hp), 0)

	drop_inventory_items_on_death_if_needed()
```
- `death_handled` で二重死亡を防ぐ
- `stats.hp` を0以下にそろえる
- `drop_inventory_items_on_death_if_needed()` へ進む
- `cause`
- 自分自身の `stats`
- 自分自身のinventory/equipment設定
- 死亡時ドロップ処理へ進む
## 4. Unitが担当する範囲
`Unit` は死亡したキャラクター全体を管理します。
死亡時ドロップでは、次を担当します。
- dropしてよいか判断する
- inventoryがあるか確認する
- bag / hotbar / equipmentからdrop対象を集める
- `ItemDropHelper` に地面dropを依頼する
- 成功したdrop元だけclearする
- playerの場合は `PlayerData` 側へ所持品状態を反映する
- 地面pickupの細かい配置計算
- stack可能pickupとのmerge
- WorldStateへのpickup保存の細部
- TSVからdrop tableを読み直すこと
## 5. dropしてよいか
最初に見る条件は `drop_inventory_on_death` と `inventory` です。
`drop_inventory_on_death=false` なら、bag、hotbar、equipmentを含めて死亡時ドロップは行いません。
`inventory == null` なら、落とす元がないので終了します。
### コード引用
死亡時ドロップが早期終了する条件を確認するためです。
```gdscript
func drop_inventory_items_on_death_if_needed() -> void:
	var debug_scope_enabled: bool = _is_debug_player_death_drop_scope_enabled()

			var empty_targets_for_drop_disabled: Array[Dictionary] = []
			_debug_log_death_drop_scope_targets(empty_targets_for_drop_disabled)
			_debug_log_death_drop_scope_result(0, 0)
			print("[DEATH DROP] skipped by drop_inventory_on_death=false")
		return
```
- debug scopeの有無を確認する
- `drop_inventory_on_death` がfalseなら終了する
- debug時はskip理由を出す
- `drop_inventory_on_death`
- `DebugSettings`
- falseならdrop対象収集へ進まない
`inventory == null` の確認、または `_collect_inventory_drop_targets()`
## 6. 落とす対象を集める
現行コードで集める対象は次の3種類です。
- bag
- hotbar
- equipment
equipmentは `drop_equipped_items_on_death` がtrueの場合だけ対象です。
### コード引用
drop対象が実所持品から作られることを確認するためです。
```gdscript
func _collect_inventory_drop_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

		return result

	if inventory.has_method("get_all_items"):
		var bag_items: Array = inventory.get_all_items()
		for i in range(bag_items.size()):
			var raw_entry: Variant = bag_items[i]
```
- `result` にdrop候補を積む
- inventoryがなければ空で返す
- bagの中身をslot順に見る
- `inventory`
- drop候補の配列
bag、hotbar、equipmentそれぞれのentry追加処理
## 7. bag / hotbar / equipmentの違い
- `inventory.get_all_items()` から取得する
- 成功したら `clear_slot()` または `set_item_data_at()` で消す
- `inventory.get_all_hotbar_items()` から取得する
- 成功したら `clear_hotbar_slot()` または `set_hotbar_item_data_at()` で消す
- `equipment_slot_order` を見て装備entryを取得する
- `drop_equipped_items_on_death=false` なら対象外
- 成功したら `clear_equipment_slot()` で外す
## 8. drop元を消すタイミング
drop元は、地面へのdropが成功したあとに消えます。
先に消してから地面生成するわけではありません。
これにより、地面生成に失敗した時にアイテムだけ失われる事故を避けています。
### コード引用
drop成功後にだけ元slotをclearする順番を確認するためです。
```gdscript
		var dropped: bool = ItemDropHelper.drop_entry_near_unit(entry, self, max_radius)
			dropped_count += 1
			_clear_inventory_drop_target(target)
			failed_count += 1

		_debug_log_death_drop_scope_result(dropped_count, failed_count)
```
- `ItemDropHelper` にdropを依頼する
- trueならdrop元をclearする
- falseなら失敗数を増やす
- drop対象entry
- 死亡したUnit
- drop半径
- 成功したものだけinventory/equipmentから消える
`ItemDropHelper.drop_entry_near_unit()`
## 9. ItemDropHelper
`ItemDropHelper` は、Unit近くにitem pickupを置く補助役です。
- entryを正規化する
- map、tile、ItemPickups nodeなどのcontextを作る
- stack可能pickupがあればmergeする
- 置けるtileを探す
- ItemPickupを生成する
- WorldStateにpickup状態を保存する
- Unitの死亡判定
- drop対象のbag/hotbar/equipment収集
- drop元slotのclear
### コード引用
地面dropがどんな条件で失敗するかを確認するためです。
```gdscript
static func drop_entry_near_unit(entry: Dictionary, unit: Node, max_radius: int = 5) -> bool:
		return false

	var normalized_entry: Dictionary = _normalize_entry(entry)
	if _is_empty_entry(normalized_entry):
		return false

	var context: Dictionary = _build_drop_context(unit)
		return false
```
- Unitがない場合は失敗する
- 空entryは失敗する
- map contextが作れない場合も失敗する
- item entry
- 死亡したUnit
- drop半径
- 成功時 true
- 失敗時 false
stack merge、配置tile探索、spawn、WorldState保存
## 10. WorldStateに保存される理由
地面に出たpickupは、その場で表示されるだけでは足りません。
mapを離れて戻ったときにpickupが残る必要があります。
そのため `ItemDropHelper` は生成またはmerge後に、pickup状態をWorldStateへ保存します。
この保存が抜けると、死亡直後は見えるのにmap再訪やsave/loadで消えます。
その場合は `ItemDropHelper`、`ItemWorldManager`、`WorldState` を見ます。
## 11. 成功時の時系列
```text
Unit.handle_death()
↓
drop_inventory_items_on_death_if_needed()
↓
drop_inventory_on_death と inventory を確認
↓
_collect_inventory_drop_targets()
↓
bag / hotbar / equipment からentryを集める
↓
ItemDropHelper.drop_entry_near_unit()
↓
地面pickup生成またはstack merge
↓
WorldState保存
↓
trueが返る
↓
_clear_inventory_drop_target()
↓
playerならPlayerDataへinventory/equipmentを保存
↓
notify_inventory_refresh()
```
成功時のポイントは、`ItemDropHelper` がtrueを返してから元slotが消えることです。
## 12. 失敗時の時系列
- drop対象を集めない
- debug scope有効時はskip logが出る
- 元slotは残る
- drop対象を集められない
- 元slotを消す処理にも進まない
- bag/hotbar/equipmentに落とせるentryがない
- 正常な空終了
`ItemDropHelper.drop_entry_near_unit()` がfalse:
- map contextがない
- entryが空
- tileが見つからない
- pickup sceneがない
- 元slotはclearされない
## 13. drop flag
- 死亡時ドロップ全体の親スイッチ
- falseならbag、hotbar、equipmentすべて落ちない
- equipmentをdrop対象に含めるかを決める
- `drop_inventory_on_death=true` のときだけ意味がある
- Unitの周囲どの範囲までdrop場所を探すか
- 現行コードでは最低1になる
## 14. debug scope
- `debug_player_death_drop_scope_test_enabled`
- `debug_player_death_drop_scope_mode`
modeは現行コードで `none`、`inventory_only`、`all` を受け付けます。
### コード引用
`apply_debug_player_death_drop_scope_if_needed()`
debug modeがdrop flagをどう変えるかを確認するためです。
```gdscript
			drop_inventory_on_death = false
			drop_equipped_items_on_death = false
			drop_inventory_on_death = true
			drop_equipped_items_on_death = false
			drop_inventory_on_death = true
			drop_equipped_items_on_death = true
```
- `none` は何も落とさない
- `inventory_only` はbag/hotbarだけ落とす
- `all` は装備も含める
- `DebugSettings.debug_player_death_drop_scope_mode`
- playerのdeath drop flagが上書きされる
## 15. 具体例
例として、Unitが `healing_potion` をbagに持って死亡した場合を追います。
- bagに `{"item_id": "healing_potion", "amount": 1}` がある
- `drop_inventory_on_death=true`
- `inventory != null`
- map上に `ItemPickups` nodeがある
```text
Unit.handle_death()
↓
drop_inventory_items_on_death_if_needed()
↓
_collect_inventory_drop_targets()
↓
bag entryとして healing_potion を収集
↓
ItemDropHelper.drop_entry_near_unit()
↓
Unitの足元または周辺tileにpickup生成
↓
WorldStateへpickup保存
↓
true
↓
bag slot clear
```
- 地面に `healing_potion` pickupが出る
- 元のbag slotは空になる
- map再訪時にもWorldStateから復元される
## 16. 不具合時の確認順
- 最初に見る: `Unit.drop_inventory_items_on_death_if_needed()`
- 次に見る: `drop_inventory_on_death`、`inventory`、`_collect_inventory_drop_targets()`
- 理由: drop全体がskipされているか、対象が空の可能性が高い
- 最初に見る: `drop_equipped_items_on_death`
- 次に見る: `_collect_inventory_drop_targets()` のequipment部分
- 理由: equipmentは別flagで対象化される
- 最初に見る: `ItemDropHelper.drop_entry_near_unit()`
- 次に見る: map root、`ItemPickups`、`item_pickup_scene`、tile探索
- 理由: 対象は集まっていても、地面生成で失敗することがある
- 最初に見る: `_clear_inventory_drop_target()`
- 次に見る: targetの `source`、`index`、`slot_name`
- 理由: 元slot clearはsource別で行われる
- 最初に見る: `ItemDropHelper` のWorldState保存
- 次に見る: `ItemWorldManager` と `WorldState`
- 理由: 表示生成と永続保存は別の責務
- 最初に見る: `DebugSettings.debug_player_death_drop_scope_test_enabled`
- 次に見る: 対象Unitがplayerかどうか
- 理由: debug scopeはplayer死亡ドロップ確認用
## 17. よくある勘違い
- 死亡時にdrop tableを読む: 現行コードでは実所持品を見る
- `ItemDropHelper` がinventoryを消す: 元slotを消すのは `Unit`
- 装備dropは常にbagと同じ: `drop_equipped_items_on_death` が必要
- drop失敗でも元itemは消える: trueが返った時だけclearする
- player death drop debugは全Unitに効く: 現行コードではplayer unitだけ
## 18. このページでは扱わない
攻撃命中、ダメージ計算、通常アイテム使用、装備効果、loot table設計、save/load全体仕様は詳細docsへ進みます。
## 19. 詳細docs
- [combat_damage_death_flow](combat_damage_death_flow.md)
- [death_drop_spec](../systems/death_drop_spec.md)
- [death_path_diagram](../systems/death_path_diagram.md)
- [unit_lifecycle_deep_dive](../systems/unit_lifecycle_deep_dive.md)
- [map_spawn_persistence_deep_dive](../systems/map_spawn_persistence_deep_dive.md)
- [save_worldstate_playerdata_map](../systems/save_worldstate_playerdata_map.md)
- [script_responsibility_map](../architecture/script_responsibility_map.md)
## 20. 理解度チェック
1. 死亡時ドロップは、最初にどの関数から呼ばれますか。
2. `drop_inventory_on_death=false` の場合、bagだけは落ちますか。
3. 装備をdrop対象に含めるflagは何ですか。
4. 死亡時ドロップは、drop tableを読み直しますか。
5. 地面pickupの生成を担当する主なscriptは何ですか。
6. dropに成功したあと、元slotを消すのはどのscriptですか。
7. `ItemDropHelper.drop_entry_near_unit()` がfalseを返した場合、元slotは消えますか。
8. 地面に出たitemがmap再訪で消える場合、どの保存経路を疑いますか。
9. debug scope mode `inventory_only` では装備は落ちますか。
10. bagは落ちるが装備だけ落ちない場合、最初に見るflagは何ですか。
---
## 回答例
1. `Unit.handle_death()` から `drop_inventory_items_on_death_if_needed()` が呼ばれます。
2. 落ちません。`drop_inventory_on_death` は死亡時ドロップ全体の親スイッチです。
3. `drop_equipped_items_on_death` です。
4. 読み直しません。実際のbag、hotbar、equipmentを見ます。
5. `scripts/item/item_drop_helper.gd` です。
6. `Unit` です。`_clear_inventory_drop_target()` でsource別に消します。
7. 消えません。trueが返った場合だけclearします。
8. `ItemDropHelper` のWorldState保存、`ItemWorldManager`、`WorldState` を見ます。
9. 落ちません。bag/hotbarだけが対象です。
10. `drop_equipped_items_on_death` です。
## 21. このページを読んだら説明できること
- [ ] 死亡時ドロップは `Unit.handle_death()` の後に始まる
- [ ] `drop_inventory_on_death` は死亡時ドロップ全体の親スイッチ
- [ ] `drop_equipped_items_on_death` は装備を含めるかのスイッチ
- [ ] drop対象は実所持品から集める
- [ ] `ItemDropHelper` は地面pickup生成と保存を担当する
- [ ] 元slotのclearはdrop成功後に `Unit` が行う
- [ ] drop失敗時は元slotを消さない
- [ ] map再訪で消える場合はWorldState保存経路を見る
