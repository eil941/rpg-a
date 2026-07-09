# Current System Reading Order

## 目的

このdocsは、`rpg-a` の現行実装を調べる時に「どの資料から、どの順番で読むか」を案内する入口です。

Step 11-A〜Nで、全体構成、サブシステム、個別の実行経路、危険な境界を段階的に文書化しました。すべてを最初から読む必要はありません。まず全体地図を掴み、作業対象に近いsystem docsへ進んでください。

このdocsは現行仕様の読み方を示すものであり、将来の理想設計やリファクタ方針を確定するものではありません。

## 最初に読む3〜5 docs

迷った時は、次の順番を基本にします。

1. [project_structure_overview.md](../architecture/project_structure_overview.md)
   - ディレクトリ、Autoload、scene、data、toolsの全体像を掴みます。
2. [subsystem_interaction_map.md](../architecture/subsystem_interaction_map.md)
   - 機能単位の責務、状態の置き場所、サブシステム間の依存を確認します。
3. [runtime_flow_overview.md](../architecture/runtime_flow_overview.md)
   - 起動、入力、戦闘、UI、save/loadなどの主要フローを追います。
4. [script_responsibility_map.md](../architecture/script_responsibility_map.md)
   - 実際に読むscriptと、その呼び出し元・呼び出し先を絞ります。
5. [feature_addition_guide.md](feature_addition_guide.md)
   - 変更するファイル、触らない境界、確認手順を作業単位で確認します。

Codexへ依頼する場合は、上記に加えて [codex_project_context.md](codex_project_context.md) を先に共有します。

## 領域別の読む順番

### Item / consumable / equipment effect

1. [equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)
2. [game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)
3. [unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md)
4. [feature_addition_guide.md](feature_addition_guide.md)

特に、消耗品、装備パッシブ、装備攻撃効果は同じ `item_effects.tsv` / `item_effect_links.tsv` を使っていても実行入口が異なります。装備用に `equipment_effect_links.tsv` を追加する前提では読まないでください。

### Inventory / Hotbar / Equipment / held item

1. [inventory_trade_chest_system_deep_dive.md](../systems/inventory_trade_chest_system_deep_dive.md)
2. [inventory_ui_state_transition.md](../systems/inventory_ui_state_transition.md)
3. [trade_chest_ownership_deep_dive.md](../systems/trade_chest_ownership_deep_dive.md)
4. [ui_lock_matrix.md](../systems/ui_lock_matrix.md)
5. [save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md)

`UIMode`、held itemのsource、実際の所有者、sceneを跨ぐ一時状態を分けて読みます。通常inventory中は移動可能であり、trade/chest中の移動lockとは別仕様です。

### Trade / Chest

1. [trade_chest_ownership_deep_dive.md](../systems/trade_chest_ownership_deep_dive.md)
2. [inventory_ui_state_transition.md](../systems/inventory_ui_state_transition.md)
3. [inventory_trade_chest_system_deep_dive.md](../systems/inventory_trade_chest_system_deep_dive.md)
4. [ui_lock_matrix.md](../systems/ui_lock_matrix.md)
5. [save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md)

trade/chestのnode参照やside inventory参照はsceneを跨いで保持しません。held item entry/source情報だけを一時保持し、新しいsceneではnormal inventoryへ正規化する境界を先に確認します。

### UI lock / input / scene transition

1. [ui_lock_matrix.md](../systems/ui_lock_matrix.md)
2. [ui_input_scene_transition_deep_dive.md](../systems/ui_input_scene_transition_deep_dive.md)
3. [inventory_ui_state_transition.md](../systems/inventory_ui_state_transition.md)
4. [runtime_flow_overview.md](../architecture/runtime_flow_overview.md)
5. [script_responsibility_map.md](../architecture/script_responsibility_map.md)

`PlayerController.is_ui_locked()` だけで全UI状態を判断しないでください。quest boardなどはUnit側にもlock入口があり、normal inventoryは移動を止めない例外です。

### Unit / Stats / Combat / Death

1. [unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md)
2. [unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md)
3. [death_path_diagram.md](../systems/death_path_diagram.md)
4. [damage_system_notes.md](../systems/damage_system_notes.md)
5. [equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)

