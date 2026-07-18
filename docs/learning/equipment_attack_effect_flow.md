# Equipment Attack Effect Flow
## 1. このページで理解すること
このページは、武器で通常攻撃した時に、装備に付いた攻撃時効果がどう発動するかを追う入口です。
対象指定アイテム、通常アイテム、装備パッシブ、死亡処理、ドロップは扱いません。
読んだあとに、次を関数名つきで説明できる状態を目指します。
- 武器で攻撃した時の処理順
- `CombatManager` が担当する範囲
- `Unit` が装備効果をどう集めて渡すか
- `ItemEffectManager` との違い
- `trigger_chance` の役割
- `effect_type` ごとの分岐
- 装備攻撃効果のデバッグ方法
前提として、[Start Here](start_here.md)、[Database And Manager Roles](database_and_manager_roles.md)、[Excel To Game Flow](excel_to_game_flow.md)、[Item Use Flow](item_use_flow.md) を読んでいる想定です。

## 2. 最初に全体像
装備攻撃効果の大まかな地図です。厳密な全分岐ではなく、最初に把握するための流れとして見てください。
```text
通常攻撃
↓ CombatManager.perform_attack()
↓ DamageCalculator.calculate_damage()
↓ target.stats.take_damage()
↓ CombatManager._apply_equipment_attack_effects()
↓ attacker.get_equipped_attack_effects()
↓ Unit.get_equipped_item_effects()
↓ ItemEffectData
↓ trigger_chance 判定
↓ effect_type ごとの処理
↓ HUD更新、攻撃ログ、戦闘処理へ戻る
```
通常アイテムでは `Inventory` が `ItemEffectManager.apply_item_effect()` を呼びました。
装備攻撃効果では、通常攻撃の入口である `CombatManager` が中心です。
`restore_resource` の時だけ、既存の回復処理を使うために `ItemEffectManager._apply_restore_resource()` を呼びます。

## 3. CombatManager
対象ファイル: `scripts/combat/combat_manager.gd`
今回見る中心関数は `perform_attack()` と `_apply_equipment_attack_effects()` です。
`perform_attack()` は attacker と target を受け取り、攻撃可能か、命中したか、ダメージはいくつかを処理します。
ダメージ後に装備攻撃効果を呼ぶ理由は、「攻撃命中時の追加効果」だからです。
現行コードでは、通常攻撃のダメージを `target.stats.take_damage(damage)` で入れた後、`_apply_equipment_attack_effects(attacker, target)` に進みます。

### `_apply_equipment_attack_effects()`
この関数は、attacker から攻撃時に使える装備効果を取り出し、1つずつ処理します。
主な流れ:
- attacker / target が null なら終了
- attacker が `get_equipped_attack_effects()` を持たなければ終了
- `effect_entries` を取得
- 各 entry から `ItemEffectData` を取得
- `trigger_chance` を判定
- 成功した effect だけ `effect_type` で分岐
- `DEAL_DAMAGE`、`APPLY_STATUS`、`RESTORE_RESOURCE` を処理
- 未対応 type は debug skip
ここで重要なのは、`CombatManager` は装備を保持しないことです。
装備を持つのは `Unit` 側で、`CombatManager` は「攻撃の流れの中で、Unitから効果を受け取って実行する」役です。

## 4. Unit
対象ファイル: `scripts/core/unit.gd`
`Unit` はキャラクター全体を持つ本体なので、装備スロットと装備中アイテムもここからたどります。
主な関数:
- `get_equipped_item_effects()`
- `get_equipped_attack_effects()`
`get_equipped_item_effects()` は、装備中アイテムから effect entry を集めます。
entry には、slot名、item_id、元entry、equipment、effect_id、effect が入ります。
`get_equipped_attack_effects()` は、その中から攻撃時に使う候補だけを絞ります。
現行コードで攻撃候補になるのは次です。
- `DEAL_DAMAGE`
- `APPLY_STATUS`
- `RESTORE_RESOURCE`
`CombatManager` が `Unit` を見る理由は、攻撃している Unit がどの装備を持っているかを知らないと、攻撃時効果を取得できないからです。
`Unit` が渡すものは、実行済み結果ではなく、`ItemEffectData` を含む effect entry です。
効果を実行するのは `CombatManager` 側です。

