# Target Item Use Flow
## 1. このページで理解すること
このページは、対象を指定して使うアイテムの処理入口です。
通常の自己使用アイテム、装備攻撃効果、装備パッシブ、AIのitem使用は扱いません。
読んだあとに、次を関数名つきで説明できる状態を目指します。
- 通常自己使用と対象指定使用の入口の違い
- `user` と `target` の違い
- `CombatManager` が関わる理由
- 対象、射程、target flags、命中判定
- `ItemEffectManager` へ渡すまでの流れ
- 成功時のitem消費
- miss時に消費されるか
- 対象指定アイテムが使えない時の確認順

## 2. 最初に全体像
対象指定アイテムの大まかな地図です。
```text
hotbarで対象指定itemを選択
↓ target mode
↓ CombatManager.can_use_selected_target_item()
↓ target flags / range / Stats確認
↓ CombatManager.perform_selected_target_item_use()
↓ 必要なら _roll_target_item_hit()
↓ _consume_selected_target_item()
↓ ItemEffectManager.apply_item_effect(user, target, item_data)
↓ 効果適用
↓ HUD更新、target mode更新
```
通常自己使用では `Inventory.use_item_at()` が入口でした。
対象指定では、target選択と射程判定が必要なので `CombatManager` が入口になります。
現行コードでは、命中判定の後、効果適用前に消費処理が呼ばれます。
そのため、missでも消費されます。

## 3. 対象スクリプト
最低限見るファイル:
- `scripts/combat/combat_manager.gd`
- `scripts/item/inventory.gd`
- `scripts/item/inventory_ui.gd`
- `scripts/item/item_effect_manager.gd`
- `scripts/item/item_database.gd`
- `scripts/controllers/player_controller.gd`
- `scripts/combat/targeting.gd`
- `scripts/core/unit.gd`
詳細docs:
- [equipment_item_effect_execution_path](../systems/equipment_item_effect_execution_path.md)
- [unit_combat_death_system_deep_dive](../systems/unit_combat_death_system_deep_dive.md)
- [script_responsibility_map](../architecture/script_responsibility_map.md)
- [Item Use Flow](item_use_flow.md)
- [Database And Manager Roles](database_and_manager_roles.md)

## 4. 通常アイテムとの比較
| 項目 | 通常自己使用 | 対象指定使用 |
| --- | --- | --- |
| 入口 | `Inventory.use_item_at()` | `CombatManager.perform_selected_target_item_use()` |
| user | 自分 | 使用者 |
| target | 通常は自分 | 選択したUnit |
| 射程 | 通常不要 | 必要 |
| target flags | 通常あまり意識しない | 必須 |
| 命中判定 | 通常不要 | user != target なら実施 |
| 消費 | 効果成功後 | 命中判定後、効果適用前 |
| 失敗時 | 多くは減らない | missでも消費される |

## 5. Unitとhotbar
対象指定アイテムは、現行コードでは選択中hotbarから取られます。
`Unit.get_selected_target_item_data()` は、選択hotbar entryを見て item_id を取り、`ItemDatabase.get_item_resource()` で item data を取得します。
装備なら対象指定itemとして扱いません。
`ItemData` が `can_throw_to_target()` または `can_use_on_other_unit()` を満たす場合に対象指定itemになります。
この判定は `usable` 単体ではなく、主に `use_flags` と `target_flags` を見ます。
射程は現行 `items.tsv` の列ではなく、`Unit` の `target_item_use_min_range` / `target_item_use_max_range` を使います。
初期値は min 1、max 5 です。

## 6. CombatManager
対象ファイル: `scripts/combat/combat_manager.gd`
中心関数:
- `can_use_selected_target_item()`
- `perform_selected_target_item_use()`
- `_roll_target_item_hit()`
- `_consume_selected_target_item()`
`can_use_selected_target_item()` は実行前のguardです。
確認すること:
- user / target がある
- 両方に `Stats` がある
- user / target の HP が残っている
- user が行動不能でない
- 選択中target itemがある
- effectがある
- target flagsに合う
- 射程内である
ここを通ったら、実行側の `perform_selected_target_item_use()` に進みます。

## 7. 実行と消費
`perform_selected_target_item_use()` は、もう一度 `can_use_selected_target_item()` を通してから実行します。
現行順序:
- item_data を取得
- item名を決める
- user != target なら `_roll_target_item_hit()`
- `_consume_selected_target_item()`
- missならログ、HUD更新、消費結果を返す
- hitなら `ItemEffectManager.apply_item_effect(user, target, item_data)`
- 成功時は新規runtimeの同action tickをskip設定
- 必要ならsleep解除
- HUD更新
重要: 消費は `ItemEffectManager` 呼び出し前です。
missでも `_consume_selected_target_item()` はすでに呼ばれています。

