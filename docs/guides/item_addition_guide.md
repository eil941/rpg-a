# Item Addition Guide

## この手順書の目的

この手順書は、`rpg-a` に新しいアイテムを追加する時に、`master_data.xlsx` のどのシートを編集し、どこから実装作業が必要になるかを判断するための入口です。

対象読者は、Godotをほぼ知らないがUnityは少し触ったことがある人、またはプログラマーとしての基礎知識はあるがゲーム開発やデータ駆動設計に慣れていない人です。

主に扱う範囲:

- `master_data.xlsx` を手作業で編集してアイテムを増やす。
- 既存の効果で足りるか、runtime実装が必要かを判断する。
- export / validate / Godot確認までの流れを揃える。

このdocs自体は手順書です。実際のExcel編集、TSV更新、runtime handler追加は別作業として行います。

## 前提知識

Unityでは、PrefabやScriptableObjectを増やしてアイテム定義を作ることがあります。`rpg-a` では、それに近い役割の多くを `master_data.xlsx` と `data/master/*.tsv` が持っています。

GodotのsceneやResourceを直接増やす前に、まずmaster dataを増やします。アイコンもGodot editorで直接設定するのではなく、`icon_path` というresource path文字列としてデータに持ちます。

runtimeでは、Godot起動時に `GameDataRegistry` がTSVを読み込み、Inventory、ItemEffectManager、Combat、Unit、ItemWorldManagerなどがそのデータを参照します。画像、演出、UI、新しい特殊処理は別作業です。

## master_data.xlsx編集の全体原則

| 原則 | 内容 |
| --- | --- |
| 正本はExcel | `master_data.xlsx` がマスターデータの正本です。 |
| TSVは出力結果 | `data/master/*.tsv` は `tools/export_master_tsv.py` によるruntime用出力です。 |
| TSVだけ直接編集しない | TSVだけを直すと次のexportでExcelの内容に戻ります。 |
| 既存行コピーが安全 | 近い既存アイテム、効果、装備、loot entryをコピーして差分だけ変えるとミスが減ります。 |
| ID参照はvalidateする | `item_id`, `effect_id`, `category`, `status_id` などはtypoしやすいので必ずvalidateします。 |
| 新列追加は別Step | 普通のアイテム追加ではありません。Excel列、export、loader、data class、validator、docs更新が必要です。 |
| 新sheet追加も別Step | export、loader、validator、lookup、docsの対応が必要です。 |
| まず小さく追加する | 大量追加の前に、1個から数個でexport / validate / Godot確認します。 |

基本の順番:

```text
master_data.xlsx を編集
    ↓
py tools\export_master_tsv.py
    ↓
py tools\validate_master_data.py
    ↓
git diff --check
    ↓
Godot起動確認
    ↓
Inventory / use / equipment / spawn / save-load などを確認
```

## アイテム管理の全体像

```text
master_data.xlsx
    ↓ tools/export_master_tsv.py
data/master/items.tsv
data/master/equipment.tsv
data/master/item_effects.tsv
data/master/item_effect_links.tsv
    ↓ Godot起動時
GameDataRegistry
    ↓
Inventory / ItemEffectManager / Combat / Unit / ItemWorldManager
```

`master_data.xlsx` と `data/master/*.tsv` の関係を壊さないことが最優先です。

## Excelで触る可能性があるシート一覧

この表は、現在 `data/master/*.tsv` と既存docsから確認できる名前に合わせています。

### 基本アイテム系

| シート / TSV | 役割 | 触るタイミング | 注意 |
| --- | --- | --- | --- |
| `items` / `items.tsv` | すべてのアイテムの基本情報 | ほぼすべてのアイテム追加 | 装備、消耗品、素材もまずここ |
| `equipment` / `equipment.tsv` | 装備品固有の情報 | 武器、防具、アクセサリを追加 | `items` に同じ `item_id` が必要 |
| `item_effects` / `item_effects.tsv` | 効果本体 | 使用効果、装備パッシブ、装備攻撃効果 | 新しい `effect_type` はruntime実装も必要 |
| `item_effect_links` / `item_effect_links.tsv` | `item_id` と `effect_id` をつなぐ | アイテムに効果を持たせる時 | 消耗品も装備もここを使う。`equipment_effect_links.tsv` は作らない |

### 分類・定義系

| シート / TSV | 役割 | 触るタイミング | 注意 |
| --- | --- | --- | --- |
| `item_categories` / `item_categories.tsv` | item category定義 | 新しい `items.category` が必要な時 | 表示やfilter、default値に影響する可能性 |
| `status_effect_types` / `status_effect_types.tsv` | status定義 | 新しい `status_id` を使う時 | 定義だけでは挙動本体がない場合がある |
| `element_types` / `element_types.tsv` | element定義 | 新しい `damage_element` や攻撃属性を使う時 | DamageCalculatorや耐性処理の影響を確認 |
| `damage_types` / `damage_types.tsv` | damage type定義 | 新しい `damage_type` を使う時 | 特別な計算差を出すなら実装が必要 |

### 出現・入手経路系