## 5. `trigger_chance`
`trigger_chance` は、装備攻撃効果が発動する確率です。
TSV列:
- `data/master/item_effects.tsv` の `trigger_chance`
読み込み:
- `GameDataRegistry._build_item_effect()` で `effect.trigger_chance` に入る
- `_normalize_trigger_chance()` により 0.0〜1.0 に clamp される
空欄時:
- デフォルトは `1.0`
- つまり空欄なら基本的に毎回発動
判定タイミング:
- 通常攻撃が命中し、通常ダメージが入った後
- `_apply_equipment_attack_effects()` の各 effect ごと
成功時:
- `effect_type` の handler に進む
失敗時:
- その effect は skip
- 通常攻撃そのものは継続済みで、巻き戻らない
例:
- `sample_dud_flame_knife_fire_damage`: `trigger_chance=0`
- `sample_unstable_flame_knife_fire_damage`: `trigger_chance=0.5`
- `sample_combo_knife_fire_damage`: 空欄なので 1.0

## 6. `effect_type`
今回は `restore_resource` を詳しく扱います。
装備攻撃効果では、`restore_resource` は target ではなく attacker を回復します。
現行コードでは `_apply_equipment_attack_restore_resource(attacker, target, effect_entry, effect)` が呼ばれ、その中で `ItemEffectManager._apply_restore_resource(attacker, attacker, effect)` を呼びます。
つまり user も target も attacker です。
`sample_combo_knife_restore_hp` の場合、攻撃者の HP が 1 回復します。

簡単に見る他の type:
- `deal_damage`: target に追加ダメージを入れる。現行 handler は direct のみ対応。
- `apply_status`: target に状態異常 runtime を付与する。
- `apply_modifier`: 攻撃時効果としては現行 `CombatManager` の match 対象外。装備パッシブ側で扱うものです。

## 7. 具体例: `sample_combo_knife`
現行データから、`sample_combo_knife` を使います。
確認したTSV:
- `data/master/items.tsv`: `sample_combo_knife`、category は `equipment`、usable は `false`
- `data/master/equipment.tsv`: `sample_combo_knife`、slot は `HAND`、attack_bonus は 3
- `data/master/item_effect_links.tsv`: `sample_combo_knife_fire_damage` が order 1、`sample_combo_knife_restore_hp` が order 2
- `data/master/item_effects.tsv`: `sample_combo_knife_restore_hp` は `restore_resource`、resource は `hp`、power は 1
流れ:
```text
通常攻撃
↓ CombatManager.perform_attack()
↓ 通常ダメージ
↓ attacker.get_equipped_attack_effects()
↓ sample_combo_knife の effect取得
↓ trigger_chance 判定、空欄なので 1.0
↓ deal_damage で追加ダメージ
↓ restore_resource
↓ 攻撃者HPを1回復
```

## 8. コード引用
全文ではなく、流れを理解するための重要部分だけを引用します。
### CombatManager: `perform_attack()`
対象: `scripts/combat/combat_manager.gd` / 理由: 通常ダメージ後に装備攻撃効果へ進む場所を見るため。
```gdscript
var damage = int(result["final_damage"])
if damage < 1:
	damage = 1

target.stats.take_damage(damage)
_apply_equipment_attack_effects(attacker, target)

var target_died: bool = false
```
読む点: 命中後、通常ダメージを入れてから装備攻撃効果を呼びます。
入力: attacker, target / 結果: 通常攻撃後に装備効果へ進む / 次: `_apply_equipment_attack_effects()`

### CombatManager: `trigger_chance`
対象: `scripts/combat/combat_manager.gd` / 理由: 発動確率の判定を見るため。
```gdscript
func _get_equipment_attack_trigger_chance(effect: ItemEffectData) -> float:
	if effect == null:
		return 0.0
	return clamp(float(effect.trigger_chance), 0.0, 1.0)

func _should_apply_equipment_attack_effect(_effect_entry: Dictionary, effect: ItemEffectData) -> bool:
	var trigger_chance: float = _get_equipment_attack_trigger_chance(effect)
```
読む点: `effect.trigger_chance` を0〜1に丸めて、発動判定に使います。
入力: `ItemEffectData` / 結果: chance値 / 次: `randf()` 判定。

### CombatManager: `_apply_equipment_attack_effects()`
対象: `scripts/combat/combat_manager.gd` / 理由: Unitからeffectを取り、type分岐する場所を見るため。
```gdscript
var effect_entries: Array = attacker.get_equipped_attack_effects()
if effect_entries.is_empty():
	return 0

var total_extra_damage: int = 0

for raw_entry in effect_entries:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		continue
```
読む点: attacker の `Unit` から攻撃時効果を取得します。
入力: attacker, target / 結果: effect entry配列 / 次: 各effectの判定。

