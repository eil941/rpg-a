# rpg-a Docs

`rpg-a` の設計メモ、理解用地図、仕様メモ、移行メモを用途別に整理した入口です。

コードやTSVを触る前に、該当するdocsを先に読むと「どこを触るべきか」「触ると危ない境界はどこか」を判断しやすくなります。

## 初めて読む場合

プロジェクト所有者が内部実装の理解を深める場合は、まず `learning/` から読みます。

`learning/` は、既存の詳細docsを置き換えるものではありません。最初に全体像をつかみ、必要になった時だけ `architecture/`、`systems/`、`guides/`、`checklists/` へ進むための入口です。

### 推奨学習順

| 順番 | docs | 目的 |
| --- | --- | --- |
| 1 | [learning/start_here.md](learning/start_here.md) | 主要スクリプトの役割と、次に読むdocsを選ぶ |
| 2 | [learning/database_and_manager_roles.md](learning/database_and_manager_roles.md) | DatabaseとManagerの違いを理解する |
| 3 | [learning/excel_to_game_flow.md](learning/excel_to_game_flow.md) | Excelからゲーム実行時データまでの流れを理解する |
| 4 | [learning/item_use_flow.md](learning/item_use_flow.md) | 通常アイテム使用と回復処理を追う |
| 5 | [learning/target_item_use_flow.md](learning/target_item_use_flow.md) | 対象指定アイテムの処理を追う |
| 6 | [learning/equipment_passive_flow.md](learning/equipment_passive_flow.md) | 装備パッシブとstat合成を追う |
| 7 | [learning/equipment_attack_effect_flow.md](learning/equipment_attack_effect_flow.md) | 装備攻撃効果とtrigger_chanceを追う |
| 8 | [learning/combat_damage_death_flow.md](learning/combat_damage_death_flow.md) | 攻撃、ダメージ、死亡処理を追う |
| 9 | [learning/death_drop_flow.md](learning/death_drop_flow.md) | 死亡時ドロップとWorldState保存を追う |
| 10 | [learning/debug_first_steps.md](learning/debug_first_steps.md) | 不具合時に最初に見る場所を選ぶ |
| 11 | [learning/adding_new_data_or_effect_type.md](learning/adding_new_data_or_effect_type.md) | データ追加だけで済むか、新実装が必要か判断する |

### 目的別入口

| 目的 | まず読むdocs |
| --- | --- |
| 全体像を知りたい | [learning/start_here.md](learning/start_here.md) |
| Excelの内容がゲームへ入る流れを知りたい | [learning/excel_to_game_flow.md](learning/excel_to_game_flow.md) |
| DatabaseとManagerの違いを知りたい | [learning/database_and_manager_roles.md](learning/database_and_manager_roles.md) |
| ポーションなど通常アイテム使用を追いたい | [learning/item_use_flow.md](learning/item_use_flow.md) |
| 対象指定アイテムを追いたい | [learning/target_item_use_flow.md](learning/target_item_use_flow.md) |
| 装備パッシブを追いたい | [learning/equipment_passive_flow.md](learning/equipment_passive_flow.md) |
| 装備攻撃効果を追いたい | [learning/equipment_attack_effect_flow.md](learning/equipment_attack_effect_flow.md) |
| 攻撃、ダメージ、死亡を追いたい | [learning/combat_damage_death_flow.md](learning/combat_damage_death_flow.md) |
| 死亡時ドロップを追いたい | [learning/death_drop_flow.md](learning/death_drop_flow.md) |
| 不具合時の最初の確認先を知りたい | [learning/debug_first_steps.md](learning/debug_first_steps.md) |
| 新しいデータやeffect typeを追加したい | [learning/adding_new_data_or_effect_type.md](learning/adding_new_data_or_effect_type.md) |

### 既存docsとの関係

`learning/` は学習用の入口です。

`architecture/` は全体構造の詳細地図、`systems/` は現行仕様と実装経路の詳細、`guides/` は実際の作業手順、`checklists/` は動作確認、`backlog/` は将来の整理候補です。

