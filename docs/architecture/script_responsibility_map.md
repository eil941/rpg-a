# Script Responsibility Map

Step 11-A 時点の主要スクリプト責務表です。全ファイルを完全網羅するものではなく、今後の開発で迷いやすい入口を優先しています。

## Core / Data / Save

| Script | 主な責務 | 主な呼び出し元 | 主な呼び出し先 | 変更すると影響する機能 | 新機能追加時の注意 |
| --- | --- | --- | --- | --- | --- |
| `scripts/data/game_data_registry.gd` | TSVを読み込み、Item/Enemy/NPC/Quest/Effect/Spawn等を辞書やResourceとして提供 | Autoload `_ready()`、ItemDatabase、manager、map scripts | 各 `scripts/data/*_data.gd`、TSV parser | 全TSV-backed機能 | 列追加時は data class と validator も確認。[../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md) で読み込み順とfallbackを確認する。 |
| `scripts/data/player_data.gd` | プレイヤーの永続状態、map位置、inventory/equipment/effects、held item一時状態 | Unit、SaveManager、InventoryUI | 主に状態保持 | Player save/load、scene跨ぎ、held item | World/NPC/Chest状態を入れすぎない。[../systems/save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md) でreset対象も確認。 |
| `scripts/world/world_state.gd` | Unit状態、map tile、chest、pickup、quest、死亡状態などワールド永続状態 | Map scripts、SaveManager、Unit、ItemWorldManager | 内部helper | map復元、敵死亡、pickup/chest永続化 | 広い辞書を雑にclearしない。[../systems/save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md) でmap_id/unit_id単位の保存先を確認。 |
| `scripts/save_manager.gd` | save/load/new game の統括、Autoload snapshot | title/menu/HUD | PlayerData、WorldState、TimeManager、map `save_all_units()` | save/load、new game、map復元 | 新しい永続フィールド追加時は [../systems/save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md) で snapshot、restore、reset の3点を見る。 |
| `scripts/debug/DebugSettings.gd` | デバッグフラグ、開始アイテム、検証用設定 | 多数のscript | なし | デバッグログ、開始所持品、検証挙動 | 通常状態では default OFF が基本。確認StepでONにしたものは戻す。 |

## Unit / Stats / Skills

| Script | 主な責務 | 主な呼び出し元 | 主な呼び出し先 | 変更すると影響する機能 | 新機能追加時の注意 |
| --- | --- | --- | --- | --- | --- |
| `scripts/core/unit.gd` | Unit共通本体。移動、data適用、inventory、equipment、stat合計、initial inventory、死亡時drop、save data | Controller、CombatManager、UnitSpawnManager、ItemEffectManager | Stats、Skills、Inventory、ItemDropHelper、ItemDatabase、WorldState | 移動、戦闘、装備、死亡、保存、AI、会話 | 最重要・高密度。[../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md) を入口にし、小さいhelper追加に留め、無関係リファクタを避ける。 |
| `scripts/core/stats.gd` | HP/MP等の基礎値、ダメージ、回復、死亡トリガ | Unit、CombatManager、ItemEffectManager | 親Unitの `handle_death()` | HP、死亡、回復、status表示 | HPを直接変更する時は死亡判定経路に注意。 |
| `scripts/core/skills.gd` | 旧固定スキルとTSV由来dynamic skills、成長、save data | Unit、status_ui、GameDataRegistry | GameData | スキル表示、成長、保存 | active API は `Skills`。`skill_state` や `Unit.add_skill_exp()` を復活させない。 |

## Input / HUD / UI

| Script | 主な責務 | 主な呼び出し元 | 主な呼び出し先 | 変更すると影響する機能 | 新機能追加時の注意 |
| --- | --- | --- | --- | --- | --- |
| `scripts/controllers/player_controller.gd` | プレイヤー入力、移動、hotbar使用、mouse action、keyboard target mode、UI lock | Player Unit | Unit、CombatManager、GameAndHud | 移動、入力、ターン進行、UI中移動制御 | 通常inventory中は移動可、trade/chest等特殊UIは移動不可の境界に注意。 |
| `scripts/hud/game_and_hud.gd` | Game root。map container、HUD、UI開閉、map load、player検索、死亡メニュー | Main scene、controller、manager | InventoryUI、StatusUI、SaveManager、map scene | map遷移、UI表示、HUD更新 | map切替で古いscene nodeはfreeされる。跨ぐ状態は Autoload へ。map遷移とspawn保存の流れは [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) を参照。 |
| `scripts/hud/game_hud.gd` | HUD表示、hotbarボタン表示 | GameAndHud、Unit | UI controls | HP/status/hotbar表示 | 表示中心に保つ。行動ロジックはController/Inventory側。 |
| `scripts/item/inventory_ui.gd` | inventory UI state machine。bag/hotbar/equipment/trade/chest/held item/tooltip/world drop | GameAndHud、Chest、DialogueManager、ユーザー入力 | Inventory、ItemDatabase、TradePriceCalculator、PlayerData | inventory UI、装備、trade/chest、held item跨ぎ | held item state と UI mode を分ける。free済み trade/chest 参照に触らない。 |
| `scripts/hud/status_ui.gd` | status/equipment/skills/quest表示 | GameAndHud | Unit、Skills、QuestManager、ItemDatabase | ステータス、スキル、クエスト表示 | スキル表示は統一済み。`[TSV Skill State]` を復活させない。 |