### CombatManager: `effect_type` 分岐
対象: `scripts/combat/combat_manager.gd` / 理由: どのhandlerへ進むかを見るため。
```gdscript
match effect.effect_type:
	ItemEffectData.EffectType.DEAL_DAMAGE:
		var extra_damage: int = _apply_equipment_attack_deal_damage(attacker, target, effect_entry, effect)
		total_extra_damage += extra_damage

	ItemEffectData.EffectType.APPLY_STATUS:
		_apply_equipment_attack_apply_status(attacker, target, effect_entry, effect)

	ItemEffectData.EffectType.RESTORE_RESOURCE:
```
読む点: 現行の装備攻撃効果はこのmatchで処理されます。
入力: `ItemEffectData` / 結果: handler呼び出し / 次: type別処理。

### CombatManager: `restore_resource`
対象: `scripts/combat/combat_manager.gd` / 理由: 攻撃者を回復する実装を見るため。
```gdscript
if not ItemEffectManager._apply_restore_resource(attacker, attacker, effect):
	_debug_log_equipment_attack_effect_skip(attacker, target, effect_entry, "restore_failed")
	return false

var after_value: int = before_value
if resource_name in stats:
	after_value = int(stats.get(resource_name))
```
読む点: user も target も attacker として回復処理へ渡しています。
入力: attacker, effect / 結果: 攻撃者のHPなどを回復 / 次: debug apply log。

### Unit: `get_equipped_item_effects()`
対象: `scripts/core/unit.gd` / 理由: 装備中effectを集める場所を見るため。
```gdscript
func get_equipped_item_effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var using_hotbar_override: bool = _is_using_hotbar_hand_override_slot()

	for slot_name in equipment_slot_order:
		if using_hotbar_override and (slot_name == "right_hand" or slot_name == "left_hand"):
			continue
```
読む点: 装備スロットを順に見て effect entry を集め始めます。
入力: Unitの装備状態 / 結果: effect entry配列 / 次: `get_equipped_attack_effects()`

### Unit: `get_equipped_attack_effects()`
対象: `scripts/core/unit.gd` / 理由: 攻撃時候補だけを絞る場所を見るため。
```gdscript
func get_equipped_attack_effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for effect_entry in get_equipped_item_effects():
		var effect: ItemEffectData = effect_entry.get("effect") as ItemEffectData
		if not _is_attack_equipment_effect_candidate(effect):
			continue
```
読む点: 全装備effectから、攻撃時に使えるものだけを残します。
入力: equipped item effects / 結果: attack effect entries / 次: `CombatManager`。

## 9. 成功時
`sample_combo_knife` の攻撃効果が成功する時系列です。
```text
perform_attack(attacker, target)
↓ can_attack()
↓ DamageCalculator.calculate_damage()
↓ 命中
↓ target.stats.take_damage(damage)
↓ _apply_equipment_attack_effects(attacker, target)
↓ attacker.get_equipped_attack_effects()
↓ sample_combo_knife_fire_damage / sample_combo_knife_restore_hp
↓ trigger_chance 成功
↓ deal_damage なら target に追加ダメージ
↓ restore_resource なら attacker を回復
↓ HUD更新、攻撃ログ
```
通常ダメージが先、装備攻撃効果が後です。
`restore_resource` は攻撃を受けた target ではなく、攻撃した attacker を回復します。

## 10. `trigger_chance`失敗時
判定:
- `_should_apply_equipment_attack_effect()` が `randf() <= trigger_chance` を見る
失敗:
- その effect は skip
- debug flag が有効なら `proc_failed` の skip log が出る
通常攻撃:
- すでに命中し、通常ダメージは入っています
- `trigger_chance` 失敗で通常攻撃は取り消されません
例:
- `sample_dud_flame_knife_fire_damage` は `trigger_chance=0` なので発動しません
- `sample_unstable_flame_knife_fire_damage` は `trigger_chance=0.5` なので半分程度です