[guides/current_system_reading_order.md](guides/current_system_reading_order.md) は、実装調査や作業対象が決まっている時の詳細docs読書順として残します。まず理解を作る時は `learning/`、作業対象を深掘りする時は `current_system_reading_order` を使います。

## フォルダ構成

| フォルダ | 内容 | 主な用途 |
| --- | --- | --- |
| `learning/` | 所有者向けの学習用ドキュメント | 基礎から処理経路と責務を理解する |
| `architecture/` | 全体構成、主要スクリプト責務、runtime flow、サブシステム相互作用 | プロジェクト全体の地図を掴む |
| `systems/` | Inventory、Combat、Data/Spawn/Save、UI/Input、Death Drop、Damageなど個別システムの深掘り | 特定機能を変更する前の調査 |
| `guides/` | 新機能追加ガイド、Codex依頼時の前提資料 | 作業依頼や実装Stepの入口 |
| `checklists/` | 実機確認マトリクス、回帰確認手順 | Godot上で確認する項目を揃える |
| `migration/` | TSV移行状況、移行完了メモ | データ移行方針や保留テーブルの確認 |
| `backlog/` | 認知的負債・整理候補 | 今後の整理Step候補 |

## まず読むもの

| 目的 | 読むdocs |
| --- | --- |
| 何から読むか、領域別にどの順番で読むか知りたい | [guides/current_system_reading_order.md](guides/current_system_reading_order.md) |
| 全体構成を知りたい | [architecture/project_structure_overview.md](architecture/project_structure_overview.md) |
| 主要スクリプトの責務を知りたい | [architecture/script_responsibility_map.md](architecture/script_responsibility_map.md) |
| 処理フローを追いたい | [architecture/runtime_flow_overview.md](architecture/runtime_flow_overview.md) |
| 機能単位の関係を知りたい | [architecture/subsystem_interaction_map.md](architecture/subsystem_interaction_map.md) |
| 新機能を追加したい | [guides/feature_addition_guide.md](guides/feature_addition_guide.md) |
| 新しいアイテムを手作業で追加し、効果実装が必要か判断したい | [guides/item_addition_guide.md](guides/item_addition_guide.md) |
| Save/Load回帰確認をしたい | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |
| DebugSettings / debug flag / debug start item を確認したい | [systems/debug_settings_deep_dive.md](systems/debug_settings_deep_dive.md) |
| 通常プレイ中に出るdebug出力の棚卸しを見たい | [backlog/debug_output_normalization_audit.md](backlog/debug_output_normalization_audit.md) |
| Codexに作業依頼したい | [guides/codex_project_context.md](guides/codex_project_context.md) |

## Inventory系を触る時

| 目的 | 読むdocs |
| --- | --- |
| Inventory / Trade / Chest 全体を理解する | [systems/inventory_trade_chest_system_deep_dive.md](systems/inventory_trade_chest_system_deep_dive.md) |
| `InventoryUI` の mode / held item 状態遷移を確認する | [systems/inventory_ui_state_transition.md](systems/inventory_ui_state_transition.md) |
| Trade / Chest / held item の所有権境界を見る | [systems/trade_chest_ownership_deep_dive.md](systems/trade_chest_ownership_deep_dive.md) |
| UI状態ごとの移動・行動・入力lockを見る | [systems/ui_lock_matrix.md](systems/ui_lock_matrix.md) |
| UI lock やscene遷移との関係を見る | [systems/ui_input_scene_transition_deep_dive.md](systems/ui_input_scene_transition_deep_dive.md) |

## 戦闘・死亡を触る時

| 目的 | 読むdocs |
| --- | --- |
| `Unit.gd` のライフサイクル別入口を知る | [systems/unit_lifecycle_deep_dive.md](systems/unit_lifecycle_deep_dive.md) |
| Unit / Combat / Death の流れを知る | [systems/unit_combat_death_system_deep_dive.md](systems/unit_combat_death_system_deep_dive.md) |
| 消耗品効果・装備パッシブ・装備攻撃効果の実行経路を知る | [systems/equipment_item_effect_execution_path.md](systems/equipment_item_effect_execution_path.md) |
| 死亡時ドロップ仕様を確認する | [systems/death_drop_spec.md](systems/death_drop_spec.md) |
| HP0から死亡処理・drop・WorldState保存までを追う | [systems/death_path_diagram.md](systems/death_path_diagram.md) |
| ダメージeffectの補足を見る | [systems/damage_system_notes.md](systems/damage_system_notes.md) |

