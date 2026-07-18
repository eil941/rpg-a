# Project Structure Overview

Step 11-A 時点のプロジェクト全体地図です。新機能追加や調査を始める前に、「どの領域を見ればよいか」を判断するための入口として使います。

## 全体像

| Path | 役割 | 主に触るタイミング | 注意点 |
| --- | --- | --- | --- |
| `project.godot` | Godot プロジェクト設定、メインシーン、Autoload、Input Map | Singleton 追加、入力アクション追加、起動シーン確認 | Autoload は多くの処理の入口です。変更時は影響範囲が広いです。 |
| `scenes/` | Godot scene ファイル。マップ、HUD、UI、Unit、Chest、Pickup など | 画面構成、ノード構成、マップやUIの見た目を変える時 | ロジック本体は多くの場合 `scripts/` 側にあります。 |
| `scripts/` | ゲームプレイ、UI、データ読み込み、戦闘、保存などの主要ロジック | ほぼ全ての機能変更 | `unit.gd`、`inventory_ui.gd`、`game_data_registry.gd` は特に高密度です。 |
| `data/master/` | Excel から出力された runtime 用 TSV | データ確認、validate 対象 | 原則 `master_data.xlsx` と同期させます。TSVだけを手編集する時は理由を明確にします。 |
| `master_data.xlsx` | マスターデータの正本 | item、enemy、npc、effect、shop、initial inventory などのデータ追加 | 編集後は export と validate を実行します。 |
| `tools/` | マスターデータの export / validate などの補助スクリプト | TSV出力仕様や検証ルールを変える時 | `export_master_tsv.py` と `validate_master_data.py` が基本です。 |
| `docs/` | 仕様、移行メモ、調査メモ、今回作成した地図 | 意思決定や今後の作業前提を残す時 | 既存コードを読む前の「地図」として使います。 |
| `assets/` | 画像、タイル、音、フォント等の素材 | 見た目やリソース追加 | TSVから参照されるパスを壊さないようにします。 |
| `.godot/` | Godot の内部生成物 | 通常は触らない | 原則編集対象外です。 |

## Autoload

`project.godot` に登録されている Singleton です。どこからでも名前で参照できるため、状態の置き場所として重要です。

| Autoload | Script | 主な責務 |
| --- | --- | --- |
| `GameData` | `scripts/data/game_data_registry.gd` | `data/master/*.tsv` を読み込み、各種マスターデータを提供する中心。 |
| `GlobalPlayerSpawn` | `scripts/world/GlobalPlayerSpawn.gd` | マップ遷移先のプレイヤー出現位置を一時保持。 |
| `TimeManager` | `scripts/systems/time_manager.gd` | ターン・時間進行、AIターン進行。 |
| `Targeting` | `scripts/combat/targeting.gd` | タイルやUnitの検索、攻撃対象判定補助。 |
| `DamageCalculator` | `scripts/combat/damage_calculator.gd` | 命中、クリティカル、防御、属性などのダメージ計算。 |
| `CombatManager` | `scripts/combat/combat_manager.gd` | 攻撃実行、ターゲットアイテム使用、装備攻撃効果。 |
| `PlayerData` | `scripts/data/player_data.gd` | プレイヤーの永続・マップ跨ぎ状態。inventory、装備、held item 一時状態も含む。 |
| `WorldState` | `scripts/world/world_state.gd` | マップ、Unit、Chest、Pickup、クエストなどのワールド状態。 |
| `GlobalDetailMap` | `scripts/map/global_detail_map.gd` | 詳細マップからの戻り先などのコンテキスト。 |
| `GlobalDungeon` | `scripts/dungeon/GlobalDungeon.gd` | ダンジョン階層、戻り先、フロア状態。 |
| `DebugSettings` | `scripts/debug/DebugSettings.gd` | デバッグフラグ、開始アイテム、検証用設定。 |
| `FactionManager` | `scripts/managers/FactionManager.gd` | faction 関係値の参照。 |
| `DialogueManager` | `scripts/managers/dialogue_manager.gd` | 会話状態、会話アクション、trade UI 起動。 |
| `QuestManager` | `scripts/managers/quest_manager.gd` | クエスト生成、受注、進行、完了、報酬。 |
| `QuestBoardManager` | `scripts/managers/quest_board_manager.gd` | クエストボードUIの状態管理。 |
| `SaveManager` | `scripts/save_manager.gd` | save/load/new game の統括。 |

## 主要ディレクトリ

| Path | 役割 | 変更すると影響するもの |
| --- | --- | --- |
| `scripts/combat/` | 戦闘、ダメージ、ターゲット判定 | 通常攻撃、アイテム攻撃、装備攻撃効果、死亡判定の入口。 |
| `scripts/controllers/` | Player/Enemy/NPC の行動制御 | 移動、入力、AI行動、UI中の移動ロック。 |
| `scripts/core/` | Unit、Stats、Skills などの基礎ノード | Unitの移動、装備、ステータス、死亡、保存、スキル。影響範囲が最大級です。 |
| `scripts/data/` | Resourceクラス、TSV Registry | TSV列追加、データ構造変更、読み込み互換性。 |
| `scripts/debug/` | デバッグ設定 | 検証用ログ、開始アイテム、確認フラグ。通常時の default に注意。 |
| `scripts/dungeon/` | ダンジョン生成・階層管理 | ダンジョンマップ、階段、ダンジョン内 spawn。 |
| `scripts/hud/` | GameAndHud、HUD、Status UI | UI表示、マップロード、インベントリやステータスの開閉。 |
| `scripts/item/` | Inventory、ItemDatabase、ItemEffect、Pickup、Chest | アイテム、hotbar、装備、使用効果、world drop、chest。 |
| `scripts/managers/` | Quest、Dialogue、Spawn、Faction など横断管理 | 会話、クエスト、spawn、faction 関連。 |
| `scripts/map/` | フィールド・詳細マップ生成とシーンスクリプト | マップタイル、敵/アイテム/Chest生成、遷移。 |
| `scripts/object/` | 既存では quest board などのワールドオブジェクト | 個別オブジェクトの interaction。 |
| `scripts/systems/` | 時間などシステム系 | ターン進行、AIターン呼び出し。 |
| `scripts/world/` | WorldState、マップ遷移補助 | save/load、マップ永続状態、遷移先座標。 |

