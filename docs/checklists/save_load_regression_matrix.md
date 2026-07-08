# Save / Load Regression Matrix

## 目的

このdocsは、Save/Load、map遷移、WorldState復元、PlayerData復元、pickup/chest復元、enemy/NPC復元をGodot上で確認するための手順表です。

仕様説明そのものではなく、実機確認時に「何を、どの順番で、何が期待結果か」を見るためのチェックリストです。仕様や構造を調べる場合は、各行の参照docsへ移動してください。

## 確認前の前提

- `py tools/validate_master_data.py` が成功していること。
- `git diff --check` が成功していること。
- DebugSettings の一時確認flagが通常状態に戻っていること。現在値や戻す対象は [../systems/debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md) を参照します。
- docsだけの変更ならGodot実行は必須ではありません。
- Save/Load、WorldState、PlayerData、map scene、Unit保存処理を変更した場合はGodot実行確認を必須にしてください。
- 実機確認結果は、必要に応じてこのdocsの「実機確認ログ」へ追記します。

## 確認レベル

| レベル | 目的 | 実施タイミング |
| --- | --- | --- |
| Smoke | 短時間でsave/loadの致命的破損がないか見る | docs以外の小変更、save/loadに近い変更の最初 |
| Core | map遷移、PlayerData、WorldState、enemy死亡、pickup/chestの代表経路を見る | Save/Load、map scene、Unit、Inventory、WorldStateを触った時 |
| Extended | dungeon、quest NPC、held item、resetなど壊れやすい端を含める | 大きめの保存仕様変更、release前、resetやquestに触った時 |

## Save/Load確認マトリクス

