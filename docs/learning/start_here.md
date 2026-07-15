# Start Here

## このページで理解すること
このページは、`rpg-a` の学習用 docs の最初の入口です。
詳細な実装解説ではなく、まず次をつかむための地図です。

- Excel と TSV が、ゲーム内処理へどう渡るか
- 最初に覚える主要スクリプトの役割
- 混同しやすいスクリプト同士の違い
- 次に読む learning docs の選び方
- 詳細 docs を最初から全部読まなくてよいこと

## 最初に全体像
最初は、厳密な全処理経路ではなく、大まかな流れとして見てください。
```text
master_data.xlsx
↓
Python
↓
TSV
↓
GameDataRegistry
↓
Database
↓
Inventory / Manager
↓
Unit / Stats / ゲーム内処理
```

この図で覚えるポイントは、`master_data.xlsx` と TSV はデータの入口であり、ゲーム実行中の処理は GDScript 側の各スクリプトが分担している、ということです。

たとえば、HP 回復アイテムは「TSV に行があるだけ」では完結しません。実行時には、所持品、使用可否、効果実行、HP 変更という複数の担当を通ります。

## 最初に覚える主要な役割

### `scripts/data/game_data_registry.gd`
- 一言での役割: TSV を読み込んで、ゲーム内データとして保持する入口。
- 主にやること: `items.tsv`、`equipment.tsv`、`item_effects.tsv`、`item_effect_links.tsv` などを読み、登録する。
- 主にやらないこと: アイテムを使う、HP を回復する、攻撃を実行する。
- 間違えやすい相手: `ItemDatabase`
- 詳しく学ぶ予定の learning docs: `learning/excel_to_game_flow.md`、`learning/database_and_manager_roles.md`（今後作成）

### `scripts/item/item_database.gd`
- 一言での役割: 登録済みのアイテムデータを検索・取得する窓口。
- 主にやること: item_id から item data、表示名、装備データ、使用可否、効果説明などを返す。
- 主にやらないこと: TSV の正本になる、アイテム効果を実行する、所持数を減らす。
- 間違えやすい相手: `GameDataRegistry`、`ItemEffectManager`
- 詳しく学ぶ予定の learning docs: `learning/database_and_manager_roles.md`（今後作成）

### `scripts/item/inventory.gd`
- 一言での役割: Unit が持っているアイテムと個数を管理する。
- 主にやること: bag、hotbar、stack、追加、削除、使用時の消費を扱う。
- 主にやらないこと: 効果内容そのものを実行する、攻撃を管理する、HP の値を直接設計する。
- 間違えやすい相手: `ItemEffectManager`、`InventoryUI`
- 詳しく学ぶ予定の learning docs: `learning/item_use_flow.md`（今後作成）

### `scripts/item/item_effect_manager.gd`
- 一言での役割: アイテムに設定された効果を実行する。
- 主にやること: 回復、状態異常、ダメージ、buff / debuff など、`ItemEffectData` の effect を適用する。
- 主にやらないこと: 所持品の枠や個数を管理する、通常攻撃の入口になる、装備パッシブの stat 合計を中心的に計算する。
- 間違えやすい相手: `Inventory`、`CombatManager`
- 詳しく学ぶ予定の learning docs: `learning/item_use_flow.md`、`learning/target_item_use_flow.md`（今後作成）

### `scripts/combat/combat_manager.gd`
- 一言での役割: 攻撃や対象指定行動など、戦闘行動の入口を管理する。
- 主にやること: 通常攻撃、対象指定アイテム、命中判定、装備攻撃効果の実行入口を扱う。
- 主にやらないこと: TSV を読み込む、所持品一覧を保持する、基礎 HP などの stat 本体を保持する。
- 間違えやすい相手: `ItemEffectManager`、`Unit`
- 詳しく学ぶ予定の learning docs: `learning/equipment_attack_effect_flow.md`、`learning/combat_damage_death_flow.md`（今後作成）

### `scripts/core/unit.gd`
- 一言での役割: キャラクター全体を管理する本体。
- 主にやること: 移動、装備、inventory、stats、死亡処理、drop、save/load 用データなどをつなぐ。
- 主にやらないこと: TSV の読み込み正本になる、HP などの数値だけを単独で持つ、攻撃計算だけに専念する。
- 間違えやすい相手: `Stats`、`CombatManager`
- 詳しく学ぶ予定の learning docs: `learning/equipment_passive_flow.md`、`learning/combat_damage_death_flow.md`、`learning/death_drop_flow.md`（今後作成）

### `scripts/core/stats.gd`
- 一言での役割: HP、攻撃力、防御力などの数値と、その変更を管理する。
- 主にやること: damage、heal、death trigger、基礎 stat、保存用 stat data を扱う。
- 主にやらないこと: Unit 全体の装備や所持品を管理する、TSV を読む、map 上の drop を作る。
- 間違えやすい相手: `Unit`
- 詳しく学ぶ予定の learning docs: `learning/combat_damage_death_flow.md`（今後作成）

