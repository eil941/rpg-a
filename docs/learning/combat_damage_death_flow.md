# Combat Damage Death Flow
## 1. このページで理解すること
このページは、通常攻撃が成立してから、ダメージ計算、HP変更、死亡処理へ進む流れを追う入口です。
死亡時ドロップの詳細は扱いません。
読んだあとに、次を関数名つきで説明できる状態を目指します。
- 通常攻撃の入口
- 命中とダメージ計算の担当
- HPを減らす担当
- HP0の判定
- `Stats` と `Unit` の死亡責務の違い
- `check_death()` と `handle_death()` の関係
- 二重死亡を防ぐ `death_handled`
- item damage と tick damage も死亡処理へつながること

## 2. 最初に全体像
これは最初に把握するための地図です。死亡時ドロップや保存の詳細は後続docsに任せます。
```text
CombatManager.perform_attack()
↓ DamageCalculator.calculate_damage()
↓ target.stats.take_damage()
↓ Stats が hp を減らす
↓ hp <= 0 なら Stats.die()
↓ Unit.handle_death()
↓ death_handled guard
↓ 死亡状態、通知、drop入口
```
注意点があります。
通常攻撃では `perform_attack()` の中でも、通常ダメージ後に `target.check_death("attack")` が呼ばれます。
一方、`Stats.take_damage()` も HP0 で `die()` を呼び、`die()` は親Unitの `handle_death()` を呼びます。
そのため、二重処理を防ぐ中心が `Unit.death_handled` です。

## 3. 対象スクリプト
最低限見るファイル:
- `scripts/combat/combat_manager.gd`
- `scripts/combat/damage_calculator.gd`
- `scripts/core/stats.gd`
- `scripts/core/unit.gd`
- `scripts/item/item_effect_manager.gd`
- `scripts/item/unit_effect_runtime.gd`
詳細docs:
- [unit_combat_death_system_deep_dive](../systems/unit_combat_death_system_deep_dive.md)
- [death_path_diagram](../systems/death_path_diagram.md)
- [damage_system_notes](../systems/damage_system_notes.md)
- [script_responsibility_map](../architecture/script_responsibility_map.md)
- [Equipment Attack Effect Flow](equipment_attack_effect_flow.md)
- [Database And Manager Roles](database_and_manager_roles.md)

## 4. CombatManager
対象ファイル: `scripts/combat/combat_manager.gd`
通常攻撃の入口は `perform_attack(attacker, target, require_hostile=true)` です。
ここでやること:
- `can_attack()` で攻撃可能か確認
- attacker と target の向きや敵対化を処理
- `_build_normal_attack_data()` を作る
- `DamageCalculator.calculate_damage()` を呼ぶ
- miss ならログとHUD更新で終了
- hit なら `target.stats.take_damage(damage)`
- 装備攻撃効果を処理
- `target.check_death("attack")` を呼ぶ
`CombatManager` は HP を保持しません。
攻撃行動の入口と、どの順番で処理を呼ぶかを管理します。

## 5. DamageCalculator
対象ファイル: `scripts/combat/damage_calculator.gd`
中心関数: `calculate_damage()`
`DamageCalculator` は HP を直接変えません。
attacker、target、attack_data を受け取り、命中、critical、防御、属性、damage type を見て結果Dictionaryを返します。
主な結果:
- `hit`
- `final_damage`
- `is_critical`
- missやinvalidの理由
HPを減らすのは `Stats.take_damage()` です。
ここを混同すると、「計算は正しいのにHPが減らない」不具合の調査順を間違えます。

## 6. Stats
対象ファイル: `scripts/core/stats.gd`
中心関数:
- `take_damage()`
- `die()`
`Stats` は HP などの数値を持つ場所です。
`take_damage()` は受け取った damage を0以上にし、`hp` を減らします。
HPが0以下なら `hp=0` にして `die()` を呼びます。
`die()` は親の `Unit` を探し、`handle_death()` があれば呼びます。
死亡時ドロップそのものは `Stats` の責務ではありません。

## 7. Unit
対象ファイル: `scripts/core/unit.gd`
中心関数:
- `check_death()`
- `handle_death()`
`Unit` はキャラクター全体を管理します。
`check_death()` は `stats.hp <= 0` かを確認し、0以下なら `handle_death(cause)` を呼びます。
`handle_death()` は死亡処理本体です。
`death_handled` が true なら即returnし、同じUnitの死亡処理が2回走るのを防ぎます。
このページでは drop の詳細は扱いませんが、現行コードでは `handle_death()` の中に drop 入口があります。

