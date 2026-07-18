# Script Quick Reference

このページは、scriptを開いたあとに「最初に何を見るか」を30秒で決めるためのリファレンスです。

learning docsのように処理を順番に学ぶ文書ではありません。流れを理解したい時は `docs/learning/`、作業手順を確認したい時は `docs/guides/`、詳細仕様を追う時は `docs/systems/` を読みます。

## 使い方

1. 症状や作業内容に近いscriptを探します。
2. 「最初に見る関数」を上から確認します。
3. 迷ったら「よく見る次のscript」へ進みます。
4. 詳しい流れが必要になったらlearning docsへ戻ります。

優先度は、プロジェクト所有者が開く頻度の目安です。

## 症状から探す

| 症状・作業内容 | 最初に見るscript | 次に見るscript | 関連learning docs |
| --- | --- | --- | --- |
| Excelへ追加したデータがゲームに入らない | GameDataRegistry | `tools/export_master_tsv.py` / 対象TSV | [excel_to_game_flow](../learning/excel_to_game_flow.md) |
| TSVにはあるがitem_idが見つからない | ItemDatabase | GameDataRegistry / `items.tsv` | [database_and_manager_roles](../learning/database_and_manager_roles.md) |
| itemとeffectのリンクが反映されない | GameDataRegistry | ItemDatabase / `item_effect_links.tsv` | [excel_to_game_flow](../learning/excel_to_game_flow.md) |
| アイテムが使えない | Inventory | ItemDatabase / ItemEffectManager | [item_use_flow](../learning/item_use_flow.md) |
| アイテムを使っても個数が減らない | Inventory | ItemEffectManager / InventoryUI | [item_use_flow](../learning/item_use_flow.md) |
| ポーションを使えるがHPが回復しない | ItemEffectManager | Stats / Unit | [item_use_flow](../learning/item_use_flow.md) |
| hotbarから使った時だけ挙動が違う | Inventory | InventoryUI / Unit | [item_use_flow](../learning/item_use_flow.md) |
| アイテムは増減しているがUIへ反映されない | InventoryUI | Inventory / Unit | [debug_first_steps](../learning/debug_first_steps.md) |
| 装備パッシブが反映されない | Unit | ItemDatabase / GameDataRegistry | [equipment_passive_flow](../learning/equipment_passive_flow.md) |
| 装備攻撃効果が発動しない | CombatManager | Unit / GameDataRegistry | [equipment_attack_effect_flow](../learning/equipment_attack_effect_flow.md) |
| `trigger_chance`が想定どおり動かない | CombatManager | GameDataRegistry / `item_effects.tsv` | [equipment_attack_effect_flow](../learning/equipment_attack_effect_flow.md) |
| 攻撃できない | CombatManager | Unit / Stats | [combat_damage_death_flow](../learning/combat_damage_death_flow.md) |
| ダメージ量がおかしい | DamageCalculator | CombatManager / Stats | [combat_damage_death_flow](../learning/combat_damage_death_flow.md) |
| 命中、回避、criticalがおかしい | DamageCalculator | Stats / Unit | [combat_damage_death_flow](../learning/combat_damage_death_flow.md) |
| HPが減らない | Stats | CombatManager / ItemEffectManager | [combat_damage_death_flow](../learning/combat_damage_death_flow.md) |
| HP0なのに死亡しない | Stats | Unit | [combat_damage_death_flow](../learning/combat_damage_death_flow.md) |
| 死亡処理が二重に動いているように見える | Unit | Stats / CombatManager | [combat_damage_death_flow](../learning/combat_damage_death_flow.md) |
| 死亡時にアイテムが落ちない | Unit | ItemDropHelper | [death_drop_flow](../learning/death_drop_flow.md) |
| 一部の所持品だけ落ちない | Unit | Inventory / ItemDropHelper | [death_drop_flow](../learning/death_drop_flow.md) |
| 地面へ出たpickupがmap再訪で消える | ItemDropHelper | ItemWorldManager / WorldState | [death_drop_flow](../learning/death_drop_flow.md) |
| save/load後にpickupが戻らない | ItemDropHelper | WorldState / ItemWorldManager | [death_drop_flow](../learning/death_drop_flow.md) |
| 敵が生成されない | UnitSpawnManager | GameDataRegistry / Unit | [debug_first_steps](../learning/debug_first_steps.md) |
| NPCが生成されない | UnitSpawnManager | GameDataRegistry / Unit | [debug_first_steps](../learning/debug_first_steps.md) |
| 保存済みの敵やNPCが復元されない | UnitSpawnManager | WorldState / GameDataRegistry | [debug_first_steps](../learning/debug_first_steps.md) |
| 初期inventoryやshop inventoryがおかしい | UnitSpawnManager | Unit / GameDataRegistry | [excel_to_game_flow](../learning/excel_to_game_flow.md) |
| debug logが出ない | DebugSettings | 対象機能のscript | [debug_first_steps](../learning/debug_first_steps.md) |
| debug logが出すぎる | DebugSettings | 対象機能のscript | [debug_first_steps](../learning/debug_first_steps.md) |
| debug start itemが配られない | DebugSettings | Unit / PlayerData | [debug_first_steps](../learning/debug_first_steps.md) |
| debug設定を戻したか分からない | DebugSettings | `debug_settings_deep_dive` | [debug_first_steps](../learning/debug_first_steps.md) |

