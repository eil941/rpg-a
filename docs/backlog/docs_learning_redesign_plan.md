# Docs Learning Redesign Plan

## 目的

この文書は、`codex` ブランチの現在の `docs/` と主要な GDScript 実装を調査し、プロジェクト所有者が段階的に理解を深めるためのドキュメント再設計案をまとめたものです。

今回は既存 docs、GDScript、scene、Excel、TSV、Python、project settings、tests、assets は変更しません。実施したのは調査と計画作成のみです。

前提として、現在の理解度は「Excel から TSV を出力して、既存効果を使った単純なアイテム追加はある程度できる。一方で、`GameDataRegistry`、`ItemDatabase`、`Inventory`、`ItemEffectManager`、`CombatManager`、`Unit`、`Stats` の責務分担と呼び出し経路はまだ追いにくい」状態と見なします。

## 調査対象

### 調査した主な docs

- [../README.md](../README.md)
- [../guides/current_system_reading_order.md](../guides/current_system_reading_order.md)
- [../architecture/project_structure_overview.md](../architecture/project_structure_overview.md)
- [../architecture/script_responsibility_map.md](../architecture/script_responsibility_map.md)
- [../architecture/runtime_flow_overview.md](../architecture/runtime_flow_overview.md)
- [../architecture/subsystem_interaction_map.md](../architecture/subsystem_interaction_map.md)
- [../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)
- [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)
- [../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md)
- [../systems/unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md)
- [../systems/death_path_diagram.md](../systems/death_path_diagram.md)
- [../systems/death_drop_spec.md](../systems/death_drop_spec.md)
- [../guides/feature_addition_guide.md](../guides/feature_addition_guide.md)
- [../guides/item_addition_guide.md](../guides/item_addition_guide.md)
- その他、`docs/systems/`、`docs/guides/`、`docs/backlog/`、`docs/migration/`、`docs/checklists/` 配下の関連 docs

存在確認時点で、依頼に挙がっていた `docs/guides/item_addition_guide.md` は存在します。加えて、`docs/backlog/debug_output_normalization_audit.md` と `docs/backlog/gamedata_registry_debug_dump_audit.md` も存在します。

### 調査した主な scripts

- `scripts/data/game_data_registry.gd`
- `scripts/item/item_database.gd`
- `scripts/item/inventory.gd`
- `scripts/item/inventory_ui.gd`
- `scripts/item/item_effect_manager.gd`
- `scripts/item/unit_effect_runtime.gd`
- `scripts/combat/combat_manager.gd`
- `scripts/combat/damage_calculator.gd`
- `scripts/core/unit.gd`
- `scripts/core/stats.gd`
- `scripts/managers/unit_spawn_manager.gd`
- `scripts/item/item_drop_helper.gd`
- `scripts/item/item_world_manager.gd`

パス名はおおむね依頼内容と一致していました。

## 1. 現在の docs 構成

### フォルダ構成

現在の `docs/` は、概ね次の役割で整理されています。