## データ・TSVを触る時

| 目的 | 読むdocs |
| --- | --- |
| Data / Spawn / Save の関係を見る | [systems/data_spawn_save_system_deep_dive.md](systems/data_spawn_save_system_deep_dive.md) |
| Save / WorldState / PlayerData の保存対象を見る | [systems/save_worldstate_playerdata_map.md](systems/save_worldstate_playerdata_map.md) |
| Map scene / spawn / persistence の流れを見る | [systems/map_spawn_persistence_deep_dive.md](systems/map_spawn_persistence_deep_dive.md) |
| Save/Load実機確認チェック表を見る | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |
| 新しいitem追加、category追加、effect実装判断の具体手順を見る | [guides/item_addition_guide.md](guides/item_addition_guide.md) |
| GameDataRegistryのTSV loader / lookup対応を見る | [systems/game_data_registry_loader_map.md](systems/game_data_registry_loader_map.md) |
| GameDataRegistry起動時debug dumpの棚卸しとsummary/details flagを見る | [backlog/gamedata_registry_debug_dump_audit.md](backlog/gamedata_registry_debug_dump_audit.md) |
| item_effects / item_effect_links の実行入口を見る | [systems/equipment_item_effect_execution_path.md](systems/equipment_item_effect_execution_path.md) |
| TSV移行状況を見る | [migration/tsv_migration_audit.md](migration/tsv_migration_audit.md) |
| TSV移行完了方針を見る | [migration/tsv_migration_completion.md](migration/tsv_migration_completion.md) |
| 新機能追加時のデータ手順を見る | [guides/feature_addition_guide.md](guides/feature_addition_guide.md) |

## Quest / Generated Quest を触る時

| 目的 | 読むdocs |
| --- | --- |
| Quest / generated quest / NPC quest lifecycle の全体像を見る | [systems/quest_generated_lifecycle_deep_dive.md](systems/quest_generated_lifecycle_deep_dive.md) |
| Save / WorldState 側の保存対象を見る | [systems/save_worldstate_playerdata_map.md](systems/save_worldstate_playerdata_map.md) |
| map reset / spawn persistence と active quest NPC 保護を見る | [systems/map_spawn_persistence_deep_dive.md](systems/map_spawn_persistence_deep_dive.md) |
| Questを含むSave/Load確認項目を見る | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |

## DebugSettings / 確認用設定を触る時

| 目的 | 読むdocs |
| --- | --- |
| DebugSettingsのflagと開始アイテムの現状を見る | [systems/debug_settings_deep_dive.md](systems/debug_settings_deep_dive.md) |
| DebugSettings管理内外のログ通常化候補を見る | [backlog/debug_output_normalization_audit.md](backlog/debug_output_normalization_audit.md) |
| Save/Load確認時にDebugSettings由来の影響を見る | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |
| DebugSettings変更時に触るscript責務を見る | [architecture/script_responsibility_map.md](architecture/script_responsibility_map.md) |

## Codexに依頼する時

まず [guides/current_system_reading_order.md](guides/current_system_reading_order.md) で対象領域のdocsを絞り、[guides/codex_project_context.md](guides/codex_project_context.md) を依頼の前提として使います。

依頼文には、できれば以下を書きます。

- 対象サブシステム
- 触ってよいファイル
- 触らないファイル
- データ変更あり/なし
- Godot確認したい項目
- 最終報告でほしい項目

## 認知的負債

今後の整理候補は [backlog/cognitive_debt_backlog.md](backlog/cognitive_debt_backlog.md) にまとめています。

現時点では、`inventory_ui.gd`、`game_data_registry.gd`、Save/WorldState境界が特に深掘り候補です。`unit.gd` については [systems/unit_lifecycle_deep_dive.md](systems/unit_lifecycle_deep_dive.md)、map scene scriptsについては [systems/map_spawn_persistence_deep_dive.md](systems/map_spawn_persistence_deep_dive.md) を入口にします。
