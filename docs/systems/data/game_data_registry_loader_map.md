# GameDataRegistry Loader Map

`scripts/data/game_data_registry.gd` は、`data/master/*.tsv` をruntime用の辞書やResourceへ変換する中心です。このdocsは、TSVを追加・変更する時に「どのloader、data class、lookup、validatorを確認するか」を迷わないための地図です。

起動時に出る `debug_print_loaded_data()` / `[GameData]` 系debug dumpの棚卸しとStep 12-Cの通常化結果は、[gamedata_registry_debug_dump_audit.md](../../backlog/gamedata_registry_debug_dump_audit.md) を参照してください。このloader mapでは読み込み順と責務を扱い、debug dumpのsummary/details flagは読み込み順やruntime validateとは別の出力制御として扱います。

## 全体像

| 段階 | 主な担当 | 内容 | 注意 |
| --- | --- | --- | --- |
| 正本編集 | `master_data.xlsx` | 各TSVの元データを編集する | TSVだけを手で直すとExcelと乖離します。 |
| export | `tools/export_master_tsv.py` | Excelから `data/master/*.tsv` を出力する | データ変更時は基本的にexportします。 |
| validate | `tools/validate_master_data.py` | 参照、範囲、bool、deprecated列などを検証する | runtime loaderより広い安全網です。 |
| runtime load | `GameDataRegistry.load_all()` | TSVを読み、辞書やResourceへ変換する | 読み込み順、fallback、post-processが重要です。 |
| runtime lookup | `GameData` lookup API / `ItemDatabase` | 各systemが読み込まれたデータを参照する | UIやmanagerは直接辞書よりAPI/wrapperを使うことが多いです。 |

## 読み込み順

`load_all()` は辞書をclearしてから、依存が少ないものから順に読みます。特に item、effect、link、enemy/npc、spawn rule は順序を崩すと参照解決が壊れます。