```text
docs/
|-- README.md
|-- architecture/
|-- systems/
|-- guides/
|-- checklists/
|-- migration/
`-- backlog/
```

### 主要 docs の役割分類

#### 初心者向け入口に近いもの

- [../README.md](../README.md)
  - docs 全体の入口です。
  - 目的別リンクはありますが、所有者の現在の理解度に合わせた「最初にこれだけ読む」導線としてはまだ情報量が多めです。
- [../guides/current_system_reading_order.md](../guides/current_system_reading_order.md)
  - 領域別の読む順番を示します。
  - ただし、最初に読む docs が 3 から 5 件あり、すでに実装構造をある程度知っている人向けの導線になっています。
- [../guides/item_addition_guide.md](../guides/item_addition_guide.md)
  - Excel からアイテムを追加する作業入口です。
  - 所有者が比較的理解できている領域に近いですが、465 行程度あり、初回学習用としては長いです。

#### 実装者向け参照資料

- [../architecture/project_structure_overview.md](../architecture/project_structure_overview.md)
- [../architecture/script_responsibility_map.md](../architecture/script_responsibility_map.md)
- [../architecture/runtime_flow_overview.md](../architecture/runtime_flow_overview.md)
- [../architecture/subsystem_interaction_map.md](../architecture/subsystem_interaction_map.md)
- [../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)
- [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)
- [../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md)
- [../systems/death_path_diagram.md](../systems/death_path_diagram.md)

これらは正確性と情報量が高く、実装前の調査資料として価値があります。一方で、最初に読む教材としては専門用語、関数名、境界条件が多く、認知負荷が高いです。

#### 作業ガイド

- [../guides/feature_addition_guide.md](../guides/feature_addition_guide.md)
- [../guides/item_addition_guide.md](../guides/item_addition_guide.md)
- [../checklists/save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md)

作業時に参照する価値は高いです。ただし、「なぜこのファイルを見るのか」「この関数の次に何が呼ばれるのか」を学習者向けに短く橋渡しする前段が不足しています。

#### 仕様・参照資料

- [../systems/death_drop_spec.md](../systems/death_drop_spec.md)
- [../systems/damage_system_notes.md](../systems/damage_system_notes.md)
- [../systems/debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md)
- [../migration/tsv_migration_audit.md](../migration/tsv_migration_audit.md)
- [../migration/tsv_migration_completion.md](../migration/tsv_migration_completion.md)

現行仕様の確認には有用です。学習用 docs から「詳細確認先」としてリンクするのが適しています。

#### 移行・backlog

- [cognitive_debt_backlog.md](cognitive_debt_backlog.md)
- [debug_output_normalization_audit.md](debug_output_normalization_audit.md)
- [gamedata_registry_debug_dump_audit.md](gamedata_registry_debug_dump_audit.md)

将来整理の候補を扱う資料です。学習者が最初に読むよりも、問題意識が出てから見る位置づけがよいです。

## 2. 現在の良い点

- 現行仕様の記録が厚く、実装者や Codex が調査する時の参照資料として価値が高いです。
- `README.md` と `current_system_reading_order.md` により、目的別に docs を探す入口はすでにあります。
- `GameDataRegistry`、item effect、Unit lifecycle、death path、DebugSettings など、壊しやすい境界が個別に文書化されています。
- `master_data.xlsx -> tools/export_master_tsv.py -> data/master/*.tsv -> GameDataRegistry` というデータ経路が docs と実装の両方で確認できます。
- `equipment_effect_links.tsv` を作らず、消耗品も装備効果も `item_effect_links.tsv` を使う方針が複数 docs に明記されています。
- DebugSettings の現在値とリスクが文書化されており、確認用設定を通常挙動と混ぜない配慮があります。
- Codex へ依頼する時に読む資料として [../guides/codex_project_context.md](../guides/codex_project_context.md) があり、作業前提を共有しやすいです。

## 3. 現在の問題点

### 現在の理解度との不一致

所有者は Excel、TSV、既存効果の利用は比較的追えています。一方で、docs はすでに実装者向けの詳細資料が中心です。現在必要なのは「詳細を減らす」ことではなく、「詳細へ入る前に、何をどの順で理解すればよいか」を示す学習用の前段です。

### 初学者が読む順番

`README.md` と `current_system_reading_order.md` は便利ですが、最初の分岐が多く、「今の自分はどれを読めばよいか」を判断する負荷があります。

たとえば、アイテム効果を理解したい場合、`item_addition_guide.md`、`equipment_item_effect_execution_path.md`、`game_data_registry_loader_map.md`、`unit_combat_death_system_deep_dive.md` が候補になります。どれも正しい一方で、初学者には入り口が多すぎます。

### docs 間の重複

同じ境界が複数 docs に出ています。

- `items.tsv`、`equipment.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- `GameDataRegistry` と `ItemDatabase`
- `ItemEffectManager` と `CombatManager`
- `Unit` と `Stats`
- death drop と initial inventory
- DebugSettings と通常実行

重複そのものは悪くありません。ただし、学習者向け docs では「ここでは概要だけ」「詳細はここ」と明示しないと、どれが主資料か分かりにくくなります。

### コードへのつながり

既存 docs にはファイル名は多く書かれていますが、学習者向けには次の粒度が足りない箇所があります。

```text
説明している処理
-> 対象スクリプト
-> 対象関数
-> 重要な実コードの見どころ
-> 次に呼ばれる関数
-> 関連TSV・Excelシート
-> 詳細を確認する既存docs
```

特に `Inventory.use_item_at()` から `ItemEffectManager.apply_item_effect()`、`apply_item_effects()`、`apply_single_effect()` を経て `Stats` や `Unit` へ届く経路は、関数単位で追う教材があると理解しやすくなります。

### 長すぎる文書

`item_addition_guide.md`、`death_path_diagram.md`、`save_worldstate_playerdata_map.md`、`equipment_item_effect_execution_path.md`、`game_data_registry_loader_map.md` は価値が高い一方、最初に読むには長いです。学習用 docs では、既存 docs を置き換えず、短い章から深掘りへ進める構造が必要です。

### デバッグ導線

DebugSettings の docs は整っていますが、所有者が「HP が回復しない」「装備しても攻撃力が上がらない」「Excel に追加したのにゲームに出ない」と感じた時に、どの順番でファイル・関数・TSV を見るかの導線が不足しています。

### スマートフォン閲覧

Markdown 表の利用自体は問題ありません。ただし、1 つの表に情報を詰め込みすぎると横スクロール前提になり、スマートフォンでは読みにくくなります。学習用 docs では、表は短くし、重要な処理経路は箇条書きまたは短いコード引用で示す方がよいです。

## 4. 再設計の基本方針

### 既存詳細 docs は残す

現行 docs は実装者向け参照資料として価値が高いため、削除や大幅簡略化は避けます。特に `systems/` と `architecture/` の深掘り資料は、学習用 docs からリンクする詳細資料として残します。

### 学習用 docs を前段に追加する

新しい `docs/learning/` を作り、所有者の現在の理解度で読める短い入口を追加する方針を推奨します。

学習用 docs は、詳細仕様を網羅する文書ではなく、「今から読むコードの地図」として作ります。

### README は入口を整理する

`README.md` は全体入口として残しつつ、将来的には次の導線を最上部に置くとよいです。

```text
初めて読む
-> docs/learning/start_here.md

作業したい
-> docs/guides/

実装を調べたい
-> docs/systems/ と docs/architecture/

将来整理候補を見る
-> docs/backlog/
```

### current_system_reading_order は中級者向けに寄せる

`current_system_reading_order.md` は有用ですが、学習初回の入口としてはやや重いです。将来的には「現行詳細 docs の読む順番」として残し、初心者向け導線は `learning/start_here.md` に移すのがよいです。

### 詳細 docs と学習 docs の違いを明確にする

- `learning/`: 15 分から 30 分で読める理解用。関数名と最小コード引用を使う。
- `guides/`: 作業手順。Excel 編集、実装追加、確認手順。
- `systems/`: 現行仕様の詳細。壊しやすい境界と実装の全体像。
- `architecture/`: プロジェクト全体の地図。
- `checklists/`: 動作確認。
- `migration/`: 過去の移行経緯。
- `backlog/`: 将来の整理候補。

### コード引用のルール

学習用 docs では、長いコード全文の転載を避けます。引用は 5 から 10 行程度にし、次を優先します。

- guard 条件
- 状態変更
- 次の関数呼び出し
- return 値
- 分岐の入口

各引用の前に `scripts/item/inventory.gd :: use_item_at()` のようにファイルと関数を明記し、引用の後に「ここで何をしているか」を日本語で説明します。

コードは変わるため、学習用 docs には「この引用が古くなるリスク」を明記し、引用を補助情報にします。主情報はファイル名、関数名、処理経路です。

## 5. 推奨フォルダ構成

再設計後の推奨構成です。

```text
docs/
|-- README.md
|-- learning/
|   |-- start_here.md
|   |-- excel_to_game_flow.md
|   |-- database_and_manager_roles.md
|   |-- item_use_flow.md
|   |-- target_item_use_flow.md
|   |-- equipment_passive_flow.md
|   |-- equipment_attack_effect_flow.md
|   |-- combat_damage_death_flow.md
|   |-- death_drop_flow.md
|   |-- debug_first_steps.md
|   `-- adding_new_data_or_effect_type.md
|-- architecture/
|-- systems/
|-- guides/
|-- checklists/
|-- migration/
`-- backlog/
```

`learning/` は詳細 docs の代替ではありません。学習者が「今の理解で読める入口」として使い、各章の最後で既存 docs へ進む構成にします。

## 6. 学習用 docs の候補

優先度は、現在の理解度と実装変更時の事故リスクから決めています。

### P0: `learning/start_here.md`

- 対象読者: プロジェクト所有者
- 目的: 最初に読む入口を 1 つにする
- 読み終わった後に説明できること: Excel、TSV、Registry、Database、Inventory、EffectManager、Unit、Stats、CombatManager が大まかに何を担当するか
- 対象スクリプト: なし。全体地図のみ
- 対象関数: なし
- 関連 TSV: `items.tsv`、`equipment.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: `items`、`equipment`、`item_effects`、`item_effect_links`
- 元にする既存 docs: [../README.md](../README.md)、[../architecture/project_structure_overview.md](../architecture/project_structure_overview.md)、[../guides/current_system_reading_order.md](../guides/current_system_reading_order.md)

### P0: `learning/excel_to_game_flow.md`

- 対象読者: Excel と TSV は理解できるが、ゲーム実行時の読み込みが曖昧な人
- 目的: `master_data.xlsx` がゲーム内データになるまでを短く追う
- 読み終わった後に説明できること: Excel は正本、TSV は出力結果、実行時は `GameDataRegistry` が読むこと
- 対象スクリプト: `tools/export_master_tsv.py`、`tools/validate_master_data.py`、`scripts/data/game_data_registry.gd`
- 対象関数: `load_all()`、`_load_items()`、`_load_equipment()`、`_load_item_effects()`、`_apply_item_effect_links()`
- 関連 TSV: `data/master/items.tsv`、`data/master/equipment.tsv`、`data/master/item_effects.tsv`、`data/master/item_effect_links.tsv`
- 関連 Excel シート: `items`、`equipment`、`item_effects`、`item_effect_links`
- 元にする既存 docs: [../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)、[../guides/item_addition_guide.md](../guides/item_addition_guide.md)

### P0: `learning/database_and_manager_roles.md`

- 対象読者: `GameDataRegistry`、`ItemDatabase`、`ItemEffectManager` の違いで迷う人
- 目的: Database と Manager の責務を混同しない
- 読み終わった後に説明できること: `GameDataRegistry` は読む、`ItemDatabase` は引く、`Inventory` は持つ、`ItemEffectManager` は効果を実行する
- 対象スクリプト: `scripts/data/game_data_registry.gd`、`scripts/item/item_database.gd`、`scripts/item/inventory.gd`、`scripts/item/item_effect_manager.gd`
- 対象関数: `GameDataRegistry.load_all()`、`ItemDatabase.get_item_data()`、`ItemDatabase.is_usable()`、`Inventory.use_item_at()`、`ItemEffectManager.apply_item_effect()`
- 関連 TSV: `items.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: `items`、`item_effects`、`item_effect_links`
- 元にする既存 docs: [../architecture/script_responsibility_map.md](../architecture/script_responsibility_map.md)、[../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)

### P0: `learning/item_use_flow.md`

- 対象読者: ポーションなど通常アイテム使用の処理を追いたい人
- 目的: inventory から使用した時の関数経路を関数単位で追う
- 読み終わった後に説明できること: `Inventory` が消費可否と個数を扱い、効果実行は `ItemEffectManager` が行うこと
- 対象スクリプト: `scripts/item/inventory.gd`、`scripts/item/item_database.gd`、`scripts/item/item_effect_manager.gd`、`scripts/core/stats.gd`
- 対象関数: `use_item_at()`、`use_hotbar_item_at()`、`ItemDatabase.is_usable()`、`apply_item_effect()`、`apply_item_effects()`、`apply_single_effect()`、`_apply_restore_resource()`、`Stats.heal()`
- 関連 TSV: `items.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: `items`、`item_effects`、`item_effect_links`
- 元にする既存 docs: [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)、[../guides/item_addition_guide.md](../guides/item_addition_guide.md)

### P1: `learning/target_item_use_flow.md`

- 対象読者: 対象指定アイテムの処理を追いたい人
- 目的: 自分に使うアイテムと対象 Unit に使うアイテムの違いを理解する
- 読み終わった後に説明できること: `user` と `target` が分かれ、命中判定や距離判定は `CombatManager` 側にあること
- 対象スクリプト: `scripts/combat/combat_manager.gd`、`scripts/item/item_effect_manager.gd`、`scripts/item/inventory.gd`
- 対象関数: `can_use_selected_target_item()`、`perform_selected_target_item_use()`、`_roll_target_item_hit()`、`Inventory.consume_selected_hotbar_item_for_target_action()`、`ItemEffectManager.apply_item_effect()`
- 関連 TSV: `items.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: `items`、`item_effects`、`item_effect_links`
- 元にする既存 docs: [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)、[../systems/unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md)

### P1: `learning/equipment_passive_flow.md`

- 対象読者: 装備しているだけで上がる能力値を理解したい人
- 目的: 装備パッシブは item 使用ではなく Unit の stat 計算で効くことを理解する
- 読み終わった後に説明できること: `apply_modifier` は装備パッシブでは `Unit` の合計 stat 計算に入ること
- 対象スクリプト: `scripts/core/unit.gd`、`scripts/item/item_database.gd`、`scripts/data/equipment_data.gd`
- 対象関数: `get_equipped_item_effects()`、`_get_total_equipment_effect_modifier()`、`_apply_equipment_effect_modifier()`、`get_total_attack()`、`get_total_defense()`、`get_total_max_hp()`、`get_total_speed()`
- 関連 TSV: `equipment.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: `equipment`、`item_effects`、`item_effect_links`
- 元にする既存 docs: [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)、[../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md)

### P1: `learning/equipment_attack_effect_flow.md`

- 対象読者: 攻撃時に状態異常や追加ダメージが出る装備を理解したい人
- 目的: 装備攻撃効果は通常攻撃後に `CombatManager` が処理することを理解する
- 読み終わった後に説明できること: `deal_damage`、`apply_status`、`restore_resource` だけが現在の攻撃時候補で、`trigger_chance` はここで使われること
- 対象スクリプト: `scripts/combat/combat_manager.gd`、`scripts/core/unit.gd`、`scripts/item/item_effect_manager.gd`
- 対象関数: `perform_attack()`、`_apply_equipment_attack_effects()`、`_should_apply_equipment_attack_effect()`、`Unit.get_equipped_attack_effects()`、`Unit._is_attack_equipment_effect_candidate()`、`_apply_equipment_attack_deal_damage()`、`_apply_equipment_attack_apply_status()`、`_apply_equipment_attack_restore_resource()`
- 関連 TSV: `equipment.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: `equipment`、`item_effects`、`item_effect_links`
- 元にする既存 docs: [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)、[../systems/unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md)

### P1: `learning/combat_damage_death_flow.md`

- 対象読者: 攻撃、ダメージ、死亡のつながりを理解したい人
- 目的: `CombatManager`、`DamageCalculator`、`Stats`、`Unit` の役割を分ける
- 読み終わった後に説明できること: 攻撃成立は `CombatManager`、ダメージ計算は `DamageCalculator`、HP変更は `Stats`、死亡処理は `Unit` が中心であること
- 対象スクリプト: `scripts/combat/combat_manager.gd`、`scripts/combat/damage_calculator.gd`、`scripts/core/stats.gd`、`scripts/core/unit.gd`
- 対象関数: `CombatManager.perform_attack()`、`DamageCalculator.calculate_damage()`、`Stats.take_damage()`、`Stats.die()`、`Unit.check_death()`、`Unit.handle_death()`
- 関連 TSV: `equipment.tsv`、`element_types.tsv`、`damage_types.tsv`
- 関連 Excel シート: `equipment`、`element_types`、`damage_types`
- 元にする既存 docs: [../systems/unit_combat_death_system_deep_dive.md](../systems/unit_combat_death_system_deep_dive.md)、[../systems/death_path_diagram.md](../systems/death_path_diagram.md)、[../systems/damage_system_notes.md](../systems/damage_system_notes.md)

### P2: `learning/death_drop_flow.md`

- 対象読者: 敵の所持品と死亡時ドロップを理解したい人
- 目的: initial inventory と death drop を混同しない
- 読み終わった後に説明できること: 死亡時に落ちるのは再抽選 loot ではなく、Unit が実際に持っている bag / hotbar / equipment であること
- 対象スクリプト: `scripts/core/unit.gd`、`scripts/item/item_drop_helper.gd`、`scripts/item/item_world_manager.gd`、`scripts/managers/unit_spawn_manager.gd`
- 対象関数: `apply_initial_inventory_from_data()`、`_has_saved_inventory_state()`、`handle_death()`、`drop_inventory_items_on_death_if_needed()`、`_collect_inventory_drop_targets()`
- 関連 TSV: `initial_inventory_tables.tsv`、`initial_inventory_entries.tsv`、`items.tsv`、`equipment.tsv`
- 関連 Excel シート: `initial_inventory_tables`、`initial_inventory_entries`、`items`、`equipment`
- 元にする既存 docs: [../systems/death_drop_spec.md](../systems/death_drop_spec.md)、[../systems/death_path_diagram.md](../systems/death_path_diagram.md)、[../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md)

### P2: `learning/debug_first_steps.md`

- 対象読者: 「なぜ動かないか」を最初に切り分けたい人
- 目的: 代表的な不具合ごとの確認順を作る
- 読み終わった後に説明できること: DebugSettings、TSV、loader、effect manager、Unit/Stats のどこを見るか
- 対象スクリプト: `scripts/debug/DebugSettings.gd`、`scripts/data/game_data_registry.gd`、`scripts/item/item_effect_manager.gd`、`scripts/core/unit.gd`
- 対象関数: `debug_print_loaded_data()`、`_is_game_data_load_summary_enabled()`、`_is_game_data_load_details_enabled()`、`apply_single_effect()`、`get_total_attack()`、`check_death()`
- 関連 TSV: 状況に応じて `items.tsv`、`equipment.tsv`、`item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: 状況に応じて同名シート
- 元にする既存 docs: [../systems/debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md)、[debug_output_normalization_audit.md](debug_output_normalization_audit.md)、[gamedata_registry_debug_dump_audit.md](gamedata_registry_debug_dump_audit.md)

### P2: `learning/adding_new_data_or_effect_type.md`

- 対象読者: 既存効果ではなく新しい `effect_type` や新しい列を足したい人
- 目的: データ追加だけで済む変更と、実装が必要な変更を分ける
- 読み終わった後に説明できること: TSV に新しい名前を書くだけでは動かず、GDScript 側の enum、loader、handler、validator が必要な場合があること
- 対象スクリプト: `scripts/data/item_effect_data.gd`、`scripts/data/game_data_registry.gd`、`scripts/item/item_effect_manager.gd`、`scripts/combat/combat_manager.gd`、`tools/validate_master_data.py`
- 対象関数: `ItemEffectData.EffectType`、`GameDataRegistry._build_item_effect()`、`GameDataRegistry._normalize_trigger_chance()`、`ItemEffectManager.apply_single_effect()`、`CombatManager._apply_equipment_attack_effects()`
- 関連 TSV: `item_effects.tsv`、`item_effect_links.tsv`
- 関連 Excel シート: `item_effects`、`item_effect_links`
- 元にする既存 docs: [../guides/item_addition_guide.md](../guides/item_addition_guide.md)、[../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)、[../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)

## 7. 推奨テンプレート

学習用 docs は、次のテンプレートに揃えると読みやすくなります。

```markdown
# タイトル

## このページで理解すること

## 最初に全体像

## この章で読むコード

## 処理ステップ

### 対象ファイル

### 対象関数

### このコードを見る理由

### 重要コード

### 入力

### 結果

### 次に進む処理

## 関連 TSV・Excel

## よくある勘違い

## 不具合時に確認する順番

## 詳細を確認する既存 docs

## 理解度チェック
```

### テンプレート運用ルール

- 1 ページ 100 から 180 行程度を目安にします。
- 表は使ってよいですが、1 表に詰め込みすぎません。
- 関数経路は短い箇条書きを優先します。
- コード引用は 1 箇所 5 から 10 行程度にします。
- コード引用の前に必ず `ファイル :: 関数` を書きます。
- 章の最後に「詳細を確認する既存 docs」を置きます。
- 「ここでは扱わないこと」を明記し、詳細 docs と役割を分けます。

## 8. 既存 docs ごとの対応方針

### `docs/README.md`

- 方針: 将来的に先頭へ `learning/start_here.md` への導線を追加します。
- 今回は変更しません。
- 理由: 既存 README は目的別リンク集として価値があります。初学者向け入口を上に足すだけでよいです。

### `docs/guides/current_system_reading_order.md`

- 方針: 中級者向けの「詳細 docs 読書順」として残します。
- 将来的には `learning/start_here.md` からリンクします。
- 理由: 現状は正確ですが、最初の入口としては分岐が多いです。

### `docs/guides/item_addition_guide.md`

- 方針: 作業ガイドとして残します。先頭に短い「まず `learning/excel_to_game_flow.md` と `learning/item_use_flow.md` を読むと理解しやすい」という導線を追加する候補です。
- 理由: 情報量が多く、実務には強いですが、学習の第 1 歩としては長いです。

### `docs/systems/game_data_registry_loader_map.md`

- 方針: 詳細参照資料として残します。
- 学習用 docs では `load_all()`、`_load_items()`、`_load_equipment()`、`_load_item_effects()`、`_apply_item_effect_links()` だけに絞って入口を作ります。

### `docs/systems/equipment_item_effect_execution_path.md`

- 方針: 詳細参照資料として残します。
- 学習用 docs では、通常アイテム使用、対象指定アイテム、装備パッシブ、装備攻撃効果の 4 章に分けます。
- 理由: 1 つの文書に 3 つ以上の処理入口が入っており、初学者には混同しやすいです。

### `docs/systems/unit_lifecycle_deep_dive.md`

- 方針: 詳細参照資料として残します。
- 学習用 docs では、`Unit` の全体ではなく `Stats`、装備 stat、initial inventory、death drop の必要箇所だけへリンクします。

### `docs/systems/unit_combat_death_system_deep_dive.md` と `docs/systems/death_path_diagram.md`

- 方針: 詳細参照資料として残します。
- 学習用 docs では、`CombatManager.perform_attack()`、`DamageCalculator.calculate_damage()`、`Stats.take_damage()`、`Unit.handle_death()` の最小経路を先に示します。

### `docs/systems/debug_settings_deep_dive.md`

- 方針: 詳細参照資料として残します。
- 学習用 docs では、不具合症状別に「まず見る flag」と「見なくてよい場所」を整理します。

### backlog docs

- 方針: 将来整理候補として残します。
- 学習用 docs からは、必要な時だけリンクします。
- 理由: 初学者が最初に読むと、現行仕様と将来案が混ざりやすいです。

## 9. 段階的な実施計画

### Step 1: 監査と設計

- 変更対象: `docs/backlog/docs_learning_redesign_plan.md`
- 目的: 現在の docs と実装を調査し、再設計方針を決める
- 完了条件: この文書が追加されている

### Step 2: README と学習入口

- 変更対象: `docs/README.md`、`docs/learning/start_here.md`
- 目的: 初学者が最初に読む場所を 1 つにする
- 完了条件: README から `learning/start_here.md` へ迷わず進める

### Step 3: Excel からゲームまで

- 変更対象: `docs/learning/excel_to_game_flow.md`
- 目的: `master_data.xlsx -> export -> TSV -> GameDataRegistry -> ItemDatabase` を理解できるようにする
- 完了条件: `items.tsv` と `equipment.tsv` の役割差を説明できる

### Step 4: Database と Manager

- 変更対象: `docs/learning/database_and_manager_roles.md`
- 目的: `GameDataRegistry`、`ItemDatabase`、`Inventory`、`ItemEffectManager` の責務を分ける
- 完了条件: 「読む」「引く」「持つ」「実行する」を説明できる

### Step 5: 通常アイテム使用

- 変更対象: `docs/learning/item_use_flow.md`
- 目的: `Inventory.use_item_at()` から `ItemEffectManager.apply_single_effect()` までを追う
- 完了条件: HP 回復アイテムがどの関数を通るか説明できる

### Step 6: 対象指定アイテム

- 変更対象: `docs/learning/target_item_use_flow.md`
- 目的: `user` と `target`、距離、命中、消費処理を分ける
- 完了条件: 対象指定アイテムが通常使用と違う入口を持つことを説明できる

### Step 7: 装備パッシブと装備攻撃効果

- 変更対象: `docs/learning/equipment_passive_flow.md`、`docs/learning/equipment_attack_effect_flow.md`
- 目的: 装備中 stat 反映と攻撃時 effect 実行を分ける
- 完了条件: `apply_modifier` と `trigger_chance` の使われ方を混同しない

### Step 8: 攻撃、ダメージ、死亡

- 変更対象: `docs/learning/combat_damage_death_flow.md`、`docs/learning/death_drop_flow.md`
- 目的: `CombatManager`、`DamageCalculator`、`Stats`、`Unit`、drop の経路を理解する
- 完了条件: HP0 から death drop までの主要関数を説明できる

### Step 9: デバッグ入門

- 変更対象: `docs/learning/debug_first_steps.md`
- 目的: 代表的な不具合の確認順を作る
- 完了条件: 「Excel に追加したのに出ない」「HP が回復しない」「装備効果が出ない」の最初の確認先を選べる

### Step 10: 既存 docs の重複整理

- 変更対象: 既存 docs の先頭導線、重複説明、リンク
- 目的: 詳細 docs を削らず、学習 docs への入口と役割分担を明確にする
- 完了条件: 同じ説明が複数 docs にある場合でも、主資料と補助資料の区別が分かる

## 10. 最初の実装 Step 案

最初の小さい docs-only Step として、次を推奨します。

```text
Step 2-A
docs/learning/start_here.md を新規作成する
```

### 変更対象

- 新規: `docs/learning/start_here.md`
- 既存変更はなし、または README へのリンク追加だけに留める

### 目的

- 所有者が最初に読む入口を作る
- 詳細 docs へ入る前に、主要スクリプトの責務を短く理解する

### 内容案

- このプロジェクトのデータと処理の全体像
- Excel、TSV、Registry、Database、Manager、Unit、Stats の一言責務
- 最初に覚える 7 つの境界
- 目的別に次に読む learning docs
- 詳細 docs へのリンク
- 理解度チェック

### 完了条件

- 15 分程度で読める
- `GameDataRegistry` と `ItemDatabase` の違いを説明できる
- `Inventory` と `ItemEffectManager` の違いを説明できる
- `ItemEffectManager` と `CombatManager` の違いを説明できる
- `Unit` と `Stats` の違いを説明できる
- 既存 docs、GDScript、TSV、Excel を変更していない

## 11. リスクと対策

### コード引用が古くなる

- リスク: 学習用 docs 内のコード引用が、後の実装変更で古くなります。
- 対策: コード全文ではなく、関数名と処理経路を主情報にします。引用は短くし、変更時は `rg` で関数名を確認する運用にします。

### 学習 docs と詳細 docs が重複する

- リスク: 同じ説明が増え、docs 総量がさらに増えます。
- 対策: 学習 docs には「ここで分かること」「詳細を確認する既存 docs」「ここでは扱わないこと」を必ず置きます。

### 初学者向け説明が不正確になる

- リスク: 分かりやすさを優先しすぎて実装とずれます。
- 対策: 各章で対象ファイルと対象関数を明記します。推測で関数名を書かず、現行コードで確認した関数名だけを書く方針にします。

### 現行仕様と将来設計が混ざる

- リスク: 学習者が「今動いている仕様」と「将来やりたい整理」を混同します。
- 対策: 学習 docs は現行仕様だけを扱い、将来案は `backlog/` へ逃がします。

### スマートフォンで読みにくい

- リスク: 表が大きくなりすぎ、横スクロールが増えます。
- 対策: 表は短くし、処理経路は箇条書き中心にします。大きな比較表は詳細 docs 側へ置きます。

### Codex 向け資料と所有者向け教材が混ざる

- リスク: Codex に渡す前提資料と、人間が理解する教材の目的が混同します。
- 対策: `docs/guides/codex_project_context.md` は Codex 向け、`docs/learning/` は所有者向けと明記します。

## 実装との一致確認

今回の調査では、既存 docs の主要な説明は現行コードと大きく矛盾していないように見えます。

確認できた主な関数経路は次の通りです。

- Excel / TSV 読み込み
  - `GameDataRegistry.load_all()`
  - `_load_items()`
  - `_load_equipment()`
  - `_load_item_effects()`
  - `_apply_item_effect_links()`
- 通常アイテム使用
  - `Inventory.use_item_at()`
  - `Inventory.use_hotbar_item_at()`
  - `ItemEffectManager.apply_item_effect()`
  - `ItemEffectManager.apply_item_effects()`
  - `ItemEffectManager.apply_single_effect()`
- 対象指定アイテム
  - `CombatManager.can_use_selected_target_item()`
  - `CombatManager.perform_selected_target_item_use()`
  - `CombatManager._roll_target_item_hit()`
- 装備パッシブ
  - `Unit.get_equipped_item_effects()`
  - `Unit._get_total_equipment_effect_modifier()`
  - `Unit._apply_equipment_effect_modifier()`
  - `Unit.get_total_attack()`
  - `Unit.get_total_defense()`
- 装備攻撃効果
  - `CombatManager.perform_attack()`
  - `CombatManager._apply_equipment_attack_effects()`
  - `CombatManager._should_apply_equipment_attack_effect()`
  - `Unit.get_equipped_attack_effects()`
  - `Unit._is_attack_equipment_effect_candidate()`
- ダメージと死亡
  - `DamageCalculator.calculate_damage()`
  - `Stats.take_damage()`
  - `Stats.die()`
  - `Unit.check_death()`
  - `Unit.handle_death()`
- death drop
  - `Unit.drop_inventory_items_on_death_if_needed()`
  - `Unit._collect_inventory_drop_targets()`
- DebugSettings
  - `debug_game_data_load_summary`
  - `debug_game_data_load_details`
  - `debug_equipment_effects`
  - `debug_equipment_attack_effects`
  - `debug_give_player_start_items`
  - `debug_player_start_items`
  - `debug_item_spawn`
  - `debug_enchant`

不一致または注意点として記録すべきことは次です。

- `ItemDatabase` は単独の正本ではなく、主に `GameDataRegistry` から item data を引く参照入口です。
- `ItemEffectManager` は消耗品や対象指定アイテムの効果実行が中心です。装備パッシブ stat 反映の中心は `Unit` です。
- 装備攻撃効果の中心は `CombatManager` です。
- `trigger_chance` は現状、主に装備攻撃効果の発動判定として使われます。消耗品効果や装備パッシブの発動率として読むと誤解しやすいです。
- `initial_inventory_entries.tsv` は Unit 生成時の所持品であり、死亡時 drop table ではありません。
- `get_stats_data()` は名前より広く、Unit の runtime save data に近い内容を含みます。

## 検証

今回実行した検証は docs-only の範囲です。

- `git branch --show-current` で `codex` ブランチを確認しました。
- `rg --files docs` で docs の実在を確認しました。
- `rg --files scripts` で対象 script の実在を確認しました。
- `rg` で主要関数名の実在を確認しました。
- 既存 docs、GDScript、scene、Excel、TSV、Python、project settings、tests、assets は変更していません。

Godot 実行は不要なため実行していません。
