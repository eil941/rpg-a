# TSV Migration Audit

Step 5-A checked the remaining master-data surface after the current TSV migration work.

## Current master TSVs

All TSV files under `data/master` are exported by `tools/export_master_tsv.py` and loaded by `GameDataRegistry`.

| TSV | GameData load | Runtime path | Status |
| --- | --- | --- | --- |
| `item_categories.tsv` | optional master | `ItemCategories` wrapper and item loading | Complete |
| `items.tsv` | required master | `ItemDatabase` wrapper, inventory, UI, quest, trade | Complete |
| `equipment.tsv` | required master | `ItemDatabase`, normal attack data | Complete |
| `item_effects.tsv` | required master | `ItemEffectManager`, item descriptions | Complete |
| `item_effect_links.tsv` | required master | item effect linking | Complete |
| `chest_tables.tsv` | optional master | chest type selection, slot counts, and item-count ranges | Mostly complete |
| `chest_loot_tables.tsv` | optional master | chest loot category/item weighted entries | Mostly complete |
| `shop_tables.tsv` | optional master | NPC shop item-count ranges and loot table selection | Mostly complete |
| `shop_loot_tables.tsv` | optional master | NPC shop category/item weighted entries | Mostly complete |
| `initial_inventory_tables.tsv` | optional master | enemy/NPC initial inventory table selection | Mostly complete |
| `initial_inventory_entries.tsv` | optional master | enemy/NPC initial inventory item entries | Mostly complete |
| `unit_races.tsv` | optional master | enemy/npc race metadata | Complete |
| `unit_factions.tsv` | optional master | `FactionManager` compatibility path | Complete |
| `faction_relations.tsv` | optional master | `FactionManager` relation lookup | Complete |
| `element_types.tsv` | optional master | element display and validation | Complete |
| `damage_types.tsv` | optional master | damage type display and validation | Complete |
| `status_effect_types.tsv` | optional master | status display metadata | Complete |
| `quests.tsv` | required master | `QuestDatabase` wrapper and `QuestManager` | Complete |
| `spawn_rules.tsv` | required master | `ItemSpawnRuleDatabase` | Mostly complete |
| `unit_spawn_rules.tsv` | required master | `SpawnRuleDatabase` wrapper | Complete |
| `dungeon_spawn_rules.tsv` | required master | `DungeonSpawnRuleDatabase` wrapper | Complete, currently no data rows |
| `enemies.tsv` | required master | `EnemyDatabase` wrapper, maps, dungeon | Complete |
| `npcs.tsv` | required master | `NpcDatabase` wrapper, dialogue/trade | Complete |
| `enchantments.tsv` | required master | `EnchantmentDatabase` wrapper | Complete |

## Validator coverage

`tools/validate_master_data.py` now loads all current `data/master/*.tsv` files. It checks:

- duplicate IDs for all ID-based master TSVs;
- item/equipment/effect link references;
- item category references;
- faction relation pair duplicates, faction references, and relation values;
- element and damage type references used by equipment, enemies, NPCs, and item effects;
- chest table IDs, loot table references, chest loot item/category references, and amount ranges;
- shop table IDs, NPC shop table references, shop loot item/category references, and amount ranges;
- initial inventory table IDs, enemy/NPC table references, entry item references, amount ranges, drop chance, and boolean flags;
- `damage_mode` values.

Current result: `warnings=0 errors=0`.

## Remaining TSV candidates

| Candidate | Current location | Why consider TSV | Priority |
| --- | --- | --- | --- |
| `drop_tables.tsv` | unit inventory/drop flags and generated inventory | Death drops are controlled by unit rows and runtime inventory entries. Add only if drops become authored tables. | Medium |
| `item_spawn_rule_category_multipliers.tsv` | `spawn_rules.tsv.category_multipliers` dictionary cell | Existing TSV works, but child rows would validate category IDs better. | Medium |
| `item_spawn_rule_item_overrides.tsv` | `spawn_rules.tsv.item_weight_overrides` dictionary cell | Existing TSV works, but child rows would validate item IDs better. | Medium |
| `attacked_behavior_types.tsv` | `AttackedBehaviorData` resources loaded from path columns | Behavior resources are gameplay configuration; keep as resources until multiple reusable behavior profiles are needed. | Low |
| `ai_style_types.tsv` | GDScript enums plus TSV numeric columns | Enums are execution logic. TSV metadata could help display/validation later. | Low |

