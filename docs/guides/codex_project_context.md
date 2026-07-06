# Codex Project Context

今後Codexに `rpg-a` の作業を依頼する時の前提資料です。依頼文に全てを書く代わりに、このdocsを参照できるようにするためのまとめです。

## プロジェクト概要

`rpg-a` は Godot 4.6.1 の2D RPGプロトタイプです。主な要素は以下です。

- tile-basedなプレイヤー移動
- field / detail / dungeon map
- TSVマスターデータから読み込む enemies / npcs / items / quests
- inventory、hotbar、equipment、trade、chest UI
- TSV-backed item effects / equipment effects
- combat、status effects、death handling
- Unitが実際に持っている inventory / hotbar / equipment を落とす死亡時ドロップ
- dialogue、quest、shop、quest board
- Autoload snapshotによるsave/load

## データ管理方針

| Source | 意味 |
| --- | --- |
| `master_data.xlsx` | マスターデータの正本。 |
| `data/master/*.tsv` | Excelから出力されたruntime用データ。 |
| `tools/export_master_tsv.py` | Excel sheetsをTSVへ出力する。 |
| `tools/validate_master_data.py` | ID重複、参照欠け、範囲、非推奨列、resource path等を検証する。 |

TSVデータ変更時の基本手順:

```powershell
py tools\export_master_tsv.py
py tools\validate_master_data.py
git diff --check
```

`py` がない環境では、利用可能なPythonまたは同梱Pythonを使い、報告に明記します。

## 主要な設計決定

| 項目 | 現在の方針 |
| --- | --- |
| 装備効果 | 装備も `item_effect_links.tsv` を使う。`equipment_effect_links.tsv` は追加しない。 |
| 装備中パッシブ | `apply_modifier` effectを装備中item linkから読み、Unitのstat合計に反映。 |
| 装備攻撃効果 | `deal_damage`、`apply_status`、`restore_resource` を `CombatManager._apply_equipment_attack_effects()` で処理。 |
| 発動率 | `item_effects.trigger_chance`。空欄/列なしは `1.0`。 |
| 死亡時ドロップ | Unitが実際に持っている bag / hotbar / equipment を設定に応じて落とす。死亡時専用抽選はしない。 |
| drop tables | drop-only reward が必要になるまで `drop_tables.tsv` / `drop_table_entries.tsv` は追加しない。 |
| initial inventory | `initial_inventory_table_id` + `initial_inventory_tables.tsv` + `initial_inventory_entries.tsv` は spawn時の所持品生成。死亡時lootではない。 |
| 旧initial inventory | `initial_inventory_items` は deprecated fallback。新規データでは使わない。 |
| Skills | active APIは `Skills` node。`Unit.add_skill_exp()` や active `skill_state` API は復活させない。 |
| Status UI skills | スキル表示は一本化済み。`[TSV Skill State]` を復活させない。 |

## Codexが作業前に確認すべきファイル

| 作業領域 | まず見るもの |
| --- | --- |
| Master data | `master_data.xlsx`, 関連 `data/master/*.tsv`, `tools/export_master_tsv.py`, `tools/validate_master_data.py` |
| TSV読み込み | `scripts/data/game_data_registry.gd`, 対応する data Resource class |
| Item/equipment | `scripts/data/item_data.gd`, `equipment_data.gd`, `item_effect_data.gd`, `scripts/item/item_database.gd` |
| Inventory UI | `scripts/item/inventory_ui.gd`, `scripts/item/inventory.gd`, `scripts/hud/game_and_hud.gd` |
| Combat | `scripts/combat/combat_manager.gd`, `damage_calculator.gd`, `scripts/core/stats.gd` |
| Unit挙動 | `scripts/core/unit.gd`, 関連controller |
| Spawn | `scripts/managers/unit_spawn_manager.gd`, map scene script, `enemies.tsv` / `npcs.tsv` |
| Death drop | [../systems/death_drop_spec.md](../systems/death_drop_spec.md), `Unit.drop_inventory_items_on_death_if_needed()`, `ItemDropHelper` |
| Save/load | `scripts/save_manager.gd`, `PlayerData`, `WorldState`, `Unit.get_stats_data()` |
| Dialogue/quest | `DialogueManager`, `QuestManager`, `quest_board_ui.gd`, quest系TSV |

