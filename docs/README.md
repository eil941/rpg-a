# rpg-a Docs

`rpg-a` の docs 全体の入口です。
コードやデータを触る前に、このページで「どこから読むか」を決めます。

この README は詳細説明ではなく、学習・調査・作業・確認へ進むための分岐点です。

## 最初に読む

| 目的 | 入口 |
| --- | --- |
| 学習開始 | [docs/learning/start_here.md](learning/start_here.md) |
| scriptから探す | [docs/reference/script_quick_reference.md](reference/script_quick_reference.md) |
| 現在のシステムを詳しく読む | [docs/guides/current_system_reading_order.md](guides/current_system_reading_order.md) |
| アイテム追加 | [docs/guides/item_addition_guide.md](guides/item_addition_guide.md) |
| 新機能追加 | [docs/guides/feature_addition_guide.md](guides/feature_addition_guide.md) |
| 不具合調査 | [docs/learning/debug_first_steps.md](learning/debug_first_steps.md) |
| Codex依頼 | [docs/guides/codex_project_context.md](guides/codex_project_context.md) |

## 目的別に探す

| 知りたいこと・作業 | まず読むdocs |
| --- | --- |
| プロジェクト内のデータと処理の大まかな関係 | [learning/start_here.md](learning/start_here.md) |
| Excelの内容がゲームへ入る流れ | [learning/excel_to_game_flow.md](learning/excel_to_game_flow.md) |
| DatabaseとManagerの違い | [learning/database_and_manager_roles.md](learning/database_and_manager_roles.md) |
| 通常アイテム使用 | [learning/item_use_flow.md](learning/item_use_flow.md) |
| 対象指定アイテム使用 | [learning/target_item_use_flow.md](learning/target_item_use_flow.md) |
| 装備パッシブ | [learning/equipment_passive_flow.md](learning/equipment_passive_flow.md) |
| 装備攻撃効果 | [learning/equipment_attack_effect_flow.md](learning/equipment_attack_effect_flow.md) |
| 攻撃・ダメージ・死亡 | [learning/combat_damage_death_flow.md](learning/combat_damage_death_flow.md) |
| 死亡時ドロップ | [learning/death_drop_flow.md](learning/death_drop_flow.md) |
| 新しいデータやeffect typeを追加する判断 | [learning/adding_new_data_or_effect_type.md](learning/adding_new_data_or_effect_type.md) |
| 症状から最初に見るscriptを選ぶ | [reference/script_quick_reference.md](reference/script_quick_reference.md) |
| Save/Loadの手動確認 | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |

## フォルダ構成

| フォルダ | 目的 | 使う場面 |
| --- | --- | --- |
| `learning/` | 基礎や処理の流れを学ぶ | 初めて理解する時、忘れた内容を学び直す時 |
| `reference/` | 早見表・逆引き | 開発中に短時間で確認する時 |
| `guides/` | 作業手順 | アイテム追加、新機能追加、Codex依頼時 |
| `systems/` | 現行実装の詳細仕様 | 特定機能を詳しく調査する時 |
| `architecture/` | 全体構造と責務 | subsystemやscript関係を確認する時 |
| `checklists/` | 確認項目 | Godot実行確認や回帰確認時 |
| `migration/` | 移行履歴 | 過去方式と変更経緯を確認する時 |
| `backlog/` | 将来候補 | 未対応項目や認知的負債を確認する時 |

`systems/` のうち、件数が多い領域だけ `combat/`、`inventory/`、`data/` に分けています。
1から2件の領域は、不要に深くしないため `systems/` 直下に残しています。

## 学習する

まず [learning/start_here.md](learning/start_here.md) で全体像をつかみます。
その後は、目的に近い learning docs だけを読みます。

推奨順は次の通りです。

1. [learning/start_here.md](learning/start_here.md)
2. [learning/database_and_manager_roles.md](learning/database_and_manager_roles.md)
3. [learning/excel_to_game_flow.md](learning/excel_to_game_flow.md)
4. [learning/item_use_flow.md](learning/item_use_flow.md)
5. [learning/target_item_use_flow.md](learning/target_item_use_flow.md)
6. [learning/equipment_passive_flow.md](learning/equipment_passive_flow.md)
7. [learning/equipment_attack_effect_flow.md](learning/equipment_attack_effect_flow.md)
8. [learning/combat_damage_death_flow.md](learning/combat_damage_death_flow.md)
9. [learning/death_drop_flow.md](learning/death_drop_flow.md)
10. [learning/debug_first_steps.md](learning/debug_first_steps.md)
11. [learning/adding_new_data_or_effect_type.md](learning/adding_new_data_or_effect_type.md)

`learning/` は詳細docsを置き換えるものではありません。
最初に全体像をつかみ、必要になった時だけ `architecture/`、`systems/`、`guides/`、`checklists/` へ進みます。

## 実装を調査する

| 調査したいこと | 入口 |
| --- | --- |
| 領域別にどのdocsから読むか | [guides/current_system_reading_order.md](guides/current_system_reading_order.md) |
| scriptを開いて最初に見る関数 | [reference/script_quick_reference.md](reference/script_quick_reference.md) |
| scriptごとの責務 | [architecture/script_responsibility_map.md](architecture/script_responsibility_map.md) |
| 全体構造 | [architecture/project_structure_overview.md](architecture/project_structure_overview.md) |
| runtime flow | [architecture/runtime_flow_overview.md](architecture/runtime_flow_overview.md) |
| サブシステム間の関係 | [architecture/subsystem_interaction_map.md](architecture/subsystem_interaction_map.md) |