## 特に混同しやすい違い
### GameDataRegistry と ItemDatabase
- `GameDataRegistry`: TSV を読み込んで保持・提供する側。
- `ItemDatabase`: 登録済みの item data を item_id などで取得する側。

`ItemDatabase` は正本ではありません。正本は `master_data.xlsx`、実行時入力は TSV、実行中に読み込んで保持する中心が `GameDataRegistry` です。

### Inventory と ItemEffectManager
- `Inventory`: 何を何個持っているか、使えるか、使ったら消費するかを扱う。
- `ItemEffectManager`: そのアイテムに設定された効果を実際に適用する。

HP 回復アイテムで言うと、`Inventory` は「そのアイテムを使う入口と消費」を担当し、`ItemEffectManager` は「HP を回復する効果の実行」を担当します。

### ItemEffectManager と CombatManager
- `ItemEffectManager`: アイテム効果を適用する。
- `CombatManager`: 攻撃、対象指定アイテム、装備攻撃効果など、戦闘行動の入口を管理する。

装備攻撃効果は、中心を `CombatManager` として見ると追いやすいです。`ItemEffectManager` は一部効果の実行で使われますが、攻撃そのものの入口ではありません。

### Unit と Stats
- `Unit`: キャラクター全体。inventory、equipment、stats、移動、死亡、drop などをつなぐ。
- `Stats`: HP、攻撃力、防御力などの数値と、その変更。

`Stats` は数値担当、`Unit` はキャラクター全体のまとめ役です。死亡処理や drop は `Unit` 側まで見ないと全体を追えません。

## 目的別に次に読むもの
以下は今後作成する予定の learning docs です。未作成のため、ここでは Markdown リンクにしていません。
```text
Excelの内容がゲームへ入る流れ
-> learning/excel_to_game_flow.md（今後作成）

DatabaseとManagerの違い
-> learning/database_and_manager_roles.md（今後作成）

ポーションなど通常アイテム使用
-> learning/item_use_flow.md（今後作成）

装備パッシブ
-> learning/equipment_passive_flow.md（今後作成）

装備攻撃効果
-> learning/equipment_attack_effect_flow.md（今後作成）

攻撃・ダメージ・死亡
-> learning/combat_damage_death_flow.md（今後作成）

死亡時ドロップ
-> learning/death_drop_flow.md（今後作成）

不具合の調べ方
-> learning/debug_first_steps.md（今後作成）
```

## 既存の詳細 docs との違い
`learning/` は、所有者が理解を深めるための入口です。既存の詳細 docs を置き換えるものではありません。

- `learning/`: まず理解するための短い入口。
- `architecture/`: 全体構造の詳細地図。
- `systems/`: 現行仕様と実装経路の詳細。
- `guides/`: 実際の作業手順。
- `checklists/`: 動作確認。
- `backlog/`: 将来の整理候補。

詳細が必要になったら、[../architecture/project_structure_overview.md](../architecture/project_structure_overview.md)、[../architecture/script_responsibility_map.md](../architecture/script_responsibility_map.md)、[../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)、[../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md) などへ進みます。

最初から詳細 docs を全部読む必要はありません。まず learning docs で「どの役割がどこにあるか」をつかんでから、必要な詳細だけを見に行く方が楽です。

## 学習時の読み方
おすすめの読み方は次の順番です。
```text
1. learning docsで全体像を読む
2. 対象スクリプトと関数を確認する
3. 必要ならPCで実コードを開く
4. 詳細が必要ならsystemsまたはarchitectureへ進む
5. 最後に自分の言葉で処理を説明する
```

分からない時は、いきなり長い docs を全部読むより、「今知りたい処理の入口はどのスクリプトか」を先に探してください。

## 理解度チェック
1. `GameDataRegistry` と `ItemDatabase` の違いは何ですか。
2. `Inventory` と `ItemEffectManager` の違いは何ですか。
3. `ItemEffectManager` と `CombatManager` の違いは何ですか。
4. `Unit` と `Stats` の違いは何ですか。
5. HP 回復アイテムの処理を知りたい場合、次に読む予定の learning docs はどれですか。

---
## 回答例
1. `GameDataRegistry` は TSV を読み込んで保持する側です。`ItemDatabase` は登録済みの item data を検索・取得する側です。
2. `Inventory` は所持品、個数、使用入口、消費を扱います。`ItemEffectManager` はアイテム効果を実行します。
3. `ItemEffectManager` は effect を適用します。`CombatManager` は攻撃や対象指定行動など、戦闘行動の入口を管理します。
4. `Unit` はキャラクター全体を管理します。`Stats` は HP などの数値と、その変更を管理します。
5. `learning/item_use_flow.md` です。まだ未作成なら、作成後に読む予定の docs として扱います。
