# Death Drop Specification

Step 10-B confirms the current death drop behavior as the formal runtime rule.

HP0から `Unit.handle_death()`、ItemDropHelper、WorldState保存までの実装経路は [death_path_diagram.md](death_path_diagram.md) を参照してください。

## Death trigger

A unit is considered dead when its HP reaches 0 or less. Any gameplay path that reduces HP to 0 must reach the common unit death path exactly once.

Current audited paths:

- Normal bump/attack damage uses `Stats.take_damage()`.
- Selected target item damage uses `ItemEffectManager`, then `Stats.take_damage()` or a direct HP fallback followed by `Unit.check_death()`.
- Equipment attack `deal_damage` effects use `Stats.take_damage()`.
- Hunger starvation damage uses `Stats.take_damage()` or a direct HP fallback followed by `Unit.check_death("starvation")`.
- Runtime status ticks use `Stats.take_damage()` or a direct HP fallback followed by `Unit.check_death("status_*")`.
- Offscreen status elapsed damage directly reduces HP and then calls `Unit.check_death("offscreen_status_*")`.
- Loading a saved unit with HP 0 or less calls `Unit.check_death("load")`.

`Stats.take_damage()` calls `Stats.die()` when HP reaches 0. `Stats.die()` calls `Unit.handle_death()`. `Unit.check_death()` also calls `Unit.handle_death()` when HP is 0 or less.

`Unit.handle_death()` is guarded by `death_handled`, so repeated calls from `die()`, `check_death()`, attack cleanup, item effects, or status ticks do not duplicate death drops.

## Drop flags

`drop_inventory_on_death` is the parent switch for all death drops.

| drop_inventory_on_death | drop_equipped_items_on_death | Dropped entries |
| --- | --- | --- |
| `false` | any value | Nothing |
| `true` | `false` | Inventory bag and hotbar only |
| `true` | `true` | Inventory bag, hotbar, and equipped items |

If `drop_inventory_on_death=false`, equipped items are not dropped even when `drop_equipped_items_on_death=true`.

## Player scope verification

Step 10-E verified the player death drop scope with debug-only settings:

- `none`: no drops;
- `inventory_only`: inventory bag and hotbar only;
- `all`: inventory bag, hotbar, and equipped items.

The debug scope switch is player-only and defaults to off, so normal play, enemies, and NPCs are unaffected.

## TSV blank defaults

Enemy and NPC TSV rows may leave the death drop columns blank. Blank values are treated as the full-drop default:

- `drop_inventory_on_death` blank default: `true`
- `drop_equipped_items_on_death` blank default: `true`
- `death_inventory_drop_radius` blank default: `5`

This means a row with all three columns blank drops inventory bag, hotbar, and equipped items on death. Blank boolean values must not be interpreted as `false`.

## Inventory and hotbar

The inventory bag and hotbar are both treated as carried inventory for death drops.

They are stored as separate entry arrays. If the same `item_id` exists in both the bag and hotbar as separate entries, both are dropped because the unit is actually carrying both entries.

After each successful drop, the source slot is cleared:

- bag entries clear the inventory slot;
- hotbar entries clear the hotbar slot;
- equipped entries clear the equipment slot.

Stack amounts are preserved in the dropped entry. Entries with `instance_data` are preserved and are not merged as stackable world pickups.

## Equipped items

When `drop_equipped_items_on_death=true`, all current equipment slots are candidates:

- `right_hand`
- `left_hand`
- `head`
- `body`
- `hands`
- `waist`
- `feet`
- `accessory_1`
- `accessory_2`
- `accessory_3`
- `accessory_4`

Equipped item entries are duplicated with their full entry data. Enchanted equipment keeps its `instance_data`, and `ItemPickup` saves that entry data back into world pickup state.

## Drop placement

`death_inventory_drop_radius` controls the nearby tile search radius. Runtime code clamps it to at least 1.

The drop helper first tries the unit tile when valid. If the unit tile already has a pickup or cannot accept a drop, it searches nearby valid empty tiles up to the radius. Stackable entries can merge into an existing compatible pickup on the unit tile.

## Initial inventory relationship

`initial_inventory_table_id` and `initial_inventory_entries.tsv` are spawn-time carried inventory rules.

Death-time logic does not reroll `initial_inventory_entries.tsv`. It only drops the item entries that currently exist in the unit's inventory bag, hotbar, and optionally equipment.

The old `initial_inventory_items` column remains only as a deprecated compatibility fallback.

## No authored death loot tables

There is no `drop_tables.tsv` or `drop_table_entries.tsv` in the current formal design.

Adding authored death-only loot tables is deferred until the game needs rewards that should not exist as carried inventory while the unit is alive.

## Current data baseline

Current enemy and NPC data uses:

- `drop_inventory_on_death=true`
- `drop_equipped_items_on_death=true`
- `death_inventory_drop_radius=5`

That means current enemies and NPCs are configured to drop all carried bag, hotbar, and equipped entries on death.

## Implementation guardrails

New HP damage paths should call `Stats.take_damage()` whenever possible. If a path must directly set or subtract HP, it must call `Unit.check_death()` immediately after the mutation.

Do not add death-time inventory rerolls, `drop_tables.tsv`, or `drop_table_entries.tsv` unless a future design explicitly needs drop-only rewards.