## GameDataRegistry

パス: `scripts/data/game_data_registry.gd`

役割:
TSVを読み込み、Item、Enemy、NPC、Effect、Spawnなどのruntime用データを保持します。
ゲーム中の多くのDatabaseやManagerへ、登録済みデータを提供する土台です。

このscriptを開く状況:
- Excel / TSVに書いたデータがゲームに入らない
- item_id、effect_id、enemy_type_id、npc_type_id が見つからない
- `item_effect_links.tsv` の効果がitemへ反映されない

最初に見る関数:
- `load_all()`
- `get_item()`
- `get_enemy()`
- `_build_item_effect()`
- `_apply_item_effect_links()`

このscriptは何をしないか:
- アイテムを使用しない
- 攻撃やダメージを実行しない
- 所持数やUI状態を管理しない

よく見る次のscript:
```text
GameDataRegistry
↓
ItemDatabase
↓
Inventory / ItemEffectManager / UnitSpawnManager
```

読む優先順位:
★★★★★

初心者が最初に読むべきか:
YES

理解できれば何ができるようになるか:
- Excel / TSVからゲームへ入る流れを追える
- itemとeffectの紐づき不具合を調べられる
- spawnやenemy / npc dataの入口を探せる

## ItemDatabase

パス: `scripts/item/item_database.gd`

役割:
登録済みのitem dataをitem_idから取得する窓口です。
表示名、説明、アイコン、装備情報、usable判定など、item lookupをまとめています。

このscriptを開く状況:
- item_idは分かるが、表示名や説明が取れない
- `usable` や装備判定がおかしい
- InventoryやUIがitem情報をどう取得するか知りたい

最初に見る関数:
- `get_item_data()`
- `is_usable()`
- `is_equipment()`
- `get_equipment_resource()`
- `get_effect_summary_lines()`

このscriptは何をしないか:
- TSVを直接読み込まない
- item効果を実行しない
- item個数を増減しない

よく見る次のscript:
```text
ItemDatabase
↓
GameDataRegistry
↓
Inventory / InventoryUI
```

読む優先順位:
★★★★★

初心者が最初に読むべきか:
YES

理解できれば何ができるようになるか:
- item_idから何が取得されるか分かる
- InventoryやUIのitem表示不具合を追える
- DatabaseとManagerの違いを実感できる

## Inventory

パス: `scripts/item/inventory.gd`

