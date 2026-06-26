from __future__ import annotations

import csv
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


PROJECT_ROOT = Path(__file__).resolve().parent.parent
MASTER_DIR = PROJECT_ROOT / "data" / "master"

RESOURCE_PATH_COLUMNS = {
    "items": ["icon_path", "resource_path"],
    "equipment": ["icon_path", "resource_path"],
    "enemies": [
        "scene_path",
        "sprite_frames_path",
        "attacked_by_player_behavior_path",
        "talk_portrait_path",
        "animation_profile_path",
        "idle_right_frames",
        "walk_right_frames",
        "idle_left_frames",
        "walk_left_frames",
        "idle_down_frames",
        "walk_down_frames",
        "idle_up_frames",
        "walk_up_frames",
    ],
    "npcs": [
        "scene_path",
        "sprite_frames_path",
        "attacked_by_player_behavior_path",
        "talk_portrait_path",
        "animation_profile_path",
        "idle_right_frames",
        "walk_right_frames",
        "idle_left_frames",
        "walk_left_frames",
        "idle_down_frames",
        "walk_down_frames",
        "idle_up_frames",
        "walk_up_frames",
    ],
}


@dataclass
class Table:
    filename: str
    header: list[str]
    rows: list[dict[str, str]]
    line_numbers: list[int]


class Reporter:
    def __init__(self) -> None:
        self.error_count = 0
        self.warning_count = 0
        self.ok_count = 0

    def ok(self, message: str) -> None:
        self.ok_count += 1
        print(f"[OK] {message}")

    def warn(self, message: str) -> None:
        self.warning_count += 1
        print(f"[WARN] {message}")

    def error(self, message: str) -> None:
        self.error_count += 1
        print(f"[ERROR] {message}")


reporter = Reporter()


def normalize_lower(value: str) -> str:
    return value.strip().lower()


def identity(value: str) -> str:
    return value.strip()


def load_tsv(filename: str) -> Table:
    path = MASTER_DIR / filename
    if not path.exists():
        reporter.error(f"missing TSV: {path}")
        return Table(filename, [], [], [])

    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f, delimiter="\t")
        try:
            header = next(reader)
        except StopIteration:
            reporter.error(f"{filename} is empty")
            return Table(filename, [], [], [])

        rows: list[dict[str, str]] = []
        line_numbers: list[int] = []
        padded_short_rows = 0

        for line_number, row in enumerate(reader, start=2):
            if not any(cell.strip() for cell in row):
                continue

            if len(row) < len(header):
                padded_short_rows += 1
                row = row + [""] * (len(header) - len(row))
            elif len(row) > len(header):
                extra = row[len(header):]
                if any(cell.strip() for cell in extra):
                    reporter.error(
                        f"{filename}:{line_number} has non-empty extra columns: {extra}"
                    )
                row = row[:len(header)]

            rows.append(dict(zip(header, row)))
            line_numbers.append(line_number)

    padding_note = f" padded_short_rows={padded_short_rows}" if padded_short_rows > 0 else ""
    reporter.ok(f"loaded {filename} rows={len(rows)} cols={len(header)}{padding_note}")
    return Table(filename, header, rows, line_numbers)


def require_column(table: Table, column: str, severity: str = "error") -> bool:
    if column in table.header:
        return True

    message = f"{table.filename} missing column: {column}"
    if severity == "warn":
        reporter.warn(message)
    else:
        reporter.error(message)
    return False


def check_duplicates(table: Table, id_column: str) -> None:
    if not require_column(table, id_column):
        return

    seen: dict[str, int] = {}
    duplicate_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        value = row.get(id_column, "").strip()
        if value == "":
            reporter.error(f"{table.filename}:{line_number} empty {id_column}")
            continue

        if value in seen:
            duplicate_count += 1
            reporter.error(
                f"{table.filename}:{line_number} duplicate {id_column} '{value}' first seen at line {seen[value]}"
            )
            continue

        seen[value] = line_number

    if duplicate_count == 0:
        reporter.ok(f"{table.filename}.{id_column} has no duplicates")