| シート / TSV | 役割 | 触るタイミング | 注意 |
| --- | --- | --- | --- |
| `spawn_rules` / `spawn_rules.tsv` | map上のitem spawn rule本体 | フィールドやダンジョンに自然生成したい時 | 子テーブルと組み合わせて読む |
| `item_spawn_rule_category_multipliers` | category単位のspawn重み補正 | categoryごとの出方を変える時 | `category` 参照をvalidate |
| `item_spawn_rule_item_overrides` | item単位のspawn重み上書き | 特定itemを出したい/抑えたい時 | `item_id` 参照をvalidate |
| `chest_tables` | chestの親テーブル | chest typeごとの枠数やloot tableを変える時 | `loot_table_id` 参照 |
| `chest_loot_tables` | chest loot entry | 宝箱候補にitem/categoryを入れる時 | weight、amountを既存列に合わせる |
| `shop_tables` | shopの親テーブル | shopごとの枠数やloot tableを変える時 | `loot_table_id` 参照 |
| `shop_loot_tables` | shop loot entry | 店にitem/categoryを並べる時 | `can_sell` とは別 |
| `initial_inventory_tables` | Unit初期所持品テーブル本体 | enemy/NPCに持たせるtableを増やす時 | death drop専用ではない |
| `initial_inventory_entries` | Unit初期所持品entry | enemy/NPCがspawn時に持つ候補 | `spawn_chance` は生成時確率 |

### 装備・強化・特殊関連

| シート / TSV | 役割 | 触るタイミング | 注意 |
| --- | --- | --- | --- |
| `enchantments` / `enchantments.tsv` | 装備エンチャント候補 | 装備生成時のランダム補正候補を増やす時 | 装備instance data保存も関係 |
| `skill_effect_links` / `skill_effect_links.tsv` | skillとeffectをつなぐ | skill効果を変える時 | 通常アイテム追加とは別扱い |
| `skills` / `skills.tsv` | skill本体 | skill追加・変更時 | item効果とskill効果を混同しない |
| `skill_levels` / `skill_levels.tsv` | skill level別値 | skill成長値を変える時 | item追加とは通常別 |
| `skill_requirements` / `skill_requirements.tsv` | skill解放条件 | skill条件を変える時 | item追加とは通常別 |

### Quest / NPC / enemy 関連

| シート / TSV | 役割 | 触るタイミング | 注意 |
| --- | --- | --- | --- |
| `enemies` / `enemies.tsv` | enemy定義 | enemyに初期所持品tableや装備を設定する時 | `initial_inventory_table_id` を使う。旧 `initial_inventory_items` は使わない |
| `npcs` / `npcs.tsv` | NPC定義 | NPC/shop/questに絡める時 | shop inventoryと本体inventoryを混ぜない |
| `quests` / `quests.tsv` | quest定義 | item要求やitem報酬にする時 | `objective_item_id`, `reward_item_ids` などの参照に注意 |
| `npc_quest_links` / `npc_quest_links.tsv` | NPCとquestをつなぐ | NPCにquest候補を持たせる時 | item追加とは別作業になりやすい |

## まず決めること

| 項目 | 決めること |
| --- | --- |
| `item_id` | 内部ID。英数字とunderscoreの `snake_case` 推奨 |
| `display_name` | 画面に出す名前。日本語名はここ |
| `description` | 説明文 |
| `category` | `consumable`, `equipment`, `material`, `misc` など既存カテゴリに合わせる |
| `icon_path` | まずは `res://assets/Tentative_Assets/item.png` でよい |
| `max_stack` | 1枠に重ねられる数。装備は基本1 |
| `usable` | inventoryから使用できるか |
| `base_price` | 売買価格の基準 |
| `can_sell` | 売却できるか |
| `rarity` | 既存データの値に合わせる |
| `spawn_weight` | 通常ランダム出現の重み。0以下なら通常候補から外れる |
| `use_flags` | 使い方。自己使用、対象指定、投げ使用など |
| `target_flags` | 対象。自分、味方、敵、中立など |
| 効果が必要か | `item_effects` / `item_effect_links` が必要か |
| 装備かどうか | `equipment` sheetが必要か |
| 出現場所 | spawn、chest、shop、initial inventory、DebugSettingsのどれか |
| 実装が必要か | 既存 `effect_type` や既存カテゴリで足りるか |

## `items` sheet編集の詳細手順

`items` はすべてのアイテムの基本情報です。装備でも、消耗品でも、素材でも、まずここに行が必要です。

### 基本手順

1. 近い既存アイテムを探します。
2. その行をコピーします。
3. `item_id` を一意なIDへ変えます。
4. `display_name` / `description` を入れます。
5. `category` は既存カテゴリから選びます。
6. 新カテゴリが必要な時だけ、`item_categories` 追加手順へ進みます。
7. `icon_path` はまず `res://assets/Tentative_Assets/item.png` で構いません。
8. `max_stack`、`usable`、`base_price`、`can_sell`、`rarity`、`spawn_weight` を近い既存アイテムに合わせます。
9. `use_flags` / `target_flags` は近い既存アイテムをコピーします。

### `items` の列説明

| 列 | 説明 | 注意 |
| --- | --- | --- |
| `item_id` | 内部ID | 後から変えると参照が壊れやすい。英数字とunderscore推奨 |
| `display_name` | 画面表示名 | 日本語名はここに入れる |
| `description` | 説明文 | 使用効果があるものは書くと確認しやすい |
| `category` | アイテム分類 | 既存の `item_categories.tsv` にあるカテゴリを使う |
| `icon_path` | アイコン画像のresource path | 当面は `res://assets/Tentative_Assets/item.png` を使ってよい |
| `max_stack` | 1枠の最大stack数 | 装備は基本1。素材/消耗品は既存に合わせる |
| `usable` | inventoryから使用できるか | `item_effect_links` とセットで考える。効果なし素材や装備は通常 `false` |
| `base_price` | 価格の基準値 | shop/trade価格計算の元になる |
| `can_sell` | 売却可能か | quest/key itemは `false` が自然なことが多い |
| `rarity` | rarity値 | spawn/chest/shopの候補調整に関わる場合がある |
| `spawn_weight` | ランダム出現重み | `0` 以下は通常ランダム候補から外れる。固定ID指定やDebugSettingsでは使える |
| `use_flags` | 使用場面のbit flag | `1=USE_SELF`, `2=USE_UNIT_TARGET`, `4=USE_THROW_TARGET`, `8=USE_SPECIAL` |
| `target_flags` | 対象のbit flag | `1=TARGET_SELF`, `2=TARGET_ALLY`, `4=TARGET_ENEMY`, `8=TARGET_NEUTRAL` |

