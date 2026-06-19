from __future__ import annotations

import csv
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


PROJECT_ROOT = Path(__file__).resolve().parent.parent
MASTER_DIR = PROJECT_ROOT / "data" / "master"


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


def main() -> int:
    if not MASTER_DIR.exists():
        reporter.error(f"missing master data directory: {MASTER_DIR}")
        return 1

    filenames = {
        "items": "items.tsv",
        "equipment": "equipment.tsv",
        "item_effects": "item_effects.tsv",
        "item_effect_links": "item_effect_links.tsv",
        "quests": "quests.tsv",
        "enemies": "enemies.tsv",
        "npcs": "npcs.tsv",
        "enchantments": "enchantments.tsv",
        "element_types": "element_types.tsv",
        "damage_types": "damage_types.tsv",
        "status_effect_types": "status_effect_types.tsv",
        "unit_races": "unit_races.tsv",
        "unit_factions": "unit_factions.tsv",
    }

    tables = {name: load_tsv(filename) for name, filename in filenames.items()}

    duplicate_checks = {
        "items": "item_id",
        "item_effects": "effect_id",
        "quests": "quest_id",
        "enemies": "enemy_type_id",
        "npcs": "npc_type_id",
        "enchantments": "enchant_id",
        "element_types": "element_id",
        "damage_types": "damage_type_id",
        "status_effect_types": "status_id",
        "unit_races": "race_id",
        "unit_factions": "faction_id",
    }

    for table_name, id_column in duplicate_checks.items():
        check_duplicates(tables[table_name], id_column)

    item_ids = make_id_set(tables["items"], "item_id")
    effect_ids = make_id_set(tables["item_effects"], "effect_id")
    element_ids = make_id_set(tables["element_types"], "element_id", normalize_lower)
    damage_type_ids = make_id_set(tables["damage_types"], "damage_type_id", normalize_lower)

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

    print()
    print(
        f"Summary: ok={reporter.ok_count} warnings={reporter.warning_count} errors={reporter.error_count}"
    )
    return 1 if reporter.error_count > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
