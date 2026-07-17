#!/usr/bin/env python3
"""Quick validation for Maharashtra AISHE import helpers."""

from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "tools" / "import_maharashtra_aishe.py"

spec = importlib.util.spec_from_file_location("import_maharashtra_aishe", SCRIPT)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)


def test_categories():
    assert mod.categorize("Pune Institute of Engineering and Technology") == "Engineering"
    assert mod.categorize("Symbiosis Institute of Business Management") == "MBA"
    assert mod.categorize("Government College of Nursing Pune") == "Nursing"
    assert mod.categorize("College of Agriculture Pune") == "Agriculture"
    assert mod.categorize("NIFT Fashion Design College") == "Fashion"


def test_search_tokens_include_name():
    tokens = mod.build_search_tokens(
        "COEP Engineering College",
        "Pune",
        "Pune",
        "Maharashtra",
        "Engineering",
        ["B.Tech"],
        ["engineering", "pune"],
    )
    assert "coep" in tokens


def test_row_maharashtra():
    now = "2026-01-01T00:00:00Z"
    row = mod.row_to_college(
        {
            "id": "999",
            "state": "Maharashtra",
            "name": "Test Engineering College",
            "city": "Pune",
            "district": "Pune",
            "address_line1": "Road 1",
            "address_line2": "",
            "pin_code": "411001",
        },
        now,
    )
    assert row is not None
    assert row["category"] == "Engineering"
    assert len(row["searchTokens"]) >= 5


if __name__ == "__main__":
    test_categories()
    test_search_tokens_include_name()
    test_row_maharashtra()
    print("All Maharashtra import tests passed.")
