# Runtime Flow Overview

Step 11-A 時点の主要処理フローです。細部を完全に追うより、「どこからどこへ進むか」を掴むための地図です。

## 1. ゲーム起動

1. Godot が `project.godot` を読みます。
2. Autoload が生成されます。
3. `GameDataRegistry._ready()` から `GameData.load_all()` が走り、`data/master/*.tsv` が読み込まれます。
4. `GameData.validate_all()` が runtime 側の簡易検証やログを出します。
5. main scene は `scenes/game_and_hud.tscn` です。
6. `GameAndHud._ready()` がHUD/UIを準備し、`_load_initial_map_from_save_manager()` で開始マップを決めます。
7. `SaveManager` に pending load/new game があればそれを使い、なければ `default_start_map_scene_path` を使います。

## 2. TSV読み込み

1. `master_data.xlsx` を `tools/export_master_tsv.py` で `data/master/*.tsv` に出力します。
2. Godot実行時は `GameDataRegistry` がTSVを読みます。
3. 読み込み順は概ね以下です。
   - category/typeなどの基礎テーブル
   - items / equipment
   - chest / shop / initial inventory tables
   - item effects / effect links
   - spawn rules / enchantments / faction / element / status metadata
   - enemies / npcs / quests
4. `item_effect_links.tsv` は item/equipment/effect が揃った後に反映されます。
5. enemy/npc の `initial_inventory_table_id` は `InitialInventoryEntry` に解決されます。
6. 旧 `initial_inventory_items` は deprecated fallback です。新規データでは使いません。

## 3. プレイヤー入力から移動/行動

1. `PlayerController._physics_process()` がプレイヤー入力の中心です。
2. UI toggle、status lock、hotbar使用、会話/interaction、keyboard target mode、mouse action、移動を扱います。
3. keyboard移動は概ね以下です。
   - `handle_move_input()`
   - `try_move_in_direction()`
   - `Unit.try_move()`
   - 成功時に `TimeManager.advance_time()` でターンが進みます。
4. mouse移動は `handle_mouse_map_input()` や `handle_left_click_on_tile()` からauto pathに進みます。
5. UI中移動制御の考え方:
   - 通常inventory中は移動可能です。
   - trade/chestなど特殊Inventory mode中は移動不可です。
   - dialogue/status/quest board等も入力lock対象です。

## 4. マップ/シーン移動

1. タイルイベント、階段、入口などから map scene の `request_map_change()` や `GameAndHud.load_map_by_path()` が呼ばれます。
2. 必要に応じて現在マップの状態を保存します。
   - `save_all_units()`
   - `save_map_tiles()`
   - `ItemWorldManager.save_current_state()`
3. 遷移文脈は以下に保持されることがあります。
   - `GlobalPlayerSpawn`: 次の出現tile
   - `GlobalDungeon`: dungeon階層・階段文脈
   - `GlobalDetailMap`: 詳細マップ復帰文脈
   - `PlayerData.map_positions`: map別player位置
4. `GameAndHud.load_map()` が古いmap sceneをfreeし、新しいsceneを `CurrentMapContainer` 配下に置きます。
5. 古いscene nodeへの参照は無効になります。sceneを跨ぐ必要がある状態は `PlayerData` や `WorldState` に置きます。

## 5. アイテム取得・インベントリ操作

1. world上のアイテムは `ItemPickup` node です。
2. `Unit.try_pickup_items_on_current_tile()` が現在tileのpickupを検出し、`Inventory` に追加します。
3. `Inventory` は主に2種類の配列を持ちます。
   - bag: `items`
   - hotbar: `hotbar_items`
4. `InventoryUI` は bag / hotbar / equipment / trade side / chest side を表示します。
5. held item は `InventoryUI` が以下で持ちます。
   - `held_entry`
   - `held_from_area`
   - `held_from_index`
   - `held_from_slot_name`
6. scene移動を跨ぐ held item は `PlayerData` の一時状態に同期されます。
7. trade/chest参照はsceneを跨いで持ち越しません。新しいsceneでUIを開く時は通常inventory modeへ正規化します。

## 6. アイテム使用・効果発動

1. 使用入口は複数あります。
   - `Inventory.use_item_at()`
   - `Inventory.use_selected_hotbar_item()`
   - `InventoryUI.use_selected_item()`
   - PlayerControllerのhotbar action
2. item data は `ItemDatabase` 経由で `GameData` から解決されます。
3. `ItemEffectManager.apply_item_effects()` が linked effects を順に処理します。
4. `ItemEffectManager.apply_single_effect()` が `ItemEffectData.EffectType` ごとにdispatchします。
5. 主なeffect:
   - `restore_resource`
   - `apply_status`
   - `apply_modifier`
   - `deal_damage`
   - `grant_item`
   - `teleport`
   - skill/recipe/document系
6. 時限statusやmodifierは `UnitEffectRuntime` としてUnitへ付与されます。

## 7. 装備・装備効果

1. 装備データは `equipment.tsv` から `EquipmentData` として読み込まれます。
2. 装備も `item_effect_links.tsv` で効果を持てます。
3. `InventoryUI` の装備/解除や save/load で `Unit.equipped_items` が更新されます。
4. 装備中パッシブ効果:
   - `Unit.get_equipped_item_effects()`
   - `ItemEffectData.EffectType.APPLY_MODIFIER` を抽出
   - stat getter内で装備中だけ加算