役割:
bag、hotbar、所持品entry、個数、消費、保存用データを管理します。
通常アイテム使用の入口もここにあります。

このscriptを開く状況:
- ポーションが使えない
- itemが減らない、増えない、stackしない
- hotbarから使った時だけ挙動が違う

最初に見る関数:
- `use_item_at()`
- `use_hotbar_item_at()`
- `add_item_entry()`
- `consume_item_amount()`
- `get_all_items()`

このscriptは何をしないか:
- HP回復そのものを実行しない
- TSVを直接読まない
- UIの描画やslot visualを作らない

よく見る次のscript:
```text
Inventory
↓
ItemDatabase
↓
ItemEffectManager
↓
InventoryUI
```

読む優先順位:
★★★★★

初心者が最初に読むべきか:
YES

理解できれば何ができるようになるか:
- 通常アイテム使用の入口を追える
- 所持品の増減や消費タイミングを調べられる
- bagとhotbarの違いを追える

## ItemEffectManager

パス: `scripts/item/item_effect_manager.gd`

役割:
通常アイテムや対象指定アイテムのeffectを実行します。
`ItemData.effects` を順に見て、effect_typeごとのhandlerへ分岐します。

このscriptを開く状況:
- ポーションは使えるが回復しない
- status、damage、teleportなどのitem effectが効かない
- `item_effects.tsv` に書いたeffect_typeが実行されない

最初に見る関数:
- `apply_item_effect()`
- `apply_item_effects()`
- `apply_single_effect()`
- `_apply_restore_resource()`
- `_apply_resource_restore()`

このscriptは何をしないか:
- Inventory個数を管理しない
- 通常攻撃の入口を担当しない
- 装備パッシブのstat合成を担当しない

よく見る次のscript:
```text
ItemEffectManager
↓
ItemData / ItemEffectData
↓
Stats / Unit
```

読む優先順位:
★★★★★

初心者が最初に読むべきか:
YES

理解できれば何ができるようになるか:
- 通常アイテム効果の分岐を追える
- effect_type追加が必要か判断しやすくなる
- 回復、状態異常、damage系の不具合入口が分かる

## CombatManager

パス: `scripts/combat/combat_manager.gd`

役割:
攻撃、対象指定行動、装備攻撃効果の入口を管理します。
攻撃可否、命中後のダメージ処理、target item use、装備attack effectの発動判定が集まっています。

このscriptを開く状況:
- 攻撃できない
- 装備攻撃効果が出ない
- 対象指定アイテムが使えない
- 通常攻撃後の死亡確認を追いたい

最初に見る関数:
- `can_attack()`
- `perform_attack()`
- `can_use_selected_target_item()`
- `perform_selected_target_item_use()`
- `_apply_equipment_attack_effects()`

このscriptは何をしないか:
- TSVを読み込まない
- Unitの装備を保持しない
- HPやstatusの基礎値を保存しない

よく見る次のscript:
```text
CombatManager
↓
DamageCalculator
↓
Stats / Unit
↓
ItemEffectManager
```

読む優先順位:
★★★★★

初心者が最初に読むべきか:
YES

理解できれば何ができるようになるか:
- 通常攻撃の入口を追える
- 装備攻撃効果とtrigger_chanceを追える
- 対象指定アイテムの戦闘側入口を調べられる

## DamageCalculator

パス: `scripts/combat/damage_calculator.gd`

役割:
攻撃者、対象、attack_dataから命中、critical、元素、damage値を計算します。
計算結果を返すだけで、HP変更や死亡処理は行いません。

このscriptを開く状況:
- ダメージ量が想定と違う
- 命中、回避、criticalがおかしい
- elementやdamage_type補正を確認したい

最初に見る関数:
- `calculate_damage()`
- `_make_result()`
- `_get_effective_attack()`
- `_get_effective_defense()`
- `_get_element_rate()`

このscriptは何をしないか:
- HPを書き換えない
- 死亡処理しない
- 攻撃対象を選ばない