def check_composite_duplicates(table: Table, columns: list[str]) -> None:
    for column in columns:
        if not require_column(table, column):
            return

    seen: dict[tuple[str, ...], int] = {}
    duplicate_count = 0
    label = "+".join(columns)

    for row, line_number in zip(table.rows, table.line_numbers):
        values = tuple(row.get(column, "").strip() for column in columns)
        if any(value == "" for value in values):
            reporter.error(f"{table.filename}:{line_number} empty {label} value")
            continue

        if values in seen:
            duplicate_count += 1
            reporter.error(
                f"{table.filename}:{line_number} duplicate {label} '{values}' first seen at line {seen[values]}"
            )
            continue

        seen[values] = line_number

    if duplicate_count == 0:
        reporter.ok(f"{table.filename}.{label} has no duplicates")


def make_id_set(table: Table, id_column: str, normalizer: Callable[[str], str] = identity) -> set[str]:
    if id_column not in table.header:
        return set()

    result: set[str] = set()
    for row in table.rows:
        value = normalizer(row.get(id_column, ""))
        if value != "":
            result.add(value)
    return result


def check_reference(
    table: Table,
    column: str,
    valid_values: set[str],
    target_label: str,
    *,
    normalizer: Callable[[str], str] = identity,
    allow_empty: bool = False,
    severity: str = "error",
    empty_fallback: str = "",
    missing_column_severity: str = "error",
) -> None:
    if not require_column(table, column, missing_column_severity):
        return

    checked = 0
    issue_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        raw_value = row.get(column, "")
        value = normalizer(raw_value)

        if value == "":
            if allow_empty:
                if empty_fallback != "":
                    reporter.warn(
                        f"{table.filename}:{line_number} empty {column}; falls back to {empty_fallback}"
                    )
                continue

            reporter.error(f"{table.filename}:{line_number} empty {column}")
            issue_count += 1
            continue

        checked += 1
        if value not in valid_values:
            issue_count += 1
            message = (
                f"{table.filename}:{line_number} {column} '{raw_value.strip()}' not found in {target_label}"
            )
            if severity == "warn":
                reporter.warn(message)
            else:
                reporter.error(message)

    if issue_count == 0:
        reporter.ok(f"{table.filename}.{column} references {target_label} ({checked} checked)")


def check_allowed_values(
    table: Table,
    column: str,
    valid_values: set[str],
    *,
    normalizer: Callable[[str], str] = identity,
    allow_empty: bool = False,
    severity: str = "error",
) -> None:
    if not require_column(table, column):
        return

    checked = 0
    issue_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        raw_value = row.get(column, "")
        value = normalizer(raw_value)

        if value == "":
            if allow_empty:
                continue

            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} empty {column}")
            continue

        checked += 1
        if value not in valid_values:
            issue_count += 1
            message = f"{table.filename}:{line_number} {column} '{raw_value.strip()}' is not one of {sorted(valid_values)}"
            if severity == "warn":
                reporter.warn(message)
            else:
                reporter.error(message)

    if issue_count == 0:
        reporter.ok(f"{table.filename}.{column} values are valid ({checked} checked)")


def iter_resource_paths(raw_value: str) -> list[str]:
    values: list[str] = []

    for part in raw_value.split("|"):
        value = part.strip()
        if value.startswith("res://"):
            values.append(value)

    return values


def get_resource_file_path(resource_path: str) -> Path | None:
    file_part = resource_path.split("::", 1)[0].strip()
    if not file_part.startswith("res://"):
        return None

    relative_path = file_part.removeprefix("res://").replace("\\", "/")
    if relative_path == "":
        return None

    return PROJECT_ROOT / Path(*relative_path.split("/"))


