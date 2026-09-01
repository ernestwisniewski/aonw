#!/usr/bin/env python3
"""Fail on missing, duplicate, stale, or invalid Dart replacement dispositions."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "engine/fixtures/persistence/dart-replacement-surface.json"
AI_LEDGER = ROOT / "engine/fixtures/ai/dart-replacement-ledger.json"
GENERATOR = ROOT / "tool/generate_rust_replacement_surface.py"
TOP_LEVEL_KEYS = {
    "sourceRoot",
    "policy",
    "sourceBarrelCount",
    "sourceExportCount",
    "legacyPaths",
    "barrels",
    "entries",
}
DISPOSITIONS = {
    "port-to-rust",
    "retire",
    "move-to-flutter",
    "move-to-server",
    "replace-with-protocol",
    "replace-with-content",
    "test-only",
}


def fail(message: str) -> None:
    raise SystemExit(f"Rust replacement surface failed: {message}")


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != keys:
        fail(f"{label} fields differ")
    return value


def main() -> None:
    try:
        ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
        generated = subprocess.run(
            [sys.executable, str(GENERATOR)],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        expected = json.loads(generated)
        ai_ledger = json.loads(AI_LEDGER.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        fail(f"cannot load strict ledger: {error}")
    strict_object(ledger, "ledger", TOP_LEVEL_KEYS)
    if ledger != expected:
        fail(
            "ledger differs from public Dart barrels; regenerate and review with "
            "tool/generate_rust_replacement_surface.py --output "
            "engine/fixtures/persistence/dart-replacement-surface.json"
        )
    if ledger["sourceRoot"] != "packages/aonw_core/lib":
        fail("source root differs")
    if ledger["policy"] != "one-current-rust-replacement-no-legacy":
        fail("policy differs")
    if ledger["legacyPaths"] is not False:
        fail("legacy paths must remain disabled")
    barrels = ledger["barrels"]
    entries = ledger["entries"]
    if not isinstance(barrels, list) or barrels != sorted(set(barrels)):
        fail("barrels must be unique and sorted")
    if ledger["sourceBarrelCount"] != len(barrels):
        fail("barrel count differs")
    if not isinstance(entries, list) or ledger["sourceExportCount"] != len(entries):
        fail("export count differs")
    keys: list[tuple[str, str]] = []
    counts = {name: 0 for name in sorted(DISPOSITIONS)}
    for index, raw_entry in enumerate(entries):
        entry = strict_object(raw_entry, f"entries[{index}]", {"barrel", "export", "disposition"})
        if not all(isinstance(entry[key], str) for key in entry):
            fail(f"entries[{index}] values must be strings")
        if entry["barrel"] not in barrels:
            fail(f"entries[{index}] references an unknown barrel")
        if entry["disposition"] not in DISPOSITIONS:
            fail(f"entries[{index}] has an invalid disposition")
        keys.append((entry["barrel"], entry["export"]))
        counts[entry["disposition"]] += 1
    if len(keys) != len(set(keys)):
        fail("an export has more than one disposition")
    ai_retired = {entry["export"] for entry in ai_ledger["retire"]}
    ai_entries = [entry for entry in entries if entry["barrel"] == "ai.dart"]
    if len(ai_entries) != ai_ledger["sourceExportCount"]:
        fail("AI surface count differs from its capability ledger")
    for entry in ai_entries:
        expected_ai = "retire" if entry["export"] in ai_retired else "port-to-rust"
        if entry["disposition"] != expected_ai:
            fail(f"AI disposition differs for {entry['export']}")
    summary = ", ".join(f"{name}={count}" for name, count in counts.items() if count)
    print(
        "Rust replacement surface passed: "
        f"{len(entries)} exports in {len(barrels)} barrels; {summary}."
    )


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
