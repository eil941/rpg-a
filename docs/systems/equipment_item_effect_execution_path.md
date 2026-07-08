# Equipment / ItemEffect Execution Path

## 目的

このdocsは、Step 8で整備した装備効果TSV化と、既存の消耗品効果実行経路を、現状理解用に整理するための地図です。

目的は、次の3つを分けて読めるようにすることです。

- 消耗品効果: itemを使った時に `ItemEffectManager` が実行する。
- 装備パッシブ効果: Unitが装備状態を見て、ステータス合計値へ反映する。
- 装備攻撃効果: 通常攻撃命中後に `CombatManager` が装備中itemの効果を拾って実行する。

これは将来の改善案や共通化案ではありません。現状のコードとTSVがどうつながっているかを理解するためのdocsです。

## データ構造

### `items.tsv`

`items.tsv` は、消耗品と装備品を含むitemの基本情報です。

効果実行に関係する主な列:

- `item_id`: itemのID。`item_effect_links.tsv` の `item_id` と対応する。
- `category`: `consumable`, `equipment`, `material`, `misc` など。現状の列名は `item_type` ではなく `category`。
- `usable`: 通常使用できるか。`Inventory.use_item_at()` はここを見て、使用不可itemを弾く。
- `max_stack`: stack上限。
- `spawn_weight`: random spawn候補の重み。`spawn_weight <= 0` は通常ランダム生成候補から除外される。
- `use_flags`, `target_flags`: self使用、unit target使用、throw targetなどの対象判定に使われる。

`sample_*` 装備はGameData上には残っていますが、`spawn_weight=0` のため通常random spawn候補には入りません。

### `equipment.tsv`

`equipment.tsv` は、`items.tsv` 上で `category=equipment` のitemに装備固有情報を足します。

主な列:

- `item_id`: `items.tsv.item_id` と対応する。`equipment_id` という別列ではない。
- `slot_type`: `HAND`, `BODY`, `ACCESSORY` など。
- `max_hp_bonus`, `attack_bonus`, `defense_bonus`, `speed_bonus`: 装備そのものの固定bonus。
- `attack_type_id`, `attack_element`, `attack_damage_type`: 通常攻撃側の属性・タイプ。
- `attack_min_range`, `attack_max_range`: 通常攻撃射程。
- `combat_style`, `move_style`: AI用の戦闘・移動傾向。

`equipment.tsv` のbonusと、`item_effect_links.tsv` 由来の `apply_modifier` は別です。

例:

- `power_ring` は `equipment.tsv` 側で `attack_bonus=20` を持つ。
- さらに `item_effect_links.tsv` で `power_ring_attack_bonus` が紐づき、装備パッシブとして `attack +1` が追加で反映される。

### `item_effects.tsv`

`item_effects.tsv` は効果本体です。代表的な列:

- `effect_id`
- `effect_type`
- `value_mode`
- `resource_type`
- `power_min`, `power_max`
- `percent_value`
- `damage_element`, `damage_type`, `damage_mode`
- `calculated_power`, `bonus_accuracy`, `bonus_crit_rate`, `ignore_defense_rate`, `fixed_damage_bonus`
- `status_id`, `status_power`
- `modifier_kind`, `stat_name`, `stat_flat`, `stat_percent`
- `duration_type`, `duration_value`
- `teleport_mode`, `teleport_min_range`, `teleport_max_range`, `warp_point_id`
- `grant_item_id`, `grant_item_amount`, `grant_currency_amount`
- `skill_id`, `recipe_id`, `identify_all`, `document_text`, `spawn_object_id`
- `curse_status_pool`, `curse_status_power_overrides`
- `trigger_chance`

`GameDataRegistry._build_item_effect()` はこれらを `ItemEffectData` に変換します。

`trigger_chance` は `ItemEffectData` に読み込まれます。ただし現状コードで発動率として使っているのは、装備攻撃効果の `CombatManager._should_apply_equipment_attack_effect()` です。消耗品効果や装備パッシブ効果では、現状この発動率判定は行われません。

### `item_effect_links.tsv`

`item_effect_links.tsv` は、itemとeffectの接続です。

列:

- `item_id`
- `effect_id`
- `order`

重要な現行仕様:

- 消耗品効果も装備効果も `item_effect_links.tsv` を使う。
- 装備効果専用の `equipment_effect_links.tsv` は使っていない。
- `GameDataRegistry._apply_item_effect_links()` が `order` 順にlinkを並べ、該当itemの `effects` 配列へ `ItemEffectData` を入れる。
- 同じ `effects` 配列を、消耗品使用、装備パッシブ、装備攻撃効果がそれぞれ別の入口から解釈する。

そのため、同じ `effect_id` でも、どの入口から読まれるかで意味や実行タイミングが変わります。

## 読み込みの流れ

`GameDataRegistry.load_all()` の関連部分は、おおまかに次の順です。

1. `_load_items()`
2. `_load_equipment()`
3. `_load_item_effects()`
4. `_load_item_effect_links()`
5. `_apply_item_effect_links()`

`_load_equipment()` は `items.tsv` で登録済みの `ItemData` を `EquipmentData` に置き換えます。その後、`_apply_item_effect_links()` により消耗品にも装備品にも `effects` が入ります。

## 消耗品効果の実行経路

入口は主に `ItemEffectManager` です。

### 通常inventory / hotbarから使う場合

大まかな流れ:

1. `InventoryUI.use_selected_item()` が通常inventoryまたはhotbarの選択itemを使う。
2. `Inventory.use_item_at()` または `Inventory.use_hotbar_item_at()` が呼ばれる。
3. `ItemDatabase.is_usable(item_id)` で使用可能か確認する。
4. `ItemEffectManager.apply_item_effect(owner_unit, item_id)` を呼ぶ。
5. `ItemEffectManager` が `ItemDatabase.get_item_data(item_id)` から `ItemData.effects` を取得する。
6. `apply_item_effects(user, target, item_data)` が各effectを `apply_single_effect()` へ渡す。
7. 成功した場合、Inventory側がamountを1減らす。

この経路では、基本的に `target = user` です。自分に使う消耗品として扱われます。

### target itemとして使う場合

対象指定itemは `CombatManager.perform_selected_target_item_use()` から実行されます。

大まかな流れ:

1. playerがtarget itemを選択して対象Unitへ使う。
2. `CombatManager.can_use_selected_target_item()` が射程、対象可否、効果有無などを確認する。
3. 命中判定が必要な場合は `_roll_target_item_hit()` を行う。
4. `ItemEffectManager.apply_item_effect(user, target, item_data)` を呼ぶ。
5. 成功時、status runtimeの同一action tick skipなどを調整する。

この経路では、`user` と `target` が分かれます。

### `ItemEffectManager` が扱うeffect_type

`ItemEffectManager.apply_single_effect()` は、現状以下を分岐します。

- `restore_resource`
  - `target` の `stats` を見て、HPなどを回復する。
  - `value_mode=flat/percent/full` に対応している。
- `cure_status`
  - `target.remove_status_effect(status_id)` を呼ぶ。
  - `sleep` は回復対象外として扱われる。
- `apply_status`
  - `target.add_status_effect_runtime()` へ `UnitEffectRuntime` を追加する。
  - `status_id=curse` の場合は、curse poolから複数statusを選ぶ専用処理へ進む。
- `apply_modifier`
  - `target.add_status_effect_runtime()` へ modifier runtimeを追加する。
  - 消耗品の一時buff/debuffはこの経路。
- `deal_damage`
  - `damage_mode=calculated` なら `DamageCalculator` を使う。
  - それ以外はdirect damageとして `target` のHPを減らす。
  - 実行後に `target.check_death("item_effect_damage")` を呼ぶ。
- `grant_item`
  - `target.grant_items_from_effect()` または `target.grant_item_from_effect()` を呼べる場合に使う。
- `grant_currency`
  - `target.grant_currency_from_effect()` があれば使う。
- `teleport`
  - `target.apply_item_teleport_effect()` があれば使う。
- `permanent_stat_growth`
  - `target.stats` の指定statを恒久的に増やす。
- `learn_skill`
  - `target.learn_skill_from_effect()` があれば使う。
- `unlock_recipe`
  - `target.unlock_recipe_from_effect()` があれば使う。
- `identify_item`
  - `target.identify_item_from_effect()` があれば使う。
- `read_document`
  - `target.read_document_from_effect()` があれば使う。
- `spawn_object`
  - `target.spawn_object_from_effect()` があれば使う。