def check_resource_paths(table: Table, columns: list[str]) -> None:
    checked = 0
    issue_count = 0

    for column in columns:
        if column not in table.header:
            continue

        for row, line_number in zip(table.rows, table.line_numbers):
            for resource_path in iter_resource_paths(row.get(column, "")):
                checked += 1
                file_path = get_resource_file_path(resource_path)
                if file_path is None:
                    continue

                if not file_path.exists():
                    issue_count += 1
                    relative = file_path.relative_to(PROJECT_ROOT)
                    reporter.warn(
                        f"{table.filename}:{line_number} {column} resource not found: {resource_path} -> {relative}"
                    )

    if issue_count == 0:
        reporter.ok(f"{table.filename} resource paths exist ({checked} checked)")


def check_damage_mode(table: Table) -> None:
    valid_modes = {"direct", "calculated"}
    if not require_column(table, "damage_mode", "warn"):
        return

    counts: dict[str, int] = {}
    issue_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        raw_value = row.get("damage_mode", "")
        value = normalize_lower(raw_value)
        if value == "":
            reporter.warn(f"{table.filename}:{line_number} empty damage_mode; falls back to direct")
            counts["<empty>"] = counts.get("<empty>", 0) + 1
            continue

        counts[value] = counts.get(value, 0) + 1
        if value not in valid_modes:
            issue_count += 1
            reporter.warn(
                f"{table.filename}:{line_number} damage_mode '{raw_value.strip()}' is not direct/calculated; falls back to direct"
            )

    if issue_count == 0:
        count_text = ", ".join(f"{key}={value}" for key, value in sorted(counts.items()))
        reporter.ok(f"{table.filename}.damage_mode values are valid ({count_text})")


def check_npc_quest_links(table: Table) -> None:
    for column in ("npc_type_id", "quest_id", "weight", "enabled"):
        require_column(table, column)

    issue_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        weight = parse_float_cell(table, row, line_number, "weight")
        if weight is None:
            issue_count += 1
        elif weight < 0:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} weight must be >= 0")

        if parse_bool_cell(table, row, line_number, "enabled") is None:
            issue_count += 1

    if issue_count == 0:
        reporter.ok(f"{table.filename}.weight/enabled values are valid ({len(table.rows)} checked)")


def check_localization_texts(table: Table) -> None:
    for column in ("text_key", "ja", "en", "enabled"):
        require_column(table, column)

    issue_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        if parse_bool_cell(table, row, line_number, "enabled") is None:
            issue_count += 1

        ja_text = row.get("ja", "").strip()
        en_text = row.get("en", "").strip()
        if ja_text == "" and en_text == "":
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} ja and en are both empty")

    if issue_count == 0:
        reporter.ok(f"{table.filename} localization rows are valid ({len(table.rows)} checked)")


def check_dialogue_sets(table: Table) -> None:
    for column in ("dialogue_set_id", "usage", "enabled"):
        require_column(table, column)

    issue_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        if parse_bool_cell(table, row, line_number, "enabled") is None:
            issue_count += 1

    if issue_count == 0:
        reporter.ok(f"{table.filename}.enabled values are valid ({len(table.rows)} checked)")


def check_dialogue_lines(table: Table) -> None:
    for column in ("dialogue_set_id", "line_id", "context", "text_key", "weight", "enabled"):
        require_column(table, column)

    issue_count = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        if row.get("context", "").strip() == "":
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} empty context")

        weight = parse_float_cell(table, row, line_number, "weight")
        if weight is None:
            issue_count += 1
        elif weight < 0:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} weight must be >= 0")

        if parse_bool_cell(table, row, line_number, "enabled") is None:
            issue_count += 1

    if issue_count == 0:
        reporter.ok(f"{table.filename} dialogue rows are valid ({len(table.rows)} checked)")