| ID | レベル | 確認対象 | 手順 | 期待結果 | 失敗時に見るdocs/ファイル | 結果 |
| --- | --- | --- | --- | --- | --- | --- |
| SL-001 | Smoke | New game開始 | titleからnew gameを開始する | 起動エラーなし、playerが初期mapに出る | `docs/systems/save_worldstate_playerdata_map.md`, `scripts/save_manager.gd`, `scripts/data/player_data.gd` |  |
| SL-002 | Smoke | その場でsave | 初期mapでsaveする | save完了、エラーなし | `scripts/save_manager.gd`, `docs/systems/save_worldstate_playerdata_map.md` |  |
| SL-003 | Smoke | load入口 | titleに戻る、または再起動相当後にloadする | save fileが読まれ、map sceneがロードされる | `scripts/save_manager.gd`, `scripts/hud/game_and_hud.gd` |  |
| SL-004 | Smoke | player位置復元 | saveしたtileとload後tileを比べる | `PlayerData.map_positions` 由来で同じ位置に戻る | `docs/systems/save_worldstate_playerdata_map.md`, `scripts/hud/game_and_hud.gd`, `scripts/core/unit.gd` |  |
| SL-005 | Smoke | player基本stats復元 | HPなどを変化させてsave/loadする | HP、基本statsが巻き戻らず復元される | `scripts/core/unit.gd`, `scripts/data/player_data.gd`, `docs/systems/unit_lifecycle_deep_dive.md` |  |
| SL-010 | Core | player inventory / hotbar復元 | bag/hotbarにitemを置いてsave/loadする | item、amount、hotbar配置が維持される | `docs/systems/save_worldstate_playerdata_map.md`, `scripts/item/inventory.gd`, `scripts/core/unit.gd` |  |
| SL-011 | Core | player equipment復元 | 装備を付けてsave/loadする | slot、装備entry、stat反映が復元される | `docs/systems/unit_lifecycle_deep_dive.md`, `scripts/core/unit.gd`, `scripts/item/inventory_ui.gd` |  |
| SL-012 | Core | instance_data付き装備 | enchant等instance_data付き装備を持ってsave/loadする | `instance_data` が消えない | `scripts/item/item_database.gd`, `scripts/core/unit.gd`, `docs/systems/save_worldstate_playerdata_map.md` |  |
| SL-013 | Core | active effects / runtime modifier | buff/status中にsave/loadする | effect runtimeとmodifierが復元される | `scripts/item/item_effect_manager.gd`, `scripts/item/unit_effect_runtime.gd`, `scripts/core/unit.gd` |  |
| SL-014 | Core | map_positions復元 | 複数mapを移動後にsave/loadする | current/last/map_positionsの復元が自然 | `scripts/data/player_data.gd`, `scripts/hud/game_and_hud.gd`, `docs/systems/save_worldstate_playerdata_map.md` |  |
| SL-020 | Extended | 通常inventory held item scene跨ぎ | 通常inventoryでitemを持ったままscene移動する | held itemが消えず、移動後UIで復元される | `docs/systems/inventory_ui_state_transition.md`, `scripts/item/inventory_ui.gd`, `scripts/data/player_data.gd` |  |
| SL-021 | Extended | held item配置 | scene移動後、held itemを通常inventoryへ置く | itemが正しく配置され、重複/消失しない | `scripts/item/inventory_ui.gd`, `docs/systems/inventory_ui_state_transition.md` |  |
| SL-022 | Core | trade/chest中移動不可 | trade/chest画面を開いて移動入力する | playerが移動しない。通常inventory中移動は維持 | `scripts/controllers/player_controller.gd`, `scripts/item/inventory_ui.gd` |  |
| SL-023 | Extended | trade/chest由来held item不正配置 | trade/chest由来itemをheldした状態で異常経路を確認する | freed参照に触らず、不正にplayer bagへ入らない | `docs/systems/inventory_ui_state_transition.md`, `scripts/item/inventory_ui.gd`, `scripts/data/player_data.gd` |  |
| SL-030 | Core | detail mapへ入る | FieldMapからdetail/special placeへ入る | `GlobalDetailMap` contextでdetail mapが生成/復元される | `docs/systems/map_spawn_persistence_deep_dive.md`, `scripts/map/map_scene_scripts/FiledMap.gd`, `scripts/map/map_scene_scripts/main.gd` |  |
| SL-031 | Core | detail mapからfieldへ戻る | detail mapから戻り出口を使う | FieldMapの正しいreturn tileへ戻る | `scripts/core/unit.gd`, `scripts/map/global_detail_map.gd`, `scripts/map/map_scene_scripts/FiledMap.gd` |  |
| SL-032 | Core | detail map再訪state復元 | detail mapでenemy/pickup/chest状態を変えて再訪する | 同じmap stateが復元され、再生成されない | `docs/systems/map_spawn_persistence_deep_dive.md`, `scripts/world/world_state.gd` |  |
| SL-033 | Core | map移動後save/load | 別mapへ移動してsave/loadする | 現在map、player tile、map stateが復元される | `scripts/save_manager.gd`, `scripts/hud/game_and_hud.gd`, `docs/systems/save_worldstate_playerdata_map.md` |  |
| SL-034 | Core | scene node参照 | map移動、save/load、UI復元後にログを見る | previously freed系エラーが出ない | `docs/systems/inventory_ui_state_transition.md`, `scripts/item/inventory_ui.gd`, `scripts/hud/game_and_hud.gd` |  |
| SL-040 | Core | enemy死亡後save/load | enemyを倒してsave/loadする | dead enemyがspawnされない | `docs/systems/unit_lifecycle_deep_dive.md`, `scripts/core/unit.gd`, `scripts/managers/unit_spawn_manager.gd` |  |
| SL-041 | Core | dead enemy復活防止 | 倒したmapを離れて戻る | `map_enemy_spawns` / `unit_states` のdead扱いで復活しない | `scripts/world/world_state.gd`, `scripts/managers/unit_spawn_manager.gd` |  |
| SL-042 | Core | enemy inventory保存/復元 | enemyが所持品を持つ状態でsave/loadする | saved Unit inventoryが維持される | `scripts/core/unit.gd`, `docs/systems/unit_lifecycle_deep_dive.md` |  |
| SL-043 | Core | initial inventory再抽選防止 | saved Unitをloadし直して所持品を見る | initial inventoryが増えない/再抽選されない | `docs/systems/map_spawn_persistence_deep_dive.md`, `scripts/core/unit.gd`, `scripts/managers/unit_spawn_manager.gd` |  |
| SL-044 | Core | NPC会話復元 | NPCがいるmapでsave/load後に話す | NPCが残り、会話可能 | `scripts/managers/unit_spawn_manager.gd`, `scripts/managers/dialogue_manager.gd`, `docs/systems/save_worldstate_playerdata_map.md` |  |
| SL-045 | Extended | quest中NPC reset保護 | active quest NPCがいる状態でreset条件を進める | active quest NPCがresetで消えない | `scripts/world/world_state.gd`, `docs/systems/map_spawn_persistence_deep_dive.md` |  |
| SL-050 | Core | pickup取得後save/load | map上pickupを拾ってsave/loadする | pickupが復活しない | `scripts/item/item_world_manager.gd`, `scripts/item/item_pickup.gd`, `docs/systems/map_spawn_persistence_deep_dive.md` |  |
| SL-051 | Core | pickup再生成防止 | pickup取得済みmapへ再訪する | `map_item_pickups` の状態が優先される | `scripts/item/item_world_manager.gd`, `scripts/world/world_state.gd` |  |
| SL-052 | Core | death drop pickup永続 | enemy/player death dropを発生させ、map再訪する | drop pickupが残る、または拾った後は復活しない | `docs/systems/death_drop_spec.md`, `scripts/item/item_drop_helper.gd`, `scripts/item/item_world_manager.gd` |  |
| SL-053 | Core | chest open | chestを開く | opened状態が保存対象になる | `scripts/item/chest/chest.gd`, `scripts/item/item_world_manager.gd` |  |
| SL-054 | Core | chest中身取り出し後save/load | chestからitemを出してsave/loadする | 中身が巻き戻らない | `scripts/item/chest/chest.gd`, `scripts/item/inventory_ui.gd`, `scripts/item/item_world_manager.gd` |  |
| SL-055 | Core | chest再抽選防止 | chest操作後にmap再訪する | chest inventoryが再抽選されない | `docs/systems/map_spawn_persistence_deep_dive.md`, `scripts/item/item_world_manager.gd` |  |
| SL-060 | Extended | dungeonへ入る | FieldMapのdungeon入口から入る | `GlobalDungeon` contextでfloor 1へ入る | `scripts/map/map_scene_scripts/FiledMap.gd`, `scripts/dungeon/dungeon_main.gd` |  |
| SL-061 | Extended | dungeon階層移動 | stairsで上下階へ移動する | floor、stairs位置、player位置が自然 | `scripts/dungeon/dungeon_main.gd`, `scripts/dungeon/GlobalDungeon.gd` |  |
| SL-062 | Extended | dungeon内save/load | dungeon内でsave/loadする | dungeon map/floor/player stateが復元される | `scripts/save_manager.gd`, `scripts/dungeon/dungeon_main.gd`, `docs/systems/save_worldstate_playerdata_map.md` |  |
| SL-063 | Extended | dungeon floor state復元 | dungeon floorでenemy/pickup/chest状態を変えて再訪する | floorごとのenemy/pickup/chestが復元される | `docs/systems/map_spawn_persistence_deep_dive.md`, `scripts/item/item_world_manager.gd` |  |
| SL-064 | Extended | dungeon data保持 | 階層移動中にログ/状態を見る | `dungeon_data/dungeon_floor_data` が途中で消えない | `scripts/world/world_state.gd`, `scripts/dungeon/dungeon_main.gd` |  |
| SL-065 | Extended | FieldMap帰還後dungeon reset | reset条件後にFieldMapへ戻る | FieldMap上で安全にdungeon reset/regenerationされる | `scripts/world/world_state.gd`, `scripts/map/map_scene_scripts/FiledMap.gd` |  |
| SL-070 | Extended | quest受注後save/load | questを受注してsave/loadする | active quest状態が復元される | `scripts/managers/quest_manager.gd`, `scripts/world/world_state.gd` |  |
| SL-071 | Extended | quest進行復元 | 進行途中でsave/loadする | 進行状態、報酬/条件が巻き戻らない | `scripts/managers/quest_manager.gd`, `docs/systems/save_worldstate_playerdata_map.md` |  |
| SL-072 | Extended | generated quest NPC | generated quest NPC関連状態をsave/loadする | NPC/quest cacheが復元される | `scripts/world/world_state.gd`, `scripts/managers/quest_manager.gd` |  |
| SL-073 | Extended | active generated quest reset方針 | reset後のactive generated questを確認する | `reset_active_generated_quests_on_world_reset=false` 方針が維持される | `scripts/world/world_state.gd`, `docs/systems/map_spawn_persistence_deep_dive.md` |  |
| SL-080 | Extended | new game reset | 既存save後にnew gameを開始する | PlayerData/WorldStateが初期化される | `scripts/save_manager.gd`, `scripts/data/player_data.gd`, `scripts/world/world_state.gd` |  |
| SL-081 | Extended | world/monthly reset | month/reset条件を進める | 対象mapが再生成される | `scripts/world/world_state.gd`, `scripts/map/map_scene_scripts/FiledMap.gd` |  |
| SL-082 | Extended | active quest NPC保護 | active quest NPCがいるmapでresetする | NPC状態が保護される | `scripts/world/world_state.gd`, `docs/systems/map_spawn_persistence_deep_dive.md` |  |
| SL-083 | Extended | held item new game reset | held item一時状態を作った後new gameする | held item stateが残らない | `scripts/data/player_data.gd`, `scripts/item/inventory_ui.gd` |  |
| SL-084 | Extended | debug start items再配布 | debug start items適用後new gameする | `debug_start_items_applied` が再配布可能状態に戻る | `scripts/data/player_data.gd`, `scripts/debug/DebugSettings.gd`, `scripts/core/unit.gd` |  |

