# サブシステム相互作用マップ

Step 11-B 時点の、機能単位で見た相互作用マップです。1つのスクリプトではなく、複数スクリプトがどう協力して機能を作っているかを把握するための地図です。

## サブシステム一覧

| サブシステム | 主な責務 | 主要スクリプト | 主な状態の置き場所 | 主な入口 | 主な出口/呼び出し先 | 変更時の注意 |
| --- | --- | --- | --- | --- | --- | --- |
| データ・TSV・Registry | Excel/TSVをResourceや辞書に変換し、実行時へ提供 | `scripts/data/game_data_registry.gd`, `scripts/data/*_data.gd`, `tools/validate_master_data.py` | `GameData` Autoload 内の辞書、`data/master/*.tsv` | `GameData.load_all()` | `ItemDatabase`, `UnitSpawnManager`, Quest/Dialogue/Item系 | TSV列追加時は [../systems/data/game_data_registry_loader_map.md](../systems/data/game_data_registry_loader_map.md) を入口に、data class、loader、validator、Excel/TSV同期をセットで見る。 |
| プレイヤー・Unit・能力値 | Unit共通挙動、HP/能力値、装備、死亡、保存 | `scripts/core/unit.gd`, `scripts/core/stats.gd`, `scripts/data/player_data.gd` | Unit node、`Stats` node、`PlayerData` | Unit生成、data適用、player load | Inventory、Combat、WorldState、ItemDropHelper | `unit.gd` は影響範囲が広い。小さいhelperで触る。 |
| 入力・Controller | 入力、移動、攻撃、UI lock、AI/NPC行動 | `scripts/controllers/player_controller.gd`, `ai_controller.gd`, `enemy_controller.gd`, `npc_controller.gd` | Controller node内の一時状態、Unit | `_physics_process()`, `TimeManager` | `Unit.try_move()`, `CombatManager`, UI open | 通常inventoryは移動可、trade/chestは移動不可の境界に注意。状態別matrixは [../systems/ui_lock_matrix.md](../systems/ui_lock_matrix.md) を見る。 |
| インベントリ・Hotbar・装備 | bag/hotbar/equipment entryの管理、装備/解除、held item | `scripts/item/inventory.gd`, `scripts/item/inventory_ui.gd`, `scripts/core/unit.gd` | `Inventory.items`, `Inventory.hotbar_items`, `Unit.equipped_items`, `PlayerData.held_inventory_*` | pickup、UI操作、save/load | ItemEffectManager、ItemDropHelper、PlayerData | `entry` と `instance_data` を消さない。held state と UI mode を混ぜない。trade/chest所有権境界は [../systems/inventory/trade_chest_ownership_deep_dive.md](../systems/inventory/trade_chest_ownership_deep_dive.md) も見る。 |
| 取引・チェスト | merchant/chestのside inventory、売買・出し入れ | `InventoryUI`, `chest.gd`, `DialogueManager`, `GameAndHud`, `TradePriceCalculator` | merchant/chest inventory、`InventoryUI.trade_inventory` | 会話action、Chest interaction | Inventory transfer、価格計算、権限判定 | scene跨ぎでtrade/chest参照を持ち越さない。特殊mode中は移動不可。所有権と保存境界は [../systems/inventory/trade_chest_ownership_deep_dive.md](../systems/inventory/trade_chest_ownership_deep_dive.md)、入力lockは [../systems/ui_lock_matrix.md](../systems/ui_lock_matrix.md) を見る。 |
| アイテム効果・装備効果 | 消耗品効果、装備中効果、装備攻撃効果 | `ItemEffectManager`, `ItemEffectData`, `Unit`, `CombatManager` | `ItemData.effects`, `EquipmentData.effects`, `Unit.active_effect_runtimes` | item使用、装備、攻撃命中 | Stats、UnitEffectRuntime、CombatManager | consumableとequipmentで同じeffect dataを使うが、実行タイミングは違う。入口差分は [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md) を見る。 |
| 戦闘・ダメージ・死亡 | 攻撃、ダメージ計算、HP減少、死亡処理 | `CombatManager`, `DamageCalculator`, `Stats`, `Unit` | Unit/Stats、`death_handled` | bump attack、AI攻撃、target item | `Stats.take_damage()`, `Unit.handle_death()` | HP0経路は共通死亡処理へ到達させる。二重death dropを避ける。経路図は [../systems/combat/death_path_diagram.md](../systems/combat/death_path_diagram.md) を見る。 |
| 生成・Enemy・NPC | enemy/npc pool生成、保存済みUnit復元、initial inventory、shop inventory | `UnitSpawnManager`, map scene scripts, `EnemyData`, `NpcData` | `WorldState.map_enemy_spawns`, `map_npc_spawns`, `unit_states` | map load、dungeon floor load | Unit.apply_enemy_data(), Unit.apply_npc_data() | 保存済みUnitでは initial inventory を再抽選しない。shop inventoryは用途上区別するが、現保存先はUnit.inventory。map別のspawn優先順は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) へ。 |
| 賞金首 | 既存enemy候補からランダム選出する期間限定の強化enemy生成、討伐状態、追加 `gold` 報酬、名前・頭上マーカー、NPC情報表示 | `BountyManager`, `UnitSpawnManager`, `Unit`, `UnitInteractionLogic` | `WorldState.bounty_data`, 賞金首Unitの実行時フィールド | enemy spawn後、時間経過、Unit死亡処理、NPC会話 | ItemDropHelper、SaveManager、TimeManager | 賞金首個体はExcel/TSVで直接作らない。通常enemyの `map_enemy_spawns` には混ぜず、`bounty_data` を正本にする。頭上マーカーは表示補助で、通常リセットを跨ぐ理由と期限切れ処理は [../systems/bounty_system_deep_dive.md](../systems/bounty_system_deep_dive.md) で確認する。 |
| マップ・シーン遷移 | map scene切替、出現位置、map固有状態 | `GameAndHud`, map scene scripts, `GlobalPlayerSpawn`, `GlobalDungeon`, `GlobalDetailMap` | Autoload各種、`WorldState`, `PlayerData.map_positions` | tile event、stairs、field/detail transition | map save/load、UnitSpawnManager、ItemWorldManager | 古いscene nodeはfreeされる。跨ぐ状態はAutoloadへ逃がす。field/detail/dungeon差分は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md)、UI状態の保持/正規化は [../systems/ui_lock_matrix.md](../systems/ui_lock_matrix.md) へ。 |
| セーブ・ロード・WorldState | player/world/map/unit/chest/pickup状態の保存復元 | `SaveManager`, `PlayerData`, `WorldState`, `Unit.get_stats_data()` | save file、Autoload snapshots | save/load/new game | GameAndHud map load、Unit apply_stats_data | 新しい永続状態は [../systems/data/save_worldstate_playerdata_map.md](../systems/data/save_worldstate_playerdata_map.md) でsnapshot対象とreset対象を両方確認。賞金首は `WorldState.bounty_data` が保存対象。死亡Unitとdrop pickupの保存は [../systems/combat/death_path_diagram.md](../systems/combat/death_path_diagram.md) も見る。 |
| 会話・Quest | NPC会話、会話action、quest受注/完了、quest board | `DialogueManager`, `DialogueUI`, `QuestManager`, `QuestBoardManager`, quest board scripts | `QuestManager`, `WorldState` quest fields | talk、quest board interaction | Inventory reward、Trade UI、Status UI | 会話actionは文字列駆動。quest stateのreset/保存に注意。賞金首一覧は `UnitInteractionLogic` から `BountyManager` へつながる。 |
| デバッグ・確認 | 確認用フラグ、開始アイテム、限定ログ | `DebugSettings`, 各feature script | `DebugSettings` Autoload, 一部script-local debug設定 | 手動flag切替、debug start | 対象feature script | [../systems/debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md) でDebugSettings管理かscript-local debugかを確認する。確認終了後は通常プレイへ影響しない状態に戻す。 |