よく見る次のscript:
```text
CombatManager
↓
DamageCalculator
↓
Stats
```

読む優先順位:
★★★★☆

初心者が最初に読むべきか:
NO

理解できれば何ができるようになるか:
- damage計算の原因を切り分けられる
- attack、defense、accuracy、evasionの影響を追える
- element耐性の影響を確認できる

## Unit

パス: `scripts/core/unit.gd`

役割:
キャラクター全体を管理する中心scriptです。
Stats、Inventory、装備、移動、死亡、drop、save/load、status runtimeなど多くの機能をつなぎます。

このscriptを開く状況:
- 装備効果がおかしい
- HP0なのに死亡しない
- 死亡時ドロップがおかしい
- Unitの保存や復元がおかしい

最初に見る関数:
- `get_equipped_item_effects()`
- `get_equipped_attack_effects()`
- `get_total_attack()`
- `check_death()`
- `handle_death()`

このscriptは何をしないか:
- TSVを直接読み込まない
- damage計算式そのものを持たない
- InventoryUIの表示を組み立てない

よく見る次のscript:
```text
Unit
↓
Stats / Inventory
↓
CombatManager / ItemDropHelper
```

読む優先順位:
★★★★☆

初心者が最初に読むべきか:
NO

理解できれば何ができるようになるか:
- 装備パッシブを追える
- HP0から死亡処理まで追える
- death dropやstatus runtimeの入口を探せる

## Stats

パス: `scripts/core/stats.gd`

役割:
HP、stamina、hunger、基礎能力値、派生戦闘値を持ちます。
HP damage / heal / dieの基礎処理と、能力値からの派生値計算を扱います。

このscriptを開く状況:
- HPが減らない、増えない
- HP0から死亡に進まない
- attack、defense、accuracyなどの基礎値を確認したい

最初に見る関数:
- `take_damage()`
- `die()`
- `heal()`
- `refresh_derived_max_hp()`
- `get_effective_attack()`

このscriptは何をしないか:
- 死亡時ドロップをしない
- 装備一覧を保持しない
- item effectの分岐をしない

よく見る次のscript:
```text
Stats
↓
Unit
↓
CombatManager / ItemEffectManager
```

読む優先順位:
★★★★☆

初心者が最初に読むべきか:
YES

理解できれば何ができるようになるか:
- HP変更と死亡通知の入口を追える
- 派生戦闘値の基礎を確認できる
- Unitとの責務差を理解できる

## InventoryUI

パス: `scripts/item/inventory_ui.gd`

役割:
Inventory、hotbar、equipment、trade、chestなどのUI表示と入力を管理します。
held item、slot選択、ドラッグ相当の移動、tooltip、表示更新が集まっています。

このscriptを開く状況:
- itemは増減しているがUIに反映されない
- inventory画面の操作がおかしい
- held itemやtrade / chest表示がおかしい

最初に見る関数:
- `open_with_inventory()`
- `refresh()`
- `use_selected_item()`
- `handle_confirm_action()`
- `drop_held_entry_to_inventory()`

このscriptは何をしないか:
- TSVを読まない
- item効果を実行しない
- HPやdamageを計算しない

よく見る次のscript:
```text
InventoryUI
↓
Inventory
↓
ItemDatabase
```

読む優先順位:
★★★☆☆

初心者が最初に読むべきか:
NO

理解できれば何ができるようになるか:
- UI表示と内部Inventoryのずれを調べられる
- held itemやslot移動の問題を追える
- trade / chest UIの入口を探せる

## ItemDropHelper

パス: `scripts/item/item_drop_helper.gd`

役割:
Unit近くにitem pickupを生成し、stack mergeやWorldState保存を行う補助scriptです。
死亡時ドロップや手動dropの地面配置側を担当します。

このscriptを開く状況:
- 死亡時にitemが地面へ出ない
- pickupがmap再訪で消える
- stack可能itemがまとまらない