`use_flags` / `target_flags` のbit値を直接変える時は意味を確認します。例として、`target_flags=15` は `1+2+4+8` なので、自分、味方、敵、中立をすべて許可する意味です。基本は近い既存アイテムをコピーしてください。

## 新しい item category を追加する手順

新カテゴリは、まず本当に必要か確認します。表示名だけ違う素材なら、既存の `material` や `craft_material` で足りることが多いです。

### 判断

| やりたいこと | 新カテゴリが必要か |
| --- | --- |
| 木材、鉱石、草などの素材を増やす | 既存 `material` / `craft_material` で足りることが多い |
| 食べ物を増やす | 既存 `consumable` で足りることが多い |
| 装備を増やす | 既存 `equipment` を使う |
| UI filterやspawn分類を新しく分けたい | 新カテゴリ候補 |
| 売却不可、通常spawn不可などの特別扱いをカテゴリ単位で持たせたい | 既存仕様確認と実装が必要な可能性 |

### 追加手順

1. `item_categories` sheetを確認します。
2. 既存列に合わせて `category_id`, `display_name`, `sort_order`, `show_in_inventory`, `default_usable`, `default_can_sell`, `default_max_stack`, `description` を入れます。
3. `items.category` に新しい `category_id` を使います。
4. `GameDataRegistry` が `item_categories.tsv` を読んでいることを確認します。
5. `validate_master_data.py` が `items.category` を `item_categories.category_id` として検証していることを確認します。
6. exportします。
7. validateします。
8. Godot起動で category warning/error がないか確認します。
9. Inventory UI、filter、spawn、chest、shopに影響がないか確認します。

新カテゴリで特別な挙動をしたい場合は、Excel追加だけでは足りない可能性があります。どのruntimeがカテゴリを見ているかを調査Stepに分けてください。

## `equipment` sheet編集の詳細手順

装備品は `items` と `equipment` の両方が必要です。

| 必要な行 | 理由 |
| --- | --- |
| `items` に `category=equipment` の行 | itemとしてinventory、pickup、tradeで扱うため |
| `equipment` に同じ `item_id` の行 | 装備slot、stat bonus、攻撃属性などを持つため |

`items` だけでは装備としての詳細が足りません。`equipment` だけではアイテムとして存在しません。

### 基本手順

1. `items` に装備アイテム行を追加します。
2. `category=equipment` にします。
3. `max_stack=1` にします。
4. `equipment` に同じ `item_id` の行を追加します。
5. `slot_type` は既存slotから選びます。
6. `attack_bonus`, `defense_bonus`, `speed_bonus`, range、damage element、damage typeなどは近い既存武器・防具をコピーして調整します。
7. 装備効果なしなら `item_effects` は不要です。
8. 装備パッシブや攻撃時効果があるなら `item_effects` + `item_effect_links` を使います。

### `equipment` の主な列

| 列 | 説明 | 注意 |
| --- | --- | --- |
| `item_id` | `items.item_id` と同じID | 参照欠けはvalidate対象 |
| `slot_type` | `HAND`, `HEAD`, `BODY`, `HANDS`, `WAIST`, `FEET`, `ACCESSORY` | 新slotはUI / Unit / save-load影響が大きい |
| `max_hp_bonus` | 最大HP補正 | 装備固有bonus |
| `attack_bonus` | 攻撃補正 | `item_effects` の `apply_modifier` とは別 |
| `defense_bonus` | 防御補正 | 同上 |
| `speed_bonus` | 速度補正 | 同上 |
| `attack_type_id` | `melee`, `shot`, `magic`, `heal` など | 既存装備をコピーする |
| `attack_element` | 通常攻撃属性 | `element_types` と関係 |
| `attack_damage_type` | 通常攻撃damage type | `damage_types` と関係 |
| `attack_min_range` / `attack_max_range` | 通常攻撃射程 | UI/AI/Combat確認が必要 |
| `combat_style` / `move_style` | AI用傾向 | enemy/NPC装備時に影響 |

新しい `slot_type` が必要な場合は、`Unit` の装備slot、`InventoryUI`、save/load、装備表示、drop、装備効果計算へ影響します。Excelに新しい文字列を書くだけでは終わらないため、別Stepで調査してください。

装備効果も `item_effect_links.tsv` を使います。`equipment_effect_links.tsv` は作りません。

## `item_effects` sheet編集の詳細手順

`item_effects` は効果本体です。アイテムに効果を持たせるには、ここで効果を作った後、`item_effect_links` で item と effect を接続します。

### 主な列