## 確認対象ごとの参照docs

| 確認対象 | 主に見るdocs | 主に見るscript |
| --- | --- | --- |
| PlayerData | `docs/systems/save_worldstate_playerdata_map.md` | `scripts/data/player_data.gd`, `scripts/save_manager.gd`, `scripts/core/unit.gd` |
| WorldState | `docs/systems/save_worldstate_playerdata_map.md` | `scripts/world/world_state.gd`, `scripts/save_manager.gd` |
| Map transition | `docs/systems/map_spawn_persistence_deep_dive.md` | `scripts/hud/game_and_hud.gd`, `scripts/core/unit.gd`, map scene scripts |
| InventoryUI held item | `docs/systems/inventory_ui_state_transition.md` | `scripts/item/inventory_ui.gd`, `scripts/data/player_data.gd` |
| Unit save/load | `docs/systems/unit_lifecycle_deep_dive.md` | `scripts/core/unit.gd`, `scripts/managers/unit_spawn_manager.gd` |
| Enemy/NPC spawn | `docs/systems/map_spawn_persistence_deep_dive.md` | `scripts/managers/unit_spawn_manager.gd`, `scripts/core/unit.gd` |
| Pickup/Chest | `docs/systems/map_spawn_persistence_deep_dive.md` | `scripts/item/item_world_manager.gd`, `scripts/item/chest/chest.gd`, `scripts/item/item_pickup.gd` |
| Dungeon | `docs/systems/map_spawn_persistence_deep_dive.md` | `scripts/dungeon/dungeon_main.gd`, `scripts/dungeon/GlobalDungeon.gd` |
| Quest | `docs/systems/save_worldstate_playerdata_map.md` | `scripts/managers/quest_manager.gd`, `scripts/world/world_state.gd` |
| Reset | `docs/systems/save_worldstate_playerdata_map.md`, `docs/systems/map_spawn_persistence_deep_dive.md` | `scripts/world/world_state.gd`, `scripts/save_manager.gd`, `scripts/map/map_scene_scripts/FiledMap.gd` |
| DebugSettings | `docs/systems/debug_settings_deep_dive.md` | `scripts/debug/DebugSettings.gd`, `scripts/core/unit.gd`, `scripts/data/player_data.gd` |