| 順 | Loader | 主なTSV | 理由・依存 |
| --- | --- | --- | --- |
| 1 | `_load_item_categories()` | `item_categories.tsv` | item defaultやカテゴリ表示の土台。builtin fallbackあり。 |
| 2 | `_load_status_effect_types()` | `status_effect_types.tsv` | status表示・validate用。builtin fallbackあり。 |
| 3 | `_load_element_types()` | `element_types.tsv` | damage/effect表示用。builtin fallbackあり。 |
| 4 | `_load_damage_types()` | `damage_types.tsv` | damage type表示用。builtin fallbackあり。 |
| 5 | `_load_localization_texts()` | `localization_texts.tsv` | skill/dialogue等の表示文言参照。 |
| 6 | `_load_dialogue_sets()` | `dialogue_sets.tsv` | dialogue lineの親。 |
| 7 | `_load_dialogue_lines()` | `dialogue_lines.tsv` | set別にlineを保持。 |
| 8 | `_load_skills()` | `skills.tsv` | skill本体。 |
| 9 | `_load_skill_levels()` | `skill_levels.tsv` | skill_idごとのlevel定義。 |
| 10 | `_load_items()` | `items.tsv` | item基礎。equipment/effect linkの前提。 |
| 11 | `_load_equipment()` | `equipment.tsv` | `items[item_id]` を `EquipmentData` へ差し替える。 |
| 12 | `_load_chest_tables()` | `chest_tables.tsv` | chest親テーブル。 |
| 13 | `_load_chest_loot_tables()` | `chest_loot_tables.tsv` | chest loot entry。 |
| 14 | `_load_shop_tables()` | `shop_tables.tsv` | shop親テーブル。 |
| 15 | `_load_shop_loot_tables()` | `shop_loot_tables.tsv` | shop在庫entry。 |
| 16 | `_load_initial_inventory_tables()` | `initial_inventory_tables.tsv` | Unit生成時inventory親テーブル。 |
| 17 | `_load_initial_inventory_entries()` | `initial_inventory_entries.tsv` | Unit生成時inventory entry。 |
| 18 | `_load_item_effects()` | `item_effects.tsv` | effect本体。 |
| 19 | `_load_item_effect_links()` | `item_effect_links.tsv` | item/equipmentとeffectのlink。 |
| 20 | `_apply_item_effect_links()` | post-process | `ItemData.effects` / `EquipmentData.effects` に実体を接続。 |
| 21 | `_load_skill_effect_links()` | `skill_effect_links.tsv` | skillとeffectのlink。effect読込後が必要。 |
| 22 | `_load_enchantments()` | `enchantments.tsv` | equipment instance enchantment。 |
| 23 | `_load_dungeon_spawn_rules()` | `dungeon_spawn_rules.tsv` | dungeon用Unit spawn rule。 |
| 24 | `_load_unit_spawn_rules()` | `unit_spawn_rules.tsv` | map/dungeon Unit spawn rule。 |
| 25 | `_load_unit_races()` | `unit_races.tsv` | enemy/npcのrace参照前に読む。builtin fallbackあり。 |
| 26 | `_load_unit_factions()` | `unit_factions.tsv` | enemy/npcのfaction参照前に読む。builtin fallbackあり。 |
| 27 | `_load_faction_relations()` | `faction_relations.tsv` | faction関係。builtin fallbackあり。 |
| 28 | `_load_unit_skill_tables()` | `unit_skill_tables.tsv` | Unit初期skill table親。 |
| 29 | `_load_unit_skill_entries()` | `unit_skill_entries.tsv` | Unit初期skill entry。 |
| 30 | `_load_enemies()` | `enemies.tsv` | enemy定義。item/equipment/initial inventory等を参照。 |
| 31 | `_load_npcs()` | `npcs.tsv` | NPC定義。dialogue/shop/quest/initial inventory等を参照。 |
| 32 | `_load_quests()` | `quests.tsv` | quest定義。 |
| 33 | `_load_npc_quest_links()` | `npc_quest_links.tsv` | NPCとquestのlink。NPC/quest読込後が必要。 |
| 34 | `_load_skill_requirements()` | `skill_requirements.tsv` | skill requirement。 |
| 35 | `_load_item_spawn_rule_category_multipliers()` | `item_spawn_rule_category_multipliers.tsv` | item spawn rule子テーブル。 |
| 36 | `_load_item_spawn_rule_item_overrides()` | `item_spawn_rule_item_overrides.tsv` | item spawn rule子テーブル。 |
| 37 | `_load_item_spawn_rules()` | `spawn_rules.tsv` | item spawn rule本体。子テーブルを取り込む。 |
| 38 | `debug_print_loaded_data()` | runtime debug dump | 読み込み件数summaryは `debug_game_data_load_summary`、詳細列挙は `debug_game_data_load_details` で制御。読み込み順やvalidateとは別。 |

## TSVカテゴリ別Loader Map