| 列 | 役割 | 主に使うeffect_type |
| --- | --- | --- |
| `effect_id` | 効果ID | 全effect |
| `effect_type` | 効果種別 | 全effect |
| `value_mode` | `flat`, `percent`, `full` などの値扱い | `restore_resource` |
| `resource_type` | `hp`, `mp`, `stamina`, `hunger` | `restore_resource` |
| `power_min` / `power_max` | 数値範囲 | 回復、damage、permanent stat growth |
| `percent_value` | 割合値 | `restore_resource` など |
| `damage_element` | damage属性 | `deal_damage` |
| `damage_type` | damage type | `deal_damage` |
| `damage_mode` | `direct` / `calculated` | `deal_damage` |
| `calculated_power` | calculated damage倍率 | `deal_damage` |
| `bonus_accuracy` / `bonus_crit_rate` | calculated damage補正 | `deal_damage` |
| `ignore_defense_rate` | defense無視率 | `deal_damage` |
| `fixed_damage_bonus` | 固定damage加算 | `deal_damage` |
| `status_id` | status ID | `apply_status`, `cure_status` |
| `status_power` | status強度 | `apply_status` |
| `modifier_kind` | `buff` / `debuff` | `apply_modifier` |
| `stat_name` | 対象stat | `apply_modifier`, `permanent_stat_growth` |
| `stat_flat` | 固定stat補正 | `apply_modifier` |
| `stat_percent` | 割合stat補正 | `apply_modifier` |
| `duration_type` | `none`, `time`, `turn`, `action` | status/modifier系 |
| `duration_value` | duration数値 | status/modifier系 |
| `teleport_mode` / range / `warp_point_id` | teleport設定 | `teleport` |
| `grant_item_id` / `grant_item_amount` | 付与item | `grant_item` |
| `grant_currency_amount` | 付与通貨量 | `grant_currency` |
| `curse_status_pool` / overrides | curse専用 | `apply_status` の `status_id=curse` |
| `trigger_chance` | 装備攻撃効果の発動率 | 現状は装備攻撃効果で使用 |

空欄defaultはeffect_typeごとに違います。近い既存effectをコピーするのが安全です。

### 現在の `item_effects.tsv` に存在するeffect_type

| effect_type | 主な用途 | 主に見る列 | 現状の入口 |
| --- | --- | --- | --- |
| `restore_resource` | HP / hungerなどを回復 | `resource_type`, `value_mode`, `power_min`, `power_max`, `percent_value` | 使用時効果、装備攻撃時の回復 |
| `deal_damage` | damage item、攻撃時追加damage | `damage_element`, `damage_type`, `damage_mode`, `power_min`, `power_max`, calculated系列 | 使用時効果、装備攻撃効果 |
| `apply_status` | poison / sleep / slow / curseなど | `status_id`, `status_power`, `duration_type`, `duration_value`, curse系列 | 使用時効果、装備攻撃効果 |
| `cure_status` | 状態異常回復 | `status_id` | 使用時効果 |
| `apply_modifier` | buff / debuff / 装備パッシブ | `modifier_kind`, `stat_name`, `stat_flat`, `stat_percent`, `duration_type`, `duration_value` | 使用時効果、装備パッシブ |
| `teleport` | teleport item | `teleport_mode`, `teleport_min_range`, `teleport_max_range`, `warp_point_id` | 使用時効果 |
| `permanent_stat_growth` | life_seed系など | `stat_name`, `power_min`, `power_max` | 使用時効果 |
| `grant_currency` | currency付与 | `grant_currency_amount` | 使用時効果 |
| `grant_item` | item付与 | `grant_item_id`, `grant_item_amount` | 使用時効果 |

`ItemEffectData` と `ItemEffectManager` には、将来用の分岐があるeffect typeもあります。ただし、現在の `item_effects.tsv` に存在しないものは、通常のアイテム追加手順では扱わず、必要になった時に調査Stepを立ててください。

### `trigger_chance` の注意

- 空欄または列なしは `1.0` 扱いです。
- `0.0` は発動しません。
- `0.5` は50%発動です。
- `1.0` は100%発動です。
- 不正値はloaderでclampまたはdefault化され、validatorでも検証対象です。
- 現状、発動率として使っているのは装備攻撃効果です。消耗品や装備パッシブの発動率としては扱っていません。

## `item_effect_links` sheet編集の詳細手順

`item_effect_links` は、`items` の `item_id` と `item_effects` の `effect_id` を接続します。

| 列 | 説明 |
| --- | --- |
| `item_id` | 効果を持たせたいアイテムID |
| `effect_id` | 接続する効果ID |
| `order` | 複数effectがある場合の順序 |

重要:

- `item_effects` に効果を作っただけでは、アイテムに効果は付きません。
- `items` にアイテムを作っただけでも、効果は付きません。
- 消耗品効果も装備効果も `item_effect_links` を使います。
- 装備パッシブも `item_effect_links` です。
- 攻撃時効果つき武器も `item_effect_links` です。
- `equipment_effect_links.tsv` は作りません。
- `trigger_chance` は link 側ではなく `item_effects` 側です。
- `item_id` typo / `effect_id` typo はvalidateで検出します。
- 複数effectの `order` は、追加damageと回復などで意味を持つ可能性があります。

## 既存effect_typeを使う場合の作業手順

### HP回復アイテム

1. `items` に行を追加します。
2. `usable=true` にします。
3. `item_effects` に `restore_resource` を追加します。
4. `resource_type=hp`、`power_min`、`power_max` を設定します。
5. `item_effect_links` で接続します。
6. exportします。
7. validateします。
8. Godotで使用してHPが回復することを確認します。

### 攻撃アイテム

1. `items` に行を追加します。
2. 近い攻撃アイテムから `use_flags` / `target_flags` をコピーします。
3. `item_effects` に `deal_damage` を追加します。
4. `damage_element`, `damage_type`, `damage_mode`, `power_min`, `power_max` を設定します。
5. `item_effect_links` で接続します。
6. Godotで対象指定、damage、消費、死亡時挙動を確認します。

### 装備パッシブ

1. `items` に `category=equipment` の行を追加します。
2. `equipment` に同じ `item_id` の行を追加します。
3. `item_effects` に `apply_modifier` を追加します。
4. `stat_name`, `stat_flat`, `stat_percent`, `duration_type=none` などを設定します。
5. `item_effect_links` で接続します。
6. Godotで装備時にstatが変わり、解除時に戻ることを確認します。

### 攻撃時効果武器