## データやアイテムを追加する

| 作業 | 入口 |
| --- | --- |
| アイテムを追加する | [guides/item_addition_guide.md](guides/item_addition_guide.md) |
| 新機能追加の影響範囲を確認する | [guides/feature_addition_guide.md](guides/feature_addition_guide.md) |
| ExcelからTSV、ゲーム内データまでの流れを確認する | [learning/excel_to_game_flow.md](learning/excel_to_game_flow.md) |
| 新しいeffect typeが必要か判断する | [learning/adding_new_data_or_effect_type.md](learning/adding_new_data_or_effect_type.md) |
| GameDataRegistryの読み込みを確認する | [systems/data/game_data_registry_loader_map.md](systems/data/game_data_registry_loader_map.md) |
| item effectの実行経路を確認する | [systems/equipment_item_effect_execution_path.md](systems/equipment_item_effect_execution_path.md) |

## 不具合を調査する

| 状況 | 入口 |
| --- | --- |
| 症状から最初の確認先を選ぶ | [learning/debug_first_steps.md](learning/debug_first_steps.md) |
| script名から確認関数を選ぶ | [reference/script_quick_reference.md](reference/script_quick_reference.md) |
| DebugSettingsやdebug start itemを確認する | [systems/debug_settings_deep_dive.md](systems/debug_settings_deep_dive.md) |
| Save/Loadの回帰確認をする | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |
| Debug出力の整理候補を見る | [backlog/debug_output_normalization_audit.md](backlog/debug_output_normalization_audit.md) |

## Codexへ依頼する

Codexへ作業を依頼する前に、まず [guides/current_system_reading_order.md](guides/current_system_reading_order.md) で対象領域のdocsを選びます。
依頼文の前提として渡す情報は [guides/codex_project_context.md](guides/codex_project_context.md) にまとめています。

依頼文には、できれば次を含めます。

- 対象サブシステム
- 触ってよいファイル
- 触らないファイル
- データ変更の有無
- Godot確認の要否
- 最終報告でほしい項目

## 詳細なシステム仕様

| 領域 | 詳細docs |
| --- | --- |
| Data / Spawn / Save | [systems/data/data_spawn_save_system_deep_dive.md](systems/data/data_spawn_save_system_deep_dive.md) |
| Save / WorldState / PlayerData | [systems/data/save_worldstate_playerdata_map.md](systems/data/save_worldstate_playerdata_map.md) |
| Map spawn / persistence | [systems/map_spawn_persistence_deep_dive.md](systems/map_spawn_persistence_deep_dive.md) |
| Inventory / Trade / Chest | [systems/inventory/inventory_trade_chest_system_deep_dive.md](systems/inventory/inventory_trade_chest_system_deep_dive.md) |
| Inventory UI state | [systems/inventory/inventory_ui_state_transition.md](systems/inventory/inventory_ui_state_transition.md) |
| UI lock / scene transition | [systems/ui_lock_matrix.md](systems/ui_lock_matrix.md), [systems/ui_input_scene_transition_deep_dive.md](systems/ui_input_scene_transition_deep_dive.md) |
| Equipment / item effects | [systems/equipment_item_effect_execution_path.md](systems/equipment_item_effect_execution_path.md) |
| Combat / death | [systems/combat/unit_combat_death_system_deep_dive.md](systems/combat/unit_combat_death_system_deep_dive.md), [systems/combat/death_path_diagram.md](systems/combat/death_path_diagram.md) |
| Death drop | [systems/combat/death_drop_spec.md](systems/combat/death_drop_spec.md) |
| Damage notes | [systems/combat/damage_system_notes.md](systems/combat/damage_system_notes.md) |
| Unit lifecycle | [systems/unit_lifecycle_deep_dive.md](systems/unit_lifecycle_deep_dive.md) |
| Quest lifecycle | [systems/quest_generated_lifecycle_deep_dive.md](systems/quest_generated_lifecycle_deep_dive.md) |

## チェックリスト

| 用途 | docs |
| --- | --- |
| Save/Load回帰確認 | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |

## 移行の履歴

| 用途 | docs |
| --- | --- |
| TSV移行の調査記録 | [migration/tsv_migration_audit.md](migration/tsv_migration_audit.md) |
| TSV移行の完了メモ | [migration/tsv_migration_completion.md](migration/tsv_migration_completion.md) |

## backlog・将来候補

`backlog/` は現行仕様ではなく、将来の整理候補や調査計画です。
実装判断の正本として使う前に、必ず `learning/`、`systems/`、`architecture/`、`guides/` の現行docsを確認します。

| 用途 | docs |
| --- | --- |
| learning docs再設計計画 | [backlog/docs_learning_redesign_plan.md](backlog/docs_learning_redesign_plan.md) |
| 認知的負債の整理候補 | [backlog/cognitive_debt_backlog.md](backlog/cognitive_debt_backlog.md) |
| debug出力整理候補 | [backlog/debug_output_normalization_audit.md](backlog/debug_output_normalization_audit.md) |
| GameDataRegistry debug dump整理候補 | [backlog/gamedata_registry_debug_dump_audit.md](backlog/gamedata_registry_debug_dump_audit.md) |
