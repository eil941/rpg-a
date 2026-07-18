# Unit / Combat / Death System Deep Dive

Unit、Stats、Combat、ItemEffect、Death Drop は密につながっています。ここではHPを減らす各経路が、最終的に共通の死亡処理へ到達するかを中心に整理します。

`Unit.gd` 全体を lifecycle別に読む入口は [unit_lifecycle_deep_dive.md](../unit_lifecycle_deep_dive.md) を参照してください。

HP0へ到達する各入口、`handle_death()`、death drop、WorldState更新だけを追う場合は [death_path_diagram.md](death_path_diagram.md) を参照してください。

## 関連スクリプトと役割

| Script | 役割 |
| --- | --- |
| `scripts/core/unit.gd` | Unit共通本体。移動、装備、initial inventory、効果、死亡、死亡drop、save/load。 |
| `scripts/core/stats.gd` | HP/MP/攻撃/防御などの基礎・派生値、`take_damage()`、`die()`。 |
| `scripts/combat/combat_manager.gd` | 通常攻撃、target item、装備攻撃効果、戦闘後処理。 |
| `scripts/combat/damage_calculator.gd` | 命中、crit、防御、属性/タイプなどのダメージ計算。 |
| `scripts/item/item_effect_manager.gd` | アイテム効果実行。回復、状態異常、modifier、damageなど。 |
| `scripts/item/unit_effect_runtime.gd` | runtime status/modifier、tick、duration、save data。 |
| `scripts/item/item_drop_helper.gd` | 死亡時や手動dropでworld pickupを配置。 |
| [death_drop_spec.md](death_drop_spec.md) | 死亡時ドロップの正式仕様。 |

## Unitの主な役割

- Unit種別、ID、faction、race、element、AI/Controllerを持ちます。
- `Inventory`、`Stats`、`Skills` と連携します。
- `apply_enemy_data()` / `apply_npc_data()` でTSV由来の設定を反映します。
- `apply_initial_inventory_from_data()` でspawn時所持品を生成します。
- `get_stats_data()` / `apply_stats_data()` で保存・復元します。
- `handle_death()` で死亡処理と死亡時dropを行います。
- `death_handled` で二重死亡処理を防ぎます。

## Statsの役割

- HP/MP/攻撃/防御/速度などの基礎値を保持します。
- `take_damage(amount)` でHPを減らし、0以下で `die()` を呼びます。
- `die()` は親Unitの `handle_death()` を呼びます。
- `Unit.check_death()` もHP0以下を検出して `handle_death()` へ進みます。

## CombatManagerの役割

- `perform_attack()` が通常攻撃の中心です。
- `can_attack()` で攻撃可能性を確認します。
- `DamageCalculator.calculate_damage()` を使ってダメージを決めます。
- 命中後に `target.stats.take_damage(damage)` を呼びます。
- 攻撃命中後に装備攻撃効果を `_apply_equipment_attack_effects()` で処理します。
- 装備攻撃効果は `deal_damage`、`apply_status`、`restore_resource` に分離されています。

## ItemEffectManager / UnitEffectRuntime

- `ItemEffectManager` は item use / target item use のeffectを実行します。
- `deal_damage` effectはtargetのHPを減らします。
- `apply_status` / `apply_modifier` は `UnitEffectRuntime` としてUnitへ乗ることがあります。
- `UnitEffectRuntime` のtick damageやoffscreen elapsed damageも、最終的に死亡判定へつなげる必要があります。

## ダメージ経路一覧

| ダメージ経路 | 入口 | HPを減らす場所 | 死亡判定 | death dropへ到達するか | 注意 |
| --- | --- | --- | --- | --- | --- |
| 通常攻撃 | `CombatManager.perform_attack()` | `target.stats.take_damage(damage)` | `Stats.die()` -> `Unit.handle_death()` | 到達する | 装備攻撃効果との順序に注意。 |
| bump attack | Player/AI controllerからCombatManager | `Stats.take_damage()` | 同上 | 到達する | `can_attack()` の条件を共有。 |
| item `deal_damage` | `ItemEffectManager.apply_single_effect()` | `Stats.take_damage()` またはfallback後 `Unit.check_death()` | `Stats.die()` または `Unit.check_death()` | 到達する | 直接HP変更時は必ずcheck_deathが必要。 |
| 装備攻撃 `deal_damage` | `CombatManager._apply_equipment_attack_deal_damage()` | `target.stats.take_damage(extra_damage)` | `Stats.die()` | 到達する | target死亡済みならskip。 |
| 装備攻撃 `apply_status` | `CombatManager._apply_equipment_attack_apply_status()` | 直接は減らさない | 後続tickで死亡する可能性 | tick経由で到達 | target死亡済みならskip。 |
| 装備攻撃 `restore_resource` | `CombatManager._apply_equipment_attack_restore_resource()` | targetではなくattackerを回復 | 通常は死亡判定なし | target死亡済みでも発生可 | on-hit reward仕様。attacker死亡済みならskip。 |
| status tick damage | `UnitEffectRuntime` / Unit tick処理 | `Stats.take_damage()` またはHP直接変更 | `Stats.die()` / `Unit.check_death()` | 到達する | tick/offscreen経路の二重処理に注意。 |
| starvation等 | Unitの状態処理 | `Stats.take_damage()` またはHP直接変更 | `Unit.check_death("starvation")` 等 | 到達する | combat外HP減少も共通死亡へ流す。 |
| load時HP0 | `Unit.apply_stats_data()` 後 | HPは保存値 | `Unit.check_death("load")` | 到達する | load直後の死亡処理重複に注意。 |

