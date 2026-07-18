# Adding New Data Or Effect Type
このページは、新しいデータや新しい効果を追加したい時に、どこまで作業が必要かを判断するための入口です。
実装手順の完全版ではありません。
まず「既存データ追加だけで済むのか」「既存effect_typeの値違いで済むのか」「新しいGDScript実装が必要なのか」を分けます。
## 1. このページで理解すること
- Excel / TSVだけで済む変更がある
- 既存effect_typeを使うならGDScript追加が不要な場合がある
- 新しいeffect_typeはdata、loader、実行側、validatorを同時に見る
- 通常アイテム、装備パッシブ、装備攻撃効果で実行入口が違う
- 新しいTSVを増やす場合はexportとvalidateも対象になる
- Codexへ依頼する時は「どのレベルの追加か」を明記する
## 2. 最初に全体像
```text
やりたいことを1文にする
↓
既存のitem / equipment / effect_typeで表現できるか確認
↓
Excelを編集
↓
PythonでTSV export
↓
validate
↓
GameDataRegistryが読み込む
↓
Databaseが取得する
↓
Inventory / Unit / CombatManager が実行入口になる
↓
必要なら新しいGDScript実装を追加
```
最初に見るのは「新しいコードを書きたいか」ではありません。
既存データで表現できるかです。
## 3. 変更レベル
- 既存データの行を追加するだけ
- 例: 新しい回復ポーション、既存categoryの新アイテム
- 既存effect_typeを使い、値だけ変える
- 例: 回復量、`trigger_chance`、`apply_modifier` のstat名や値
- 既存システムの新しいIDを追加する
- 例: 新しいstatus_id、element_type、damage_type
- データだけで済むこともあるが、表示、処理、耐性、AI対応を確認する
- 新しい振る舞いを追加する
- 例: 位置交換、周囲全体回復、特殊な召喚、既存handlerにないeffect_type
- この場合はGDScript実装が必要になる
## 4. 判断表
| やりたいこと | まず見るもの | GDScript追加の可能性 |
| --- | --- | --- |
| 新しい通常アイテム | `items`、`item_effects`、`item_effect_links` | 既存効果なら低い |
| 新しい装備 | `items`、`equipment`、`item_effect_links` | 既存効果なら低い |
| 回復量違いのポーション | `restore_resource` | 低い |
| 装備中stat bonus | `apply_modifier` | 低い |
| 攻撃時追加ダメージ | `deal_damage`、`trigger_chance` | 低い |
| 新しい効果type | `ItemEffectData`、loader、実行側 | 高い |
| 新しいTSVカテゴリ | export、loader、validator | 高い |
この表は入口です。
最終判断は現行コードのhandler有無で決めます。
## 5. Excel / TSVだけで済む例
`healing_potion` と同じ仕組みで、回復量だけ違うポーションを作る場合です。
- `master_data.xlsx`
- `items`
- `item_effects`
- `item_effect_links`
- `data/master/items.tsv`
- `data/master/item_effects.tsv`
- `data/master/item_effect_links.tsv`
この場合、既存の `restore_resource` を使えます。
`ItemEffectManager._apply_restore_resource()` がすでにあるため、新しいhandlerは不要です。
## 6. 新しいeffect_typeが必要な例
例として「敵と自分の位置を入れ替える効果」を考えます。
これは仮の例で、現行実装として存在するとは限りません。
既存の `restore_resource`、`apply_status`、`apply_modifier`、`deal_damage` などで表現できないなら、新しいeffect_type候補です。
- `ItemEffectData.EffectType` に種類を追加
- `GameDataRegistry._build_item_effect()` でTSV文字列を読む
- `ItemEffectManager.apply_single_effect()` に分岐を追加
- 装備攻撃効果なら `CombatManager` 側にも対応を検討
- validatorに値や参照チェックを追加
- docsと確認データを追加
## 7. TSV export
Excelのsheetを `data/master/*.tsv` へ書き出すscriptです。
新しいsheetを増やす場合は、ここに対応が必要です。
### コード引用
`SHEET_TO_TSV`
Excel sheetとTSVファイルの対応を確認するためです。
```python
SHEET_TO_TSV = {
    "item_categories": "item_categories.tsv",
    "items": "items.tsv",
    "equipment": "equipment.tsv",
    "item_effects": "item_effects.tsv",
    "item_effect_links": "item_effect_links.tsv",
    "chest_tables": "chest_tables.tsv",
```
- sheet名とTSVファイル名を対応させる
- 既存sheetはこのmapに沿ってexportされる
- 新しいTSV系統を増やすならここを見る
- `master_data.xlsx`
- `data/master/*.tsv`
## 8. validate
TSV同士のID重複や参照関係を確認するscriptです。
新しいデータ系統や参照関係を増やす場合は、validatorも合わせて見ます。
### コード引用
`filenames`
validatorがどのTSVを読むかを確認するためです。
```python
    filenames = {
        "item_categories": "item_categories.tsv",
        "items": "items.tsv",
        "equipment": "equipment.tsv",
        "item_effects": "item_effects.tsv",
        "item_effect_links": "item_effect_links.tsv",
        "chest_tables": "chest_tables.tsv",
```
- validate対象のTSVを列挙する
- `item_effects` と `item_effect_links` も対象
- 新しいTSVを作るなら登録が必要になる可能性がある
- `data/master/*.tsv`
- 重複や参照欠けの検出
duplicate check、reference check、列ごとの値検証
## 9. ItemEffectData
item effectの型と値を持つResourceです。
新しいeffect_typeを追加するなら、まずここで表現できるかを見ます。
### コード引用
`EffectType`
現行コードで定義済みのeffect_typeを確認するためです。
```gdscript
enum EffectType {
	NONE,
	RESTORE_RESOURCE,
	CURE_STATUS,
	APPLY_STATUS,
	APPLY_MODIFIER,
	DEAL_DAMAGE,
	GRANT_ITEM,
```
- effect_typeの候補をenumで定義する
- `restore_resource` や `deal_damage` は既存型
- ここにない振る舞いは追加実装が必要
- `GameDataRegistry` で変換されたTSV値
- 実行側がmatchできるenum値
`GameDataRegistry._build_item_effect()`
## 10. GameDataRegistry
`item_effects.tsv` の1行を `ItemEffectData` に変換する場所です。
### コード引用
TSVの `effect_type` 文字列がenumへ変換される場所を確認するためです。
```gdscript
			effect.effect_type = ItemEffectData.EffectType.RESTORE_RESOURCE
			effect.resource_type = _resource_type_from_text(_get_string(row, "resource_type", "hp"))
			effect.value_mode = _value_mode_from_text(_get_string(row, "value_mode", "flat"))
			effect.power_min = _to_int(_get_string(row, "power_min"), 0)
			effect.power_max = _to_int(_get_string(row, "power_max"), effect.power_min)
```
- `effect_type` の文字列を見る
- `restore_resource` ならenumと関連値を設定する
- `resource_type`、`value_mode`、`power_min` などをTSVから読む
- `item_effects.tsv` の1行
- `ItemEffectData`
## 11. item_effect_links
itemとeffectをつなぎ、`ItemData.effects` に入れる場所です。
### コード引用
`item_effect_links.tsv` のorder順にeffectがitemへ入ることを確認するためです。
```gdscript
		var links: Array = item_effect_links[item_id]
		links.sort_custom(func(a, b): return int(a["order"]) < int(b["order"]))

		item.effects.clear()

			var effect_id := String(link["effect_id"])
			var effect: ItemEffectData = effects.get(effect_id)
```
- linkをorder順に並べる
- itemのeffectsを作り直す
- effect_idから `ItemEffectData` を取得する
- `item_effect_links.tsv`
- `item_effects.tsv`
- `ItemData.effects`
通常アイテムなら `ItemEffectManager`、装備パッシブなら `Unit`、装備攻撃効果なら `CombatManager`
## 12. 通常アイテムの実行側
通常アイテムや対象指定アイテムのeffectを実行する分岐です。
### コード引用
既存effect_typeにhandlerがあるかを確認するためです。
```gdscript
			return false

		ItemEffectData.EffectType.RESTORE_RESOURCE:
			return _apply_restore_resource(user, target, effect)

		ItemEffectData.EffectType.CURE_STATUS:
			return _apply_cure_status(user, target, effect)
```
- effect_typeごとにhandlerへ分岐する
- 未対応なら成功しない
- 新しいeffect_typeには新しい分岐とhandlerが必要
- user
- target
- item_data
- effect
- 成功時 true
- 失敗時 false
追加したいeffect_typeに対応するhandler
## 13. 装備攻撃効果の実行側
通常攻撃後に、装備攻撃効果を処理する場所です。
同じ `ItemEffectData` を使っていても、通常アイテムとは実行入口が別です。
### コード引用
装備攻撃効果で対応済みのeffect_typeを確認するためです。
```gdscript
			ItemEffectData.EffectType.DEAL_DAMAGE:
				var extra_damage: int = _apply_equipment_attack_deal_damage(attacker, target, effect_entry, effect)
				total_extra_damage += extra_damage

			ItemEffectData.EffectType.APPLY_STATUS:
				_apply_equipment_attack_apply_status(attacker, target, effect_entry, effect)

			ItemEffectData.EffectType.RESTORE_RESOURCE:
```
- 装備攻撃効果用にeffect_typeを分岐する
- 現行では `deal_damage`、`apply_status`、`restore_resource` が中心
- 通常アイテムで対応済みでも、装備攻撃効果では未対応の場合がある
- attacker
- target
- 装備から集めたeffect
- 追加ダメージ、状態付与、攻撃者回復などが実行される
`trigger_chance` とeffect_typeごとの装備攻撃handler
## 14. trigger_chance
`trigger_chance` は `item_effects.tsv` の列です。
現行コードでは `GameDataRegistry._build_item_effect()` で読み込みます。
通常アイテム使用では、基本的にアイテム効果の実行順や成功判定が重要です。
装備攻撃効果では、`CombatManager` 側で攻撃時に発動判定されます。
ここを混同しないようにします。
## 15. 新しいTSVを増やす場合
新しいTSVを増やす場合は、だいたい次をセットで考えます。
- Excel sheet
- `tools/export_master_tsv.py`
- `data/master/*.tsv`
- data Resource class
- `GameDataRegistry` のload/build/lookup
- `tools/validate_master_data.py`
- 実行側script
- save/loadやWorldStateが必要か
- docs
TSVを1つ足すだけに見えても、読み込み、検証、参照、実行の入口が必要になります。
## 16. 具体例1: 上級回復ポーション
現行TSVには `high_healing_potion` があります。
これは、既存の `restore_resource` を使う例です。
```text
items.tsv
↓
high_healing_potion
↓
item_effect_links.tsv
↓
high_healing_potion_restore_hp
↓
item_effects.tsv
↓
restore_resource / hp / 60-80
↓
GameDataRegistry
↓
ItemEffectManager._apply_restore_resource()
```
このタイプの追加では、新しいeffect handlerは不要です。
## 17. 具体例2: sample_combo_knife
現行TSVには `sample_combo_knife` があります。
これは装備攻撃効果の例です。
```text
items.tsv
↓
equipment.tsv
↓
item_effect_links.tsv
↓
sample_combo_knife_fire_damage
sample_combo_knife_restore_hp
↓
item_effects.tsv
↓
deal_damage / restore_resource
↓
Unit.get_equipped_attack_effects()
↓
CombatManager._apply_equipment_attack_effects()
```
同じ `restore_resource` でも、通常アイテムと装備攻撃効果では実行入口と意味が変わります。
## 18. よくある勘違い
新しいitemは必ずGDScript追加が必要、enumを足せば効果が動く、通常アイテムで動く効果は装備攻撃でも自動で動く、という理解は誤りです。
## 19. 不具合時の確認順
- 最初に見る: `items.tsv`
- 次に見る: `GameDataRegistry` のitems読み込み
- 理由: ExcelからTSVへ出ていない、または読み込まれていない可能性がある
- 最初に見る: `item_effect_links.tsv`
- 次に見る: `ItemData.effects`
- 理由: itemとeffectがつながっていないと実行側まで届かない
- 最初に見る: `GameDataRegistry._build_item_effect()`
- 次に見る: 実行側のmatch分岐
- 理由: 文字列がenumへ変換され、handlerへ分岐される必要がある
- 最初に見る: `CombatManager._apply_equipment_attack_effects()`
- 次に見る: 対応effect_typeと `trigger_chance`
- 理由: 実行入口が `ItemEffectManager` ではない
- 最初に見る: 該当TSVのID
- 次に見る: 参照先TSVにそのIDがあるか
- 理由: `item_effect_links.effect_id` なら `item_effects.effect_id` が必要
## 20. Codexへ依頼する時のテンプレート
```text
やりたいこと: 攻撃時に30%でHPを1回復するナイフを追加したい。
既存効果で表現できそうか: restore_resource と trigger_chanceで足りそう。
対象: 新規item_id drain_sample_knife
経路: 装備攻撃効果
変更範囲: Excel/TSV/docsのみ。GDScriptは変更しない。
```
この依頼なら、既存 `restore_resource` が装備攻撃効果で対応済みかを確認してから、データ追加で済むか判断します。
## 21. このページでは扱わない
Excelの画面操作、effect handler全文実装、Godot editor操作、save/load全体設計、UI追加、自動テスト詳細は扱いません。
## 22. 詳細docs
- [excel_to_game_flow](excel_to_game_flow.md)
- [database_and_manager_roles](database_and_manager_roles.md)
- [item_use_flow](item_use_flow.md)
- [equipment_passive_flow](equipment_passive_flow.md)
- [equipment_attack_effect_flow](equipment_attack_effect_flow.md)
- [debug_first_steps](debug_first_steps.md)
- [item_addition_guide](../guides/item_addition_guide.md)
- [feature_addition_guide](../guides/feature_addition_guide.md)
- [game_data_registry_loader_map](../systems/data/game_data_registry_loader_map.md)
- [equipment_item_effect_execution_path](../systems/equipment_item_effect_execution_path.md)
- [script_responsibility_map](../architecture/script_responsibility_map.md)
## 23. 理解度チェック
1. 新しい回復ポーションを作る時、必ずGDScriptを追加しますか。
2. Excelに新しいsheetを増やす場合、`tools/export_master_tsv.py` を見る理由は何ですか。
3. `item_effects.tsv` の `effect_type` 文字列を読む中心関数は何ですか。
4. `item_effect_links.tsv` は何をつなぎますか。
5. 新しいeffect_typeを追加する時、`ItemEffectData` だけを変えれば動きますか。
6. 通常アイテムのeffect実行入口は主にどのscriptですか。
7. 装備攻撃効果のeffect実行入口は主にどのscriptですか。
8. `trigger_chance` は装備攻撃効果ではどこで意味を持ちますか。
9. validateで `effect_id` 参照エラーが出た場合、どのTSV同士を見ますか。
10. 既存effect_typeで表現できるかを最初に確認する理由は何ですか。
11. 通常アイテムでは動くeffectが装備攻撃で動かない時、最初に見る関数は何ですか。
---
## 回答例
1. いいえ。既存 `restore_resource` で足りるならデータ追加だけで済むことがあります。
2. Excel sheetとTSVファイルの対応を管理しているからです。
3. `GameDataRegistry._build_item_effect()` です。
4. item_idとeffect_idをつなぎ、itemのeffectsへ反映します。
5. 動きません。loader、実行側handler、validatorなども必要です。
6. `scripts/item/item_effect_manager.gd` です。
7. `scripts/combat/combat_manager.gd` です。
8. `_apply_equipment_attack_effects()` の発動判定で意味を持ちます。
9. `item_effect_links.tsv` と `item_effects.tsv` です。
10. 不要なGDScript追加を避け、現行仕様を壊さずに追加できるか判断するためです。
11. `CombatManager._apply_equipment_attack_effects()` です。