## 重要な依存関係

- `GameDataRegistry` は多くのサブシステムの根です。Item、Enemy、NPC、Quest、Effect、Spawn Rule はここでResource化され、`ItemDatabase` や `UnitSpawnManager` などへ渡ります。
- `ItemDatabase` は実体のDBというより `GameData` の薄いwrapperです。UIやInventoryは直接 `GameData` を触るより `ItemDatabase` を経由することが多いです。
- `InventoryUI` は `Inventory` を直接操作しますが、sceneを跨ぐ held item は `PlayerData.held_inventory_*` に逃がします。UI modeはscene跨ぎで特殊modeを維持せず、通常inventoryへ正規化します。
- `CombatManager` は攻撃の進行を持ち、命中・ダメージ計算は `DamageCalculator` に任せます。HPを減らす処理は `Stats.take_damage()` を通り、死亡処理は `Stats` から `Unit.handle_death()` へ流れます。
- 装備効果は2系統あります。装備中パッシブは `Unit` のstat getterで効き、攻撃時効果は `CombatManager._apply_equipment_attack_effects()` で攻撃命中後に効きます。
- `initial_inventory_*` は spawn時にUnitの本体inventoryへ入るだけです。死亡時は `initial_inventory_entries.tsv` を読まず、Unitが実際に持っているentryだけを `ItemDropHelper` で落とします。
- `UnitSpawnManager` は enemy/npc を生成し、`Unit.apply_enemy_data()` / `apply_npc_data()` を呼びます。保存済みUnitは `WorldState.unit_states` から復元し、initial inventoryを再抽選しません。map sceneごとの入口は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) を参照してください。
- `BountyManager` は既存enemy候補からゲーム内で賞金首をランダム選出し、`WorldState.bounty_data` を正本にして enemy spawn後に賞金首Unitを追加します。通常リセットで消える `map_enemy_spawns` とは別管理です。
- shop inventory は用途上merchantの売り物ですが、現コードでは `merchant_unit.inventory` に生成されます。death collectorもUnit.inventoryを見るため、由来別の自動除外はありません。Chest.inventoryやInventoryUIのside参照とは別の話として扱います。
- `GameAndHud` はUIとmap sceneの親です。scene遷移で古いmap nodeはfreeされるため、古いscene内のInventory/Chest/Trade参照をAutoloadへ直接持ち越すと危険です。
- `SaveManager` は `PlayerData` と `WorldState` のsnapshotを保存します。player固有の状態は `PlayerData`、map/world単位の状態は `WorldState` に寄せます。

