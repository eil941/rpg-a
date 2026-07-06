# Damage System Notes

This note records the current TSV-driven damage setup and the compatibility rules that should be preserved while the system evolves.

## Damage mode

`item_effects.tsv` uses `damage_mode` to choose the processing path for `effect_type=deal_damage`.

- `direct`: Existing behavior. `power_min` and `power_max` are rolled as fixed HP damage in `ItemEffectManager`. This path does not use `DamageCalculator`.
- `calculated`: Uses `DamageCalculator.calculate_damage()` with item effect attack data. Item-use accuracy is already checked before the effect runs, so calculated item damage passes `skip_accuracy_check=true`.

Empty or missing `damage_mode` falls back to `direct`. Unknown values should warn and fall back to `direct`.

## Direct damage

Direct damage is the compatibility path for existing damage items.

- Uses `power_min` / `power_max`.
- Does not use defense.
- Does not use element resistance.
- Does not use critical rate.
- Does not use `DamageCalculator`.
- `damage_element` and `damage_type` are currently display/classification data only on this path.

Existing rows such as `blast_stone_damage` should remain `damage_mode=direct` unless a balance pass intentionally changes them.

## Calculated damage

Calculated item damage builds attack data for `DamageCalculator`.

Current fields:

- `calculated_power` -> `attack_data["power"]`
- `damage_element` -> `attack_data["element"]`
- `damage_type` -> `attack_data["damage_type"]`
- `bonus_accuracy` -> `attack_data["bonus_accuracy"]`
- `bonus_crit_rate` -> `attack_data["bonus_crit_rate"]`
- `ignore_defense_rate` -> `attack_data["ignore_defense_rate"]`
- `fixed_damage_bonus` -> `attack_data["fixed_damage_bonus"]`
- `skip_accuracy_check` -> `true`

Because `skip_accuracy_check=true`, `bonus_accuracy` is mostly future-facing for item effects unless item accuracy flow changes later.

## Element fields

`damage_element`, `attack_element`, and `default_attack_element` use IDs from `element_types.tsv`.

Current default is `neutral`.

- Normal weapon attack priority: weapon `attack_element`, then attacker `default_attack_element`, then `neutral`.
- Item calculated damage: item effect `damage_element`.
- Item direct damage: display/classification only.

`element_resistances` are still read from unit stats and are applied by `DamageCalculator` to calculated damage and normal attacks.

## Damage type fields

`damage_type`, `attack_damage_type`, and `default_attack_damage_type` use IDs from `damage_types.tsv`.

Current IDs:

- `physical`
- `magical`
- `true`

Current behavior:

- `physical`: Existing `DamageCalculator` formula.
- `magical`: Same as `physical` for now. There is no separate `magic_attack` or `magic_defense` stat yet.
- `true`: Defense is fully ignored in `DamageCalculator`; element resistance is still applied.

Direct damage does not use `damage_type` for runtime calculation.

## Compatibility rules

- Do not change existing item rows from `direct` to `calculated` without an explicit balance pass.
- Missing or empty element fields should fall back to `neutral`.
- Missing or empty damage type fields should fall back to `physical`.
- Missing or empty damage mode should fall back to `direct`.
- `true` damage must not ignore element resistance unless a future rule explicitly adds that behavior.
- `magical` should stay formula-compatible with `physical` until magic stats and balance rules exist.

## Calculated damage test options

Option A: Temporarily change `blast_stone_damage` to `calculated`.

- Easy to test.
- Risky because it changes a production item and can accidentally affect balance.

Option B: Add debug-only item/effect rows such as `debug_calculated_stone` and `debug_true_damage_stone`.

- Safer for repeat testing if the rows are not spawned, sold, dropped, or linked from normal content.
- Adds debug data to production TSVs, so names and usage notes must be obvious.

Option C: Add no test rows and use a manual temporary local edit when testing.

- No production data pollution.
- Manual setup is slower and easier to forget.

Recommended default: use Option C for now. If calculated damage needs repeated QA, move to Option B with clearly named debug IDs and no spawn/shop/drop links.

## Future TODO

- Decide whether debug-only master data should live in a separate TSV or dev-only sheet.
- Add separate `magic_attack` / `magic_defense` only when `magical` needs a real formula difference.
- Consider `ignore_element_resistance` or damage-type rule columns only after the current `true` behavior has been validated.
- Keep `damage_mode` and `damage_type` conceptually separate: mode chooses the processing path, type describes damage classification.
