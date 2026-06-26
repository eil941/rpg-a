# TSV Migration Completion

This document records the Step 5-K completion decision for the master-data TSV migration.

## Completion Decision

The TSV migration can be treated as complete for the current master-data scope.

The authoritative master-data sources are now:

- `master_data.xlsx`
- `data/master/*.tsv`
- `tools/export_master_tsv.py`
- `tools/validate_master_data.py`

The completed TSV-managed areas are:

| Area | TSV source | Completion status |
| --- | --- | --- |
| Items | `items.tsv` | Complete |
| Equipment | `equipment.tsv` | Complete |
| Item effects | `item_effects.tsv`, `item_effect_links.tsv` | Complete |
| Quests | `quests.tsv` | Complete |
| Item spawn rules | `spawn_rules.tsv`, `item_spawn_rule_category_multipliers.tsv`, `item_spawn_rule_item_overrides.tsv` | Complete, fallback columns retained |
| Enemies | `enemies.tsv` | Complete |
| NPCs | `npcs.tsv` | Complete |
| Enchantments | `enchantments.tsv` | Complete |
| Chests | `chest_tables.tsv`, `chest_loot_tables.tsv` | Complete for loot/type data, Resource retained for visuals/UI/fallback |
| Shops | `shop_tables.tsv`, `shop_loot_tables.tsv` | Complete, fallback columns retained |
| Initial inventory | `initial_inventory_tables.tsv`, `initial_inventory_entries.tsv` | Complete, fallback column retained |
| Unit metadata | `unit_races.tsv`, `unit_factions.tsv`, `faction_relations.tsv` | Complete |
| Combat metadata | `element_types.tsv`, `damage_types.tsv`, `status_effect_types.tsv` | Complete for metadata |

Validation status at Step 5-K:

- `tools/export_master_tsv.py`: OK
- `tools/validate_master_data.py`: `warnings=0 errors=0`
- `git diff --check`: OK

## Resources To Keep

### ChestData

`ChestData` should remain as a Resource for now.

Keep in `ChestData`:

- closed/opened textures;
- inventory slot count applied to the chest scene;
- put/take permissions;
- allowed/denied item category filters;
- shared/one-time/special function flags;
- UI panel size, slot size, slot columns, and background;
- compatibility fallback loot settings.

TSV is authoritative for:

- chest ID / display name;
- min/max generated items;
- gold min/max;
- loot table ID;
- weighted loot category/item entries and amount ranges.

Do not delete `scripts/item/chest/sample_chest.tres` or `sample_chest2.tres` yet. Active scenes still export `chest_data_list`, `scenes/chest.tscn` uses a default `ChestData`, and UI/visual settings have no TSV replacement.

### AttackedBehaviorData

`AttackedBehaviorData` should remain an optional Resource for now.

It is loaded through `attacked_by_player_behavior_path` on enemies/NPCs and applied only when a unit is attacked. The path can be empty. Missing/empty data falls back to existing behavior without crashing.

Keep as Resource because it represents behavior configuration:

- whether the unit becomes hostile;
- whether behavior changes;
- optional combat style override;
- optional move style override.

Do not TSV-ize it until multiple reusable behavior profiles are actively needed. If that happens, prefer a small metadata table such as `attacked_behavior_types.tsv`, while keeping behavior execution in GDScript.

### Visual And Runtime Resources

Keep these outside TSV:

- `Texture2D`, `TileSet`, `PackedScene`, `SpriteFrames`, materials, sounds, animation profiles, and UI background resources;
- `ChestData` for chest visuals/UI/compatibility;
- `AttackedBehaviorData` for optional behavior profiles;
- small runtime Resource containers such as `InitialInventoryEntry` and `LootCategoryEntry` while they are still used as in-memory compatibility objects.

## Fallback Columns

Do not remove fallback columns yet.

| Fallback | Current replacement | Delete now? | Reason |
| --- | --- | --- | --- |
| `shop_min_items` | `shop_tables.tsv.min_items` | No | Still read by `GameDataRegistry`, `Unit`, and `UnitSpawnManager` if `shop_table_id` is empty or invalid. |
| `shop_max_items` | `shop_tables.tsv.max_items` | No | Same as above. |
| `shop_loot_categories` | `shop_loot_tables.tsv` | No | Same as above, and useful for rollback while playtesting shops. |
| `initial_inventory_items` | `initial_inventory_entries.tsv` | No | Still parsed as fallback if `initial_inventory_table_id` is empty, invalid, or has no entries. Death drops depend on the generated runtime inventory. |
| `category_multipliers` | `item_spawn_rule_category_multipliers.tsv` | No | Still parsed when child rows are absent; keep until item spawn has been verified across maps/dungeons. |
| `item_weight_overrides` | `item_spawn_rule_item_overrides.tsv` | No | Same as above. |

