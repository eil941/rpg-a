# Subsystem Interaction Map

Step 11-B 時点の、機能単位で見た相互作用マップです。1つのスクリプトではなく、複数スクリプトがどう協力して機能を作っているかを把握するための地図です。

## サブシステム一覧

| サブシステム | 主な責務 | 主要スクリプト | 主な状態の置き場所 | 主な入口 | 主な出口/呼び出し先 | 変更時の注意 |
| --- | --- | --- | --- | --- | --- | --- |
| Data / TSV / Registry | Excel/TSVをResourceや辞書に変換し、runtimeへ提供 | `scripts/data/game_data_registry.gd`, `scripts/data/*_data.gd`, `tools/validate_master_data.py` | `GameData` Autoload 内の辞書、`data/master/*.tsv` | `GameData.load_all()` | `ItemDatabase`, `UnitSpawnManager`, Quest/Dialogue/Item系 | TSV列追加時は data class、loader、validator、Excel/TSV同期をセットで見る。 |
| Player / Unit / Stats | Unit共通挙動、HP/能力値、装備、死亡、保存 | `scripts/core/unit.gd`, `scripts/core/stats.gd`, `scripts/data/player_data.gd` | Unit node、`Stats` node、`PlayerData` | Unit生成、data適用、player load | Inventory、Combat、WorldState、ItemDropHelper | `unit.gd` は影響範囲が広い。小さいhelperで触る。 |
| Input / Controller | 入力、移動、攻撃、UI lock、AI/NPC行動 | `scripts/controllers/player_controller.gd`, `ai_controller.gd`, `enemy_controller.gd`, `npc_controller.gd` | Controller node内の一時状態、Unit | `_physics_process()`, `TimeManager` | `Unit.try_move()`, `CombatManager`, UI open | 通常inventoryは移動可、trade/chestは移動不可の境界に注意。 |
| Inventory / Hotbar / Equipment | bag/hotbar/equipment entryの管理、装備/解除、held item | `scripts/item/inventory.gd`, `scripts/item/inventory_ui.gd`, `scripts/core/unit.gd` | `Inventory.items`, `Inventory.hotbar_items`, `Unit.equipped_items`, `PlayerData.held_inventory_*` | pickup、UI操作、save/load | ItemEffectManager、ItemDropHelper、PlayerData | `entry` と `instance_data` を消さない。held state と UI mode を混ぜない。 |
| Trade / Chest | merchant/chestのside inventory、売買・出し入れ | `InventoryUI`, `chest.gd`, `DialogueManager`, `GameAndHud`, `TradePriceCalculator` | merchant/chest inventory、`InventoryUI.trade_inventory` | 会話action、Chest interaction | Inventory transfer、価格計算、権限判定 | scene跨ぎでtrade/chest参照を持ち越さない。特殊mode中は移動不可。 |
| Item Effect / Equipment Effect | 消耗品効果、装備中効果、装備攻撃効果 | `ItemEffectManager`, `ItemEffectData`, `Unit`, `CombatManager` | `ItemData.effects`, `EquipmentData.effects`, `Unit.active_effect_runtimes` | item使用、装備、攻撃命中 | Stats、UnitEffectRuntime、CombatManager | consumableとequipmentで同じeffect dataを使うが、実行タイミングは違う。 |
| Combat / Damage / Death | 攻撃、ダメージ計算、HP減少、死亡処理 | `CombatManager`, `DamageCalculator`, `Stats`, `Unit` | Unit/Stats、`death_handled` | bump attack、AI攻撃、target item | `Stats.take_damage()`, `Unit.handle_death()` | HP0経路は共通死亡処理へ到達させる。二重death dropを避ける。 |
| Spawn / Enemy / NPC | enemy/npc pool生成、保存済みUnit復元、initial inventory、shop inventory | `UnitSpawnManager`, map scene scripts, `EnemyData`, `NpcData` | `WorldState.map_enemy_spawns`, `map_npc_spawns`, `unit_states` | map load、dungeon floor load | Unit.apply_enemy_data(), Unit.apply_npc_data() | 保存済みUnitでは initial inventory を再抽選しない。shop inventoryと本体inventoryを混ぜない。 |
| Map / Scene Transition | map scene切替、出現位置、map固有状態 | `GameAndHud`, map scene scripts, `GlobalPlayerSpawn`, `GlobalDungeon`, `GlobalDetailMap` | Autoload各種、`WorldState`, `PlayerData.map_positions` | tile event、stairs、field/detail transition | map save/load、UnitSpawnManager、ItemWorldManager | 古いscene nodeはfreeされる。跨ぐ状態はAutoloadへ逃がす。 |
| Save / Load / WorldState | player/world/map/unit/chest/pickup状態の保存復元 | `SaveManager`, `PlayerData`, `WorldState`, `Unit.get_stats_data()` | save file、Autoload snapshots | save/load/new game | GameAndHud map load、Unit apply_stats_data | 新しい永続状態はsnapshot対象とreset対象を両方確認。 |
| Dialogue / Quest | NPC会話、会話action、quest受注/完了、quest board | `DialogueManager`, `DialogueUI`, `QuestManager`, `QuestBoardManager`, quest board scripts | `QuestManager`, `WorldState` quest fields | talk、quest board interaction | Inventory reward、Trade UI、Status UI | 会話actionは文字列駆動。quest stateのreset/保存に注意。 |
| Debug / Verification | 確認用フラグ、開始アイテム、限定ログ | `DebugSettings`, 各feature script | `DebugSettings` Autoload | 手動flag切替、debug start | 対象feature script | default OFF が基本。確認終了後は通常プレイへ影響しない状態に戻す。 |