5. 装備攻撃効果:
   - `Unit.get_equipped_attack_effects()`
   - `CombatManager._apply_equipment_attack_effects()`
   - `deal_damage`、`apply_status`、`restore_resource` を実行
6. `item_effects.trigger_chance` は装備攻撃効果の発動率です。空欄/列なしは `1.0` 扱いです。

## 8. 戦闘・ダメージ・死亡判定

1. bump attack、手動攻撃、AI攻撃から `CombatManager.perform_attack()` や `try_bump_attack()` に入ります。
2. `CombatManager.can_attack()` が射程、敵対、target妥当性を確認します。
3. `DamageCalculator.calculate_damage()` が命中・crit・防御・属性などを計算します。
4. 命中後:
   - targetの `Stats.take_damage(damage)`
   - 装備攻撃効果の処理
   - 必要に応じて `Unit.check_death("attack")`
5. `Stats.take_damage()` はHPを減らし、0以下で `Stats.die()` を呼びます。
6. `Stats.die()` は親 `Unit.handle_death()` を呼びます。
7. `Unit.handle_death()` は `death_handled` guard で二重死亡処理を避けます。

## 9. 死亡時ドロップ

正式仕様は `docs/death_drop_spec.md` を参照します。

1. `Unit.handle_death()` が `drop_inventory_items_on_death_if_needed()` を呼びます。
2. `drop_inventory_on_death=false` なら何も落としません。
3. trueならUnitが実際に持っているbagとhotbarのentryを集めます。
4. `drop_equipped_items_on_death=true` なら装備中entryも集めます。
5. 各entryを `ItemDropHelper.drop_entry_near_unit(entry, unit, death_inventory_drop_radius)` で近傍に配置します。
6. 成功したdrop元slotはclearされます。
7. 死亡時に `initial_inventory_entries.tsv` を再抽選しません。
8. 現在、death専用の `drop_tables.tsv` / `drop_table_entries.tsv` はありません。

## 10. Enemy/NPC生成とinitial inventory

1. map scene scripts が enemy/npc pool を作ります。
   - 詳細マップ: `scripts/map/map_scene_scripts/main.gd`
   - field: `scripts/map/map_scene_scripts/FiledMap.gd`
   - dungeon: `scripts/dungeon/dungeon_main.gd`
2. poolは `GameData.get_all_enemies()` / `get_all_npcs()` から、`spawn_generator_tags`、difficulty、rule、weightで絞り込みます。
3. `UnitSpawnManager.spawn_random_enemies()` / `spawn_random_npcs()` がUnitをinstantiateします。
4. Unitに `Unit.apply_enemy_data()` / `apply_npc_data()` が適用されます。
5. 保存済みinventory stateがない場合だけ `Unit.apply_initial_inventory_from_data()` が各 `InitialInventoryEntry` を独立判定します。
6. 保存済みUnitでは `WorldState.unit_states` を使い、initial inventoryを再抽選しません。
7. 商人の売り物/取引用在庫は shop table系であり、本体inventoryとは別です。

## 11. Trade / Chest UI

Trade:

1. プレイヤーがmerchant系Unitと会話します。
2. `DialogueManager` が dialogue action `open_trade_ui` を処理します。
3. `GameAndHud.open_trade_ui()` が `InventoryUI.open_trade_mode()` を呼びます。
4. `InventoryUI` は `ui_mode = UIMode.TRADE` になり、左にplayer inventory、右にmerchant inventoryを出します。
5. 価格は `TradePriceCalculator` が計算します。

Chest:

1. プレイヤーが `Chest` とinteractionします。
2. `Chest.open_chest(player)` が `InventoryUI` を探します。
3. `InventoryUI.open_chest_mode()` が呼ばれます。
4. `ui_mode = UIMode.CHEST` になり、chest inventoryがside panelになります。
5. `Chest.can_player_take_item()` / `can_player_put_item()` がtransfer時に見られます。

共通:

- trade/chest は特殊Inventory modeで、player移動を止めます。
- 通常inventory modeは移動を止めません。
- scene移動が発生した場合、特殊modeは持ち越さず通常inventoryへ戻します。

## 12. Save / Load / WorldState

1. `SaveManager.save_current_game()` が現在mapに `save_all_units()` を要求します。
2. save対象は主に以下です。
   - `WorldState`
   - `PlayerData`
   - `GlobalDetailMap`
   - `GlobalDungeon`
   - `TimeManager`
3. `Unit.get_stats_data()` はstats、position、inventory、equipment、effects、skills、death stateを保存します。
4. `Inventory.save_inventory_full_data()` はbag/hotbarを保存します。
5. `SaveManager.request_load_game()` がsaveを読み、Autoload snapshotを復元します。
6. `GameAndHud` がpending map sceneを消費してmapを読みます。
7. map scriptsが `WorldState` から保存済みspawn/unit/chest/pickupを復元します。

## 未整理ポイント

- `Unit.gd`、`InventoryUI.gd`、`GameDataRegistry.gd` は責務が大きく、将来的には深掘りdocsや小分け設計メモがあると楽です。
- map scene scripts は似た処理を複数持っていますが、現Stepでは統一しません。
- `initial_inventory_items` はdeprecated fallbackとして残っています。新規データでは使いません。
- `drop_tables.tsv` は現時点では意図的に未追加です。drop-only reward が必要になった時に再検討します。