## Item / Inventory / Effect

| Script | 主な責務 | 主な呼び出し元 | 主な呼び出し先 | 変更すると影響する機能 | 新機能追加時の注意 |
| --- | --- | --- | --- | --- | --- |
| `scripts/item/inventory.gd` | bag/hotbar entry管理、stack、instance_data、add/remove/save/load/use | Unit、InventoryUI、quest/trade | ItemDatabase、ItemEffectManager | inventory、hotbar、save/load、死亡drop元 | 装備やenchant付きentryは `instance_data` を深く保持する。 |
| `scripts/item/item_database.gd` | GameDataへのitem/equipment/effect lookup wrapper、random item helper | Inventory/UI/world manager | GameData | item表示、random spawn、equipment entry生成 | random候補は `spawn_weight <= 0` を除外する方針。sample品を混ぜない。 |
| `scripts/item/item_effect_manager.gd` | consumable/target item effect実行。restore/status/modifier/damage/grant/teleport等 | Inventory、CombatManager、Item use | UnitEffectRuntime、Stats、CombatManager、ItemDatabase | 消耗品、状態異常、バフ、回復、ダメージ | 装備攻撃効果と同じ `ItemEffectData` を使うが、trigger path は別。 |
| `scripts/item/unit_effect_runtime.gd` | runtime status/modifierの持続、tick、save data | ItemEffectManager、Unit | なし | 状態異常、継続ダメージ、時限buff | tick damage は死亡処理へ正しくつながる必要があります。 |
| `scripts/item/item_world_manager.gd` | world pickup/chest の生成、load/save、random item/chest table処理 | map scene scripts | ItemDatabase、GameData、WorldState、Chest | field/dungeon item、chest、pickup永続化 | random生成はspawn candidate filterと保存済み状態を尊重。detail/dungeonでの使われ方は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) へ。 |
| `scripts/item/item_drop_helper.gd` | Unit近傍へentryをdrop、stackable pickup merge、WorldState保存 | Unit死亡drop、InventoryUI discard | ItemPickup、WorldState | 死亡drop、手動drop | `instance_data` 維持とsource slot clearの順序に注意。 |
| `scripts/item/item_pickup.gd` | world上のpickup node、entry保存、見た目 | ItemWorldManager、ItemDropHelper | ItemDatabase | pickup表示、取得、保存 | `setup_with_entry()` は装備instance情報を保持できる。 |
| `scripts/item/chest/chest.gd` | chest inventory、権限、save/load、chest UI起動 | Player interaction | InventoryUI.open_chest_mode() | chest storage、loot UI | `UIMode.CHEST` は特殊Inventory画面。 |

## Combat / AI

| Script | 主な責務 | 主な呼び出し元 | 主な呼び出し先 | 変更すると影響する機能 | 新機能追加時の注意 |
| --- | --- | --- | --- | --- | --- |
| `scripts/combat/combat_manager.gd` | 攻撃可否、通常攻撃実行、target item use、装備攻撃効果 | Player/AI controller | DamageCalculator、ItemEffectManager、Unit、Stats | 攻撃、死亡、装備攻撃効果 | `deal_damage`、`apply_status`、`restore_resource` の死亡時挙動差を維持。 |
| `scripts/combat/damage_calculator.gd` | 命中、crit、防御、属性/タイプ補正 | CombatManager、item effect | Unit stat getter | ダメージバランス | 新フィールドは `ItemEffectData` と validator まで見る。 |
| `scripts/combat/targeting.gd` | tile/unit lookup、範囲判定補助 | Controller、CombatManager | scene unit nodes | bump attack、mouse target | tile座標・layer前提に注意。 |
| `scripts/controllers/ai_controller.gd` | enemy AI行動選択 | TimeManager / Unit setup | CombatManager、Unit.try_move() | enemy行動 | enemy dataの列で表現できるならhardcodeしない。 |
| `scripts/controllers/enemy_controller.gd` | simple enemy movement fallback | Unit setup | Unit.try_move() | enemy移動 | 古い/単純経路の可能性あり。 |
| `scripts/controllers/npc_controller.gd` | NPC movement fallback | Unit setup | Unit.try_move() | NPC移動 | merchant/shop在庫はここではない。 |

## Spawn / Map / Persistence

