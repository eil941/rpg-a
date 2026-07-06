# Data / Spawn / Save System Deep Dive

Data、Spawn、Save は「いつデータを作るか」と「いつ保存済み状態を優先するか」が重要です。特に initial inventory と shop inventory、WorldState と PlayerData の境界を整理します。

## master_data.xlsx -> TSV -> GameDataRegistry

1. `master_data.xlsx` がマスターデータの正本です。
2. `tools/export_master_tsv.py` が各シートを `data/master/*.tsv` に出力します。
3. `tools/validate_master_data.py` がTSVの参照、範囲、重複、非推奨列などを確認します。
4. Godot実行時は `GameDataRegistry.load_all()` がTSVを読み込みます。
5. 読み込まれたデータは `ItemData`、`EquipmentData`、`EnemyData`、`NpcData`、`ItemEffectData`、`InitialInventoryEntry` などのResourceや辞書になります。

## GameDataRegistryの読み込みカテゴリ

| カテゴリ | 代表TSV | runtimeで使う主な機能 |
| --- | --- | --- |
| item基礎 | `item_categories.tsv`, `items.tsv`, `equipment.tsv` | Inventory、Equipment、Pickup、Trade |
| item effect | `item_effects.tsv`, `item_effect_links.tsv` | Consumable effect、equipment effect |
| chest/shop | `chest_tables.tsv`, `chest_loot_tables.tsv`, `shop_tables.tsv`, `shop_loot_tables.tsv` | Chest生成、merchant在庫生成 |
| initial inventory | `initial_inventory_tables.tsv`, `initial_inventory_entries.tsv` | Enemy/NPC生成時の本体所持品 |
| unit metadata | `unit_races.tsv`, `unit_factions.tsv`, `faction_relations.tsv` | Unit表示、faction関係 |
| combat metadata | `element_types.tsv`, `damage_types.tsv`, `status_effect_types.tsv` | ダメージ/状態異常/表示/validate |
| skill | `skills.tsv`, `skill_levels.tsv`, `unit_skill_*` | Skills node、status表示、成長 |
| quest/dialogue | `quests.tsv`, `npc_quest_links.tsv`, `dialogue_*` | QuestManager、DialogueManager |
| spawn | `spawn_rules.tsv`, `unit_spawn_rules.tsv`, `dungeon_spawn_rules.tsv` | map/dungeon spawn |
| enchant | `enchantments.tsv` | 装備instance/enchant |
| enemy/npc | `enemies.tsv`, `npcs.tsv` | UnitSpawnManager、Unit.apply_*_data() |

## Data Resource class の役割

- `ItemData`: itemの基本情報とlinked effects。
- `EquipmentData`: item + equipment slot/stat/attack data。
- `ItemEffectData`: effect schema。`trigger_chance` もここ。
- `EnemyData` / `NpcData`: TSVのUnit定義。initial inventory、death drop設定、装備、shop/dialogue等。
- `InitialInventoryEntry`: spawn時の所持品候補。`spawn_chance` は `chance` に入ります。
- `SpawnRuleData` / `DungeonSpawnRuleData`: map/dungeonのspawn rule。

## Validatorの役割

`tools/validate_master_data.py` はruntimeではなく開発用の安全網です。

- ID重複確認
- item/effect/equipment/categoryなどの参照確認
- initial inventory の table/item/chance/amount/bool確認
- death drop columns のbool/radius確認
- `initial_inventory_items` のdeprecated warning
- resource path存在確認
- `trigger_chance` の範囲確認

データ列追加時は、runtime loaderだけでなくvalidatorも更新するのが基本です。

## Enemy/NPC spawnの流れ

1. map scene scriptが対象mapのspawn poolを作ります。
2. `spawn_generator_tags`、difficulty、spawn rule、weightなどで候補を絞ります。
3. `UnitSpawnManager.spawn_random_enemies()` / `spawn_random_npcs()` がUnitを生成します。
4. 生成したUnitに `apply_enemy_data()` / `apply_npc_data()` を呼びます。
5. enemy/npc data内のinventory/equipment/death drop/shop/dialogue等がUnitへ適用されます。
6. spawn情報は `WorldState.map_enemy_spawns` / `map_npc_spawns` に保存されます。

## initial_inventoryの適用タイミング

- `GameDataRegistry` は `initial_inventory_table_id` から `InitialInventoryEntry` 配列を `EnemyData` / `NpcData` に持たせます。
- Unit生成時、保存済み状態がなければ `Unit.apply_initial_inventory_from_data()` がentryごとに独立判定します。
- `guaranteed=true` は必ず生成、falseなら `spawn_chance` を使います。
- `min_amount`〜`max_amount` の範囲でamountを決めます。
- 生成されたitemは通常の本体inventoryに入るため、死亡時には通常のcarried entryとして扱われます。