## 11. デバッグ
| 症状 | 最初に見る場所 | 次に見る場所 | 理由 |
| --- | --- | --- | --- |
| 攻撃はできるが効果が出ない | `combat_manager.gd` の `_apply_equipment_attack_effects()` | `unit.gd` の `get_equipped_attack_effects()` | 攻撃後に効果取得へ進んでいるかを見るため |
| `trigger_chance`が発動しない | `item_effects.tsv` の `trigger_chance` | `_should_apply_equipment_attack_effect()` | 0、0.5、空欄などの値と判定を確認するため |
| HP吸収しない | `_apply_equipment_attack_restore_resource()` | `ItemEffectManager._apply_restore_resource()` | attacker を回復対象にしているか、Stats が取れるかを見るため |
| 装備を変えても変わらない | `unit.gd` の `get_equipped_item_effects()` | hotbar override 関連 | 実際に有効な手装備が別になっている可能性があるため |
| effectが取得できない | `item_effect_links.tsv` | `game_data_registry.gd` の `_apply_item_effect_links()` | item と effect の接続が `ItemData.effects` に入るかを見るため |

## 12. よくある勘違い
- `CombatManager` が装備を保持する: 違います。装備状態は `Unit` 側です。
- `ItemEffectManager` が通常攻撃を担当する: 違います。通常攻撃の入口は `CombatManager` です。
- `trigger_chance` は `ItemDatabase` で判定する: 違います。`CombatManager` で判定します。
- `Unit` が効果を実行する: 違います。`Unit` は effect entry を返し、実行は `CombatManager` です。
- `restore_resource` は target を回復する: 装備攻撃効果では違います。現行コードでは attacker を回復します。

## 13. このページでは扱わない
- パッシブ
- 通常アイテム
- 死亡
- ドロップ
- status の詳細
- teleport

## 14. 詳細docs
さらに詳しく確認する場合は、次を見ます。
- [equipment_item_effect_execution_path](../systems/equipment_item_effect_execution_path.md)
- [script_responsibility_map](../architecture/script_responsibility_map.md)
- [unit_combat_death_system_deep_dive](../systems/combat/unit_combat_death_system_deep_dive.md)
このページは詳細 docs を置き換えるものではありません。
まず流れをつかみ、必要になったら詳細 docs に進みます。

## 15. 理解度チェック
1. 通常攻撃の入口として最初に見る関数は何か。
2. 通常ダメージ後に呼ばれる装備攻撃効果の関数は何か。
3. `CombatManager` は装備を保持しているか。
4. `Unit.get_equipped_item_effects()` は何を集めるか。
5. `Unit.get_equipped_attack_effects()` は何を絞り込むか。
6. `trigger_chance` はどこで判定されるか。
7. `trigger_chance` が空欄の場合、基本的に何として扱われるか。
8. `trigger_chance` が失敗したら通常攻撃ダメージは取り消されるか。
9. 装備攻撃効果の `restore_resource` は誰を回復するか。
10. 効果が出ない時に最初に見る中心ファイルはどれか。
11. `sample_combo_knife` の回復effect idは何か。
12. `apply_modifier` は現行の装備攻撃効果の中心か。
---
## 回答例
1. `scripts/combat/combat_manager.gd` の `perform_attack()`。
2. `_apply_equipment_attack_effects()`。
3. 保持していない。装備状態は `Unit` 側。
4. 装備中 item の effect entry。
5. `DEAL_DAMAGE`、`APPLY_STATUS`、`RESTORE_RESOURCE` の攻撃時候補。
6. `CombatManager._should_apply_equipment_attack_effect()`。
7. 1.0。つまり基本的に毎回発動。
8. 取り消されない。通常ダメージ後に装備効果だけ skip される。
9. 攻撃者 attacker。
10. `scripts/combat/combat_manager.gd`。
11. `sample_combo_knife_restore_hp`。
12. いいえ。現行では装備パッシブ側の扱いで、攻撃時matchでは未対応です。

## 16. このページを読んだら説明できること
- [ ] 武器攻撃は `CombatManager.perform_attack()` から始まる。
- [ ] 通常ダメージ後に `_apply_equipment_attack_effects()` が呼ばれる。
- [ ] `CombatManager` は装備を保持せず、attacker の `Unit` から effect を取得する。
- [ ] `Unit.get_equipped_item_effects()` は装備中effectを集める。
- [ ] `Unit.get_equipped_attack_effects()` は攻撃時候補を絞る。
- [ ] `trigger_chance` は `CombatManager` で effect ごとに判定する。
- [ ] `trigger_chance` 失敗時も通常攻撃は継続済みで、装備効果だけ skip される。
- [ ] 装備攻撃効果の `restore_resource` は attacker を回復する。
- [ ] `ItemEffectManager` は通常攻撃の入口ではなく、restore 処理の一部で再利用される。
- [ ] 効果が出ない時は `CombatManager`、`Unit`、TSV link の順に見る。
