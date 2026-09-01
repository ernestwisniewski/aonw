#!/usr/bin/env python3
"""Validate current-save restore evidence for every strategic command family."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / "engine/fixtures/persistence/restore-matrix.json"
FAMILIES = {
    "artifact",
    "city",
    "combat",
    "diplomacy",
    "logistics",
    "movement",
    "production",
    "research",
    "turn",
    "worker",
}


def fail(message: str) -> None:
    raise SystemExit(f"Rust restore matrix failed: {message}")


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != keys:
        fail(f"{label} fields differ")
    return value


def validate_evidence(entry: dict[str, Any], label: str) -> None:
    path_value = entry["testFile"]
    test_name = entry["testName"]
    if not isinstance(path_value, str) or not isinstance(test_name, str):
        fail(f"{label} evidence must be strings")
    path = ROOT / path_value
    expected_root = ROOT / "engine/crates/aonw_local_runtime/tests"
    try:
        path.resolve().relative_to(expected_root.resolve())
        source = path.read_text(encoding="utf-8")
    except (OSError, ValueError) as error:
        fail(f"{label} test file is invalid: {error}")
    if re.search(rf"(?m)^fn {re.escape(test_name)}\(\)", source) is None:
        fail(f"{label} test function is missing")
    if "export_save_json" not in source or "open_save_json" not in source:
        fail(f"{label} does not exercise save and reopen")


def main() -> None:
    try:
        matrix = json.loads(MATRIX.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot load matrix: {error}")
    strict_object(
        matrix,
        "matrix",
        {"capability", "policy", "compatibility", "commandFamilies", "recoveryDrills"},
    )
    if matrix["capability"] != "current-save-restore-complete":
        fail("capability differs")
    if matrix["policy"] != "engine-first-current-only-no-legacy":
        fail("policy differs")
    compatibility = strict_object(
        matrix["compatibility"],
        "compatibility",
        {"apiVersionPreserved", "currentOnly", "legacyReaders", "upcasters"},
    )
    if compatibility != {
        "apiVersionPreserved": True,
        "currentOnly": True,
        "legacyReaders": False,
        "upcasters": False,
    }:
        fail("compatibility policy differs")

    entries = matrix["commandFamilies"]
    if not isinstance(entries, list) or len(entries) != len(FAMILIES):
        fail("command family count differs")
    found: set[str] = set()
    mid_workflows = 0
    for index, raw_entry in enumerate(entries):
        entry = strict_object(
            raw_entry,
            f"commandFamilies[{index}]",
            {"family", "workflow", "midWorkflow", "testFile", "testName"},
        )
        family = entry["family"]
        if family not in FAMILIES or family in found:
            fail(f"invalid or duplicate command family: {family}")
        if not isinstance(entry["workflow"], str) or not entry["workflow"].strip():
            fail(f"{family} workflow is empty")
        if not isinstance(entry["midWorkflow"], bool):
            fail(f"{family} midWorkflow must be boolean")
        mid_workflows += int(entry["midWorkflow"])
        validate_evidence(entry, family)
        found.add(family)
    if found != FAMILIES:
        fail(f"command family set differs: missing={sorted(FAMILIES - found)}")
    if mid_workflows < 4:
        fail("at least four mid-workflow restore drills are required")

    drills = matrix["recoveryDrills"]
    if not isinstance(drills, list) or len(drills) != 2:
        fail("recovery drill count differs")
    names: set[str] = set()
    for index, raw_entry in enumerate(drills):
        entry = strict_object(
            raw_entry,
            f"recoveryDrills[{index}]",
            {"name", "testFile", "testName"},
        )
        if not isinstance(entry["name"], str) or entry["name"] in names:
            fail("recovery drill names must be unique strings")
        validate_evidence(entry, entry["name"])
        names.add(entry["name"])
    if names != {"atomic-backup-rollback", "turn-boundary-soak"}:
        fail("recovery drill set differs")
    print(
        "Rust restore matrix passed: "
        f"{len(found)} command families, {mid_workflows} mid-workflow drills, {len(names)} recovery drills."
    )


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
