"""Tests for Maharashtra AISHE import pipeline."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "tools" / "import_maharashtra_aishe.py"

spec = importlib.util.spec_from_file_location("import_maharashtra_aishe", SCRIPT)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)


def test_categorize_engineering():
    assert mod.categorize("Pune Institute of Engineering and Technology") == "engineering"


def test_categorize_medical():
    assert mod.categorize("Grant Medical College") == "medical_health"


def test_infer_type_government():
    assert mod.infer_type("Government Polytechnic Pune", "polytechnic") == "government"


def test_clean_city_falls_back_to_district():
    assert mod.clean_city("NA", "Aurangabad") == "Aurangabad"


def test_build_search_tokens():
    tokens = mod.build_search_tokens(
        "COEP Pune",
        "Pune",
        "Pune",
        "Maharashtra",
        courses=["B.Tech"],
        keywords=["engineering"],
    )
    assert "pune" in tokens
    assert "pun" in tokens


def test_row_to_college_maharashtra_only():
    now = "2026-01-01T00:00:00Z"
    mh = mod.row_to_college(
        {
            "id": "123",
            "state": "Maharashtra",
            "name": "Test Engineering College",
            "city": "Pune",
            "district": "Pune",
            "address_line1": "Campus Road",
            "address_line2": "",
            "pin_code": "411001",
        },
        now,
    )
    assert mh is not None
    assert mh["state"] == "Maharashtra"
    assert mh["id"] == "aishe_123"
    assert mh["category"] == "engineering"

    other = mod.row_to_college(
        {"id": "1", "state": "Gujarat", "name": "X", "city": "Y", "district": "Z"},
        now,
    )
    assert other is None