| カテゴリ | TSV | Loader / Builder | Runtime格納先 | 主なData class | 主な利用先 | 変更時に見るもの |
| --- | --- | --- | --- | --- | --- | --- |
| Item category | `item_categories.tsv` | `_load_item_categories()`, `_make_item_category_entry()`, `_register_item_category()` | `item_categories` | `Dictionary` | `items.tsv` default、UI表示、validator | `ItemData` default、validatorのcategory検証 |
| Item base | `items.tsv` | `_load_items()` | `items[item_id]` | `ItemData` | Inventory、Pickup、Trade、ItemDatabase | `item_data.gd`, `item_database.gd`, validator |
| Equipment | `equipment.tsv` | `_load_equipment()` | `items[item_id]` を `EquipmentData` として保持 | `EquipmentData` | Unit equipment、InventoryUI、Combat | `equipment_data.gd`, slot/attack fields, validator |
| Item effect | `item_effects.tsv` | `_load_item_effects()`, `_build_item_effect()` | `effects[effect_id]` | `ItemEffectData` | ItemEffectManager、Unit passive、Combat equipment attack | `item_effect_data.gd`, effect handler, validator |
| Item effect link | `item_effect_links.tsv` | `_load_item_effect_links()`, `_apply_item_effect_links()` | `item_effect_links[item_id]`, `item.effects` | `Dictionary` link | Consumables、equipment effects | link order、missing item/effect、validator |
| Chest table | `chest_tables.tsv` | `_load_chest_tables()` | `chest_tables[chest_type]` | `Dictionary` | ItemWorldManager chest生成 | chest loot table refs、validator |
| Chest loot | `chest_loot_tables.tsv` | `_load_chest_loot_tables()` | `chest_loot_tables[loot_table_id]` | `Dictionary` entry | chest loot抽選 | item/category refs、weight/amount |
| Shop table | `shop_tables.tsv` | `_load_shop_tables()` | `shop_tables[shop_table_id]` | `Dictionary` | merchant/trade在庫生成 | shop loot refs、validator |
| Shop loot | `shop_loot_tables.tsv` | `_load_shop_loot_tables()` | `shop_loot_tables[loot_table_id]` | `Dictionary` entry | shop在庫抽選 | item/category refs、stock/weight |
| Initial inventory table | `initial_inventory_tables.tsv` | `_load_initial_inventory_tables()` | `initial_inventory_tables[table_id]` | `Dictionary` | Enemy/NPC生成時inventory | table id refs、validator |
| Initial inventory entry | `initial_inventory_entries.tsv` | `_load_initial_inventory_entries()` | `initial_inventory_entries[inventory_table_id]` | `InitialInventoryEntry` | Unit spawn時の本体inventory | `spawn_chance`、amount、item refs |
| Enemy | `enemies.tsv` | `_load_enemies()`, `_build_enemy_data()` | `enemies[enemy_type_id]` | `EnemyData` | UnitSpawnManager、Unit.apply_enemy_data() | spawn tags、equipment、initial inventory、death drop |
| NPC | `npcs.tsv` | `_load_npcs()`, `_build_npc_data()` | `npcs[npc_type_id]` | `NpcData` | UnitSpawnManager、Dialogue、Trade、Quest | dialogue/shop/quest、initial inventory、death drop |
| Quest | `quests.tsv` | `_load_quests()` | `quests[quest_id]` | `QuestData` | QuestManager | objective/reward refs、dialogue text |
| NPC quest link | `npc_quest_links.tsv` | `_load_npc_quest_links()` | `npc_quest_links`, `npc_quest_links_by_npc` | `Dictionary` link | Dialogue/Quest | npc/quest refs、enabled |
| Dialogue set | `dialogue_sets.tsv` | `_load_dialogue_sets()` | `dialogue_sets[dialogue_set_id]` | `Dictionary` | DialogueManager | set refs、enabled |
| Dialogue line | `dialogue_lines.tsv` | `_load_dialogue_lines()` | `dialogue_lines_by_set[dialogue_set_id]` | `Dictionary` line | DialogueManager | localization key refs |
| Localization | `localization_texts.tsv` | `_load_localization_texts()` | `localization_texts[text_key]` | `Dictionary` | Dialogue、Skill表示 | missing key warnings |
| Skill | `skills.tsv` | `_load_skills()` | `skills[skill_id]` | `SkillData` | Skills node、StatusUI | `skills.gd`, validator |
| Skill level | `skill_levels.tsv` | `_load_skill_levels()` | `skill_levels_by_skill[skill_id][level]` | `SkillLevelData` | skill exp/level計算 | exp curve refs |
| Skill effect link | `skill_effect_links.tsv` | `_load_skill_effect_links()` | `skill_effect_links_by_skill[skill_id]` | `Dictionary` link | skill effect候補 | effect refs |
| Skill requirement | `skill_requirements.tsv` | `_load_skill_requirements()` | `skill_requirements_by_skill[skill_id]` | `Dictionary` | skill unlock/validation | skill refs |
| Unit skill table | `unit_skill_tables.tsv` | `_load_unit_skill_tables()` | `unit_skill_tables[table_id]` | `Dictionary` | Unit dynamic skills | table refs |
| Unit skill entry | `unit_skill_entries.tsv` | `_load_unit_skill_entries()` | `unit_skill_entries_by_table[table_id]` | `Dictionary` entry | `build_initial_dynamic_skills()` | skill refs、initial level/exp |
| Item spawn rule | `spawn_rules.tsv` | `_load_item_spawn_rules()`, `_build_item_spawn_rule()` | `item_spawn_rules`, `item_spawn_rules_by_id` | `ItemSpawnRuleData` | ItemWorldManager random item生成 | priority、theme、category multipliers |
| Item spawn category multiplier | `item_spawn_rule_category_multipliers.tsv` | `_load_item_spawn_rule_category_multipliers()` | `item_spawn_rule_category_multipliers[rule_id]` | `Dictionary` | item spawn rule post-build | category refs |
| Item spawn item override | `item_spawn_rule_item_overrides.tsv` | `_load_item_spawn_rule_item_overrides()` | `item_spawn_rule_item_overrides[rule_id]` | `Dictionary` | item spawn rule post-build | item refs |
| Unit spawn rule | `unit_spawn_rules.tsv` | `_load_unit_spawn_rules()` | `unit_spawn_rules[rule_id]` | `SpawnRuleData` | UnitSpawnManager/map scripts | generator tags、difficulty、weight |
| Dungeon spawn rule | `dungeon_spawn_rules.tsv` | `_load_dungeon_spawn_rules()` | `dungeon_spawn_rules[rule_id]` | `DungeonSpawnRuleData` | Dungeon floor生成 | floor/difficulty/theme |
| Enchantment | `enchantments.tsv` | `_load_enchantments()` | `enchantments[enchant_id]` | `EnchantmentData` | equipment instance generation | slot/type/stat refs |
| Unit race | `unit_races.tsv` | `_load_unit_races()` | `unit_races[race_id]` | `Dictionary` | Enemy/NPC表示・分類 | builtin fallback |
| Unit faction | `unit_factions.tsv` | `_load_unit_factions()` | `unit_factions[faction_id]` | `Dictionary` | Unit関係・表示 | builtin fallback |
| Faction relation | `faction_relations.tsv` | `_load_faction_relations()` | `faction_relations[source][target]` | `Dictionary` | AI/関係判定 | builtin fallback |
| Element type | `element_types.tsv` | `_load_element_types()` | `element_types[element_id]` | `Dictionary` | damage/effect表示 | builtin fallback |
| Damage type | `damage_types.tsv` | `_load_damage_types()` | `damage_types[damage_type_id]` | `Dictionary` | damage/effect表示 | builtin fallback |
| Status effect type | `status_effect_types.tsv` | `_load_status_effect_types()` | `status_effect_types[status_id]` | `Dictionary` | ItemEffectManager、StatusUI | builtin fallback |