Inventory側は「使えるか」「消費するか」を持ち、`ItemEffectManager` は「効果を適用できるか」を持つ、という責務分担です。

## 装備パッシブ効果の実行経路

入口は `Unit.gd` です。

装備パッシブ効果は、itemを使った時に実行されません。Unitが装備中itemの `effects` を見て、ステータス合計値を計算する時に反映します。

主な関数:

- `get_equipped_item_effects()`
- `_get_total_equipment_effect_modifier(stat_name, context)`
- `_apply_equipment_effect_modifier(stat_name, base_value, min_value, context)`
- `get_total_attack()`
- `get_total_defense()`
- `get_total_max_hp()`
- `get_total_speed()`
- `get_total_accuracy()`
- `get_total_evasion()`
- `get_total_crit_rate()`

流れ:

1. `get_equipped_item_effects()` が装備slotを走査する。
2. 装備中entryから `EquipmentData` を取得する。
3. `EquipmentData.effects` に入っている `ItemEffectData` を、slot名やitem_id付きのDictionaryとして集める。
4. `_get_total_equipment_effect_modifier()` が `effect_type=apply_modifier` だけを対象にする。
5. `stat_name` が要求statと一致するものだけを合算する。
6. `modifier_kind=debuff` なら符号を反転し、`stat_flat` と `stat_percent` を合算する。
7. `_apply_equipment_effect_modifier()` がbase値にflatとpercentを適用する。

装備パッシブは基礎ステータスそのものを書き換えません。`stats.attack += 1` のような永続変更ではなく、合計値計算時に装備状態を見て反映します。

代表例:

- `sample_copper_guard_ring`
  - `sample_copper_guard_ring_defense_bonus`
  - `apply_modifier`
  - `stat_name=defense`
  - `stat_flat=1`
  - 装備中だけdefenseに反映されるサンプル。
- `power_ring`
  - `power_ring_attack_bonus`
  - `apply_modifier`
  - `stat_name=attack`
  - `stat_flat=1`
  - `equipment.tsv` の `attack_bonus=20` とは別に、item effect由来のattack +1が乗る。

DebugSettings:

- `debug_equipment_effects=true` の時、`[EquipmentPassiveEffect]` や `[EquipmentPassiveStat]` が出る。
- `debug_equipment_attack_effects=true` でも、現状 `Unit._is_equipment_passive_debug_enabled()` の条件によりpassive logが出る。
- このdocsではDebugSettingsの値は変更しない。

## 装備攻撃効果の実行経路

入口は `CombatManager.gd` です。

通常攻撃が命中した後、攻撃者の装備中itemから攻撃時効果候補を拾います。

主な関数:

- `CombatManager.perform_attack()`
- `CombatManager._apply_equipment_attack_effects(attacker, target)`
- `CombatManager._should_apply_equipment_attack_effect(effect_entry, effect)`
- `Unit.get_equipped_attack_effects()`
- `Unit.get_equipped_item_effects()`

流れ:

1. `CombatManager.perform_attack()` が通常攻撃の可否と命中を判定する。
2. 通常攻撃が命中したら、通常ダメージを `target.stats.take_damage(damage)` で適用する。
3. その直後に `_apply_equipment_attack_effects(attacker, target)` を呼ぶ。
4. `attacker.get_equipped_attack_effects()` が、装備中itemの効果から攻撃時候補だけを返す。
5. 各effectに対して `trigger_chance` 判定を行う。
6. `effect_type` ごとに `deal_damage`, `apply_status`, `restore_resource` を実行する。
7. その後 `target.check_death("attack")` が呼ばれる。

### 攻撃時候補になるeffect_type

`Unit._is_attack_equipment_effect_candidate()` では、現状以下だけが候補です。

- `deal_damage`
- `apply_status`
- `restore_resource`

`apply_modifier` は装備中パッシブ用なので、攻撃時候補から除外されます。

### `trigger_chance`

装備攻撃効果では、各effectの実行前に `trigger_chance` を判定します。

現状:

- `trigger_chance >= 1.0`: 必ず発動。
- `trigger_chance <= 0.0`: 発動しない。
- それ以外: `randf() <= trigger_chance`。
- 値は `0.0` から `1.0` にclampされる。

`trigger_chance` は `item_effects.tsv` のeffect側にあります。item側やlink側ではありません。

### `deal_damage`