`Stats.take_damage()`、各damage入口、`Unit.handle_death()`、`death_handled` guardを一続きで読みます。呼び出し側に重複した死亡確認があっても、dropを初回だけにするguardを壊さないことが重要です。

### Death drop / item drop / pickup save

1. [death_drop_spec.md](../systems/death_drop_spec.md)
2. [death_path_diagram.md](../systems/death_path_diagram.md)
3. [unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md)
4. [save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md)
5. [map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md)

死亡時に落とすのはUnitが実際に持つbag / hotbar / equipmentです。`initial_inventory_entries` を死亡時に再抽選せず、pickup配置成功後にsourceをclearし、生成pickupをWorldStateへ保存する順番を確認します。

### Save / Load / WorldState / PlayerData

1. [save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md)
2. [data_spawn_save_system_deep_dive.md](../systems/data_spawn_save_system_deep_dive.md)
3. [map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md)
4. [save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md)
5. [runtime_flow_overview.md](../architecture/runtime_flow_overview.md)

PlayerData、WorldState、map scene側保存、GlobalDungeon / GlobalDetailMapの所有範囲とreset条件を分けて読みます。変更後は対象に応じてregression matrixのSmoke / Core / Extendedを選びます。

### Map spawn / Enemy / NPC / initial inventory

1. [map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md)
2. [data_spawn_save_system_deep_dive.md](../systems/data_spawn_save_system_deep_dive.md)
3. [unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md)
4. [game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)
5. [save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md)

`initial_inventory_*` はUnit生成時の所持品抽選です。保存済みUnitの復元時には再抽選せず、死亡時drop tableとして扱いません。

### Quest / generated quest / NPC quest

1. [quest_generated_lifecycle_deep_dive.md](../systems/quest_generated_lifecycle_deep_dive.md)
2. [save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md)
3. [map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md)
4. [save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md)
5. [subsystem_interaction_map.md](../architecture/subsystem_interaction_map.md)

template quest、generated quest、NPC link、QuestManager、WorldState、map resetを同時に確認します。repeatableやgeneration block保存の残課題は、現行仕様と混ぜずbacklogとして扱います。

### DebugSettings / logs / start items

1. [debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md)
2. [script_responsibility_map.md](../architecture/script_responsibility_map.md)
3. [save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md)
4. [cognitive_debt_backlog.md](../backlog/cognitive_debt_backlog.md)

flagのdefault値、参照先、start itemの再配布guard、DebugSettings外のdebug出力を分けて確認します。確認Stepで一時的にONにした値を通常状態へ戻す条件も依頼文に明記します。

### Codexへ依頼する前

1. [codex_project_context.md](codex_project_context.md)
2. この [current_system_reading_order.md](current_system_reading_order.md)
3. 対象領域のsystem docs
4. [feature_addition_guide.md](feature_addition_guide.md)
5. 必要なら [cognitive_debt_backlog.md](../backlog/cognitive_debt_backlog.md)

依頼文には、対象サブシステム、変更可能ファイル、変更禁止ファイル、データ変更の有無、Godot確認範囲、最終報告項目を書きます。現行仕様調査と将来リファクタ調査を同じStepに混ぜないことも重要です。

## 危険な境界と参照docs

| 境界 | 壊れやすい点 | 先に読むdocs |
| --- | --- | --- |
| Excel / TSV / loader / validator | 正本との乖離、列default、参照欠け、読み込み順 | [game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md), [data_spawn_save_system_deep_dive.md](../systems/data_spawn_save_system_deep_dive.md) |
| Consumable / equipment effect | 同じeffect dataでも実行入口と意味が違う | [equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md) |
| Inventory entry / ownership / held state | item消失、不正取得、`instance_data`消失、free済み参照 | [inventory_ui_state_transition.md](../systems/inventory_ui_state_transition.md), [trade_chest_ownership_deep_dive.md](../systems/trade_chest_ownership_deep_dive.md) |
| UI mode / input lock | normal inventory中の移動を誤って止める | [ui_lock_matrix.md](../systems/ui_lock_matrix.md), [ui_input_scene_transition_deep_dive.md](../systems/ui_input_scene_transition_deep_dive.md) |
| Unit / Stats / death | 二重death、二重drop、死亡入口の取りこぼし | [death_path_diagram.md](../systems/death_path_diagram.md), [unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md) |
| Initial inventory / death drop | spawn時抽選とdeath時dropの混同 | [unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md), [death_drop_spec.md](../systems/death_drop_spec.md) |
| Drop / pickup / WorldState | drop成功前clear、再訪問時の再生成、保存漏れ | [death_path_diagram.md](../systems/death_path_diagram.md), [map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) |
| Save ownership / reset | 状態消失、二重復元、new game reset漏れ | [save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md), [save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md) |
| Map scene / random spawn / saved Unit | 保存済み個体の再抽選、map固有例外の破損 | [map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) |
| Quest / WorldState / NPC lifecycle | completed/active状態、generated NPC保護、reset差 | [quest_generated_lifecycle_deep_dive.md](../systems/quest_generated_lifecycle_deep_dive.md) |
| DebugSettings / runtime logs | 通常プレイへのdebug配布・ログ流入 | [debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md) |

