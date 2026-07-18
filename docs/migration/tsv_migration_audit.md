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
| `item_spawn_rule_category_multipliers.tsv` | optional master | item spawn category weight multipliers | Mostly complete |
| `item_spawn_rule_item_overrides.tsv` | optional master | item spawn item-specific weight overrides | Mostly complete, currently no data rows |
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
- initial inventory table IDs, enemy/NPC table references, entry item references, amount ranges, spawn chance, and boolean flags;
- item spawn rule child tables, including rule/category pairs, rule/item pairs, category/item references, and non-negative multiplier/weight values;
- selected TSV resource path columns, including `res://...::SubResource` paths, as WARN-level existence checks;
- `damage_mode` values.

Current result after Step 5-H: `warnings=0 errors=0`.

## Remaining TSV candidates

| Candidate | Current location | Why consider TSV | Priority |
| --- | --- | --- | --- |
| `drop_tables.tsv` | unit inventory/drop flags and generated inventory | Deferred. Death drops currently use the unit's runtime inventory, so authored drop tables would duplicate initial inventory data until a separate drop-only design is needed. | Low |
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

`initial_inventory_entries.tsv` includes `roll_equipment_enchantments` to preserve the fifth field from the old composite format. The `guaranteed` column maps to `chance=1.0`; otherwise `spawn_chance` is used as the generation chance. The old `drop_chance` name remains a loader/validator fallback only.

## Death drop migration status

Step 5-E investigated authored `drop_tables.tsv` / `drop_table_entries.tsv` and deferred them. Current death drops are not a separate authored loot table. `Unit.handle_death()` calls `drop_inventory_items_on_death_if_needed()`, which collects the unit's current bag, hotbar, and optionally equipped items, then drops those entries near the unit.

Step 10-B formalized the runtime death drop rule in [../systems/combat/death_drop_spec.md](../systems/combat/death_drop_spec.md). `drop_inventory_on_death` is the parent switch for all death drops. When it is false, bag, hotbar, and equipped items are all retained. When it is true, bag and hotbar entries are dropped, and equipped entries are also dropped only if `drop_equipped_items_on_death` is true.

Step 10-D confirmed the TSV control defaults for death drop settings. Blank `drop_inventory_on_death` values are treated as `true`, blank `drop_equipped_items_on_death` values are treated as `true`, and blank `death_inventory_drop_radius` values are treated as `5`. This keeps empty TSV cells in `enemies.tsv` / `npcs.tsv` aligned with the full-drop default instead of accidentally disabling drops.

Step 10-E verified the player death drop scope with debug-only settings: `none` drops nothing, `inventory_only` drops bag + hotbar only, and `all` drops bag + hotbar + equipped items. The debug switch remains player-only and defaults to off.

`InitialInventoryEntry` chance handling happens at spawn/initialization time when entries are built and added to the unit inventory. Death-time logic does not reroll `spawn_chance`; it simply drops whatever inventory entries remain. This means `initial_inventory_tables.tsv` already covers the only currently authored source of enemy/NPC carried items.

Adding drop tables now would create two competing data sources: items granted to the unit at spawn, and separate items generated only on death. Keep `drop_tables.tsv` deferred until there is a concrete need for drop-only rewards such as boss loot, non-carried monster drops, or shared drop pools that should not appear in the unit's inventory while alive.

## Item spawn rule child table status

Step 5-F added `item_spawn_rule_category_multipliers.tsv` and `item_spawn_rule_item_overrides.tsv`. These split the former `spawn_rules.tsv` composite dictionaries into row-based child tables that can be validated against `spawn_rules.tsv`, `item_categories.tsv`, and `items.tsv`. In `master_data.xlsx`, the category multiplier sheet is named `spawn_rule_category_multipliers` because Excel worksheet names are limited to 31 characters; the exported TSV keeps the full master filename.

`GameDataRegistry` loads the child tables before `spawn_rules.tsv` is converted into `ItemSpawnRuleData`. If a child table has rows for a `rule_id`, those rows are used. If no child rows exist for a rule, the old `category_multipliers` / `item_weight_overrides` composite columns in `spawn_rules.tsv` remain as fallback.

The old composite columns are intentionally still present for compatibility and rollback during Godot verification. Once child table coverage has been tested, they can be considered for removal or left as authoring fallback.

## Resource path validation status

Step 5-G added validator checks for selected TSV columns that store `res://` resource paths. Empty cells are allowed. For Godot subresource paths such as `res://path/file.tres::Resource_id`, only the base file path is checked for existence; the subresource ID is not validated yet.