装備攻撃効果の `deal_damage` は、現状 `damage_mode=direct` のみ実行します。

- targetがすでに死亡状態ならskip。
- `damage_mode` が `direct` 以外ならskip。
- `power_min` / `power_max` から `effect.get_rolled_power()` で追加ダメージを決める。
- 防御計算や属性耐性計算は行わず、追加ダメージとしてHPを減らす。

### `apply_status`

装備攻撃効果の `apply_status` は、targetへ `UnitEffectRuntime` を追加します。

- targetがすでに死亡状態ならskip。
- `status_id` が空ならskip。
- targetに `add_status_effect_runtime()` がなければskip。

通常攻撃ダメージや追加ダメージでtargetのHPが0以下になっている場合、`apply_status` はskipされます。

### `restore_resource`

装備攻撃効果の `restore_resource` は、attacker側へ適用されます。現状は攻撃命中報酬、on-hit rewardとして扱われます。

- attackerがnullなら失敗。
- attackerが死亡状態ならskip。
- targetが死亡していても、それだけではskipしない。
- `ItemEffectManager._apply_restore_resource(attacker, attacker, effect)` を使う。
- 実際の回復量は、適用前後のresource値からログ用に計算される。

そのため、targetが通常攻撃や追加ダメージで死亡しても、attackerが生きていれば `restore_resource` は発生し得ます。

## 代表sample / production data

- `sample_copper_guard_ring`
  - `sample_copper_guard_ring_defense_bonus`
  - 装備パッシブ `apply_modifier`
  - defense +1。
  - `spawn_weight=0`。

- `sample_poison_knife`
  - `sample_poison_knife_poison`
  - 装備攻撃 `apply_status`
  - poisonを3秒相当で付与。
  - `trigger_chance` は空欄扱いのためdefault 1.0。
  - `spawn_weight=0`。

- `sample_dud_flame_knife`
  - `sample_dud_flame_knife_fire_damage`
  - 装備攻撃 `deal_damage`
  - fire direct damage 1。
  - `trigger_chance=0.0` のため発動しない確認用。
  - `spawn_weight=0`。

- `sample_unstable_flame_knife`
  - `sample_unstable_flame_knife_fire_damage`
  - 装備攻撃 `deal_damage`
  - fire direct damage 1。
  - `trigger_chance=0.5` の確認用。
  - `spawn_weight=0`。

- `sample_combo_knife`
  - `sample_combo_knife_fire_damage`
  - `sample_combo_knife_restore_hp`
  - 1つの装備に複数effectをlinkした確認用。
  - `item_effect_links.tsv` の `order=1` が追加ダメージ、`order=2` がHP回復。
  - `spawn_weight=0`。

- `power_ring`
  - `power_ring_attack_bonus`
  - 本番装備の装備パッシブ `apply_modifier`。
  - `equipment.tsv` の `attack_bonus=20` に加え、item effect由来でattack +1。
  - `spawn_weight=100`。

## effect_type別の現状入口

### `restore_resource`

- consumable: `ItemEffectManager._apply_restore_resource()`
- equipment passive: 対象外。`Unit` のpassive集計は `apply_modifier` だけを見る。
- equipment attack: `CombatManager._apply_equipment_attack_restore_resource()`。attackerへ適用する。

### `apply_status`

- consumable: `ItemEffectManager._apply_status()`。targetへstatus runtimeを追加する。
- equipment passive: 対象外。
- equipment attack: `CombatManager._apply_equipment_attack_apply_status()`。targetへstatus runtimeを追加する。target死亡済みならskip。

### `apply_modifier`

- consumable: `ItemEffectManager._apply_modifier()`。targetへmodifier runtimeを追加する。
- equipment passive: `Unit._get_total_equipment_effect_modifier()` が装備中itemから拾い、stat合計値に反映する。
- equipment attack: 現状候補外。`get_equipped_attack_effects()` では返されない。

### `deal_damage`

- consumable: `ItemEffectManager._apply_deal_damage()`。`direct` と `calculated` がある。
- equipment passive: 対象外。
- equipment attack: `CombatManager._apply_equipment_attack_deal_damage()`。現状は `damage_mode=direct` のみ実行。

### `cure_status`

- consumable: `ItemEffectManager._apply_cure_status()`。
- equipment passive: 対象外。
- equipment attack: 現状候補外。

