#!/usr/bin/env python3
"""Validate the explicit Dart AI export replacement ledger."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "engine/fixtures/ai/dart-replacement-ledger.json"
ALLOWED_KEYS = {
    "source",
    "sourceExportCount",
    "policy",
    "legacyPaths",
    "portCapabilities",
    "retire",
}
ALLOWED_CAPABILITIES = {
    "boundedSearch",
    "combatDefense",
    "deterministicRng",
    "diplomacy",
    "expansionExploration",
    "outcomeAwareness",
    "production",
    "profileWeights",
    "research",
    "strategicAssessment",
    "turnPolicy",
    "worker",
}
EXPORT_PATTERN = re.compile(r"^export '([^']+)'(?: show [^;]+)?;$")


def fail(message: str) -> None:
    raise SystemExit(f"Rust AI replacement ledger failed: {message}")


def source_exports(path: Path) -> list[str]:
    exports = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line.startswith("export "):
            continue
        match = EXPORT_PATTERN.fullmatch(line)
        if match is None:
            fail(f"unsupported Dart export syntax: {line}")
        exports.append(match.group(1))
    return exports


def main() -> None:
    try:
        ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot read strict ledger: {error}")
    if not isinstance(ledger, dict) or set(ledger) != ALLOWED_KEYS:
        fail("top-level fields differ")
    if ledger["source"] != "packages/aonw_core/lib/ai.dart":
        fail("source path differs")
    if ledger["policy"] != "behavior-port-or-explicit-retire":
        fail("policy differs")
    if ledger["legacyPaths"] is not False:
        fail("legacy paths must remain disabled")

    source_path = ROOT / ledger["source"]
    exports = source_exports(source_path)
    if ledger["sourceExportCount"] != len(exports):
        fail("source export count differs")
    if len(exports) != len(set(exports)):
        fail("source contains duplicate exports")

    capabilities = ledger["portCapabilities"]
    if not isinstance(capabilities, dict) or set(capabilities) != ALLOWED_CAPABILITIES:
        fail("port capability set differs")
    ported: list[str] = []
    for capability, values in capabilities.items():
        if (
            not isinstance(values, list)
            or not values
            or not all(isinstance(value, str) for value in values)
        ):
            fail(f"{capability} must contain exported paths")
        ported.extend(values)

    retired: list[str] = []
    retire_entries = ledger["retire"]
    if not isinstance(retire_entries, list):
        fail("retire entries must be a list")
    for entry in retire_entries:
        if not isinstance(entry, dict) or set(entry) != {"export", "reason"}:
            fail("retire entry fields differ")
        if not isinstance(entry["export"], str) or not isinstance(entry["reason"], str):
            fail("retire entry values must be strings")
        if not entry["reason"].strip():
            fail("retire reason must not be empty")
        retired.append(entry["export"])

    classified = ported + retired
    if len(classified) != len(set(classified)):
        fail("an export has more than one disposition")
    if set(classified) != set(exports):
        missing = sorted(set(exports) - set(classified))
        unknown = sorted(set(classified) - set(exports))
        fail(f"export disposition differs: missing={missing}, unknown={unknown}")
    print(
        "Rust AI replacement ledger passed: "
        f"{len(ported)} port, {len(retired)} retire, {len(exports)} total exports."
    )


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