## saved Unitでは再抽選しない

- `WorldState.unit_states` に保存済みUnitがある場合は、保存済みinventory/equipment/statsを復元します。
- 保存済みUnitのload時にinitial inventoryを再抽選すると、save/loadで持ち物が増減してしまいます。
- そのため、initial inventoryは「新規Unit生成時だけ」の処理です。

## shop inventory と本体inventory

| 種類 | 目的 | 生成場所 | 死亡時drop対象か | 注意 |
| --- | --- | --- | --- | --- |
| 本体inventory | Unitが実際に持っているitem | `initial_inventory_*`、pickup、UI操作 | 対象 | death dropはこれを見る。 |
| hotbar | Unitが実際に持っているquick slot | Inventory save data | 対象 | inventory扱い。 |
| equipment | Unitが装備中のitem | enemy/npc data、UI操作 | flag次第 | `drop_equipped_items_on_death` を見る。 |
| shop inventory | 商人の売り物 | shop table / fallback columns | 原則混ぜない | trade用在庫。本体dropとは別。 |

## 状態の保存先

| 状態 | 保存先 | 誰が書くか | 誰が読むか | いつ消える/更新されるか | 注意 |
| --- | --- | --- | --- | --- | --- |
| player inventory | `PlayerData.inventory_data` | `Unit.save_player_data()`、Inventory操作後同期 | `Unit.load_player_data()`、SaveManager | save/load、新規ゲームreset | bag/hotbarを含む。 |
| player equipment | `PlayerData.equipment_data` | Unit装備変更、save_player_data | Unit.load_player_data | 装備/解除、save/load | 装備entryの `instance_data` を維持。 |
| held item一時状態 | `PlayerData.held_inventory_*` | `InventoryUI.persist_held_state_to_player_data()` | 新しい `InventoryUI` | clear_held_state/new game | scene内参照は持たない。 |
| enemy/npc runtime state | `WorldState.unit_states` | map `save_all_units()`、Unit死亡処理 | UnitSpawnManager、Unit.apply_stats_data | map save、死亡、reset | saved Unitはinitial inventory再抽選しない。 |
| enemy spawn list | `WorldState.map_enemy_spawns` | UnitSpawnManager | UnitSpawnManager | map生成/保存/reset | dead flagやunit_idと結びつく。 |
| npc spawn list | `WorldState.map_npc_spawns` | UnitSpawnManager | UnitSpawnManager | map生成/保存/reset | quest NPCやmerchantに注意。 |
| chest state | `WorldState` のchest関連辞書 | Chest / ItemWorldManager | ItemWorldManager / Chest | chest操作、map save/reset | chest inventoryと権限を維持。 |
| pickup state | `WorldState.map_item_pickups` | ItemWorldManager、ItemDropHelper | ItemWorldManager | pickup/drop/map save | `instance_data` 付きpickupを保存。 |
| map tile state | `WorldState` のmap tile data | map scene scripts | map scene scripts | map生成、reset | map_id単位。 |
| quest state | `QuestManager` と `WorldState` | QuestManager | QuestManager、StatusUI、Dialogue | quest受注/完了/reset/save | generated quest cacheに注意。 |
| dungeon state | `GlobalDungeon`, `WorldState.dungeon_*` | dungeon_main、SaveManager | dungeon_main、GameAndHud | floor遷移、reset、save/load | field復帰文脈も関係。 |

## SaveManagerの役割

- current mapに `save_all_units()` を要求します。
- `WorldState`、`PlayerData`、`GlobalDetailMap`、`GlobalDungeon`、`TimeManager` などをsnapshotします。
- load時にAutoloadへsnapshotを戻し、`GameAndHud` がpending mapを読みます。
- new game時に `WorldState.reset_for_new_game()` と `PlayerData.reset_for_new_game()` を呼びます。

## map scene script と WorldState

- map scene scriptはspawn poolやmap tile生成を担当します。
- 生成したenemy/npc/pickup/chestは `WorldState` に保存され、再訪時に復元されます。
- mapを離れる前に `save_all_units()` や `ItemWorldManager.save_current_state()` が呼ばれる設計です。
- scene node自体はfreeされるため、永続させたい状態はWorldStateへ書きます。

## Data / Spawn / Save変更時の確認項目

- `master_data.xlsx` とTSVが同期しているか
- validatorに新列/参照の検証があるか
- `GameDataRegistry` の読み込み順が壊れていないか
- 保存済みUnitでinitial inventoryを再抽選しないか
- 本体inventoryとshop inventoryを混ぜていないか
- `WorldState.unit_states` と spawn list のキーが一致しているか
- new game/resetで新しい状態が残らないか
- save/load後に player inventory/equipment/effects が戻るか
