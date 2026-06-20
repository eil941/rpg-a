# validate_master_data.py
# data/master/*.tsv の参照整合性を確認する簡易validatorです。

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data" / "master"
ITEM_CATEGORIES_GD = PROJECT_ROOT / "scripts" / "data" / "item_categories.gd"


class ValidationContext:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def warning(self, message: str) -> None:
        self.warnings.append(message)


def read_tsv(path: Path, ctx: ValidationContext, required: bool = True) -> list[dict[str, str]]:
    if not path.exists():
        if required:
            ctx.error(f"missing TSV: {path}")
        return []

    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        return [dict(row) for row in reader]


def require_columns(table_name: str, rows: list[dict[str, str]], columns: list[str], ctx: ValidationContext) -> None:
    if not rows:
        return

    actual = set(rows[0].keys())
    for column in columns:
        if column not in actual:
            ctx.error(f"{table_name}: missing column {column}")


def collect_ids(rows: list[dict[str, str]], column: str) -> set[str]:
    result: set[str] = set()
    for row in rows:
        value = str(row.get(column, "")).strip()
        if value:
            result.add(value)
    return result


def collect_categories(items_rows: list[dict[str, str]]) -> set[str]:
    categories: set[str] = set()

    # item_categories.tsv がない現状に合わせ、ItemCategories.ALL の定数から収集する。
    if ITEM_CATEGORIES_GD.exists():
        text = ITEM_CATEGORIES_GD.read_text(encoding="utf-8")
        for match in re.finditer(r'const\s+\w+\s*:\s*StringName\s*=\s*&"([^"]+)"', text):
            categories.add(match.group(1).strip().lower())

    # 念のため items.tsv 側に存在するカテゴリも許可する。
    for row in items_rows:
        category = str(row.get("category", "")).strip().lower()
        if category:
            categories.add(category)

    return categories


def is_number(value: str) -> bool:
    try:
        float(value)
    except ValueError:
        return False
    return True


def validate_numeric_non_negative(table_name: str, row_index: int, column: str, value: str, ctx: ValidationContext) -> None:
    value = value.strip()
    if value == "":
        ctx.error(f"{table_name}: row {row_index}: {column} is empty")
        return

    if not is_number(value):
        ctx.error(f"{table_name}: row {row_index}: {column} is not numeric: {value}")
        return

    if float(value) < 0:
        ctx.error(f"{table_name}: row {row_index}: {column} must be >= 0: {value}")


def validate_unique_pair(table_name: str, rows: list[dict[str, str]], col_a: str, col_b: str, ctx: ValidationContext) -> None:
    seen: set[tuple[str, str]] = set()
    for index, row in enumerate(rows, start=2):
        value_a = str(row.get(col_a, "")).strip()
        value_b = str(row.get(col_b, "")).strip()
        key = (value_a, value_b)
        if key in seen:
            ctx.error(f"{table_name}: row {index}: duplicate {col_a}+{col_b}: {value_a}+{value_b}")
        seen.add(key)


def validate_item_spawn_rule_category_multipliers(
    rows: list[dict[str, str]],
    rule_ids: set[str],
    categories: set[str],
    ctx: ValidationContext,
) -> None:
    table_name = "item_spawn_rule_category_multipliers"
    require_columns(table_name, rows, ["rule_id", "category", "multiplier"], ctx)
    validate_unique_pair(table_name, rows, "rule_id", "category", ctx)

    for index, row in enumerate(rows, start=2):
        rule_id = str(row.get("rule_id", "")).strip()
        category = str(row.get("category", "")).strip().lower()
        multiplier = str(row.get("multiplier", "")).strip()

        if not rule_id:
            ctx.error(f"{table_name}: row {index}: rule_id is empty")
        elif rule_id not in rule_ids:
            ctx.error(f"{table_name}: row {index}: rule_id not found in spawn_rules.tsv: {rule_id}")

        if not category:
            ctx.error(f"{table_name}: row {index}: category is empty")
        elif category not in categories:
            ctx.error(f"{table_name}: row {index}: category is unknown: {category}")

        validate_numeric_non_negative(table_name, index, "multiplier", multiplier, ctx)


def validate_item_spawn_rule_item_overrides(
    rows: list[dict[str, str]],
    rule_ids: set[str],
    item_ids: set[str],
    ctx: ValidationContext,
) -> None:
    table_name = "item_spawn_rule_item_overrides"
    require_columns(table_name, rows, ["rule_id", "item_id", "weight"], ctx)
    validate_unique_pair(table_name, rows, "rule_id", "item_id", ctx)

    for index, row in enumerate(rows, start=2):
        rule_id = str(row.get("rule_id", "")).strip()
        item_id = str(row.get("item_id", "")).strip()
        weight = str(row.get("weight", "")).strip()

        if not rule_id:
            ctx.error(f"{table_name}: row {index}: rule_id is empty")
        elif rule_id not in rule_ids:
            ctx.error(f"{table_name}: row {index}: rule_id not found in spawn_rules.tsv: {rule_id}")

        if not item_id:
            ctx.error(f"{table_name}: row {index}: item_id is empty")
        elif item_id not in item_ids:
            ctx.error(f"{table_name}: row {index}: item_id not found in items.tsv: {item_id}")

        validate_numeric_non_negative(table_name, index, "weight", weight, ctx)


def main() -> int:
    ctx = ValidationContext()

    spawn_rules = read_tsv(DATA_DIR / "spawn_rules.tsv", ctx)
    items = read_tsv(DATA_DIR / "items.tsv", ctx)
    category_multipliers = read_tsv(DATA_DIR / "item_spawn_rule_category_multipliers.tsv", ctx)
    item_overrides = read_tsv(DATA_DIR / "item_spawn_rule_item_overrides.tsv", ctx)

    rule_ids = collect_ids(spawn_rules, "rule_id")
    item_ids = collect_ids(items, "item_id")
    categories = collect_categories(items)

    validate_item_spawn_rule_category_multipliers(category_multipliers, rule_ids, categories, ctx)
    validate_item_spawn_rule_item_overrides(item_overrides, rule_ids, item_ids, ctx)

    for warning in ctx.warnings:
        print(f"[WARN] {warning}")
    for error in ctx.errors:
        print(f"[ERROR] {error}")

    print(f"validate complete: errors={len(ctx.errors)} warnings={len(ctx.warnings)}")
    return 1 if ctx.errors else 0


if __name__ == "__main__":
    sys.exit(main())