| Script | 主な責務 | 主な呼び出し元 | 主な呼び出し先 | 変更すると影響する機能 | 新機能追加時の注意 |
| --- | --- | --- | --- | --- | --- |
| `scripts/managers/unit_spawn_manager.gd` | saved/random enemy/npc生成、data適用、initial inventory、shop inventory | map scene scripts | Unit、GameData、WorldState、ItemDatabase | enemy/npc spawn、初期所持品、merchant stock | 保存済みUnitではinitial inventoryを再抽選しない。shop inventoryと本体inventoryを混ぜない。map別の入口は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) へ。 |
| `scripts/map/map_scene_scripts/main.gd` | 詳細マップ。tile生成、spawn pool、item/chest manager | GameAndHud.load_map() | UnitSpawnManager、ItemWorldManager、WorldState | 詳細マップ、random enemies/items/chests | `spawn_generator_tags` と spawn rules を使う。field/detail/dungeon差分は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) へ。 |
| `scripts/map/map_scene_scripts/FiledMap.gd` | field map、field dungeon/special place生成 | GameAndHud.load_map() | WorldState、map generators | フィールド、入口、reset flow | repo上のファイル名は `FiledMap.gd`。reset/regenerationの詳細は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) へ。 |
| `scripts/dungeon/dungeon_main.gd` | dungeon floor生成、enemy pool、stairs、item/chest manager | GameAndHud.load_map() | GlobalDungeon、UnitSpawnManager、ItemWorldManager | dungeon探索 | floor state は `WorldState.dungeon_*` に保存。floor生成/保存の詳細は [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) へ。 |
| `scripts/world/GlobalPlayerSpawn.gd` | 遷移先player tileの一時保持 | map scenes、stairs | なし | map transition位置 | one-shot stateのclear/consumeに注意。 |

## Dialogue / Quest / Trade

| Script | 主な責務 | 主な呼び出し元 | 主な呼び出し先 | 変更すると影響する機能 | 新機能追加時の注意 |
| --- | --- | --- | --- | --- | --- |
| `scripts/managers/dialogue_manager.gd` | Unit会話開始、会話アクション処理、trade UI起動 | Unit.try_talk_to_front_unit()、DialogueUI | GameAndHud.open_trade_ui()、QuestManager | NPC会話、trade入口 | action は文字列駆動。 |
| `scripts/dialogue_ui.gd` | 会話表示、選択肢、action選択 | DialogueManager | DialogueManager.on_action_selected() | dialogue UI | state owner は manager 側に寄せる。 |
| `scripts/managers/quest_manager.gd` | quest template、生成quest、受注/完了/失敗、報酬 | dialogue、quest board、status UI | GameData、Inventory、WorldState | quest system | generated quest stateのreset条件に注意。 |
| `scripts/managers/quest_board_manager.gd` | quest board UI状態 | quest board object | QuestBoardUI | quest board interaction | UI lock pathでも参照される。 |
| `scripts/object/questboard/quest_board.gd` | world上のquest board object | Player interaction | QuestBoardManager | board open | object bridge。 |
| `scripts/object/questboard/quest_board_ui.gd` | board上のquest表示、accept/complete | QuestBoardManager | QuestManager | board UI | status UIのquest pageとは別。 |
| `scripts/trade_price_calculator.gd` | 売買価格計算、友好度/スキル/enchant補正 | InventoryUI | ItemDatabase、Skills | trade価格 | inventory移動はInventoryUI側。 |

## Data Resource Scripts

| Script | 主な責務 | 補足 |
| --- | --- | --- |
| `scripts/data/item_data.gd` | item基本データ。category、stack、use/target flags、linked effects | 消耗品と装備の共通土台。 |
| `scripts/data/equipment_data.gd` | equipment item。slot、stat bonus、attack element/type/range/style | `ItemData` を継承/拡張。 |
| `scripts/data/item_effect_data.gd` | restore/status/modifier/damage等のeffect schema | `trigger_chance` は装備攻撃効果の発動率で使用。 |
| `scripts/data/enemy_data.gd` | TSV-backed enemy定義 | equipment、initial inventory、death drop設定、AI/talk/shop fields。 |
| `scripts/data/npc_data.gd` | TSV-backed NPC定義 | enemy類似 + dialogue/shop table等。 |
| `scripts/data/initial_inventory_entry.gd` | spawn時initial inventory entry | `spawn_chance` が正式名。旧 `drop_chance` はfallback。 |
| `scripts/data/quest_data.gd` | quest定義・template | QuestManagerで使用。 |
| `scripts/data/spawnrule_data.gd` | field/detail map spawn rule | map scene scriptsで使用。 |
| `scripts/data/dungeon_spawn_rule_data.gd` | dungeon spawn rule | dungeon floor生成で使用。 |

## 高密度ファイル

| File | 高密度な理由 | 実務上の読み方 |
| --- | --- | --- |
| `scripts/core/unit.gd` | Unit identity、移動、stats、equipment、effects、save、death、interactionが集約 | [../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md) で領域を絞ってから、関連関数を `rg` で特定し、小さく読む。無関係な整理を混ぜない。 |
| `scripts/item/inventory_ui.gd` | normal/trade/chest/held item/tooltip/keyboard操作が同居 | `ui_mode` と `held_from_area` を軸に読む。 |
| `scripts/data/game_data_registry.gd` | 全TSV loaderとnormalizerが同居 | 新列追加時は [../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md) を入口に、loader、data class、validator の3点セットで見る。 |
| `scripts/managers/quest_manager.gd` | template/generated quest、board、dialogue連携 | WorldStateとの永続化境界を先に確認。 |