## 重要な依存関係

- `GameDataRegistry` は多くのサブシステムの根です。Item、Enemy、NPC、Quest、Effect、Spawn Rule はここでResource化され、`ItemDatabase` や `UnitSpawnManager` などへ渡ります。
- `ItemDatabase` は実体のDBというより `GameData` の薄いwrapperです。UIやInventoryは直接 `GameData` を触るより `ItemDatabase` を経由することが多いです。
- `InventoryUI` は `Inventory` を直接操作しますが、sceneを跨ぐ held item は `PlayerData.held_inventory_*` に逃がします。UI modeはscene跨ぎで特殊modeを維持せず、通常inventoryへ正規化します。
- `CombatManager` は攻撃の進行を持ち、命中・ダメージ計算は `DamageCalculator` に任せます。HPを減らす処理は `Stats.take_damage()` を通り、死亡処理は `Stats` から `Unit.handle_death()` へ流れます。
- 装備効果は2系統あります。装備中パッシブは `Unit` のstat getterで効き、攻撃時効果は `CombatManager._apply_equipment_attack_effects()` で攻撃命中後に効きます。
- `initial_inventory_*` は spawn時にUnitの本体inventoryへ入るだけです。死亡時は `initial_inventory_entries.tsv` を読まず、Unitが実際に持っているentryだけを `ItemDropHelper` で落とします。
- `UnitSpawnManager` は enemy/npc を生成し、`Unit.apply_enemy_data()` / `apply_npc_data()` を呼びます。保存済みUnitは `WorldState.unit_states` から復元し、initial inventoryを再抽選しません。
- shop inventory は merchantの売り物用です。本体inventoryとは別扱いで、死亡時に落ちるものと混ぜない設計です。
- `GameAndHud` はUIとmap sceneの親です。scene遷移で古いmap nodeはfreeされるため、古いscene内のInventory/Chest/Trade参照をAutoloadへ直接持ち越すと危険です。
- `SaveManager` は `PlayerData` と `WorldState` のsnapshotを保存します。player固有の状態は `PlayerData`、map/world単位の状態は `WorldState` に寄せます。

## 新機能追加時の見方

1. まずこの表で該当サブシステムを選びます。
2. [script_responsibility_map.md](script_responsibility_map.md) で主要scriptの責務を確認します。
3. [runtime_flow_overview.md](runtime_flow_overview.md) で呼び出し順を確認します。
4. データが絡む場合は `master_data.xlsx`、`data/master/*.tsv`、`GameDataRegistry`、validatorをセットで見ます。
5. UIやscene遷移が絡む場合は、状態がscene内にあるのかAutoloadにあるのかを先に確認します。