## 主要な禁止事項

- 指示なしに大規模リファクタをしない。
- code-only taskで `master_data.xlsx` や `data/master/*.tsv` を変更しない。
- TSVだけを編集してExcel正本と乖離させない。
- 既存テーブルで表現できる設計に、新しいTSVテーブルを急に追加しない。
- 明示依頼なしに `skills`、`status_ui`、`skill_state` 周りを触らない。
- working tree上のユーザー変更を勝手に戻さない。
- initial inventory作業中にdeath drop semanticsを変えない。
- death drop作業中にinitial inventory semanticsを変えない。
- DebugSettingsを通常ONにしない。ただし確認Stepで明示された一時ONは除く。

## Codexが作業後に報告すべき内容

実装作業:

1. 変更ファイル一覧
2. 変更した挙動
3. 意図的に維持した挙動
4. データ変更の有無
5. データ変更時の export結果
6. validate結果
7. `git diff --check` 結果
8. Godot実行確認の有無
9. 未確認項目

調査作業:

1. 調査したファイル
2. 現在の挙動と呼び出し経路
3. 関連TSV列やデータ形
4. リスク・不明点
5. 次Stepの最小案
6. ファイル変更の有無

## よくある作業手順

### TSVデータを追加する

1. 既存TSVの列と近い行を確認します。
2. `master_data.xlsx` を編集します。
3. `tools/export_master_tsv.py` を実行します。
4. `tools/validate_master_data.py` を実行します。
5. Godotで読み込みログや実挙動を確認します。

### 既存データにruntime挙動を足す

1. 既存TSV/data classに必要なfieldがあるか確認します。
2. 既存dispatcherやhandlerを探します。
3. 小さいhelperまたはmatch branchを追加します。
4. 空欄/default挙動の互換性を保ちます。
5. validateとGodot確認を行います。

### Debug確認機能を追加する

1. `DebugSettings` に default OFF のflagを追加します。
2. 対象をplayer限定・特定system限定などに絞ります。
3. 通常プレイを変えないようにします。
4. 一時ログはflag配下に置くか、Step完了時に削除します。

### Inventory / Trade / Chest を変える

1. `InventoryUI` の `ui_mode` と held item 処理を読みます。
2. source area が `inventory` / `hotbar` / `equipment` / `trade` / `chest` のどれか確認します。
3. item entry と `instance_data` を消さないようにします。
4. 通常inventory、trade、chest、scene跨ぎheld item、free済み参照を確認します。

### Death Drop を変える

1. [../systems/death_drop_spec.md](../systems/death_drop_spec.md) を読みます。
2. `drop_inventory_on_death` と `drop_equipped_items_on_death` の組み合わせを確認します。
3. drop対象は実際に持っているentryであることを守ります。
4. source slot clearはdrop成功後に行います。
5. bag、hotbar、equipped、stack、enchanted equipmentを確認します。

## 今後まず参照するdocs

- [../architecture/project_structure_overview.md](../architecture/project_structure_overview.md): 全体構成。
- [../architecture/script_responsibility_map.md](../architecture/script_responsibility_map.md): scriptごとの責務。
- [../architecture/runtime_flow_overview.md](../architecture/runtime_flow_overview.md): 主要処理フロー。
- [feature_addition_guide.md](feature_addition_guide.md): 新機能追加時の入口。
- [../systems/death_drop_spec.md](../systems/death_drop_spec.md): 死亡時ドロップ仕様。
- [../migration/tsv_migration_audit.md](../migration/tsv_migration_audit.md): TSV化状況と保留テーブル。