## 失敗時の切り分けガイド

| 症状 | 疑う領域 | まず見るdocs | まず見るscript |
| --- | --- | --- | --- |
| load後player位置がおかしい | PlayerData map position / GameAndHud restore / GlobalPlayerSpawn | `save_worldstate_playerdata_map.md` | `scripts/hud/game_and_hud.gd`, `scripts/data/player_data.gd`, `scripts/core/unit.gd` |
| inventoryが消える | PlayerData inventory save/load / Inventory serialization | `save_worldstate_playerdata_map.md` | `scripts/core/unit.gd`, `scripts/item/inventory.gd`, `scripts/save_manager.gd` |
| equipmentのinstance_dataが消える | equipment save/load / entry duplicate / ItemDatabase | `unit_lifecycle_deep_dive.md` | `scripts/core/unit.gd`, `scripts/item/item_database.gd` |
| held itemが消える | InventoryUI held state / PlayerData temporary state | `inventory_ui_state_transition.md` | `scripts/item/inventory_ui.gd`, `scripts/data/player_data.gd` |
| previously freed エラーが出る | scene node参照持ち越し / trade/chest参照 | `inventory_ui_state_transition.md` | `scripts/item/inventory_ui.gd`, `scripts/hud/game_and_hud.gd` |
| dead enemyが復活する | death mark / spawn list / unit_states | `unit_lifecycle_deep_dive.md`, `map_spawn_persistence_deep_dive.md` | `scripts/core/unit.gd`, `scripts/managers/unit_spawn_manager.gd`, `scripts/world/world_state.gd` |
| enemy所持品が増える | saved Unitでinitial inventory再抽選 | `unit_lifecycle_deep_dive.md` | `scripts/core/unit.gd`, `scripts/managers/unit_spawn_manager.gd` |
| pickup/chestが再抽選される | `map_item_pickups/map_chests` の保存優先漏れ | `map_spawn_persistence_deep_dive.md` | `scripts/item/item_world_manager.gd`, `scripts/world/world_state.gd` |
| dungeon階層が壊れる | GlobalDungeon / dungeon_floor_data / resetタイミング | `map_spawn_persistence_deep_dive.md` | `scripts/dungeon/dungeon_main.gd`, `scripts/world/world_state.gd` |
| quest NPCが消える | active quest NPC保護 / NPC reset | `save_worldstate_playerdata_map.md` | `scripts/world/world_state.gd`, `scripts/managers/quest_manager.gd` |
| new game後に古い状態が残る | reset_for_new_game漏れ / PlayerData reset漏れ | `save_worldstate_playerdata_map.md` | `scripts/save_manager.gd`, `scripts/data/player_data.gd`, `scripts/world/world_state.gd` |

