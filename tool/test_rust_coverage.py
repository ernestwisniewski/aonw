#!/usr/bin/env python3
"""Negative fixtures for the fail-closed Rust coverage ratchet."""

from __future__ import annotations

import json
import subprocess
import tempfile
from copy import deepcopy
from fnmatch import fnmatch
from pathlib import Path
from typing import Any, Callable


REPO_ROOT = Path(__file__).resolve().parents[1]
CHECKER = REPO_ROOT / "tool/check_rust_coverage.py"
SCOPE = REPO_ROOT / "engine/quality/coverage_scope.json"


def read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def invoke(temp: Path, scope: dict[str, Any], raw: dict[str, Any], lcov: str, baseline: dict[str, Any]) -> subprocess.CompletedProcess[str]:
    scope_path = temp / "scope.json"
    raw_path = temp / "raw.json"
    lcov_path = temp / "coverage.lcov"
    baseline_path = temp / "baseline.json"
    write(scope_path, scope)
    write(raw_path, raw)
    lcov_path.write_text(lcov, encoding="utf-8")
    write(baseline_path, baseline)
    return subprocess.run(
        [
            str(CHECKER),
            "check",
            "--scope",
            str(scope_path),
            "--raw-json",
            str(raw_path),
            "--lcov-input",
            str(lcov_path),
            "--baseline",
            str(baseline_path),
            "--report",
            str(temp / "report.json"),
        ],
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def expect_failure(
    name: str,
    mutate: Callable[[dict[str, Any], dict[str, Any], str, dict[str, Any]], tuple[dict[str, Any], dict[str, Any], str, dict[str, Any]]],
    scope: dict[str, Any],
    raw: dict[str, Any],
    lcov: str,
    baseline: dict[str, Any],
) -> None:
    with tempfile.TemporaryDirectory(prefix="aonw-rust-coverage-negative-") as directory:
        result = invoke(Path(directory), *mutate(deepcopy(scope), deepcopy(raw), lcov, deepcopy(baseline)))
    if result.returncode == 0:
        raise SystemExit(f"negative coverage fixture unexpectedly passed: {name}")


def line_entry(raw: dict[str, Any], crate: str) -> dict[str, Any]:
    for entry in raw["data"][0]["files"]:
        if f"/crates/{crate}/src/" in entry["filename"]:
            return entry
    raise AssertionError(crate)


def seed_inputs(scope: dict[str, Any]) -> tuple[dict[str, Any], str]:
    engine_root = REPO_ROOT / "engine"
    excluded = [
        pattern
        for patterns in scope["exclusions"].values()
        for pattern in patterns
    ]
    files = []
    for group in scope["instrumentedGroups"]:
        for crate in scope["groups"][group]:
            crate_root = engine_root / "crates" / crate
            candidates = [
                path
                for path in sorted((crate_root / "src").rglob("*.rs"))
                if not any(
                    fnmatch(path.relative_to(crate_root).as_posix(), pattern)
                    for pattern in excluded
                )
            ]
            if not candidates:
                raise AssertionError(crate)
            files.append(
                {
                    "filename": str(candidates[0]),
                    "summary": {"lines": {"count": 10, "covered": 9, "percent": 90.0}},
                }
            )
    raw = {
        "type": "llvm.coverage.json.export",
        "version": "3.1.0",
        "data": [{"files": files, "totals": {}}],
    }
    lcov = "".join(f"SF:{entry['filename']}\nend_of_record\n" for entry in files)
    return raw, lcov


def main() -> None:
    scope = read(SCOPE)
    raw, lcov = seed_inputs(scope)
    with tempfile.TemporaryDirectory(prefix="aonw-rust-coverage-seed-") as directory:
        temp = Path(directory)
        raw_path = temp / "raw.json"
        lcov_path = temp / "coverage.lcov"
        write(raw_path, raw)
        lcov_path.write_text(lcov, encoding="utf-8")
        snapshot_path = temp / "baseline.json"
        result = subprocess.run(
            [
                str(CHECKER),
                "snapshot",
                "--scope",
                str(SCOPE),
                "--raw-json",
                str(raw_path),
                "--lcov-input",
                str(lcov_path),
                "--report",
                str(temp / "report.json"),
                "--snapshot",
                str(snapshot_path),
            ],
            cwd=REPO_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        if result.returncode != 0:
            raise SystemExit(result.stdout)
        baseline = read(snapshot_path)

    def ratio_down(s: dict[str, Any], r: dict[str, Any], l: str, b: dict[str, Any]):
        lines = line_entry(r, "aonw_engine")["summary"]["lines"]
        lines["covered"] -= 1
        lines["count"] -= 1
        return s, r, l, b

    def uncovered_up(s: dict[str, Any], r: dict[str, Any], l: str, b: dict[str, Any]):
        lines = line_entry(r, "aonw_engine")["summary"]["lines"]
        lines["count"] += 10
        lines["covered"] += 9
        return s, r, l, b

    def missing_grows(s: dict[str, Any], r: dict[str, Any], l: str, b: dict[str, Any]):
        entry = line_entry(r, "aonw_engine")
        r["data"][0]["files"].remove(entry)
        l = "\n".join(line for line in l.splitlines() if entry["filename"] not in line) + "\n"
        return s, r, l, b

    def unclassified_source(s: dict[str, Any], r: dict[str, Any], l: str, b: dict[str, Any]):
        entry = deepcopy(r["data"][0]["files"][0])
        entry["filename"] = str(REPO_ROOT / "engine/crates/aonw_map_authoring/src/injected.rs")
        r["data"][0]["files"].append(entry)
        l += f"SF:{entry['filename']}\nend_of_record\n"
        return s, r, l, b

    def stale_tool(s: dict[str, Any], r: dict[str, Any], l: str, b: dict[str, Any]):
        s["tool"]["version"] = "0.8.0"
        return s, r, l, b

    def unknown_scope_field(s: dict[str, Any], r: dict[str, Any], l: str, b: dict[str, Any]):
        s["formatVersion"] = 1
        return s, r, l, b

    def unknown_baseline_field(s: dict[str, Any], r: dict[str, Any], l: str, b: dict[str, Any]):
        first = next(iter(b["crates"].values()))
        first["waiver"] = "silent"
        return s, r, l, b

    cases = {
        "ratio decrease": ratio_down,
        "uncovered growth": uncovered_up,
        "missing-file growth": missing_grows,
        "unclassified dependency": unclassified_source,
        "tool pin drift": stale_tool,
        "unknown scope field": unknown_scope_field,
        "unknown baseline field": unknown_baseline_field,
    }
    for name, mutation in cases.items():
        expect_failure(name, mutation, scope, raw, lcov, baseline)
    print(f"Rust coverage negative fixtures passed: {len(cases)} invalid cases rejected.")


if __name__ == "__main__":
    main()