Deletion condition:

1. Godot startup and map loads are verified.
2. Chests, shops, initial inventory, item spawn, and dungeon spawn are playtested.
3. Every row has TSV child-table coverage where needed.
4. A backup point exists before removing columns from `master_data.xlsx`, TSVs, loaders, and data classes.

## Legacy Backup And Old Copies

### data/_old_tres_backup

Keep for now.

This directory contains old Resource-based master data. No active runtime reference to `res://data/_old_tres_backup` was found outside the backup folder itself. It is useful as migration history and recovery material, but it should not be treated as runtime data.

Future deletion/archive condition:

- the TSV migration has been accepted after Godot verification;
- no data recovery from old `.tres` files is needed;
- the directory is archived externally or intentionally removed in a dedicated cleanup step.

### master_sub

Keep for now.

`master_sub` appears to be an old TSV copy set. It is not used by export, validation, or active runtime loading. It is a future archive/delete candidate, but it should be removed only in a dedicated cleanup step.

### Godot .tmp Scene Snapshots

Tracked `scenes/*.tmp` snapshots were removed in Step 5-J. `.gitignore` now ignores `*.tmp` and `*.tmp.*`.

## Current Hold Items

These are intentionally not part of the current TSV completion:

- `drop_tables.tsv`: deferred until drop-only rewards are needed separately from carried inventory;
- `attacked_behavior_types.tsv`: deferred until reusable attacked behavior profiles are needed;
- magical damage formula / magic attack / magic defense: deferred until the combat stat model is designed;
- removal of fallback columns: deferred until playtesting confirms TSV coverage.

## Step 6 Regression Data

Step 6 verified that `master_data.xlsx` can be used as the operational source for adding and exporting gameplay data across multiple related TSVs.

The following `test_` data is intentionally retained as regression-check data:

| ID | Area | Purpose | Notes |
| --- | --- | --- | --- |
| `test_iron_ore` | `items.tsv` | Material item add/export check | `spawn_weight=0`; used by the test delivery quest. |
| `test_small_heal_herb` | `items.tsv`, `item_effects.tsv`, `item_effect_links.tsv` | Consumable + effect + link check | Restores 10 HP through existing `restore_resource`; `spawn_weight=0`. |
| `test_copper_ring` | `items.tsv`, `equipment.tsv` | Equipment add/export check | Accessory with `max_hp_bonus=3`; debug start item only. |
| `test_training_slime` | `enemies.tsv` | Enemy add/export check | FOREST candidate for manual enemy load/spawn checks. |
| `test_helper_villager` | `npcs.tsv` | NPC add/export and quest-giver check | GRASS candidate; `can_offer_request=true`; no shop. |
| `test_iron_ore_delivery` | `quests.tsv` | Quest add/export check | Delivery quest requiring `test_iron_ore` x1 and rewarding 50 gold. |
| `test_grass_helper_villager_spawn` | `unit_spawn_rules.tsv` | GRASS NPC spawn regression check | `spawn_kind=NPC`, `allowed_generator_types=GRASS`, `max_spawn_count=1`. |
| `test_helper_villager` links | `npc_quest_links.tsv` | Explicit NPC-to-quest link and weighted candidate check | Three enabled links are retained for this NPC only. |

Retained `npc_quest_links.tsv` rows:

| npc_type_id | quest_id | weight | enabled |
| --- | --- | ---: | --- |
| `test_helper_villager` | `test_iron_ore_delivery` | 100 | true |
| `test_helper_villager` | `quest_fixed_apple_delivery` | 100 | true |
| `test_helper_villager` | `quest_villager_material_delivery` | 100 | true |

NPC request state after cleanup:

| npc_type_id | can_offer_request | Reason |
| --- | --- | --- |
| `no_id` | false | Restored after temporary Step 6-G broad link test. |
| `npc_1` | false | Restored after temporary Step 6-G broad link test. |
| `test_helper_villager` | true | Kept as the dedicated regression quest giver. |