1. `items` に `category=equipment` の行を追加します。
2. `equipment` に同じ `item_id` の行を追加します。
3. `item_effects` に `deal_damage` / `apply_status` / `restore_resource` のいずれかを追加します。
4. 必要なら `trigger_chance` を設定します。
5. `item_effect_links` で接続します。
6. Godotで通常攻撃命中時に発動することを確認します。

## 新しい effect_type を追加する場合

ここが最も重要です。Excelの `effect_type` に新しい文字列を書いただけでは動きません。

新しいeffect typeには、少なくとも次の対応が必要です。

- `master_data.xlsx` の `item_effects` に必要列があるか確認。
- `data/master/item_effects.tsv` にexportされるか確認。
- `ItemEffectData` が値を持てるか確認。
- `GameDataRegistry._build_item_effect()` が列を読むか確認。
- 実行handlerがあるか確認。
- `tools/validate_master_data.py` がeffect typeと参照/範囲を検証するか確認。
- docsを更新する。

いきなり大量追加せず、まず調査-only Stepに分けます。

### 消耗品使用時に使うeffect_type

確認・実装候補:

- `ItemEffectData` が必要な列を持てるか。
- `GameDataRegistry` が `item_effects.tsv` から列を読むか。
- `ItemEffectManager.apply_single_effect()` が `effect_type` を処理できるか。
- Inventory使用時、対象指定使用時のどちらで呼ばれるか。
- `use_flags` / `target_flags` と矛盾しないか。
- `validate_master_data.py` がeffect typeを許可・検証しているか。

### 装備パッシブで使うeffect_type

確認・実装候補:

- `Unit.get_equipped_item_effects()` 周辺。
- Unit側の装備パッシブ適用処理。
- 現状の装備パッシブは `apply_modifier` を主に扱う。
- `apply_modifier` 以外を装備中常時効果にするなら、装備解除時に戻せるか。
- save/loadでruntime modifierが壊れないか。

### 攻撃時効果で使うeffect_type

確認・実装候補:

- `CombatManager._apply_equipment_attack_effects()`。
- effect dispatcher。
- 通常攻撃のhit時だけ発動するか。
- target死亡後も処理するか。
- attackerにかける効果か、targetにかける効果か。
- `trigger_chance` を使うか。
- 現状の攻撃時候補は `deal_damage`、`apply_status`、`restore_resource`。

### skill効果で使うeffect_type

skill効果は通常のアイテム追加とは別扱いです。

- `skill_effect_links` はskillとeffectをつなぐためのものです。
- `item_effect_links` と混同しないでください。
- skill側は `skills`, `skill_levels`, `skill_requirements` も関係します。
- 明示依頼がない限り、skills / status_ui / skill_state周りは触らない方針です。

## 新しい effect_type 実装が必要な時の最小手順

これは実装作業の流れです。この手順書では実装しません。

1. 仕様を1行で決めます。
   - 例: 対象のHPを割合で回復する。
   - 例: 攻撃命中時に周囲へ範囲ダメージを与える。
2. 既存effect_typeで代用できないか確認します。
3. `master_data.xlsx` の `item_effects` に必要な列があるか確認します。
4. 必要な列がない場合は、次を別Stepで対応します。
   - Excel列追加。
   - export script対応。
   - `GameDataRegistry` loader対応。
   - `ItemEffectData` 対応。
   - `validate_master_data.py` 対応。
   - docs更新。
5. 実行handlerを追加します。
   - 使用時効果なら `ItemEffectManager`。
   - 装備パッシブなら `Unit` 側。
   - 攻撃時効果なら `CombatManager` 側。
6. `item_effect_links` で接続します。
7. export / validateします。
8. Godotで最小確認します。
9. save/loadやdeath/dropに影響があるなら追加確認します。

注意:

- 新しいeffect type実装は、Excel編集だけでは完結しません。
- data追加Stepとruntime実装Stepを分けると安全です。
- effect type追加時は、使用時、装備中、攻撃時、skillのどの経路で対応するかを明記します。
- 1つのeffect typeを全経路で使えるとは限りません。

## 新しい resource_type / status / element / damage_type を追加する場合

### resource_type

- まず `hp` / `hunger` など既存resource typeで足りるか確認します。
- `ItemEffectData.ResourceType` には `hp`, `mp`, `stamina`, `hunger` が対応しています。
- 新しいresource typeは、`Stats`、UI、`ItemEffectManager`、save/loadへ影響する可能性があります。
- Excelに文字列を書くだけでは動かない可能性が高いです。

### status_id

- `status_effect_types` に既存statusがあるか確認します。
- 新statusを足す場合、表示、duration、効果処理、解除処理、AI/Combat影響を確認します。
- `apply_status` / `cure_status` がそのstatusを扱えるか確認します。
- 状態異常の挙動本体が未実装なら、statusを追加しても見た目だけになる可能性があります。

### element_type

- `element_types` を確認します。
- 表示だけなら比較的軽い場合があります。
- damage計算、耐性、AI判断に使うなら `DamageCalculator` やcombat周辺を確認します。

### damage_type

- `damage_types` を確認します。
- `DamageCalculator` / `CombatManager` が扱えるか確認します。
- 新damage typeで特別な計算をしたいなら実装が必要です。

## 出現・入手経路をExcelで設定する手順

アイテムを追加しても、どこからも出ないことがあります。データとして存在することと、ゲーム中に入手できることは別です。

### map上の自然生成

見るシート:

- `spawn_rules`
- `item_spawn_rule_category_multipliers`
- `item_spawn_rule_item_overrides`

考え方:

- `spawn_rules` はmapやgenerator themeに応じたitem生成ルールです。
- category multiplierはカテゴリ単位の補正です。
- item overrideは特定itemの重み上書きです。
- `items.spawn_weight` と組み合わせて考えます。
- `spawn_weight <= 0` は通常ランダム候補から外れます。
- `sample_` / `test_` itemは通常spawnに混ぜないでください。

### 宝箱

見るシート:

- `chest_tables`
- `chest_loot_tables`

考え方:

- `chest_tables` はchest type、枠数、loot tableを持ちます。
- `chest_loot_tables` は実際の候補entryです。
- `item_id` 直接指定か `category` 抽選かを既存行に合わせます。
- `weight`, `min_amount`, `max_amount` を近い既存entryに合わせます。
- 宝箱に出すならGodotでchest生成を確認します。

### shop

見るシート:

- `shop_tables`
- `shop_loot_tables`

考え方:

- `shop_tables` はshopごとの枠数やloot tableを持ちます。
- `shop_loot_tables` は在庫候補entryです。
- 店に並ぶかどうかは `can_sell` とは別です。
- `can_sell=false` でも、shop lootに入れれば並ぶ可能性があるため注意します。
- 在庫数、weight、amount系列は既存行に合わせます。

### enemy / NPC初期所持品

見るシート:

- `initial_inventory_tables`
- `initial_inventory_entries`
- `enemies`
- `npcs`

考え方:

- `initial_inventory_entries` はenemy/NPCがspawn時に持つ候補です。
- death drop tableではありません。
- 実際にinventoryへ入った状態で死亡すれば、death drop対象になり得ます。
- 保存済みUnitではinitial inventoryを再抽選しません。
- enemy/NPCに使うには、`initial_inventory_table_id` を設定します。
- 旧 `initial_inventory_items` はdeprecatedです。新規データでは使いません。
- drop専用テーブルを作りたい場合は別Stepです。`drop_tables.tsv` はまだ作りません。

### Quest

見るシート:

- `quests`
- 必要なら `npc_quest_links`

考え方:

- item要求なら `objective_item_id` などのitem参照を確認します。
- item報酬なら `reward_item_ids` / `reward_item_amounts` を確認します。
- NPCにquestをつなぐなら `npc_quest_links` も関係します。
- quest仕様とitem追加を混同せず、必要な時だけ触ります。

### DebugSettings

見るファイル:

- `scripts/debug/DebugSettings.gd`

考え方:

- `debug_player_start_items` は確認用にplayerへ初期配布する仕組みです。
- 追加したitemをすぐ確認したい時に使えます。
- 確認後に戻し忘れないでください。
- `PlayerData.debug_start_items_applied` がtrueの既存saveでは再配布されないことがあります。
- docs-onlyやデータ追加Stepでは、DebugSettings変更を残すかどうかを必ず明記します。

## パターン別の追加手順

### A. 効果なし素材アイテム

1. `items` sheetに行を追加します。
2. `category` は `material` や `craft_material` など既存カテゴリに合わせます。
3. `usable=false` にします。
4. `item_effects` と `item_effect_links` は不要です。
5. 通常出現させるなら `spawn_weight` を設定します。
6. 必要なら `spawn_rules`、`chest_loot_tables`、`shop_loot_tables` に追加します。

### B. 食べ物・回復アイテム

1. `items` sheetに行を追加します。
2. `usable=true` にします。
3. `item_effects` に `restore_resource` 効果を追加します。
4. `resource_type` は既存の `hp` や `hunger` などに合わせます。
5. `power_min` / `power_max` に回復量を入れます。
6. `item_effect_links` で `item_id` と `effect_id` をつなぎます。
7. `use_flags` / `target_flags` は近い既存アイテムを参考にします。

### C. 状態異常回復アイテム

1. `items` sheetに行を追加します。
2. `item_effects` に `cure_status` 効果を追加します。
3. `status_id` は `status_effect_types` や既存効果に合わせます。
4. `item_effect_links` でつなぎます。
5. 対象指定の有無は既存の回復アイテムを参考にします。

### D. 攻撃アイテム

1. `items` sheetに行を追加します。
2. `item_effects` に `deal_damage` 効果を追加します。
3. `damage_element`, `damage_type`, `damage_mode`, `power_min`, `power_max` を既存の攻撃アイテムに合わせます。
4. 敵に使うなら `target_flags` に `TARGET_ENEMY` が含まれるようにします。
5. `item_effect_links` でつなぎます。
6. Godotで対象指定、命中、消費、死亡時挙動を確認します。

### E. buff / debuff アイテム

1. `items` sheetに行を追加します。
2. 一時的なstat変化なら `apply_modifier` を検討します。
3. 状態異常として扱うなら `apply_status` を検討します。
4. `duration_type` / `duration_value`、`modifier_kind`、`stat_name`、`stat_flat`、`stat_percent` を既存行に合わせます。
5. `item_effect_links` でつなぎます。

### F. 装備アイテム

1. `items` sheetに `category=equipment` の行を追加します。
2. `max_stack=1` にします。
3. `equipment` sheetに同じ `item_id` の行を追加します。
4. `slot_type`、`attack_bonus`、`defense_bonus`、射程、attack elementなどを設定します。
5. 効果がない装備なら `item_effects` は不要です。
6. Godotで装備、解除、save/loadを確認します。

### G. 装備パッシブ効果つきアイテム

1. `items` と `equipment` に装備として追加します。
2. `item_effects` に `apply_modifier` 効果を追加します。
3. `modifier_kind`, `stat_name`, `stat_flat`, `stat_percent`, `duration_type=none` などを既存の装備パッシブ効果に合わせます。
4. `item_effect_links` で装備の `item_id` と `effect_id` をつなぎます。
5. 装備効果も `item_effect_links.tsv` を使います。
6. `equipment_effect_links.tsv` は作りません。