### `grant_item` / `grant_currency`

- consumable: `ItemEffectManager` からtargetのgrant系methodを呼ぶ。
- equipment passive: 対象外。
- equipment attack: 現状候補外。

### `teleport`

- consumable: `ItemEffectManager._apply_teleport()` からtargetの `apply_item_teleport_effect()` を呼ぶ。
- equipment passive: 対象外。
- equipment attack: 現状候補外。

### `permanent_stat_growth`

- consumable: `ItemEffectManager._apply_permanent_stat_growth()`。
- equipment passive: 対象外。
- equipment attack: 現状候補外。

### `learn_skill` / `unlock_recipe` / `identify_item` / `read_document` / `spawn_object`

- consumable: `ItemEffectManager` に分岐がある。target側methodが存在する場合に処理される。
- equipment passive: 対象外。
- equipment attack: 現状候補外。

## 追加・確認時に見る場所

新しい消耗品効果を見る入口:

- `data/master/items.tsv`
- `data/master/item_effects.tsv`
- `data/master/item_effect_links.tsv`
- `scripts/data/item_effect_data.gd`
- `scripts/data/game_data_registry.gd`
- `scripts/item/item_effect_manager.gd`
- `scripts/item/inventory.gd`
- `scripts/item/inventory_ui.gd`
- 対象指定itemなら `scripts/combat/combat_manager.gd`

新しい装備パッシブを見る入口:

- `data/master/items.tsv`
- `data/master/equipment.tsv`
- `data/master/item_effects.tsv`
- `data/master/item_effect_links.tsv`
- `scripts/core/unit.gd`
- `scripts/data/game_data_registry.gd`
- `scripts/data/equipment_data.gd`
- `scripts/debug/DebugSettings.gd` の `debug_equipment_effects`

新しい装備攻撃効果を見る入口:

- `data/master/items.tsv`
- `data/master/equipment.tsv`
- `data/master/item_effects.tsv`
- `data/master/item_effect_links.tsv`
- `scripts/core/unit.gd`
- `scripts/combat/combat_manager.gd`
- `scripts/item/item_effect_manager.gd` は `restore_resource` の下流で一部使われる。
- `scripts/debug/DebugSettings.gd` の `debug_equipment_attack_effects`

TSV側確認:

- item_idが `items.tsv` にあるか。
- 装備なら `equipment.tsv` に同じ `item_id` があるか。
- effect_idが `item_effects.tsv` にあるか。
- `item_effect_links.tsv` に `item_id` と `effect_id` のlinkがあるか。
- sample/test確認用itemを通常spawnに混ぜないなら `spawn_weight=0` か。

## よくある誤解・注意点

- 装備効果用の専用 `equipment_effect_links.tsv` は使っていない。
- `item_effect_links.tsv` は消耗品と装備の両方で使う。
- 同じ `ItemEffectData` でも、消耗品、装備パッシブ、装備攻撃で入口と意味が違う。
- 装備パッシブは `Unit.gd` 側でstat合計値に反映される。
- 装備攻撃効果は `CombatManager.gd` 側で通常攻撃命中後に処理される。
- `apply_modifier` は装備パッシブでは有効だが、現状の装備攻撃効果候補ではない。
- `trigger_chance` は現状、装備攻撃効果の発動判定で使う。消耗品や装備パッシブの発動率には使っていない。
- `sample_*` / `test_*` itemは通常spawnに混ぜない。
- `spawn_weight <= 0` はrandom spawn候補から除外される。
- DebugSettings値の変更はこのStepでは行わない。
- 今回は現状理解docsであり、共通化やリファクタ判断はStep 12以降の別フェーズ。

## このdocsで分かること / 分からないこと

分かること:

- 消耗品効果の入口が `ItemEffectManager` であること。
- 装備パッシブ効果の入口が `Unit.gd` であること。
- 装備攻撃効果の入口が `CombatManager.gd` であること。
- `item_effect_links.tsv` が消耗品と装備効果で共有されていること。
- `effect_type` ごとの大まかな実行経路。
- 代表sample装備と `power_ring` の意味。

分からないこと:

- 将来どこを共通化すべきか。
- リファクタすべきか。
- effect system全体の理想設計。
- 装備効果専用テーブルが将来必要か。

これらはStep 12以降の別フェーズで扱います。