最初に見る関数:
- `drop_entry_near_unit()`
- `_build_drop_context()`
- `_find_nearest_empty_drop_tile()`
- `_spawn_pickup_from_entry()`
- `_save_item_pickups_to_world_state()`

このscriptは何をしないか:
- Unitの死亡判定をしない
- drop対象のbag / hotbar / equipment収集をしない
- 元inventory slotをclearしない

よく見る次のscript:
```text
Unit
↓
ItemDropHelper
↓
ItemPickup / WorldState
```

読む優先順位:
★★★☆☆

初心者が最初に読むべきか:
NO

理解できれば何ができるようになるか:
- death dropの地面生成側を追える
- pickup永続化の入口を確認できる
- drop失敗時の原因を切り分けられる

## DebugSettings

パス: `scripts/debug/DebugSettings.gd`

役割:
debug flag、debug start item、確認用modeをまとめるAutoloadです。
関数中心ではなく、現在どのdebug設定がON/OFFかを見るためのscriptです。

このscriptを開く状況:
- debug logが出ない、出すぎる
- debug start itemが配られない
- 装備効果やdeath dropの確認flagを切り替えたい

最初に見る関数:
- 関数なし
- `debug_game_data_load_summary`
- `debug_game_data_load_details`
- `debug_equipment_effects`
- `debug_player_death_drop_scope_test_enabled`

このscriptは何をしないか:
- 不具合を直接修正しない
- itemやUnitの処理本体を実行しない
- save dataの整合性を保証しない

よく見る次のscript:
```text
DebugSettings
↓
GameDataRegistry / Unit / CombatManager
↓
対象機能のscript
```

読む優先順位:
★★★★☆

初心者が最初に読むべきか:
YES

理解できれば何ができるようになるか:
- 調査用logや開始アイテムの状態を確認できる
- debug flag由来の挙動差を切り分けられる
- 確認後に戻すべき設定を判断できる

## UnitSpawnManager

パス: `scripts/managers/unit_spawn_manager.gd`

役割:
Enemy / NPCの生成、保存済みUnitの復元、shop inventory生成補助を行います。
map側から呼ばれ、Unit sceneにdataやinventoryを適用する入口です。

このscriptを開く状況:
- 敵やNPCが出ない
- 保存済み敵やNPCが復元されない
- shop inventoryや初期inventoryがおかしい

最初に見る関数:
- `spawn_enemy_random()`
- `spawn_random_enemies()`
- `spawn_saved_enemies()`
- `spawn_npc_random()`
- `spawn_saved_npcs()`

このscriptは何をしないか:
- TSVを直接読み込まない
- Unitの戦闘処理を実行しない
- item effectを実行しない

よく見る次のscript:
```text
UnitSpawnManager
↓
GameDataRegistry
↓
Unit
↓
WorldState
```

読む優先順位:
★★★☆☆

初心者が最初に読むべきか:
NO

理解できれば何ができるようになるか:
- Unit生成と復元の入口を追える
- enemy / npc data適用の問題を調べられる
- shop inventory生成の入口を探せる

## 優先度一覧

★★★★★

- GameDataRegistry
- ItemDatabase
- Inventory
- ItemEffectManager
- CombatManager

★★★★☆

- DamageCalculator
- Unit
- Stats
- DebugSettings

★★★☆☆

- InventoryUI
- ItemDropHelper
- UnitSpawnManager

## learning docsとの違い

このreferenceは、scriptを開いた瞬間に見る場所を選ぶための索引です。

処理順を理解したい場合は、次のようなlearning docsを読みます。

- `docs/learning/start_here.md`
- `docs/learning/item_use_flow.md`
- `docs/learning/equipment_attack_effect_flow.md`
- `docs/learning/combat_damage_death_flow.md`
- `docs/learning/death_drop_flow.md`
- `docs/learning/debug_first_steps.md`