### H. 攻撃時効果つき武器

1. `items` と `equipment` に武器として追加します。
2. `item_effects` に攻撃時効果を追加します。
3. 現状の装備攻撃効果では、`deal_damage`、`apply_status`、`restore_resource` が対応済みです。
4. `trigger_chance` を設定します。空欄は実質 `1.0` です。
5. `item_effect_links` でつなぎます。
6. `CombatManager` 側が未対応のeffect typeなら、データ追加だけでは動きません。先に調査Stepに分けてください。

## データ追加だけで済むもの / 実装が必要なもの

### データ追加だけで済みやすいもの

- 効果なし素材。
- 既存effect typeを使う回復アイテム。
- 既存effect typeを使う状態異常付与や状態異常回復。
- 既存effect typeを使うdamage item。
- 既存slotの装備。
- 既存 `apply_modifier` を使う装備パッシブ。
- 既存の装備攻撃effect typeを使う武器。
- 既存カテゴリに入るitem。
- 既存spawn/chest/shop/initial inventory構造に追加するだけの入手経路。

### 実装が必要になりやすいもの

- 新しい `effect_type`。
- 新しい `resource_type`。
- 新しい `status_id` の挙動本体。
- 新しい `element_type` の計算差。
- 新しい `damage_type` の計算差。
- 新しいtarget rule。
- 新しい装備slot。
- 新しいitem categoryで特別なUI/filter/spawn挙動をしたい場合。
- 新しいUI挙動。
- 新しいアニメーションや専用演出。
- 使用時にmap、quest、dialogueへ特殊作用するアイテム。

実装が必要そうな場合は、いきなりExcel行を大量追加せず、先に「どのコードが対応しているか」を調べる小さい調査Stepに分けます。

## 実装が必要と判断する基準

| やりたいこと | Excelだけで済む可能性 | 実装が必要な可能性 | 見る場所 |
| --- | --- | --- | --- |
| 既存HP回復アイテムの数値違い | 高 | 低 | `item_effects`, `item_effect_links` |
| 新しい回復対象resource | 低 | 高 | `Stats`, `ItemEffectManager`, `ItemEffectData` |
| 既存statusを付与 | 中から高 | status挙動次第 | `status_effect_types`, `ItemEffectManager` |
| 新しいstatusを作る | 低 | 高 | status処理、UI、Combat |
| 既存damage item | 高 | 低 | `item_effects`, `ItemEffectManager` |
| 新damage_type | 低から中 | 計算差があるなら高 | `damage_types`, `DamageCalculator` |
| 既存slot装備 | 高 | 低 | `equipment` |
| 新slot装備 | 低 | 高 | `Unit`, `InventoryUI`, save/load |
| 既存apply_modifier装備 | 高 | 低 | `Unit`, `item_effect_links` |
| 新しい装備パッシブ挙動 | 低 | 高 | `Unit` |
| 既存攻撃時効果 | 中から高 | 低 | `CombatManager` |
| 新しい攻撃時効果 | 低 | 高 | `CombatManager` |
| 新categoryで通常分類だけ変える | 中 | 低から中 | `item_categories`, Inventory UI |
| 新categoryで特別挙動をする | 低 | 高 | UI、spawn、shop、validator |

## Excel編集後の必須チェックリスト

### Excel保存前

- `item_id` 重複なし。
- 参照ID typoなし。
- 近い既存行と列の埋め方が揃っている。
- 装備なら `items` と `equipment` の両方がある。
- 効果ありなら `item_effects` と `item_effect_links` がある。
- 新カテゴリなら `item_categories` がある。
- 新status / element / damage typeなら対応sheetと実装影響を確認している。
- `spawn_weight` の値が意図通り。
- `sample_` / `test_` itemが通常spawnに混ざらない。

### export後

- TSVに意図した行が出ている。
- ExcelとTSVの差分が意図通り。
- 余計なsheetや列が出ていない。
- 既存行を壊していない。

### validate後

- `errors=0`。
- `warnings=0` が理想。
- warningがあるなら理由を説明できる。
- item / effect / link / category / status / element / damage type参照エラーがない。

### Godot確認

- 起動する。
- GameDataRegistry warning/errorがない。
- inventoryで見える。
- 使用できる。
- 効果が出る。
- 装備できる。
- 攻撃時効果が出る。
- shop/chest/spawn/initial inventoryに出る。
- save/load後に壊れない。

## export / validate 手順

データを変更した後は、Windows PowerShellで次を実行します。

```powershell
py tools\export_master_tsv.py
py tools\validate_master_data.py
git diff --check
```

`py` が使えない場合は、利用可能なPythonで代替します。

```powershell
.\.venv\Scripts\python.exe tools\export_master_tsv.py
.\.venv\Scripts\python.exe tools\validate_master_data.py
```

環境によっては同梱Pythonや通常の `python` を使います。どのPythonで実行したかは作業メモや報告に残します。

## Godotでの確認観点

1. Godotを起動します。
2. 起動ログで `GameDataRegistry` のsummaryや warning/error を確認します。
3. validate warning/error が出ていないか確認します。
4. inventoryに追加したアイテムが出るか確認します。
5. 使用できるアイテムなら使用して効果を確認します。
6. 装備なら装備・解除できるか確認します。
7. 装備効果ならステータスや攻撃時挙動を確認します。
8. spawn / chest / shopに追加したなら、実際に出るか確認します。
9. save/load後に壊れないか確認します。

## よくあるミス