## 8. 複数のダメージ入口
死亡処理へつながる入口は通常攻撃だけではありません。
- 通常攻撃: `CombatManager.perform_attack()` から `Stats.take_damage()`
- item effect の damage: `ItemEffectManager._apply_direct_deal_damage()` など
- status runtime の tick damage: `Unit._apply_runtime_damage()`
どの入口でも、最終的に HP が0以下になったら `Unit` 側の死亡処理につながる必要があります。
入口が複数あるため、`death_handled` が重要です。

## 9. 実コード
### CombatManager: 通常ダメージ
対象: `scripts/combat/combat_manager.gd` / 関数: `perform_attack()` / 理由: damage後の順番を見るため。
```gdscript
var damage = int(result["final_damage"])
if damage < 1:
	damage = 1

target.stats.take_damage(damage)
_apply_equipment_attack_effects(attacker, target)

var target_died: bool = false
```
ここでは通常ダメージを入れ、装備攻撃効果へ進み、その後死亡確認へ進みます。
入力: attacker, target, damage / 結果: target HP減少 / 次: 装備効果、死亡確認。

### DamageCalculator: 入口
対象: `scripts/combat/damage_calculator.gd` / 関数: `calculate_damage()` / 理由: HPを変えず結果を返す役を見るため。
```gdscript
func calculate_damage(attacker, target, attack_data: Dictionary = {}) -> Dictionary:
	var damage_type := _normalize_damage_type(str(attack_data.get("damage_type", DEFAULT_DAMAGE_TYPE)))

	if attacker == null or target == null:
		return _make_result(false, false, false, 0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, "invalid_target", damage_type)
```
ここでは attacker / target の妥当性を見て、結果Dictionaryを作り始めます。
入力: attacker, target, attack_data / 結果: hitやdamage情報 / 次: `CombatManager`。

### Stats: HP変更
対象: `scripts/core/stats.gd` / 関数: `take_damage()` / 理由: HPを実際に減らす場所を見るため。
```gdscript
func take_damage(amount: int) -> void:
	var final_damage: int = max(0, amount)

	refresh_derived_max_hp(false)

	hp -= final_damage
	print("ダメージ: ", final_damage, " / HP: ", hp, "/", max_hp)
```
ここで HP が減ります。
入力: damage量 / 結果: hp減少 / 次: HP0なら `die()`。

### Stats: 死亡通知
対象: `scripts/core/stats.gd` / 関数: `die()` / 理由: StatsからUnitへ渡る場所を見るため。
```gdscript
func die() -> void:
	print("死亡しました")

	var unit = get_parent()
	if unit != null and unit.has_method("handle_death"):
		unit.handle_death()
```
ここでは親Unitの `handle_death()` を呼びます。
入力: なし / 結果: Unit死亡処理へ通知 / 次: `Unit.handle_death()`。

### Unit: check_death
対象: `scripts/core/unit.gd` / 関数: `check_death()` / 理由: 明示的な死亡確認を見るため。
```gdscript
if int(stats.hp) > 0:
	return false

handle_death(cause)
return true
```
ここではHPが残っていれば false、0以下なら死亡処理へ進みます。
入力: cause / 結果: 死亡したかbool / 次: `handle_death()`。

### Unit: 二重死亡guard
対象: `scripts/core/unit.gd` / 関数: `handle_death()` / 理由: 二重死亡防止を見るため。
```gdscript
func handle_death(cause: String = "") -> void:
	if death_handled:
		return

	death_handled = true
```
ここで死亡処理が2回走るのを止めます。
入力: cause / 結果: 初回だけ死亡処理継続 / 次: 通知やdrop入口。

## 10. 成功時の時系列
通常攻撃が命中して死亡する場合:
```text
perform_attack()
↓ can_attack()
↓ DamageCalculator.calculate_damage()
↓ hit=true
↓ target.stats.take_damage(damage)
↓ Stats.hp が減る
↓ hp<=0 なら Stats.die()
↓ Unit.handle_death()
↓ death_handled=true
↓ perform_attack() 側の check_death() は二重処理されない
```
通常攻撃が命中してもHPが残る場合:
```text
take_damage()
↓ hp > 0
↓ die() へ進まない
↓ check_death() も false
↓ 戦闘継続
```