## 8. target flagsと射程
対象TSV: `data/master/items.tsv`
現行列:
- `target_flags`
`ItemData.ItemTargetFlag` には、self、ally、enemy、neutral のような対象種別があります。
`CombatManager._is_target_allowed_for_item()` は、targetがuser自身か、敵対か、friendlyか、中立かを見て `item_data.has_target_flag()` を確認します。
射程は `CombatManager._is_target_in_selected_item_range()` が見ます。
user自身への使用は距離0として射程内扱いです。
他Unitへ使う場合は `Targeting.get_distance_between_units()` と `Unit.get_target_item_use_min_range()` / `get_target_item_use_max_range()` を使います。

## 9. 命中判定
対象関数: `_roll_target_item_hit()`
user と target が違う場合だけ命中判定します。
見る値:
- user の `get_total_accuracy()`
- target の `get_total_evasion()`
- user と target の luck
最終的に `hit_chance` を 0.05〜0.95 に clamp し、`randf() <= hit_chance` で判定します。
miss時は効果を適用せず、ログとHUD更新をして終了します。
現行コードでは、miss時も消費済みです。

## 10. 具体例: `fire_bottle`
現行TSVから `fire_bottle` を例にします。
確認した内容:
- `items.tsv`: `fire_bottle` は consumable、usable=true、target_flags=5
- `item_effect_links.tsv`: `fire_bottle -> fire_bottle_burning`
- `item_effects.tsv`: 対象へ burning を付与する効果
流れ:
```text
fire_bottle をhotbarで選択
↓ target modeで敵を選ぶ
↓ can_use_selected_target_item()
↓ target_flags と射程を確認
↓ _roll_target_item_hit()
↓ hotbar itemを消費
↓ ItemEffectManager.apply_item_effect(user, target, item_data)
↓ target に効果
```
適切な既存データがない場合は架空例を作らない方針ですが、`fire_bottle` は現行TSVに存在します。

## 11. 実コード
### CombatManager: guard
対象: `scripts/combat/combat_manager.gd` / 関数: `can_use_selected_target_item()` / 理由: 実行前確認を見るため。
```gdscript
func can_use_selected_target_item(user, target) -> bool:
	if user == null or target == null:
		return false
	if not user.has_node("Stats"):
		return false
	if not target.has_node("Stats"):
		return false
```
ここで基本的な対象妥当性を確認します。
入力: user, target / 結果: 使用可能かbool / 次: itemと射程確認。

### CombatManager: 実行順序
対象: `scripts/combat/combat_manager.gd` / 関数: `perform_selected_target_item_use()` / 理由: hit判定と消費順を見るため。
```gdscript
var hit: bool = true
if user != target:
	hit = _roll_target_item_hit(user, target)
var consumed: bool = _consume_selected_target_item(user)

if not hit:
	_log_attack_message(user, target, "%s は %s を使ったが、%s は回避した" % [user.name, item_name, target.name])
```
ここで命中判定の後、効果適用前に消費します。
入力: user, target, item_data / 結果: consumed / 次: missなら終了、hitなら効果。

### CombatManager: 効果適用
対象: `scripts/combat/combat_manager.gd` / 関数: `perform_selected_target_item_use()` / 理由: userとtargetを分けて渡す場所を見るため。
```gdscript
var before_target_effect_runtimes: Array = _snapshot_target_effect_runtimes(target)
var applied: bool = ItemEffectManager.apply_item_effect(user, target, item_data)

if applied:
	_mark_new_target_effect_runtimes_to_skip_same_action(target, before_target_effect_runtimes)
```
ここで `ItemEffectManager` に user、target、item_data を渡します。
入力: user, target, item_data / 結果: applied / 次: runtime調整、ログ。

### CombatManager: 消費
対象: `scripts/combat/combat_manager.gd` / 関数: `_consume_selected_target_item()` / 理由: 実際の消費先を見るため。
```gdscript
if user.has_method("consume_selected_hotbar_target_item"):
	return bool(user.consume_selected_hotbar_target_item(1))

var inv = null
if "inventory" in user:
	inv = user.inventory
```
まずUnitの消費APIを使い、なければinventoryへ進みます。
入力: user / 結果: 消費できたかbool / 次: Inventory側。

### Inventory: hotbar消費
対象: `scripts/item/inventory.gd` / 関数: `consume_selected_hotbar_item_for_target_action()` / 理由: hotbar itemが減る場所を見るため。
```gdscript
var entry: Dictionary = hotbar_items[hotbar_index]
var item_id: String = _get_entry_item_id(entry)
var current_amount: int = _get_entry_amount(entry)

if item_id == "" or current_amount <= 0:
	return false
```
ここで選択hotbarのitemと個数を確認します。
入力: amount / 結果: hotbar個数減少 / 次: UI更新。

### Unit: 対象指定item取得
対象: `scripts/core/unit.gd` / 関数: `get_selected_target_item_data()` / 理由: hotbarから対象指定itemを見つける場所を見るため。
```gdscript
var entry: Dictionary = get_selected_hotbar_target_action_entry()
var item_id: String = String(entry.get("item_id", ""))
if item_id == "":
	return null

var item_resource = ItemDatabase.get_item_resource(item_id)
```
ここで選択中hotbar entryから item data を取ります。
入力: selected hotbar / 結果: `ItemData` または null / 次: CombatManager。

