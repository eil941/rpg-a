# TSV Migration Audit

## Step 5-F: item spawn rule composite columns split

### 実装したTSV

- `data/master/item_spawn_rule_category_multipliers.tsv`
  - `rule_id`
  - `category`
  - `multiplier`
- `data/master/item_spawn_rule_item_overrides.tsv`
  - `rule_id`
  - `item_id`
  - `weight`

### 調査結果

`spawn_rules.tsv` には、既存互換用に以下の composite 列が残っています。

- `category_multipliers`
  - 形式: `category=multiplier|category=multiplier`
  - `GameDataRegistry._split_float_dict()` で `Dictionary` に変換されます。
  - `ItemSpawnRuleData.get_category_multiplier()` でカテゴリ一致時に倍率として使われます。
  - `ItemSpawnRuleDatabase._calculate_final_weight()` では、rarity 補正後の `weight_value` に乗算されます。
- `item_weight_overrides`
  - 形式: `item_id=weight|item_id=weight`
  - `GameDataRegistry._split_int_dict()` で `Dictionary` に変換されます。
  - `ItemSpawnRuleDatabase._calculate_final_weight()` では、該当アイテムがある場合に最終重みを固定値として上書きします。
  - `0` 以下は出現候補から除外されます。

### fallback仕様

Step 5-F では、旧 composite 列は削除していません。

理由:

- 既存データ互換を維持するため
- Godot起動確認後に削除判断するため
- 子テーブルが空、または未定義の環境でも既存挙動を維持するため

優先順位:

1. `item_spawn_rule_category_multipliers.tsv` / `item_spawn_rule_item_overrides.tsv` に対象 `rule_id` の行がある場合
   - 子テーブルを優先します。
2. 子テーブルに対象 `rule_id` の行がない場合
   - `spawn_rules.tsv` の `category_multipliers` / `item_weight_overrides` を fallback として使います。

### 実装メモ

- `ItemSpawnRuleChildTableDatabase` を追加し、子テーブルTSVを遅延読み込みします。
- `ItemSpawnRuleData` の `get_category_multiplier()` / `has_item_weight_override()` / `get_item_weight_override()` から子テーブルを優先参照するようにしました。
- `GameDataRegistry` の大規模変更は避け、既存の `spawn_rules.tsv` 読み込み構造は維持しました。

### validator追加

`tools/validate_master_data.py` を追加しました。

確認内容:

- `item_spawn_rule_category_multipliers` の `rule_id + category` 重複
- `rule_id` が `spawn_rules.tsv` に存在するか
- `category` が `ItemCategories` または `items.tsv` に存在するか
- `multiplier` が数値か
- `multiplier >= 0` か
- `item_spawn_rule_item_overrides` の `rule_id + item_id` 重複
- `rule_id` が `spawn_rules.tsv` に存在するか
- `item_id` が `items.tsv` に存在するか
- `weight` が数値か
- `weight >= 0` か

### master_data.xlsx

この変更では `master_data.xlsx` のバイナリ編集は未実施です。

ローカルまたはCodex側で、以下のシートを追加してください。

- `item_spawn_rule_category_multipliers`
- `item_spawn_rule_item_overrides`

追加後、`tools/export_master_tsv.py` からTSV出力できます。

### 残るTSV化候補

- `drop_tables.tsv`
- `drop_table_entries.tsv`

ただし Step 5-E の調査結果により、死亡時ドロップは現在の inventory / hotbar / 装備を落とす仕様で、専用 drop 抽選テーブルは保留が安全です。

### Godot確認項目

- 起動時にエラーが出ない
- フィールドのアイテム出現が消えていない
- 出現アイテムのカテゴリが大きく偏っていない
- `shop` / `chest` / `initial_inventory` / `damage` 系が壊れていない