def check_element_resistance_keys(table: Table, element_ids: set[str]) -> None:
    if not require_column(table, "element_resistances", "warn"):
        return

    issue_count = 0
    checked = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        value = row.get("element_resistances", "").strip()
        if value == "":
            continue

        for entry in value.split("|"):
            entry = entry.strip()
            if entry == "":
                continue

            parts = entry.split("=", 1)
            if len(parts) < 2:
                issue_count += 1
                reporter.warn(f"{table.filename}:{line_number} malformed element_resistances entry '{entry}'")
                continue

            element_id = normalize_lower(parts[0])
            if element_id == "":
                continue

            checked += 1
            if element_id not in element_ids:
                issue_count += 1
                reporter.warn(
                    f"{table.filename}:{line_number} element_resistances key '{parts[0].strip()}' not found in element_types"
                )

    if issue_count == 0:
        reporter.ok(f"{table.filename}.element_resistances keys reference element_types ({checked} checked)")


def parse_int_cell(table: Table, row: dict[str, str], line_number: int, column: str) -> int | None:
    if not require_column(table, column):
        return None

    value = row.get(column, "").strip()
    if value == "":
        reporter.error(f"{table.filename}:{line_number} empty {column}")
        return None

    try:
        return int(value)
    except ValueError:
        reporter.error(f"{table.filename}:{line_number} {column} '{value}' is not an integer")
        return None


def parse_float_cell(table: Table, row: dict[str, str], line_number: int, column: str) -> float | None:
    if not require_column(table, column):
        return None

    value = row.get(column, "").strip()
    if value == "":
        reporter.error(f"{table.filename}:{line_number} empty {column}")
        return None

    try:
        return float(value)
    except ValueError:
        reporter.error(f"{table.filename}:{line_number} {column} '{value}' is not a number")
        return None


def parse_bool_cell(table: Table, row: dict[str, str], line_number: int, column: str) -> bool | None:
    if not require_column(table, column):
        return None

    value = normalize_lower(row.get(column, ""))
    if value == "":
        reporter.error(f"{table.filename}:{line_number} empty {column}")
        return None

    if value == "true":
        return True
    if value == "false":
        return False

    reporter.error(f"{table.filename}:{line_number} {column} '{row.get(column, '').strip()}' is not true/false")
    return None


def check_chest_tables(table: Table, loot_table_ids: set[str]) -> None:
    check_reference(
        table,
        "loot_table_id",
        loot_table_ids,
        "chest_loot_tables.loot_table_id",
    )

    for column in ("slot_count", "min_items", "max_items", "gold_min", "gold_max"):
        require_column(table, column)

    issue_count = 0
    for row, line_number in zip(table.rows, table.line_numbers):
        slot_count = parse_int_cell(table, row, line_number, "slot_count")
        min_items = parse_int_cell(table, row, line_number, "min_items")
        max_items = parse_int_cell(table, row, line_number, "max_items")
        gold_min = parse_int_cell(table, row, line_number, "gold_min")
        gold_max = parse_int_cell(table, row, line_number, "gold_max")

        if slot_count is not None and slot_count < 0:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} slot_count must be >= 0")

        if min_items is not None and max_items is not None and min_items > max_items:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} min_items must be <= max_items")

        if gold_min is not None and gold_max is not None and gold_min > gold_max:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} gold_min must be <= gold_max")

    if issue_count == 0:
        reporter.ok(f"{table.filename} numeric ranges are valid")