## Data Resource Class Map

| Data class | 代表フィールド | 作られる場所 | 主な使い道 | 注意 |
| --- | --- | --- | --- | --- |
| `ItemData` | `item_id`, `category`, `max_stack`, `usable`, `can_sell`, `spawn_weight`, `effects` | `_load_items()` | inventory、pickup、trade、item表示 | `effects` は link post-process後に入ります。 |
| `EquipmentData` | slot、stat bonus、attack element/type/range/style | `_load_equipment()` | 装備、攻撃、装備効果 | `items[item_id]` が `EquipmentData` に差し替わります。 |
| `ItemEffectData` | `effect_type`, `power_min/max`, status/modifier/damage fields, `trigger_chance` | `_build_item_effect()` | 消耗品効果、装備パッシブ、装備攻撃効果 | 新effect typeは実行側も必要です。 |
| `InitialInventoryEntry` | `item_id`, `chance`, `amount_min/max`, `roll_equipment_enchantments` | `_load_initial_inventory_entries()` | Unit生成時の本体inventory候補 | `chance` は正式列 `spawn_chance` から入ります。 |
| `EnemyData` | stats、spawn tags、equipment、initial inventory、death drop、AI/talk/shop fields | `_build_enemy_data()` | enemy Unit生成 | `initial_inventory_items` はdeprecated fallbackです。 |
| `NpcData` | enemy類似 + dialogue/shop/quest fields | `_build_npc_data()` | NPC生成、会話、trade | shop inventoryと本体inventoryを混ぜない。 |
| `QuestData` | objective/reward/template fields | `_load_quests()` | QuestManager | NPC linkは別TSV。 |
| `SpawnRuleData` | generator tags、difficulty、count、weight | `_load_unit_spawn_rules()` | UnitSpawnManager | item spawn ruleとは別。 |
| `DungeonSpawnRuleData` | generator theme、floor、enemy difficulty、weight | `_load_dungeon_spawn_rules()` | dungeon enemy spawn | dungeon固有。 |
| `ItemSpawnRuleData` | priority、map kind/theme、rarity、blocked ids、multipliers | `_build_item_spawn_rule()` | field/dungeon item生成 | 子テーブルとcomposite fallbackの両方があります。 |
| `EnchantmentData` | effect type、stat、value range、weight、allowed slots | `_load_enchantments()` | 装備instance生成 | 装備drop/saveでは `instance_data` 維持が重要。 |