## Step 11-A〜Nで整備したもの

| Step | 整備した理解用の入口 |
| --- | --- |
| 11-A | project構成、script責務、runtime flow、新機能追加、Codex前提の全体地図 |
| 11-B | サブシステム相互作用とInventory、Combat、Data/Spawn/Save、UI/Inputの横断docs、認知的負債backlog |
| 11-C | docsの用途別再編、README入口、InventoryUI mode / held item状態遷移 |
| 11-D | `Unit.gd` の生成、data適用、行動、inventory、death、save/loadのlifecycle map |
| 11-E | `GameDataRegistry` のTSVカテゴリ別loader / data class / lookup / validator map |
| 11-F | SaveManager / PlayerData / WorldStateの保存対象、復元入口、reset境界 |
| 11-G | map scene scripts、spawn、saved random Unit、pickup/chest、persistence |
| 11-H | Quest / generated quest / NPC quest lifecycle |
| 11-I | Save/LoadのSmoke / Core / Extended回帰確認matrix |
| 11-J | DebugSettings、debug flag、debug start item、DebugSettings外ログ |
| 11-K | Consumable / equipment passive / equipment attack effectの実行経路 |
| 11-L | Trade / Chest / held itemの所有権とscene跨ぎ境界 |
| 11-M | UI状態ごとの移動、行動、hotbar、turn進行のlock matrix |
| 11-N | damage入口からdeath、drop、pickup配置、WorldState保存までのpath diagram |

Step 11-Oでは、これらを読む順番と危険境界で再整理しています。

## まだ改善しないもの

以下は、このStepで実装や設計変更を行いません。必要性と影響範囲をStep 12以降で個別に調査します。

- `GameDataRegistry` のsub-loader分割
- map scene scriptsの共通化
- `Unit.gd` の責務分割
- `InventoryUI` のmode / side panel / held item分割
- UI lock設計の一本化
- Trade / Chest / held item所有権モデルの再設計
- death処理とdrop処理の共通化・分割
- `drop_tables.tsv` / `drop_table_entries.tsv` の導入
- consumable / equipment effect実行経路の共通化
- debug flag / runtime logの通常化
- Quest repeatable / generation block / active dataの残課題監査

「docsで分かったから今すぐ分ける」のではなく、現行仕様を守る確認項目を先に定義してから、小さい調査Stepに分けます。

## 使い方

### 調査だけする時

1. 最初の3〜5 docsで全体と対象scriptを絞ります。
2. 領域別の読む順番に沿ってsystem docsを読みます。
3. 危険な境界を確認します。
4. 現行挙動、状態の置き場所、呼び出し経路、不明点だけを報告します。

### 実装する時

1. 対象system docsと [feature_addition_guide.md](feature_addition_guide.md) を読みます。
2. 変更可能範囲と維持する仕様を決めます。
3. データ変更ならExcel / TSV / loader / validatorの対応を確認します。
4. 実装後にvalidate、`git diff --check`、必要なGodot確認を行います。

### Docsを更新する時

1. 現行コードで確認できた事実と、将来案を分けて書きます。
2. 新しい入口を追加したら [docs/README.md](../README.md) から辿れるようにします。
3. ローカルMarkdownリンク切れと明白な仕様矛盾を確認します。
4. 将来の整理候補は [cognitive_debt_backlog.md](../backlog/cognitive_debt_backlog.md) に集約します。