def check_chest_loot_tables(
    table: Table,
    item_category_ids: set[str],
    item_ids: set[str],
) -> None:
    for column in ("loot_table_id", "category", "item_id", "weight", "min_amount", "max_amount"):
        require_column(table, column)

    issue_count = 0
    checked_category = 0
    checked_item = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        loot_table_id = row.get("loot_table_id", "").strip()
        category = normalize_lower(row.get("category", ""))
        item_id = row.get("item_id", "").strip()

        if loot_table_id == "":
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} empty loot_table_id")

        if category == "" and item_id == "":
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} category and item_id are both empty")

        if category != "":
            checked_category += 1
            if category not in item_category_ids:
                issue_count += 1
                reporter.error(
                    f"{table.filename}:{line_number} category '{row.get('category', '').strip()}' not found in item_categories.category_id"
                )

        if item_id != "":
            checked_item += 1
            if item_id not in item_ids:
                issue_count += 1
                reporter.error(f"{table.filename}:{line_number} item_id '{item_id}' not found in items.item_id")

        weight = parse_int_cell(table, row, line_number, "weight")
        min_amount = parse_int_cell(table, row, line_number, "min_amount")
        max_amount = parse_int_cell(table, row, line_number, "max_amount")

        if weight is not None and weight < 0:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} weight must be >= 0")

        if min_amount is not None and max_amount is not None and min_amount > max_amount:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} min_amount must be <= max_amount")

    if issue_count == 0:
        reporter.ok(
            f"{table.filename} rows are valid (categories={checked_category}, item_ids={checked_item})"
        )


def check_shop_tables(table: Table, loot_table_ids: set[str]) -> None:
    check_reference(
        table,
        "loot_table_id",
        loot_table_ids,
        "shop_loot_tables.loot_table_id",
    )

    for column in ("min_items", "max_items"):
        require_column(table, column)

    issue_count = 0
    for row, line_number in zip(table.rows, table.line_numbers):
        min_items = parse_int_cell(table, row, line_number, "min_items")
        max_items = parse_int_cell(table, row, line_number, "max_items")

        if min_items is not None and max_items is not None and min_items > max_items:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} min_items must be <= max_items")

    if issue_count == 0:
        reporter.ok(f"{table.filename} numeric ranges are valid")


def check_shop_loot_tables(
    table: Table,
    item_category_ids: set[str],
    item_ids: set[str],
) -> None:
    check_chest_loot_tables(table, item_category_ids, item_ids)


def check_initial_inventory_entries(
    table: Table,
    initial_inventory_table_ids: set[str],
    item_ids: set[str],
) -> None:
    for column in (
        "inventory_table_id",
        "item_id",
        "min_amount",
        "max_amount",
        "drop_chance",
        "guaranteed",
        "roll_equipment_enchantments",
    ):
        require_column(table, column)

    issue_count = 0
    checked_tables = 0
    checked_items = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        inventory_table_id = row.get("inventory_table_id", "").strip()
        item_id = row.get("item_id", "").strip()

        if inventory_table_id == "":
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} empty inventory_table_id")
        else:
            checked_tables += 1
            if inventory_table_id not in initial_inventory_table_ids:
                issue_count += 1
                reporter.error(
                    f"{table.filename}:{line_number} inventory_table_id '{inventory_table_id}' not found in initial_inventory_tables.inventory_table_id"
                )

        if item_id == "":
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} empty item_id")
        else:
            checked_items += 1
            if item_id not in item_ids:
                issue_count += 1
                reporter.error(f"{table.filename}:{line_number} item_id '{item_id}' not found in items.item_id")

        min_amount = parse_int_cell(table, row, line_number, "min_amount")
        max_amount = parse_int_cell(table, row, line_number, "max_amount")
        drop_chance = parse_float_cell(table, row, line_number, "drop_chance")
        parse_bool_cell(table, row, line_number, "guaranteed")
        parse_bool_cell(table, row, line_number, "roll_equipment_enchantments")

        if min_amount is not None and min_amount < 1:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} min_amount must be >= 1")

        if min_amount is not None and max_amount is not None and min_amount > max_amount:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} min_amount must be <= max_amount")

        if drop_chance is not None and not 0.0 <= drop_chance <= 1.0:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} drop_chance must be between 0.0 and 1.0")

    if issue_count == 0:
        reporter.ok(
            f"{table.filename} rows are valid (tables={checked_tables}, item_ids={checked_items})"
        )