Step 6 history:

| Step | Result |
| --- | --- |
| Step 6-A | Added `test_iron_ore` to verify item-only additions from Excel to TSV. |
| Step 6-B | Added `test_small_heal_herb`, `test_small_heal_herb_restore_hp`, and the item/effect link. |
| Step 6-B helper | Added Step 6 test items to debug start inventory. |
| Step 6-C | Added `test_copper_ring` to verify equipment additions. |
| Step 6-C repair | HP recovery now uses effective max HP so equipment `max_hp_bonus` can be healed into. |
| Step 6-D | Added `test_training_slime` to verify enemy additions. |
| Step 6-D helpers | Moved `test_training_slime` into the FOREST candidate set for practical checks. |
| Step 6-E | Added `test_helper_villager` to verify NPC additions. |
| Step 6-F | Added `test_iron_ore_delivery` and linked it to `test_helper_villager`. |
| Step 6-F repair | Added a minimal GRASS NPC spawn rule and fixed NPC candidate collection to include all TSV-loaded NPCs. |
| Step 6-G | Added `npc_quest_links.tsv` and explicit NPC-to-quest link loading/validation. |
| Step 6-G helper | Temporarily added links to all NPCs to verify multiple linked quest candidates and weighting. |
| Step 6-H | Removed broad temporary NPC links and restored `no_id` / `npc_1` request settings. |
| Step 6-I | Kept only focused regression data and reduced the GRASS helper villager spawn count to 1. |

Operational regression checks should use a New Game, runtime state reset, quest reset, or regenerated map when testing quest generation, because saved/generated quest state can cache older candidates.

## Step 7 Localization Foundation

Step 7-A added `localization_texts.tsv` as a lightweight foundation for future multilingual text management.

Current scope:

- `master_data.xlsx` now has a `localization_texts` sheet.
- `data/master/localization_texts.tsv` is exported from that sheet.
- `GameDataRegistry` loads enabled localization rows and exposes lookup helpers.
- `validate_master_data.py` checks `text_key`, `enabled`, duplicate keys, and empty `ja`/`en` text.

The existing display fields are intentionally unchanged for now. `items` names/descriptions, quest titles/descriptions, NPC dialogue, skill text, and UI text still use their current columns and runtime paths. Future migration steps can add text key columns and switch individual display surfaces gradually.

Step 7-B added lightweight dialogue master tables:

- `dialogue_sets.tsv` stores enabled dialogue set metadata.
- `dialogue_lines.tsv` stores enabled dialogue line candidates by set and context.
- Dialogue lines reference `localization_texts.tsv.text_key`.
- `npcs.tsv.dialogue_set_id` is optional and currently set only for `test_helper_villager`.
- Existing NPC talk display is intentionally unchanged and still uses `npcs.talk_greeting_text`.

Step 7-B regression data:

| Area | ID / key | Purpose |
| --- | --- | --- |
| `dialogue_sets.tsv` | `test_helper_villager_default` | Dialogue set foundation check for the Step 6 helper villager. |
| `dialogue_lines.tsv` | `greeting_1`, `greeting_2` | Two weighted `greeting` candidates for `test_helper_villager_default`. |
| `localization_texts.tsv` | `dialogue.test_helper_villager.greeting.1` | Japanese/English text for the first greeting candidate. |
| `localization_texts.tsv` | `dialogue.test_helper_villager.greeting.2` | Japanese/English text for the second greeting candidate. |

Future dialogue display migration can switch individual NPC talk surfaces from `talk_greeting_text` to `dialogue_set_id` after Godot-side UI behavior is verified.

## Final Completion Checklist

- [x] Master TSVs export from `master_data.xlsx`.
- [x] Validator reports `warnings=0 errors=0`.
- [x] Damage/item/element/status metadata is TSV-managed.
- [x] Chest/shop/initial inventory/item spawn child tables are TSV-managed.
- [x] Active scene missing `new_sabo.tres` references were removed.
- [x] Godot `.tmp` scene snapshots were removed and ignored.
- [x] Legacy backups are classified and retained intentionally.
- [ ] Godot editor/runtime verification after the cleanup.
- [ ] Optional later cleanup of fallback columns.
- [ ] Optional later archive/delete of `data/_old_tres_backup` and `master_sub`.
