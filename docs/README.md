# rpg-a Docs

`rpg-a` の設計メモ、理解用地図、仕様メモ、移行メモを用途別に整理した入口です。

コードやTSVを触る前に、該当するdocsを先に読むと「どこを触るべきか」「触ると危ない境界はどこか」を判断しやすくなります。

## フォルダ構成

| フォルダ | 内容 | 主な用途 |
| --- | --- | --- |
| `architecture/` | 全体構成、主要スクリプト責務、runtime flow、サブシステム相互作用 | プロジェクト全体の地図を掴む |
| `systems/` | Inventory、Combat、Data/Spawn/Save、UI/Input、Death Drop、Damageなど個別システムの深掘り | 特定機能を変更する前の調査 |
| `guides/` | 新機能追加ガイド、Codex依頼時の前提資料 | 作業依頼や実装Stepの入口 |
| `checklists/` | 実機確認マトリクス、回帰確認手順 | Godot上で確認する項目を揃える |
| `migration/` | TSV移行状況、移行完了メモ | データ移行方針や保留テーブルの確認 |
| `backlog/` | 認知的負債・整理候補 | 今後の整理Step候補 |

## まず読むもの

| 目的 | 読むdocs |
| --- | --- |
| 全体構成を知りたい | [architecture/project_structure_overview.md](architecture/project_structure_overview.md) |
| 主要スクリプトの責務を知りたい | [architecture/script_responsibility_map.md](architecture/script_responsibility_map.md) |
| 処理フローを追いたい | [architecture/runtime_flow_overview.md](architecture/runtime_flow_overview.md) |
| 機能単位の関係を知りたい | [architecture/subsystem_interaction_map.md](architecture/subsystem_interaction_map.md) |
| 新機能を追加したい | [guides/feature_addition_guide.md](guides/feature_addition_guide.md) |
| Save/Load回帰確認をしたい | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |
| Codexに作業依頼したい | [guides/codex_project_context.md](guides/codex_project_context.md) |

## Inventory系を触る時

| 目的 | 読むdocs |
| --- | --- |
| Inventory / Trade / Chest 全体を理解する | [systems/inventory_trade_chest_system_deep_dive.md](systems/inventory_trade_chest_system_deep_dive.md) |
| `InventoryUI` の mode / held item 状態遷移を確認する | [systems/inventory_ui_state_transition.md](systems/inventory_ui_state_transition.md) |
| UI lock やscene遷移との関係を見る | [systems/ui_input_scene_transition_deep_dive.md](systems/ui_input_scene_transition_deep_dive.md) |

## 戦闘・死亡を触る時

| 目的 | 読むdocs |
| --- | --- |
| `Unit.gd` のライフサイクル別入口を知る | [systems/unit_lifecycle_deep_dive.md](systems/unit_lifecycle_deep_dive.md) |
| Unit / Combat / Death の流れを知る | [systems/unit_combat_death_system_deep_dive.md](systems/unit_combat_death_system_deep_dive.md) |
| 死亡時ドロップ仕様を確認する | [systems/death_drop_spec.md](systems/death_drop_spec.md) |
| ダメージeffectの補足を見る | [systems/damage_system_notes.md](systems/damage_system_notes.md) |

## データ・TSVを触る時

| 目的 | 読むdocs |
| --- | --- |
| Data / Spawn / Save の関係を見る | [systems/data_spawn_save_system_deep_dive.md](systems/data_spawn_save_system_deep_dive.md) |
| Save / WorldState / PlayerData の保存対象を見る | [systems/save_worldstate_playerdata_map.md](systems/save_worldstate_playerdata_map.md) |
| Map scene / spawn / persistence の流れを見る | [systems/map_spawn_persistence_deep_dive.md](systems/map_spawn_persistence_deep_dive.md) |
| Save/Load実機確認チェック表を見る | [checklists/save_load_regression_matrix.md](checklists/save_load_regression_matrix.md) |
| GameDataRegistryのTSV loader / lookup対応を見る | [systems/game_data_registry_loader_map.md](systems/game_data_registry_loader_map.md) |
| TSV移行状況を見る | [migration/tsv_migration_audit.md](migration/tsv_migration_audit.md) |
| TSV移行完了方針を見る | [migration/tsv_migration_completion.md](migration/tsv_migration_completion.md) |
| 新機能追加時のデータ手順を見る | [guides/feature_addition_guide.md](guides/feature_addition_guide.md) |

## Codexに依頼する時

まず [guides/codex_project_context.md](guides/codex_project_context.md) を前提として使います。

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