def check_item_spawn_rule_category_multipliers(table: Table) -> None:
    require_column(table, "multiplier")

    issue_count = 0
    checked = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        multiplier = parse_float_cell(table, row, line_number, "multiplier")
        if multiplier is None:
            continue

        checked += 1
        if multiplier < 0.0:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} multiplier must be >= 0")

    if issue_count == 0:
        reporter.ok(f"{table.filename}.multiplier values are valid ({checked} checked)")


def check_item_spawn_rule_item_overrides(table: Table) -> None:
    require_column(table, "weight")

    issue_count = 0
    checked = 0

    for row, line_number in zip(table.rows, table.line_numbers):
        weight = parse_int_cell(table, row, line_number, "weight")
        if weight is None:
            continue

        checked += 1
        if weight < 0:
            issue_count += 1
            reporter.error(f"{table.filename}:{line_number} weight must be >= 0")

    if issue_count == 0:
        reporter.ok(f"{table.filename}.weight values are valid ({checked} checked)")


def main() -> int:
    if not MASTER_DIR.exists():
        reporter.error(f"missing master data directory: {MASTER_DIR}")
        return 1

    filenames = {
        "item_categories": "item_categories.tsv",
        "items": "items.tsv",
        "equipment": "equipment.tsv",
        "item_effects": "item_effects.tsv",
        "item_effect_links": "item_effect_links.tsv",
        "chest_tables": "chest_tables.tsv",
        "chest_loot_tables": "chest_loot_tables.tsv",
        "shop_tables": "shop_tables.tsv",
        "shop_loot_tables": "shop_loot_tables.tsv",
        "initial_inventory_tables": "initial_inventory_tables.tsv",
        "initial_inventory_entries": "initial_inventory_entries.tsv",
        "unit_races": "unit_races.tsv",
        "unit_factions": "unit_factions.tsv",
        "faction_relations": "faction_relations.tsv",
        "element_types": "element_types.tsv",
        "damage_types": "damage_types.tsv",
        "status_effect_types": "status_effect_types.tsv",
        "localization_texts": "localization_texts.tsv",
        "dialogue_sets": "dialogue_sets.tsv",
        "dialogue_lines": "dialogue_lines.tsv",
        "quests": "quests.tsv",
        "npc_quest_links": "npc_quest_links.tsv",
        "spawn_rules": "spawn_rules.tsv",
        "item_spawn_rule_category_multipliers": "item_spawn_rule_category_multipliers.tsv",
        "item_spawn_rule_item_overrides": "item_spawn_rule_item_overrides.tsv",
        "enemies": "enemies.tsv",
        "npcs": "npcs.tsv",
        "enchantments": "enchantments.tsv",
        "dungeon_spawn_rules": "dungeon_spawn_rules.tsv",
        "unit_spawn_rules": "unit_spawn_rules.tsv",
    }

    tables = {name: load_tsv(filename) for name, filename in filenames.items()}

    duplicate_checks = {
        "item_categories": "category_id",
        "items": "item_id",
        "item_effects": "effect_id",
        "chest_tables": "chest_id",
        "shop_tables": "shop_table_id",
        "initial_inventory_tables": "inventory_table_id",
        "unit_races": "race_id",
        "unit_factions": "faction_id",
        "element_types": "element_id",
        "damage_types": "damage_type_id",
        "status_effect_types": "status_id",
        "localization_texts": "text_key",
        "dialogue_sets": "dialogue_set_id",
        "quests": "quest_id",
        "spawn_rules": "rule_id",
        "enemies": "enemy_type_id",
        "npcs": "npc_type_id",
        "enchantments": "enchant_id",
        "dungeon_spawn_rules": "rule_id",
        "unit_spawn_rules": "rule_id",
    }

    for table_name, id_column in duplicate_checks.items():
        check_duplicates(tables[table_name], id_column)

    check_composite_duplicates(tables["item_spawn_rule_category_multipliers"], ["rule_id", "category"])
    check_composite_duplicates(tables["item_spawn_rule_item_overrides"], ["rule_id", "item_id"])
    check_composite_duplicates(tables["npc_quest_links"], ["npc_type_id", "quest_id"])
    check_composite_duplicates(tables["dialogue_lines"], ["dialogue_set_id", "line_id"])

    item_ids = make_id_set(tables["items"], "item_id")
    item_category_ids = make_id_set(tables["item_categories"], "category_id", normalize_lower)
    effect_ids = make_id_set(tables["item_effects"], "effect_id")
    quest_ids = make_id_set(tables["quests"], "quest_id")
    npc_ids = make_id_set(tables["npcs"], "npc_type_id")
    item_spawn_rule_ids = make_id_set(tables["spawn_rules"], "rule_id")
    chest_loot_table_ids = make_id_set(tables["chest_loot_tables"], "loot_table_id")
    shop_ids = make_id_set(tables["shop_tables"], "shop_table_id")
    shop_loot_table_ids = make_id_set(tables["shop_loot_tables"], "loot_table_id")
    initial_inventory_table_ids = make_id_set(tables["initial_inventory_tables"], "inventory_table_id")
    faction_ids = make_id_set(tables["unit_factions"], "faction_id")
    element_ids = make_id_set(tables["element_types"], "element_id", normalize_lower)
    damage_type_ids = make_id_set(tables["damage_types"], "damage_type_id", normalize_lower)
    localization_text_keys = make_id_set(tables["localization_texts"], "text_key")
    dialogue_set_ids = make_id_set(tables["dialogue_sets"], "dialogue_set_id")

    check_reference(
        tables["items"],
        "category",
        item_category_ids,
        "item_categories.category_id",
        normalizer=normalize_lower,
    )
    check_reference(
        tables["equipment"],
        "item_id",
        item_ids,
        "items.item_id",
    )
    check_reference(
        tables["item_effect_links"],
        "item_id",
        item_ids,
        "items.item_id",
    )
    check_reference(
        tables["item_effect_links"],
        "effect_id",
        effect_ids,
        "item_effects.effect_id",
    )
    check_reference(
        tables["item_spawn_rule_category_multipliers"],
        "rule_id",
        item_spawn_rule_ids,
        "spawn_rules.rule_id",
    )
    check_reference(
        tables["item_spawn_rule_category_multipliers"],
        "category",
        item_category_ids,
        "item_categories.category_id",
        normalizer=normalize_lower,
    )
    check_item_spawn_rule_category_multipliers(tables["item_spawn_rule_category_multipliers"])
    check_reference(
        tables["item_spawn_rule_item_overrides"],
        "rule_id",
        item_spawn_rule_ids,
        "spawn_rules.rule_id",
    )
    check_reference(
        tables["item_spawn_rule_item_overrides"],
        "item_id",
        item_ids,
        "items.item_id",
    )
    check_item_spawn_rule_item_overrides(tables["item_spawn_rule_item_overrides"])
    check_chest_loot_tables(
        tables["chest_loot_tables"],
        item_category_ids,
        item_ids,
    )
    check_chest_tables(tables["chest_tables"], chest_loot_table_ids)
    check_shop_loot_tables(
        tables["shop_loot_tables"],
        item_category_ids,
        item_ids,
    )
    check_shop_tables(tables["shop_tables"], shop_loot_table_ids)
    check_initial_inventory_entries(
        tables["initial_inventory_entries"],
        initial_inventory_table_ids,
        item_ids,
    )
    check_reference(
        tables["npcs"],
        "shop_table_id",
        shop_ids,
        "shop_tables.shop_table_id",
        allow_empty=True,
    )
    for table_name in ("enemies", "npcs"):
        check_reference(
            tables[table_name],
            "initial_inventory_table_id",
            initial_inventory_table_ids,
            "initial_inventory_tables.inventory_table_id",
            allow_empty=True,
        )
    check_composite_duplicates(tables["faction_relations"], ["from_faction", "to_faction"])
    check_reference(
        tables["faction_relations"],
        "from_faction",
        faction_ids,
        "unit_factions.faction_id",
    )
    check_reference(
        tables["faction_relations"],
        "to_faction",
        faction_ids,
        "unit_factions.faction_id",
    )
    check_allowed_values(
        tables["faction_relations"],
        "relation",
        {"FRIENDLY", "NEUTRAL", "HOSTILE"},
        normalizer=lambda value: value.strip().upper(),
    )

    for table_name in ("equipment",):
        check_reference(
            tables[table_name],
            "attack_element",
            element_ids,
            "element_types.element_id",
            normalizer=normalize_lower,
            allow_empty=True,
            severity="warn",
            empty_fallback="neutral",
            missing_column_severity="warn",
        )
        check_reference(
            tables[table_name],
            "attack_damage_type",
            damage_type_ids,
            "damage_types.damage_type_id",
            normalizer=normalize_lower,
            allow_empty=True,
            severity="warn",
            empty_fallback="physical",
            missing_column_severity="warn",
        )

    for table_name in ("enemies", "npcs"):
        check_reference(
            tables[table_name],
            "element",
            element_ids,
            "element_types.element_id",
            normalizer=normalize_lower,
            allow_empty=True,
            severity="warn",
            empty_fallback="neutral",
            missing_column_severity="warn",
        )
        check_reference(
            tables[table_name],
            "default_attack_element",
            element_ids,
            "element_types.element_id",
            normalizer=normalize_lower,
            allow_empty=True,
            severity="warn",
            empty_fallback="neutral",
            missing_column_severity="warn",
        )
        check_reference(
            tables[table_name],
            "default_attack_damage_type",
            damage_type_ids,
            "damage_types.damage_type_id",
            normalizer=normalize_lower,
            allow_empty=True,
            severity="warn",
            empty_fallback="physical",
            missing_column_severity="warn",
        )
        check_element_resistance_keys(tables[table_name], element_ids)

    check_reference(
        tables["item_effects"],
        "damage_element",
        element_ids,
        "element_types.element_id",
        normalizer=normalize_lower,
        allow_empty=True,
        severity="warn",
        empty_fallback="neutral",
        missing_column_severity="warn",
    )
    check_reference(
        tables["item_effects"],
        "damage_type",
        damage_type_ids,
        "damage_types.damage_type_id",
        normalizer=normalize_lower,
        allow_empty=True,
        severity="warn",
        empty_fallback="physical",
        missing_column_severity="warn",
    )
    check_damage_mode(tables["item_effects"])
    check_reference(
        tables["npc_quest_links"],
        "npc_type_id",
        npc_ids,
        "npcs.npc_type_id",
    )
    check_reference(
        tables["npc_quest_links"],
        "quest_id",
        quest_ids,
        "quests.quest_id",
    )
    check_npc_quest_links(tables["npc_quest_links"])
    check_localization_texts(tables["localization_texts"])
    check_dialogue_sets(tables["dialogue_sets"])
    check_reference(
        tables["dialogue_lines"],
        "dialogue_set_id",
        dialogue_set_ids,
        "dialogue_sets.dialogue_set_id",
    )
    check_reference(
        tables["dialogue_lines"],
        "text_key",
        localization_text_keys,
        "localization_texts.text_key",
    )
    check_dialogue_lines(tables["dialogue_lines"])
    check_reference(
        tables["npcs"],
        "dialogue_set_id",
        dialogue_set_ids,
        "dialogue_sets.dialogue_set_id",
        allow_empty=True,
    )

    for table_name, columns in RESOURCE_PATH_COLUMNS.items():
        check_resource_paths(tables[table_name], columns)

    print()
    print(
        f"Summary: ok={reporter.ok_count} warnings={reporter.warning_count} errors={reporter.error_count}"
    )
    return 1 if reporter.error_count > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