## 実機確認ログ

| 日付 | Godot version | 確認者 | 対象Step/変更 | 実施ID | 結果 | メモ |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |

## Save/Load変更時の最小確認セット

Save/LoadやWorldStateを触った場合、最低限以下を確認します。

| セット | 実施ID | 目的 |
| --- | --- | --- |
| Smoke全体 | SL-001〜SL-005 | save/loadの基本破損検出 |
| PlayerData基本 | SL-010〜SL-012 | inventory、hotbar、equipment、instance_dataの保護 |
| Map transition | SL-030〜SL-034 | map移動、位置復元、scene node参照エラー確認 |
| Enemy/initial inventory | SL-040〜SL-043 | dead enemy復活防止、saved Unit再抽選防止 |
| Pickup/Chest | SL-050〜SL-055 | world pickup/chestの再抽選・巻き戻り防止 |

変更範囲がInventoryUIやtrade/chestに近い場合は SL-020〜SL-023、dungeonに近い場合は SL-060〜SL-065、quest/resetに近い場合は SL-070〜SL-084 も追加します。

## DebugSettings変更時の追加確認

DebugSettingsやdebug start itemを触ったStepでは、通常のSave/Load確認に加えて以下を見ます。詳細は [../systems/debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md) を参照します。

| ID | 確認内容 | 観点 |
| --- | --- | --- |
| SL-D-001 | 確認用flagの戻し | `debug_equipment_attack_effects`, `debug_equipment_effects`, death drop scope, skill移動確認flagなどがStep後の期待値に戻っている。 |
| SL-D-002 | debug start item再配布 | `PlayerData.debug_start_items_applied` がsave/loadで維持され、loadのたびに増殖しない。new gameでは再配布される。 |
| SL-D-003 | DebugSettings外debug出力 | SaveManager local debugやGameDataRegistry debug dumpなど、DebugSettingsで制御されないログを混同していない。 |

## Quest / Generated Quest追加確認

Quest lifecycleの詳細は [../systems/quest_generated_lifecycle_deep_dive.md](../systems/quest_generated_lifecycle_deep_dive.md) を参照します。

| ID | 確認内容 | 観点 |
| --- | --- | --- |
| SL-Q-001 | NPCからgenerated questを受注してsave/load | `quest_active_data` と `unit_generated_quests` が戻る。 |
| SL-Q-002 | Quest boardから同じactive questを確認 | Board独自状態ではなくWorldStateから再表示される。 |
| SL-Q-003 | 納品アイテムを所持してquest完了 | Inventory消費、reward追加、completed移動を確認。 |
| SL-Q-004 | Active generated quest中にmap reset相当の再訪問 | giver NPCが消えず、報告できる。 |
| SL-Q-005 | Questを破棄/失敗してNPC reset前に再会 | generated questがすぐ再生成されない。 |
| SL-Q-006 | NPC reset後に再会 | blocked状態が解除され、必要なら新しいgenerated quest候補が出る。 |

## 今回は直さないが気になる点

- このmatrixは確認項目の入口です。実機確認結果の蓄積がまだ少ないため、Save/Load周りを変更したStepでは結果ログを追記して育てる必要があります。
- Save/Load確認は手順が長くなりやすいので、将来は「Smokeだけ」「Coreまで」「Extendedまで」をGodotで素早く回すためのdebug sceneやdebug commandを検討してもよいです。ただし通常プレイに影響しないdefault OFFが前提です。