- ExcelではなくTSVだけ編集してしまう。
- exportし忘れる。
- validateし忘れる。
- `item_id` をtypoする。
- `item_effect_links` の `item_id` / `effect_id` をtypoする。
- `item_effects` に効果を作っただけで、`item_effect_links` を忘れる。
- `item_effect_links` を作ったが `effect_id` が存在しない。
- `equipment` に追加したが `items` に追加していない。
- 装備なのに `max_stack > 1` にしてしまう。
- `spawn_weight=0` のままで通常出現しない。
- `spawn_weight` を上げすぎて出すぎる。
- `icon_path` が間違っている。
- 既存 `effect_type` にない効果を書いてしまう。
- `effect_type` 名を新しく書いたが、runtime handlerがない。
- 新しい `status_id` を書いたが状態異常の挙動本体がない。
- 新しい `resource_type` を書いたが `Stats` 側に存在しない。
- 新しいcategoryを作ったがUIやspawn側の扱いを確認していない。
- shopに出したつもりだが `shop_loot_tables` に入っていない。
- chestに出したつもりだが `chest_loot_tables` に入っていない。
- enemyに持たせたつもりだが `initial_inventory_table_id` がenemyに設定されていない。
- `equipment_effect_links.tsv` を作ろうとする。
- `initial_inventory_*` をdeath drop tableだと誤解する。
- debug start itemに入れたまま戻し忘れる。
- DebugSettingsに入れたが既存saveでは `debug_start_items_applied` 済みで再配布されない。
- `sample_` / `test_` itemを通常spawnに混ぜる。
- 保存済みUnitでinitial inventoryが再抽選されると思い込む。

## `item_id` 命名ルールの目安

- `snake_case` を使います。
- 英数字とunderscoreを使います。
- 日本語名ではなく内部IDにします。
- 後から変えない前提で決めます。
- 確認用は `test_` / `sample_` で分かりやすくできますが、通常出現させないよう注意します。
- 日本語名は `display_name` に入れます。

## 追加時メモ用テンプレート

```text
item_id:
display_name:
category:
icon_path:
max_stack:
usable:
base_price:
can_sell:
rarity:
spawn_weight:
use_flags:
target_flags:

effectが必要か:
effect_type:
item_effect_links:
equipmentが必要か:
出現場所:
実装が必要か:
確認方法:
```

## 新しいeffect typeが必要な時のCodex依頼テンプレート

```text
新しいeffect_type `<effect_type>` を追加したいです。

目的:
- 何をする効果か:

使用経路:
- 使用時アイテム:
- 装備パッシブ:
- 攻撃時装備効果:
- skill効果:

master_data.xlsx 側:
- 追加予定sheet:
- 追加予定列:
- item_effectsの使用列:
- item_effect_linksで接続するitem:

既存effect_typeで代用できない理由:
-

確認したいこと:
- loader対応が必要か
- ItemEffectData対応が必要か
- ItemEffectManager対応が必要か
- CombatManager対応が必要か
- Unit装備パッシブ対応が必要か
- validate_master_data.py対応が必要か

制約:
- equipment_effect_links.tsv は作らない
- drop_tables.tsv は作らない
- 既存effect_typeを壊さない
- まず調査-onlyでお願いします
```

## 最小追加例

以下は説明用の架空例です。実際にTSVへ追加しないでください。

### 例1: 効果なし素材

```text
item_id: example_copper_ore
display_name: 銅鉱石
category: material
icon_path: res://assets/Tentative_Assets/item.png
max_stack: 99
usable: false
spawn_weight: 20
effect: なし
```

`items` に行を追加するだけでデータとしては成立します。実際に出したい場合は、spawn / chest / shopなどへ別途追加します。

### 例2: HP回復アイテム

```text
item_id: example_small_heal_leaf
effect_id: example_small_heal_leaf_restore_hp
effect_type: restore_resource
resource_type: hp
power_min: 10
power_max: 10
```

`items` にアイテムを追加し、`item_effects` に効果を追加し、`item_effect_links` でつなぎます。

### 例3: 装備パッシブつき指輪

```text
item_id: example_focus_ring
category: equipment
slot_type: ACCESSORY
effect_id: example_focus_ring_attack_bonus
effect_type: apply_modifier
modifier_kind: buff
stat_name: attack
stat_flat: 1
duration_type: none
```

`items` と `equipment` に追加し、`item_effects` と `item_effect_links` で装備効果をつなぎます。装備効果も `item_effect_links` を使います。

## Codexを使わずに作業する時の流れ

1. この手順書と関連docsを読みます。
2. 近い既存アイテムを探します。
3. Excelで必要な行を追加します。
4. exportします。
5. validateします。
6. Godotで確認します。
7. 問題がなければcommitします。

大量追加の前に、まず10から20個程度で試します。新しい効果が必要なものは、データ追加とは別の実装Stepに分けます。

## Codexに依頼すべきタイミング

基本は手作業で進められますが、次の場合はCodexに依頼すると安全です。

- 新しい `effect_type` が必要。
- 既存効果が効かない。
- validate errorの原因が分からない。
- Godot起動時に `GameDataRegistry` warning/error が出る。
- 装備効果や攻撃時効果が動かない。
- UIや演出の実装が必要。
- save/loadやspawn挙動に影響しそう。

## 関連docs

- [GameDataRegistry Loader Map](../systems/data/game_data_registry_loader_map.md)
- [Equipment / ItemEffect Execution Path](../systems/equipment_item_effect_execution_path.md)
- [DebugSettings Deep Dive](../systems/debug_settings_deep_dive.md)
- [Data / Spawn / Save System Deep Dive](../systems/data/data_spawn_save_system_deep_dive.md)
- [Current System Reading Order](current_system_reading_order.md)
- [Feature Addition Guide](feature_addition_guide.md)
- [Codex Project Context](codex_project_context.md)
