# Debug First Steps
このページは、不具合が起きた時に最初にどこを見るかを決めるための入口です。
目的は、症状を見た瞬間に「データ」「処理」「表示」「保存」のどこから切り分けるかを選べるようにすることです。
## 1. このページで理解すること
- 不具合を最初に小さく言い換える
- データが入っていない問題と、処理が動いていない問題を分ける
- `DebugSettings` は確認用であり、通常状態へ戻す対象でもある
- logは件数、ID、skip理由、成功/失敗を見る
- 症状ごとに最初に見るscriptを決める
- 詳細が必要になったら、該当するlearning docsまたはsystems docsへ進む
## 2. 最初に全体像
```text
症状を1文にする
↓
データ / 処理 / 表示 / 保存 のどれかに仮置きする
↓
関係するIDを確認する
↓
DebugSettingsや既存logを確認する
↓
最初の入口関数を見る
↓
次の関数へ1つずつ進む
↓
詳細docsへ進む
↓
最後に原因を自分の言葉で説明する
```
最初から全コードを読む必要はありません。
まず、止まっている層を決めます。
## 3. 最初の切り分け
- Excelに書いた値がTSVに出ていない
- TSVにあるのに `GameDataRegistry` に入っていない
- item_idやeffect_idの参照がつながっていない
- 関数が呼ばれていない
- 条件でskipされている
- handlerがfalseを返している
- 成功後の次処理へ進んでいない
- 内部値は変わっているがUIが更新されない
- logには出ているが見た目だけ変わらない
- エフェクトやメッセージだけがずれる
- その場では正しいがmap再訪で消える
- save/load後に戻る
- PlayerDataやWorldStateへ反映されていない
## 4. DebugSettingsの位置付け
`DebugSettings` は、確認用flagとdebug開始アイテムをまとめる場所です。
不具合を直す本体ではなく、確認しやすくするために一時的にflagを変える場所です。
### コード引用
debug flag定義
装備効果、死亡ドロップ、GameData読み込みの確認flagを把握するためです。
```gdscript
var debug_equipment_effects: bool = false
var debug_equipment_attack_effects: bool = false
var debug_player_death_drop_scope_test_enabled: bool = false
var debug_player_death_drop_scope_mode: String = "all"
var debug_game_data_load_summary: bool = true
var debug_game_data_load_details: bool = false
```
- 装備パッシブ確認flagがある
- 装備攻撃効果確認flagがある
- player死亡ドロップ範囲確認flagがある
- GameData読み込みsummary/detailsの出力flagがある
- 手動で変更するdebug設定
- 関連scriptのlogや検証挙動が変わる
対象症状のscript側で、このflagが参照される場所
## 5. logの読み方
logを見る時は、文章全体より先に次を探します。
- 対象ID
- 件数
- skip理由
- success / failed
- null
- empty
- not found
- unsupported
- `[GameData] items: 48`
- `[ITEM EFFECT] failed effect_type=restore_resource`
- `[DEATH DROP] skipped by drop_inventory_on_death=false`
- `effect link item not found`
- `unsupported_type`
logは「何が起きたか」だけでなく、「どこまで進んだか」を見るためのものです。
## 6. GameData読み込みを疑う時
ExcelやTSVに書いたものがゲームに入っていない気がする時は、まずGameDataの読み込み件数を見ます。
### コード引用
読み込まれたデータの件数がlogに出ることを確認するためです。
```gdscript
func debug_print_loaded_data() -> void:
	var should_print_summary := _is_game_data_load_summary_enabled()
	var should_print_details := _is_game_data_load_details_enabled()
	if not should_print_summary and not should_print_details:
		return

	print("========== GameData Loaded ==========")
		print("[GameData] items: ", items.size())
```
- summary/details flagを見る
- どちらもoffなら何も出さない
- summaryがonなら読み込み件数を出す
- `DebugSettings.debug_game_data_load_summary`
- `DebugSettings.debug_game_data_load_details`
- GameData読み込み件数のlogが出る
対象TSVのloader、または [excel_to_game_flow](excel_to_game_flow.md)
## 7. debug start itemを疑う時
「DebugSettingsに開始アイテムを書いたのに配られない」場合は、まず早期returnを見ます。
### コード引用
debug開始アイテムが配られない条件を確認するためです。
```gdscript
func apply_debug_start_items_if_needed() -> void:
		return

	if not DebugSettings.debug_give_player_start_items:
		return

	if PlayerData.debug_start_items_applied:
		return
```
- player unit以外には配らない
- `debug_give_player_start_items` がfalseなら配らない
- すでに配布済みなら再配布しない
- player判定
- `DebugSettings.debug_give_player_start_items`
- `PlayerData.debug_start_items_applied`
- 条件を満たす場合だけdebug開始アイテム配布へ進む
`DebugSettings.debug_player_start_items` と、new game / save dataの状態
## 8. よく使う確認入口
- 最初に見る: `tools/export_master_tsv.py`
- 次に見る: `data/master/*.tsv`
- その次: `scripts/data/game_data_registry.gd`
- 最初に見る: `data/master/items.tsv`
- 次に見る: `GameDataRegistry`
- その次: `scripts/item/item_database.gd`
- 最初に見る: `scripts/item/inventory.gd`
- 次に見る: `scripts/item/item_database.gd`
- その次: `scripts/item/item_effect_manager.gd`
- 最初に見る: `scripts/item/item_effect_manager.gd`
- 次に見る: `scripts/core/stats.gd`
- その次: UI更新経路
- 最初に見る: `scripts/core/unit.gd`
- 次に見る: `get_equipped_item_effects()`
- その次: `get_total_*` 系のstat合成
- 最初に見る: `scripts/combat/combat_manager.gd`
- 次に見る: `_apply_equipment_attack_effects()`
- その次: `trigger_chance` とeffect_type
- 最初に見る: `scripts/core/stats.gd`
- 次に見る: `take_damage()` / `die()`
- その次: `Unit.check_death()` / `Unit.handle_death()`
- 補足: `Stats.take_damage()` からは `Stats.die()` 経由で `Unit.handle_death()` へ進み、明示的な死亡確認は `Unit.check_death()` から `Unit.handle_death()` へ進む。二重死亡処理は `Unit.death_handled` で止める
- 最初に見る: `Unit.drop_inventory_items_on_death_if_needed()`
- 次に見る: drop flag
- その次: `ItemDropHelper`
## 9. 症状別の確認順
- 最初に見る: `data/master/items.tsv`
- 次に見る: `GameDataRegistry` のitems読み込み
- 理由: ExcelからTSVへ出ていなければゲームには入らない
- 関連docs: [excel_to_game_flow](excel_to_game_flow.md)
- 最初に見る: `scripts/data/game_data_registry.gd`
- 次に見る: `scripts/item/item_database.gd`
- 理由: `ItemDatabase` は登録済みデータを取得する側
- 関連docs: [database_and_manager_roles](database_and_manager_roles.md)
- 最初に見る: `Inventory.use_item_at()`
- 次に見る: `ItemDatabase.get_item_data()`、`ItemEffectManager.apply_item_effect()`
- 理由: 使用可否、item data取得、effect実行のどこかで止まっている
- 関連docs: [item_use_flow](item_use_flow.md)
- 最初に見る: `ItemEffectManager._apply_restore_resource()`
- 次に見る: `ItemEffectManager._apply_resource_restore()`
- その次: targetのStatsと `stats.hp`
- 理由: 通常ポーションの現行経路では `Stats.heal()` を直接呼ばず、`_apply_resource_restore()` が `stats.hp` を更新する
- 最初に見る: `stats.hp` の更新結果
- 次に見る: InventoryやHUDの更新通知
- 理由: 内部値変更と表示更新は別
- 最初に見る: `Unit.get_equipped_item_effects()`
- 次に見る: 装備entryと `item_effect_links.tsv`
- 理由: 装備中効果は `Unit` が装備から集める
- 関連docs: [equipment_passive_flow](equipment_passive_flow.md)
- 最初に見る: `CombatManager._apply_equipment_attack_effects()`
- 次に見る: `Unit.get_equipped_attack_effects()`、`trigger_chance`
- 理由: 装備攻撃効果は攻撃処理の中で発動判定される
- 関連docs: [equipment_attack_effect_flow](equipment_attack_effect_flow.md)
- 最初に見る: `Stats.take_damage()`
- 次に見る: `Stats.die()`、`Unit.check_death()`、`Unit.handle_death()`
- 理由: `Stats.take_damage()` からの死亡通知と、`Unit.check_death()` からの明示的な死亡確認は別入口。どちらも最終的に `Unit.handle_death()` へ進み、二重処理は `Unit.death_handled` で止まる
- 関連docs: [combat_damage_death_flow](combat_damage_death_flow.md)
- 最初に見る: `Unit.drop_inventory_items_on_death_if_needed()`
- 次に見る: `drop_inventory_on_death`、`drop_equipped_items_on_death`、`ItemDropHelper`
- 理由: drop対象収集と地面生成は別
- 関連docs: [death_drop_flow](death_drop_flow.md)
- 最初に見る: `ItemDropHelper` のWorldState保存
- 次に見る: `ItemWorldManager`、`WorldState`
- 理由: その場の生成ではなく、保存と復元の問題
## 10. コードを見る時の順番
```text
1. 入口関数
2. 早期return
3. 対象IDの取得
4. null / empty / not found
5. 分岐条件
6. handler呼び出し
7. bool戻り値
8. 成功後の更新
9. UI / save / WorldState
```
最初からhelper関数を深追いしすぎると迷いやすいです。
入口から1つずつ進みます。
## 11. DebugSettingsを触る時の注意
- 何を確認したいか書き出す
- 関連docsで現在値を確認する
- flag名を間違えない
- 目的のlogだけを見る
- 変化したかどうかを短くメモする
- 複数flagを同時に変えすぎない
- 通常状態へ戻す
- debug start itemがsave dataに影響したか確認する
- 不要なlogが残っていないか確認する
## 12. よくある勘違い
- Excelを直せばゲーム内データも自動で変わる: exportとGameData読み込みが必要
- `ItemDatabase` がTSVを読む: TSVを読む中心は `GameDataRegistry`
- HPが増えないならInventoryが悪い: 回復処理は `ItemEffectManager` と `Stats` 側
- 装備効果は全部 `ItemEffectManager` で実行される: パッシブは `Unit`、攻撃効果は `CombatManager`
- その場で見えたpickupは保存済み: map再訪やsave/loadはWorldState保存経路を見る
## 13. Codexへ依頼する時の書き方
```text
症状: healing_potionを使ってもHPが増えません。
期待: HPが30増え、itemが1個減る。
実際: itemは減るがHPが増えない。
見たID: healing_potion / healing_potion_restore_hp
関連docs: docs/learning/item_use_flow.md
変更範囲: docs確認とGDScript調査のみ。まだ修正しない。
```
## 14. このページでは扱わない
- 個別機能の完全な実装解説
- 全debug flag一覧
- Godotエディタ上の詳細操作
- 自動テスト設計
- save fileの中身の完全解説
- 新しいeffect typeの実装手順
新しいデータや効果を追加する判断は、[adding_new_data_or_effect_type](adding_new_data_or_effect_type.md) を読みます。
## 15. 詳細docs
- [start_here](start_here.md)
- [excel_to_game_flow](excel_to_game_flow.md)
- [database_and_manager_roles](database_and_manager_roles.md)
- [item_use_flow](item_use_flow.md)
- [equipment_passive_flow](equipment_passive_flow.md)
- [equipment_attack_effect_flow](equipment_attack_effect_flow.md)
- [combat_damage_death_flow](combat_damage_death_flow.md)
- [death_drop_flow](death_drop_flow.md)
- [debug_settings_deep_dive](../systems/debug_settings_deep_dive.md)
- [debug_output_normalization_audit](../backlog/debug_output_normalization_audit.md)
- [game_data_registry_loader_map](../systems/data/game_data_registry_loader_map.md)
## 16. 理解度チェック
1. 不具合調査で最初にやることは、全コードを読むことですか。
2. Excelに書いたitemがゲームに出ない時、最初に確認する生成物は何ですか。
3. TSVにはあるがゲーム内で取れない場合、`ItemDatabase` の前に見るべき中心scriptは何ですか。
4. `DebugSettings` は不具合修正の本体ですか。
5. debug start itemが配られない時、`PlayerData.debug_start_items_applied` を見る理由は何ですか。
6. ポーションが使えるが回復しない場合、最初に見る関数はどれですか。
7. 装備攻撃効果が発動しない時、通常アイテム使用経路を見るだけで十分ですか。
8. HP0なのに死亡しない場合、`Stats` と `Unit` のどちらも見る理由は何ですか。
9. 地面pickupがmap再訪で消える場合、表示生成と何を分けて考えますか。
10. logで `not found` や `unsupported` を見つけた時、次に確認するものは何ですか。
---
## 回答例
1. 違います。まず症状を1文にし、データ / 処理 / 表示 / 保存へ仮置きします。
2. `data/master/*.tsv` です。ExcelからTSVへ出ているかを確認します。
3. `scripts/data/game_data_registry.gd` です。
4. 違います。確認用flagとdebug開始アイテムの設定場所です。
5. すでに配布済みなら再配布されないためです。
6. `ItemEffectManager._apply_restore_resource()`、次に `ItemEffectManager._apply_resource_restore()`、targetのStatsと `stats.hp` です。
7. 不十分です。装備攻撃効果は `CombatManager` 側を見ます。
8. `Stats.take_damage()` は `Stats.die()` 経由で `Unit.handle_death()` へ進み、明示的な死亡確認は `Unit.check_death()` から `Unit.handle_death()` へ進むためです。
9. WorldStateへの保存と復元です。
10. 対象ID、TSV、loader、effect_type分岐など、参照元と参照先のつながりを確認します。
## 17. このページを読んだら説明できること
- [ ] 不具合をデータ / 処理 / 表示 / 保存に分けられる
- [ ] `DebugSettings` の役割を説明できる
- [ ] GameData読み込み件数を見る意味を説明できる
- [ ] debug start itemが再配布されない理由を説明できる
- [ ] 通常アイテム、装備パッシブ、装備攻撃効果の調査入口を分けられる
- [ ] 死亡ドロップ不具合で最初に見る場所を説明できる
- [ ] map再訪で消える問題をWorldState保存として疑える
- [ ] 詳細を読むdocsを症状ごとに選べる
