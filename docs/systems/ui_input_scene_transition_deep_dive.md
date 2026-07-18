# UI / Input / Scene Transition Deep Dive

UI、入力、シーン遷移は「どの状態なら移動できるか」と「sceneを跨ぐ状態をどこへ逃がすか」が重要です。

InventoryUIのmodeとheld item復元に絞って確認したい場合は、[inventory/inventory_ui_state_transition.md](inventory/inventory_ui_state_transition.md) も参照してください。

UI状態ごとの移動・行動・入力可否と、判定関数の意味の違いは [ui_lock_matrix.md](ui_lock_matrix.md) に整理しています。

## 関連スクリプト

| Script | 役割 |
| --- | --- |
| `scripts/controllers/player_controller.gd` | 入力処理、移動、攻撃、UI lock、mouse auto path。 |
| `scripts/hud/game_and_hud.gd` | UI開閉、map load、player検索、HUD表示。 |
| `scripts/item/inventory_ui.gd` | inventory/trade/chest mode、held item。 |
| `scripts/hud/status_ui.gd` | status/skills/equipment/quest表示。 |
| `scripts/dialogue_ui.gd` | 会話UI。 |
| `scripts/object/questboard/quest_board_ui.gd` | quest board UI。 |
| `scripts/world/GlobalPlayerSpawn.gd` | 次mapのplayer出現tile。 |
| `scripts/dungeon/GlobalDungeon.gd` | dungeon文脈。 |
| `scripts/map/global_detail_map.gd` | detail map文脈。 |
| `scripts/data/player_data.gd` | player map位置、held item一時状態。 |
| `scripts/world/world_state.gd` | map/unit/chest/pickup等の永続状態。 |

## PlayerControllerの入力処理

`PlayerController._physics_process()` が主な入力入口です。

主な順序:

1. keyboard target modeやUI toggleを処理します。
2. status UIが開いている場合は移動しません。
3. inventory toggleを処理します。
4. hotbar使用を処理します。
5. `is_ui_locked()` なら移動・mouse auto navigationを止めます。
6. lockされていなければmouse/keyboard movementへ進みます。

## GameAndHudのUI開閉

- `toggle_inventory_ui()` は通常inventoryを開閉します。
- tradeは `open_trade_ui()` から `InventoryUI.open_trade_mode()` に進みます。
- chestは `Chest.open_chest()` から `InventoryUI.open_chest_mode()` に進みます。
- statusは `toggle_status_ui()` / `open_status_ui()` / `close_status_ui()` で管理します。
- `is_special_inventory_ui_open()` は trade/chest 等の特殊inventory mode判定です。

## UI状態ごとの移動可否

| UI状態 | 移動できるか | 主な判定関数 | 状態の置き場所 | scene遷移時の扱い | 注意 |
| --- | --- | --- | --- | --- | --- |
| UIなし | 可 | `PlayerController.is_ui_locked()` false | Unit/Controller | 通常通り | 移動でターンが進む。 |
| 通常inventory | 可 | `GameAndHud.is_inventory_open()` はtrueでも `is_special_inventory_ui_open()` はfalse | `InventoryUI`, `Inventory`, `PlayerData.held_inventory_*` | held itemは復元可能 | 通常inventory中の移動・scene跨ぎは許可。 |
| trade | 不可 | `InventoryUI.is_trade_mode_open()`, `GameAndHud.is_special_inventory_ui_open()` | `InventoryUI.trade_inventory`, merchant Unit | modeは持ち越さずnormalへ | merchant参照はscene跨ぎで無効になる可能性。 |
| chest | 不可 | `InventoryUI.is_chest_mode_open()`, `is_special_inventory_ui_open()` | `InventoryUI.trade_inventory` 相当、Chest node | modeは持ち越さずnormalへ | chest参照はscene跨ぎで無効になる可能性。 |
| status | 不可 | `GameAndHud.is_status_open()` | `StatusUI` | scene切替時はUIを閉じる/再構築対象 | status表示中は移動を止める。 |
| dialogue | 不可 | `DialogueManager.is_dialog_open()` | `DialogueManager`, `DialogueUI` | scene切替時は古い対象に注意 | dialogue actionでtradeが開くことがある。 |
| quest board | 不可寄り | `QuestBoardManager` / board UI状態 | QuestBoardManager, QuestBoardUI | scene nodeはfree対象 | controllerのinteraction/lock経路を確認。 |
| keyboard target mode | 状況依存 | controller内mode判定 | PlayerController | UI操作やcancelで解除 | 移動・wait・attack modeとの干渉に注意。 |

## is_ui_locked の考え方

`PlayerController.is_ui_locked()` は移動やmouse auto navigationを止めるための入口です。現在の主なlock対象:

- dialogue open
- special inventory UI open、つまり trade/chest
- status open

通常inventoryは意図的にlock対象ではありません。これは、通常inventory中にheld itemを持ったまま移動やscene移動できる仕様とつながっています。

## 通常inventoryと特殊inventoryの違い

| 項目 | 通常inventory | trade/chest |
| --- | --- | --- |
| 移動 | 可 | 不可 |
| scene跨ぎ | held itemを保持可能 | modeは保持しない |
| 外部参照 | player inventory/equipment中心 | merchant/chest node参照を持つ |
| 危険点 | held item消失 | free済み参照、不正取得 |

## map / scene transition 時にfreeされるもの

`GameAndHud.load_map()` は古いmap sceneをfreeして新しいmap sceneをinstantiateします。これにより、古いscene配下の以下は無効になる可能性があります。

- map上の enemy/npc/chest/pickup nodes
- Chest node とその参照
- merchant Unit node とその参照
- map-specific UIが参照していたnode

そのため、sceneを跨ぐ必要がある状態はAutoloadへ逃がします。

## sceneを跨ぐ状態

| Autoload | 役割 | 例 |
| --- | --- | --- |
| `PlayerData` | player固有状態、map位置、inventory/equipment、held item一時状態 | `map_positions`, `inventory_data`, `equipment_data`, `held_inventory_entry` |
| `WorldState` | world/map/unit/chest/pickup/quest状態 | `unit_states`, `map_enemy_spawns`, `map_item_pickups` |
| `GlobalPlayerSpawn` | 次mapのplayer出現tile | stairs/door後の出現座標 |
| `GlobalDungeon` | dungeon run/floor/return状態 | floor index、stairs context |
| `GlobalDetailMap` | detail map復帰文脈 | field/detailの往復 |

## sceneを跨がない状態

- `InventoryUI.trade_inventory`
- `InventoryUI.trade_unit`
- Chest node reference
- merchant Unit node reference
- 現在map内のnode直接参照

これらをAutoloadにそのまま保存すると、次sceneでfreed objectへアクセスする危険があります。

## UI / 入力 / scene遷移変更時の確認項目

- 通常inventory中に移動できるか
- 通常inventoryでheld itemを持ったままscene移動できるか
- trade中に移動できないか
- chest中に移動できないか
- trade/chest中に万一scene遷移しても、次sceneではnormal inventoryへ戻るか
- held itemが消えないか
- trade/chest由来held itemを不正にplayer bagへ入れないか
- status/dialogue/quest board中の入力lockが維持されるか
- map transition後、古いscene node参照に触らないか
- PlayerData / WorldState / Global* のどこに状態を置くべきか判断できているか