## Link / Build / Post-Process

| 処理 | 何を解決するか | 重要な理由 |
| --- | --- | --- |
| `_apply_item_effect_links()` | `item_effect_links.tsv` の `effect_id` を `ItemData.effects` / `EquipmentData.effects` へ実体接続 | 消耗品効果と装備効果は同じlink方式です。`equipment_effect_links.tsv` は使いません。 |
| `_load_skill_effect_links()` | skillとeffectのlinkをskillごとに保持 | `effects` 読込後でないと参照できません。 |
| `_load_npc_quest_links()` | NPCとquestのenabled linkを `npc_quest_links_by_npc` にまとめる | Dialogue/Quest入口で使います。 |
| `_get_initial_inventory_entries_for_loaded_unit()` | `initial_inventory_table_id` のentry解決と旧 `initial_inventory_items` fallback | 正式方式はtableです。旧compositeは互換用です。 |
| `_load_item_spawn_rule_category_multipliers()` / `_load_item_spawn_rule_item_overrides()` | item spawn ruleの子テーブルを先読み | `_build_item_spawn_rule()` が子テーブルを取り込みます。 |
| `_load_equipment()` | base `ItemData` を元に `EquipmentData` を作る | `items.tsv` の行が先に必要です。 |
| `_normalize_loaded_initial_inventory_table_id()` | enemy/npcのtable id正規化 | 参照欠けや空欄を安全に扱います。 |
| `_normalize_trigger_chance()` | item effectの発動率を0.0から1.0へ正規化 | 装備攻撃効果のproc判定で使います。 |

## Lookup API Map

| 領域 | 主なAPI | 主な利用先 |
| --- | --- | --- |
| Item | `get_item()`, `has_item()`, `get_all_items()`, `get_item_category()`, `has_item_category()` | ItemDatabase、InventoryUI、ItemWorldManager |
| Effect | `effects`辞書、`ItemData.effects` | ItemEffectManager、Unit、CombatManager |
| Equipment | `get_item()` 経由で `EquipmentData` を取得 | Unit装備、InventoryUI、Combat |
| Chest | `get_chest_table()`, `has_chest_table()`, `get_chest_loot_entries()` | ItemWorldManager、Chest生成 |
| Shop | `get_shop_table()`, `has_shop_table()`, `get_shop_loot_entries()` | merchant/trade在庫生成 |
| Initial inventory | `get_initial_inventory_table()`, `has_initial_inventory_table()`, `get_initial_inventory_entries()` | Enemy/NPC data、UnitSpawnManager |
| Enemy/NPC | `get_enemy()`, `has_enemy()`, `get_all_enemies()`, `get_npc()`, `has_npc()`, `get_all_npcs()` | UnitSpawnManager、map scripts |
| Quest | `get_quest()`, `has_quest()`, `get_all_quests()` | QuestManager |
| NPC quest link | `get_npc_quest_links()`, `has_npc_quest_links()`, `get_all_npc_quest_links()` | Dialogue/Quest |
| Dialogue/localization | `get_localized_text()`, `get_dialogue_set()`, `get_dialogue_lines()`, `get_random_dialogue_text()` | DialogueManager、UI |
| Skills | `get_skill()`, `get_skill_level()`, `get_skill_exp_to_next()`, `get_skill_levels()`, `build_initial_dynamic_skills()` | Skills node、StatusUI |
| Unit metadata | `get_unit_race()`, `get_unit_faction()`, `get_faction_relation()` | Unit display/AI relation |
| Combat metadata | `get_element_type()`, `get_damage_type()`, `get_status_effect_type()` | Damage/effect display、validator相当のruntime fallback |
| Spawn | `get_unit_spawn_rule()`, `get_dungeon_spawn_rule()`, `get_item_spawn_rule()`, `get_all_item_spawn_rules()` | UnitSpawnManager、map/dungeon item generation |
| Enchantment | `get_enchantment()`, `has_enchantment()`, `get_all_enchantments()` | ItemDatabase/equipment instance generation |