Missing resource paths are reported as WARN, not ERROR. Several loader paths can fall back to `null`, and resource references may include optional visual or behavior data, so making these strict errors immediately would block migration work before each optional path has been classified.

Step 5-H cleared the orphaned `npcs.tsv:2 attacked_by_player_behavior_path` reference to `res://data/test/NPC/new_sabo.tres::Resource_id2ul`. That resource only exists under `data/_old_tres_backup`, so the master `npcs` row now leaves the optional attacked behavior path empty.

Current missing resource paths: none.

Future tightening should classify path columns as required or optional before promoting any WARN to ERROR. `attacked_by_player_behavior_path` should remain optional unless attacked behavior data becomes mandatory for all NPCs.

## Scene/resource path audit status

Step 5-I audited non-TSV `res://data/test/NPC/new_sabo.tres` references in active scenes and scripts. Active scene references were removed from `scenes/Main.tscn`, `scenes/dungeon_main.tscn`, `scenes/start_field.tscn`, `scenes/twon_test1.tscn`, and `scenes/npc_debug_map_special_reworked.tscn`.

The normal map and dungeon scenes now leave old exported enemy/NPC data arrays empty; their scripts fall back to `EnemyDatabase` / `NpcDatabase`, which read the TSV-backed `GameData`. The special debug map now stores `npc_type_id = "no_id"` on its `SpecialMapUnitEntry`, and the entry resolves that ID through `NpcDatabase` when no direct `NpcData` resource is assigned.

The legacy `new_sabo.tres` resource was not restored from `data/_old_tres_backup`. Step 5-J later removed tracked Godot `.tmp` scene snapshots, so the remaining text hits are limited to this audit document, `master_sub`, and `data/_old_tres_backup`.

## Legacy backup/copy cleanup status

Step 5-J classified the remaining post-migration legacy data:

- `data/_old_tres_backup`: 124 tracked files. These are old resource-based master data backups (`ItemData`, `EnemyData`, `NpcData`, quest, spawn rule, item effect, equipment, and test resources). No active scene/script reference to `res://data/_old_tres_backup` was found outside the backup folder itself. Keep this directory as migration backup for now; do not restore resources from it unless a specific behavior needs to be recovered.
- `master_sub`: 11 tracked TSV files. This appears to be an old TSV copy set and is not used by `tools/export_master_tsv.py`, `tools/validate_master_data.py`, or active runtime loading. Keep it as a legacy copy for now; it is a future deletion/archive candidate after user review.
- Godot `.tmp` scene snapshots: 33 tracked `scenes/*.tmp` files were removed. They were editor temporary snapshots, not active scenes, and several still contained stale `res://data/test` resource paths. `.gitignore` now ignores `*.tmp` and `*.tmp.*` so new editor snapshots are not added accidentally.

## Completion decision

Step 5-K records the TSV migration completion decision in [tsv_migration_completion.md](tsv_migration_completion.md).

The current master-data TSV scope is complete enough to treat TSV/Excel as the authoritative source. Remaining Resources are intentional: visuals/UI, optional behavior profiles, runtime compatibility containers, and fallback data that should be kept until Godot playtesting confirms TSV coverage.

## Noted issues

- The old `npcs.tsv` attacked behavior reference to `res://data/test/NPC/new_sabo.tres::Resource_id2ul` was cleared in Step 5-H. If NPC attacked behavior should be restored later, create or restore an intentional `AttackedBehaviorData` resource and reference that new path.
- `data/_old_tres_backup` contains legacy `ItemData`, `EnemyData`, `NpcData`, `QuestData`, `SpawnRuleData`, `ItemEffectData`, and related resources. It appears to be migration backup data, not active runtime data.
- `master_sub` contains old TSV copies and appears unused by runtime code.
- The tracked `scenes/*.tmp` Godot scene snapshots were removed in Step 5-J. If a deleted snapshot was intentionally kept for comparison, recover it from Git history rather than recreating it as runtime data.

## Suggested next steps

1. Decide whether chest UI/visual metadata should remain in `ChestData` permanently.
2. Decide whether attacked behavior resources should stay as optional `.tres` resources or gain a dedicated TSV metadata table later.
3. Decide whether to archive or delete `data/_old_tres_backup` and `master_sub` after TSV migration is fully accepted.
4. Remove old shop, initial inventory, and item spawn fallback columns only after enough playtesting confirms TSV coverage.
5. Future drop step: Add `drop_tables.tsv` only when drop-only rewards are needed separately from carried inventory.