## データパイプライン

| Source | Output / Consumer | 役割 |
| --- | --- | --- |
| `master_data.xlsx` | `tools/export_master_tsv.py` | マスターデータの正本。 |
| `tools/export_master_tsv.py` | `data/master/*.tsv` | Excel各シートをTSVへ出力。 |
| `data/master/*.tsv` | `GameDataRegistry` | Godot実行時に読み込まれるruntimeデータ。 |
| `tools/validate_master_data.py` | Console report | ID重複、参照欠け、範囲、非推奨列、resource path などを検証。 |

重要な設計:

- 装備効果も `item_effect_links.tsv` を使います。`equipment_effect_links.tsv` は作りません。
- `initial_inventory_*` は Unit 生成時の所持品生成です。死亡時に再抽選しません。
- 現在 `drop_tables.tsv` / `drop_table_entries.tsv` はありません。死亡時は実際に持っている inventory / hotbar / equipment を落とします。
- `sample_*` や `test_*` は残してよいですが、通常ランダム生成に混ざらないよう `spawn_weight <= 0` や `TEST_ONLY` で隔離します。

## Scenes と Scripts の関係

| Scene | Script | 役割 |
| --- | --- | --- |
| `scenes/game_and_hud.tscn` | `scripts/hud/game_and_hud.gd` | ゲーム画面の親。現在マップ、HUD、各UIの管理。 |
| `scenes/Main.tscn` | `scripts/map/map_scene_scripts/main.gd` | 詳細マップ。動的な enemy / npc / item / chest 生成。 |
| `scenes/FiledMap.tscn` 付近 | `scripts/map/map_scene_scripts/FiledMap.gd` | フィールドマップ。ファイル名は `FiledMap.gd`。 |
| dungeon scene | `scripts/dungeon/dungeon_main.gd` | ダンジョン階層生成、敵・アイテム・Chest生成。 |
| Inventory UI scene | `scripts/item/inventory_ui.gd` | 通常インベントリ、trade、chest、held item、tooltip。 |
| Unit scene | `scripts/core/unit.gd` | Player/Enemy/NPC共通のUnit本体。 |
| Chest scene | `scripts/item/chest/chest.gd` | ChestのinventoryとUI起動。 |
| Pickup scene | `scripts/item/item_pickup.gd` | world上の落ちているアイテム。 |

## 既存 docs の役割

| Doc | 役割 |
| --- | --- |
| [../systems/combat/death_drop_spec.md](../systems/combat/death_drop_spec.md) | 死亡時ドロップの正式仕様。 |
| [../migration/tsv_migration_audit.md](../migration/tsv_migration_audit.md) | TSV化状況、未移行・保留方針。 |
| [../migration/tsv_migration_completion.md](../migration/tsv_migration_completion.md) | TSV移行の完了判断と過去Stepの記録。 |
| [../systems/combat/damage_system_notes.md](../systems/combat/damage_system_notes.md) | ダメージシステムと effect の補足。 |
| [project_structure_overview.md](project_structure_overview.md) | このファイル。全体構成地図。 |
| [script_responsibility_map.md](script_responsibility_map.md) | 主要スクリプトの責務表。 |
| [runtime_flow_overview.md](runtime_flow_overview.md) | 実行時の主要処理フロー。 |
| [../guides/feature_addition_guide.md](../guides/feature_addition_guide.md) | 新機能追加時の入口。 |
| [../guides/codex_project_context.md](../guides/codex_project_context.md) | Codex依頼時の前提資料。 |

## 変更リスクの目安

| 領域 | リスク | 理由 |
| --- | --- | --- |
| `scripts/core/unit.gd` | 高 | Unitの移動、装備、死亡、保存、初期所持品、効果が集まっています。 |
| `scripts/item/inventory_ui.gd` | 高 | 通常inventory、trade、chest、held item、scene跨ぎ状態をまとめて持ちます。 |
| `scripts/data/game_data_registry.gd` | 高 | 全TSV読み込みの中心。列追加時は validator も合わせて確認します。 |
| `scripts/combat/combat_manager.gd` | 中〜高 | 通常攻撃、装備攻撃効果、死亡タイミングに影響します。 |
| `scripts/item/item_effect_manager.gd` | 中〜高 | 消耗品・状態異常・回復などeffect実行に影響します。 |
| `scripts/managers/unit_spawn_manager.gd` | 中 | enemy/npc生成、initial inventory、shop inventory の境界に注意。 |
| `data/master/*.tsv` | 中 | runtimeデータ。Excel正本との同期が必要です。 |
| `docs/` | 低 | 理解補助。ただし仕様docsは実装判断に影響します。 |