## Random / Spawn Candidate 関連

| 対象 | 主な場所 | ルール |
| --- | --- | --- |
| item random candidate | `scripts/item/item_database.gd` | `spawn_weight <= 0` は通常ランダム候補から除外します。明示ID指定では使えます。 |
| item spawn rule | `spawn_rules.tsv` + item spawn rule子テーブル | map kind、generator theme、difficulty、rarity、blocked category/item、overrideで候補を調整します。 |
| chest category抽選 | chest table/loot table + ItemDatabase | category抽選でも `spawn_weight <= 0` のsample装備は混ざらない方針です。 |
| shop category抽選 | shop table/loot table + ItemDatabase | 固定ID指定は有効、カテゴリ抽選はspawn候補filterを尊重します。 |
| enemy/npc spawn | `unit_spawn_rules.tsv`, `dungeon_spawn_rules.tsv`, `spawn_generator_tags` | GameDataはdata/ruleを提供し、候補選定はUnitSpawnManager/map側が担当します。 |
| sample/test enemy | `spawn_generator_tags = TEST_ONLY` | 通常GRASS/FOREST等へ混ぜない方針です。 |

## Validatorとの関係

`GameDataRegistry` はruntimeで可能な限り読みますが、master dataの品質保証は主に `tools/validate_master_data.py` が担当します。

| 検証対象 | Validatorで見ること | Runtime側で見ること |
| --- | --- | --- |
| item/equipment | ID重複、category、equipment item参照、slot等 | `ItemData` / `EquipmentData` 化、default適用 |
| item effects | effect type、範囲、`trigger_chance`、参照 | `ItemEffectData` 化、clamp/default |
| item effect links | item/effect参照、order | `item.effects` へ実体接続 |
| chest/shop | table/loot参照、item/category参照、amount/stock | table辞書とentry配列化 |
| initial inventory | table参照、item参照、`spawn_chance`、amount、bool | `InitialInventoryEntry` 化、旧 `drop_chance` fallback |
| enemy/npc | initial inventory table参照、death drop設定、resource path等 | `EnemyData` / `NpcData` 化、equipment/initial inventory解決 |
| deprecated columns | `initial_inventory_items` 非空ならwarning | 互換fallbackは残す |
| spawn rules | rule refs、range、multipliers/overrides | `SpawnRuleData` / `ItemSpawnRuleData` 化 |
| localization/dialogue/quest/skill | ID参照、key参照、重複 | lookup辞書化 |

データ列を追加する時は、最低限以下をセットで確認します。

1. `master_data.xlsx` の列
2. `data/master/*.tsv` の列
3. 対応する data Resource class
4. `GameDataRegistry` の loader/build/default処理
5. `tools/validate_master_data.py` の検証
6. 実際に使うsystem側のhandlerやlookup

## Defaults / Fallback / Deprecated

| 項目 | 現在の扱い | 注意 |
| --- | --- | --- |
| `item_categories.tsv` | TSVが無い/不足でもbuiltin fallbackを補う | ただし本番データはTSV管理が基本です。 |
| unit race/faction/relation | builtin fallbackあり | enemy/npc参照欠けを雑に増やさない。 |
| element/damage/status metadata | builtin fallbackあり | 表示名や説明はTSV側で管理する方針。 |
| item category default | item側の空欄をcategory defaultで補う | `max_stack`, `usable`, `can_sell` など。 |
| `item_effects.trigger_chance` | 空欄/列なしは `1.0`、数値は0.0から1.0へclamp | 装備攻撃効果の発動率。既存効果は空欄で100%。 |
| `initial_inventory_entries.spawn_chance` | 正式列。`guaranteed=true` なら実質1.0 | Unit生成時の所持品生成確率です。死亡時drop率ではありません。 |
| `initial_inventory_entries.drop_chance` | 旧列fallback | 新規データでは使わない。 |
| `enemies/npcs.initial_inventory_items` | deprecated legacy fallback | 新規データでは使わない。validatorは非空をwarningします。 |
| death drop settings | `drop_inventory_on_death`, `drop_equipped_items_on_death` は空欄default true、`death_inventory_drop_radius` は空欄default 5 | death dropは死亡時抽選ではなく、実際に持っているentryを落とします。 |
| sample equipment | `spawn_weight <= 0` | 明示IDやDebugSettingsでは使えるが、通常ランダム候補には出さない。 |