## 通常攻撃の流れ

1. Controllerが攻撃入力またはAI攻撃を決めます。
2. `CombatManager.perform_attack(attacker, target)`。
3. `can_attack()` で有効性を確認します。
4. `DamageCalculator.calculate_damage()`。
5. 命中すれば `target.stats.take_damage(damage)`。
6. 攻撃命中後に `_apply_equipment_attack_effects()`。
7. HP0以下なら `Stats.die()` / `Unit.check_death()` から `Unit.handle_death()`。

## アイテムダメージの流れ

1. Inventoryやhotbarからitem使用。
2. `ItemEffectManager.apply_item_effects()`。
3. `ItemEffectData.EffectType.DEAL_DAMAGE` をdispatch。
4. targetの `Stats.take_damage()` またはfallbackでHP変更。
5. fallbackの場合は `Unit.check_death()` が必要です。

## 装備攻撃効果の流れ

1. 通常攻撃が命中します。
2. `Unit.get_equipped_attack_effects()` で装備中itemの攻撃時効果候補を取得します。
3. `_should_apply_equipment_attack_effect()` で `trigger_chance` 判定します。
4. effect typeごとにhelperへdispatchします。
5. `deal_damage` は追加ダメージ、`apply_status` はtargetへ状態付与、`restore_resource` はattackerを回復します。

## 死亡判定の共通経路

基本は以下のどちらかです。

```text
Stats.take_damage()
-> Stats.die()
-> Unit.handle_death()
```

または、

```text
HPを直接変更
-> Unit.check_death(cause)
-> Unit.handle_death()
```

`Unit.handle_death()` は `death_handled` を最初に確認します。これにより、通常攻撃、追加ダメージ、status tick、loadなど複数経路から呼ばれても死亡dropが二重に出ません。

## Death Drop

正式仕様は [death_drop_spec.md](death_drop_spec.md) と一致します。

| flag | 挙動 |
| --- | --- |
| `drop_inventory_on_death=false` | bag / hotbar / equipment をすべて落とさない |
| `drop_inventory_on_death=true`, `drop_equipped_items_on_death=false` | bag / hotbar のみ落とす |
| `drop_inventory_on_death=true`, `drop_equipped_items_on_death=true` | bag / hotbar / equipment を落とす |

対象:

- inventory bag entries
- hotbar entries
- equipped entries。ただし `drop_equipped_items_on_death=true` の時だけ

`death_inventory_drop_radius` はdrop配置範囲で、runtimeで最低1にclampされます。

## initial_inventoryを死亡時に再抽選しない理由

- `initial_inventory_entries.tsv` はUnit生成時に本体inventoryへ入る候補です。
- 死亡時に再抽選すると、生前に持っていないitemが死亡時だけ出ることになります。
- 現在の仕様は「Unitが実際に持っているものを落とす」です。
- drop-only reward が必要になるまでは `drop_tables.tsv` を作らず、initial inventory と death drop を分けません。

## 戦闘・効果・死亡を変更するときの確認項目

- HPを減らす全経路が `Stats.take_damage()` または `Unit.check_death()` に到達するか
- `death_handled` により二重死亡処理が起きないか
- 通常攻撃で死亡する場合
- item damageで死亡する場合
- 装備攻撃追加ダメージで死亡する場合
- status tick/offscreen damageで死亡する場合
- target死亡済み時に装備 `deal_damage` / `apply_status` がskipされるか
- target死亡済みでも `restore_resource` が仕様通りon-hit rewardとして発生するか
- death drop対象がbag/hotbar/equipment設定通りか
- `instance_data` 付き装備がdrop後も保持されるか
- `initial_inventory_entries.tsv` を死亡時に読みに行っていないか