## Keep outside TSV

- `Texture2D`, `PackedScene`, `TileSet`, `SpriteFrames`, animation profiles, materials, and visual resources.
- `DamageCalculator`, item effect execution, AI behavior execution, targeting, and UI logic.
- Save-state compatibility adapters.
- Chest visual/UI settings that are still carried by `ChestData`, such as textures, slot UI sizing, panel background, and scene placement.

## Chest migration status

Step 5-B added `chest_tables.tsv` and `chest_loot_tables.tsv` as master data. `GameDataRegistry` loads them and `ItemWorldManager` prefers TSV chest type/loot data when present. If the TSVs are absent or a loot table has no entries, the existing `ChestData` resource path is still used.

`ChestData` resources remain in use for chest visuals, UI sizing, textures, and compatibility with `scenes/chest.tscn` / scene exports. `sample_chest*.tres` should not be deleted until those visual concerns have a separate replacement plan.

## Shop migration status

Step 5-C added `shop_tables.tsv` and `shop_loot_tables.tsv` as master data. `npcs.tsv` now has `shop_table_id`; existing `shop_min_items`, `shop_max_items`, and `shop_loot_categories` remain as compatibility fallback columns.

`GameDataRegistry` loads shop tables, and both `Unit.apply_shop_inventory_from_data()` and `UnitSpawnManager.generate_random_shop_inventory_from_data()` prefer a valid `shop_table_id`. If `shop_table_id` is empty, missing, invalid, or the referenced loot table has no entries, the existing NPC columns are still used.

The existing `food` entry in the old `shop_loot_categories` fallback normalizes to `misc` at runtime because `food` is not a registered item category. The new `general_shop_loot` TSV stores that effective category as `misc` so validator checks can stay strict without changing the intended fallback path.

## Initial inventory migration status

Step 5-D added `initial_inventory_tables.tsv` and `initial_inventory_entries.tsv` as master data. `enemies.tsv` and `npcs.tsv` now have `initial_inventory_table_id`; the existing `initial_inventory_items` composite column remains as a compatibility fallback.

`GameDataRegistry` prefers a valid `initial_inventory_table_id` with at least one TSV entry. If the table ID is empty, invalid, missing, or has no entries, the loader falls back to the old `initial_inventory_items` column. The loaded data is still converted into `InitialInventoryEntry` resources, so `Unit.apply_initial_inventory_from_data()` and death drop behavior do not need a new runtime path.

`initial_inventory_entries.tsv` includes `roll_equipment_enchantments` to preserve the fifth field from the old composite format. The `guaranteed` column maps to `chance=1.0`; otherwise `drop_chance` is used as the generation chance.

## Noted issues

- `npcs.tsv` has one `attacked_by_player_behavior_path` pointing at `res://data/test/NPC/new_sabo.tres::Resource_id2ul`; the file was not found in the current tree. This is not a TSV migration blocker because the loader safely returns `null`, but it should be checked before making attacked behavior data stricter.
- `data/_old_tres_backup` contains legacy `ItemData`, `EnemyData`, `NpcData`, `QuestData`, `SpawnRuleData`, `ItemEffectData`, and related resources. It appears to be migration backup data, not active runtime data.
- `master_sub` contains old TSV copies and appears unused by runtime code.

## Suggested next steps

1. Step 5-E: Decide whether death drops need authored `drop_tables.tsv`, or whether runtime inventory drops are enough.
2. Step 5-F: Decide whether chest UI/visual metadata should remain in `ChestData` permanently.
3. Step 5-G: Add optional validator checks for resource path columns.
4. Step 5-H: Decide whether to archive or ignore `data/_old_tres_backup` and `master_sub`.
5. Step 5-I: Remove old shop and initial inventory fallback columns only after enough playtesting confirms TSV coverage.