## 11. 失敗時の終了経路
| 状況 | どこで止まるか | 結果 |
| --- | --- | --- |
| attackerまたはtargetが無効 | `can_attack()` | 攻撃しない |
| 攻撃不可 | `can_attack()` | damage計算しない |
| miss | `perform_attack()` | HPは減らない |
| damageが1未満 | `perform_attack()` で1へ補正 | 最低1damage |
| HPが残る | `Stats.take_damage()` 後 | 死亡しない |
| すでに死亡処理済み | `Unit.handle_death()` | 二重処理しない |
| 死亡対象ではない | `check_death()` | false |

## 12. デバッグ
| 症状 | 最初に見る場所 | 次に見る場所 | 理由 |
| --- | --- | --- | --- |
| 攻撃できない | `CombatManager.can_attack()` | targetのStats、敵対、射程 | 攻撃前guardを見るため |
| 攻撃は当たるがHPが減らない | `perform_attack()` の `take_damage()` | `Stats.take_damage()` | 計算結果からHP変更へ渡るかを見るため |
| damage値がおかしい | `DamageCalculator.calculate_damage()` | attacker/targetの合計stat | 計算担当はここだから |
| HP0なのに死亡しない | `Stats.die()` | `Unit.check_death()` / `handle_death()` | HP0からUnitへ渡るかを見るため |
| 死亡処理が2回起きる | `Unit.death_handled` | 複数damage入口 | 二重guardが効くかを見るため |
| 通常攻撃では死亡するがitem damageでは死亡しない | `ItemEffectManager._apply_direct_deal_damage()` | `target.check_death()` | item damage側の死亡確認を見るため |
| tick damageで死亡しない | `Unit._apply_runtime_damage()` | `check_death("status_*")` | 継続damage入口を見るため |

## 13. よくある勘違い
- `DamageCalculator` がHPを減らす: 違います。計算結果を返します。
- `CombatManager` がHPを保持する: 違います。HPは `Stats` です。
- `Stats` がdeath dropまで全部行う: 違います。Unitへ通知します。
- `Unit` がdamage計算を行う: 違います。通常攻撃計算は `DamageCalculator` です。
- 死亡入口は1つだけ: 違います。通常攻撃、item damage、tick damageがあります。
- `check_death()` を何度呼んでも安全とは限らない: 二重処理を防ぐのは `death_handled` です。

## 14. このページでは扱わない
- death drop の詳細
- WorldState保存の詳細
- 装備パッシブ
- 対象指定アイテム
- Save/Load
- 復活処理
- プレイヤー死亡メニューの詳細

## 15. 理解度チェック
1. 通常攻撃の入口関数は何か。
2. HPを直接減らす関数は何か。
3. `DamageCalculator` はHPを変更するか。
4. `Stats.die()` は次に何を呼ぶか。
5. `Unit.check_death()` は何を見て true を返すか。
6. 二重死亡を防ぐ変数は何か。
7. 通常攻撃以外のdamage入口を2つ挙げる。
8. HPが0なのに死亡しない時、最初に見る場所はどこか。
9. damage値がおかしい時、最初に見る場所はどこか。
10. death dropの詳細はこのページで扱うか。
---
## 回答例
1. `CombatManager.perform_attack()`。
2. `Stats.take_damage()`。
3. 変更しない。結果Dictionaryを返す。
4. 親Unitの `handle_death()`。
5. `stats.hp <= 0`。
6. `death_handled`。
7. item effect の `deal_damage`、status runtime の tick damage。
8. `Stats.die()` と `Unit.handle_death()`。
9. `DamageCalculator.calculate_damage()`。
10. 扱わない。後続のdeath/drop docsで読む。

## 16. 自己確認チェックリスト
- [ ] 通常攻撃は `perform_attack()` から始まる。
- [ ] damage計算は `DamageCalculator` が行う。
- [ ] HP変更は `Stats.take_damage()` が行う。
- [ ] HP0で `Stats.die()` から `Unit.handle_death()` へ進む。
- [ ] `check_death()` は明示的な死亡確認入口である。
- [ ] `death_handled` が二重死亡を防ぐ。
- [ ] item damage と tick damage も死亡処理へつながる。
- [ ] death drop の詳細はこのページの対象外である。