## 実務ガイド

### 新しいTSV列を足す

1. 既存の近い列を探します。
2. `master_data.xlsx` の対象sheetに列を追加します。
3. data Resource classにfieldを追加します。
4. `GameDataRegistry` の `_build_*` または `_load_*` で読む処理を追加します。
5. 空欄/default/fallbackの仕様を決めます。
6. `tools/validate_master_data.py` に検証を追加します。
7. `py tools\export_master_tsv.py`、`py tools\validate_master_data.py`、`git diff --check` を実行します。

### 新しいitem effect typeを足す

1. `ItemEffectData.EffectType` と列を確認します。
2. `item_effects.tsv` に既存列で表現できるか確認します。
3. 消耗品なら `ItemEffectManager`、装備攻撃効果なら `CombatManager`、装備中パッシブなら `Unit` のstat計算を見ます。
4. `item_effect_links.tsv` を使います。`equipment_effect_links.tsv` は作りません。
5. validatorでeffect type、参照、範囲を検証します。

### Enemy/NPCに所持品を持たせる

1. `initial_inventory_tables.tsv` / `initial_inventory_entries.tsv` を確認します。
2. 既存共有テーブルで足りるなら `enemies.tsv` / `npcs.tsv` の `initial_inventory_table_id` だけを設定します。
3. 新規テーブルが必要なら、entriesの `spawn_chance` は生成時確率として設定します。
4. 旧 `initial_inventory_items` は使いません。
5. 死亡時に再抽選されないことを前提に確認します。

### Random生成に混ぜたくないsample itemを残す

1. item/equipmentデータ自体は残します。
2. `spawn_weight <= 0` にして通常ランダム候補から除外します。
3. DebugSettingsや固定ID指定では使えることを確認します。
4. category抽選・chest/shop抽選から混ざらないことを確認します。

## 触ると危ない境界

| 境界 | 危ない理由 | 安全な進め方 |
| --- | --- | --- |
| `load_all()` の順序 | linkやdata buildの依存順がある | 依存元を先に読む。post-processは実体読込後にする。 |
| `items`辞書とequipment | equipmentは `items[item_id]` を置き換える | item/equipment両方のfield維持を確認する。 |
| `ItemData.effects` | 消耗品と装備が同じlink方式を使う | 片方だけのつもりでlink処理を変えない。 |
| initial inventoryとdeath drop | 名前がlootっぽいがspawn時所持品 | death時にentriesを再抽選しない。 |
| shop inventoryと本体inventory | merchantの売り物と死亡時drop対象は別 | `shop_tables` と `initial_inventory_*` を混ぜない。 |
| validatorとruntime loader | 片方だけ直すとデータ不整合を見逃す | data変更はloader/data class/validatorをセットで見る。 |
| deprecated fallback | 互換性のため残している処理がある | 削除は別Stepで監査してから。 |

## 今後の整理候補

- `GameDataRegistry` はカテゴリが多いため、将来的には item/effect/spawn/quest などのsub-loaderへ分ける候補があります。ただし、現時点では読み込み順とfallback互換性を壊すリスクが高いため、docsを足場に小さい変更を続ける方針が安全です。
- runtimeの `validate_all()` は限定的で、主な検証は `tools/validate_master_data.py` に寄っています。新列追加時に「runtimeで警告するか、validatorだけで止めるか」を毎回明確にすると安全です。
- `debug_print_loaded_data()` は読み込み確認に便利ですが、Step 12-C以降は件数summaryと詳細dumpを `DebugSettings` で分けて制御します。詳細な棚卸しと運用方針は [gamedata_registry_debug_dump_audit.md](../../backlog/gamedata_registry_debug_dump_audit.md) にあります。