## Quest・生成Questの相互作用

Quest系の詳細は [../systems/quest_generated_lifecycle_deep_dive.md](../systems/quest_generated_lifecycle_deep_dive.md) にまとめています。

| 流れ | 主なスクリプト | 状態 | 補足 |
| --- | --- | --- | --- |
| NPC依頼会話 | `DialogueManager` -> `Unit.handle_interact_action()` -> `UnitInteractionLogic` -> `QuestManager` | `WorldState.quest_active_data` | Quest actionの実処理入口は `UnitInteractionLogic`。 |
| 生成Questの提示 | `QuestManager.get_or_create_generated_unit_quests()` | `WorldState.unit_generated_quests` | NPC Unit keyごとにcacheし、UIを開くたびにrerollしない。 |
| Quest掲示板 | `QuestBoard` -> `QuestBoardManager` -> `QuestBoardUI` -> `QuestManager.get_board_quests()` | UI一時状態 + WorldState | Board独自questではなく、NPC由来offerを別UIで表示する。 |
| Quest完了 | `QuestManager.can_complete_quest()` / `complete_quest()` | Player Inventory, `WorldState.quest_completed_data` | 現状の実装済みobjectiveは `DELIVER_ITEM`。 |
| Questリセット保護 | `WorldState.clear_regenerable_map_data()`, `reset_generated_npc_quest_state()` | active quest Unit IDs | Active quest NPCやgenerated quest cacheを消しすぎない。 |

## 新機能追加時の見方

1. まずこの表で該当サブシステムを選びます。
2. [script_responsibility_map.md](script_responsibility_map.md) で主要scriptの責務を確認します。
3. [runtime_flow_overview.md](runtime_flow_overview.md) で呼び出し順を確認します。
4. データが絡む場合は `master_data.xlsx`、`data/master/*.tsv`、`GameDataRegistry`、validatorをセットで見ます。
5. UIやscene遷移が絡む場合は、状態がscene内にあるのかAutoloadにあるのかを先に確認します。