## 12. 成功時
```text
hotbarで対象指定itemを選ぶ
↓ target modeでtargetを選ぶ
↓ can_use_selected_target_item()
↓ target flags / range OK
↓ perform_selected_target_item_use()
↓ hit=true
↓ item消費
↓ ItemEffectManager.apply_item_effect(user, target, item_data)
↓ applied=true
↓ HUD更新、target mode更新
```
user と target が同じ場合は hit roll を省略します。
別Unitに使う場合は命中判定があります。

## 13. 失敗時
| 状況 | どこで止まるか | 消費 |
| --- | --- | --- |
| selected itemなし | `can_use_selected_target_item()` | 減らない |
| targetなし | `can_use_selected_target_item()` | 減らない |
| 射程外 | `_is_target_in_selected_item_range()` | 減らない |
| target flags不一致 | `_is_target_allowed_for_item()` | 減らない |
| use_flags/effectなし | guardまたはitem_data確認 | 減らない |
| miss | `perform_selected_target_item_use()` | 減る |
| ItemEffectManager失敗 | 効果適用後 | 現行では消費済み |
| 消費処理失敗 | `_consume_selected_target_item()` | 効果は進む可能性があるため要確認 |

## 14. デバッグ
| 症状 | 最初に見る場所 | 次に見る場所 | 理由 |
| --- | --- | --- | --- |
| target modeにならない | `Unit.get_selected_target_item_data()` | hotbar entry / `target_flags` | 対象指定itemとして認識されているか見るため |
| targetをクリックしても使えない | `can_use_selected_target_item()` | range / target flags | guardで止まる条件を見るため |
| 射程内なのに使えない | `_is_target_in_selected_item_range()` | `Unit.get_target_item_use_*` | 現行射程はUnit側の共通値だから |
| missしかしない | `_roll_target_item_hit()` | accuracy / evasion / luck | 命中計算を見るため |
| 効果は出るがitemが減らない | `_consume_selected_target_item()` | Inventory hotbar消費 | 消費APIを確認するため |
| itemは減るが効果が出ない | `ItemEffectManager.apply_item_effect()` | effect link / effect type | 消費後の効果適用を見るため |
| 自分ではなく別Unitに効果が出る | `perform_selected_target_item_use()` | user/target引数 | targetに渡す設計を確認するため |
| 使用後もtarget modeが残る | `PlayerController` | UI更新処理 | 実行後の表示状態を見るため |

## 15. よくある勘違い
- 通常アイテムと同じ `Inventory.use_item_at()` だけで完結する: 違います。
- user と target は常に同じ: 違います。対象指定では分かれます。
- `ItemEffectManager` が射程判定する: 違います。`CombatManager` です。
- `ItemDatabase` が命中判定する: 違います。`CombatManager` です。
- missなら必ず消費されない: 現行コードではmissでも消費されます。
- `CombatManager` がitem個数を直接保持する: 違います。消費API経由です。
- target flags はUI表示だけに使う: 違います。実行可否にも使います。

## 16. このページでは扱わない
- 通常自己使用の詳細
- 装備攻撃効果
- 装備パッシブ
- AIによるitem使用
- 全target flagsの詳細
- 全effect_type
- 死亡処理の詳細
- Save/Load

## 17. 理解度チェック
1. 対象指定itemの実行入口はどの関数か。
2. 実行前guardはどの関数か。
3. user と target は何が違うか。
4. 射程判定はどのファイルのどの関数を見るか。
5. target flags不一致はどこで判定されるか。
6. user != target の時、命中判定はどの関数か。
7. 現行コードではmiss時にitemは消費されるか。
8. 効果適用はどの関数に渡されるか。
9. hotbar itemを減らすInventory関数は何か。
10. target modeにならない時、最初に見るUnit関数は何か。
---
## 回答例
1. `CombatManager.perform_selected_target_item_use()`。
2. `CombatManager.can_use_selected_target_item()`。
3. userは使用者、targetは効果対象。
4. `combat_manager.gd` の `_is_target_in_selected_item_range()`。
5. `_is_target_allowed_for_item()`。
6. `_roll_target_item_hit()`。
7. 消費される。命中判定後、効果適用前に消費するため。
8. `ItemEffectManager.apply_item_effect(user, target, item_data)`。
9. `consume_selected_hotbar_item_for_target_action()`。
10. `get_selected_target_item_data()`。

## 18. 自己確認チェックリスト
- [ ] 通常自己使用と対象指定使用の入口の違いを説明できる。
- [ ] user と target の違いを説明できる。
- [ ] `CombatManager` が射程、target flags、命中を確認すると説明できる。
- [ ] `ItemEffectManager` は効果適用担当だと説明できる。
- [ ] 現行コードではmissでも消費されると説明できる。
- [ ] hotbar消費の入口を説明できる。
- [ ] target mode不具合時にUnit、CombatManager、UIを分けて確認できる。
