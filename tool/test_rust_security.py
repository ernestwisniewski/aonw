#!/usr/bin/env python3
"""Negative fixtures for the fail-closed Rust security-test policy."""

from __future__ import annotations

import importlib.util
import json
import tempfile
from copy import deepcopy
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[1]
CHECKER_PATH = ROOT / "tool/check_rust_security.py"
POLICY_PATH = ROOT / "engine/quality/security_test_policy.json"


def load_checker() -> Any:
    spec = importlib.util.spec_from_file_location("aonw_rust_security_checker", CHECKER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load Rust security checker")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def expect_rejection(
    checker: Any,
    baseline: dict[str, Any],
    label: str,
    mutation: Callable[[dict[str, Any]], None],
) -> None:
    policy = deepcopy(baseline)
    mutation(policy)
    with tempfile.TemporaryDirectory(prefix="aonw-rust-security-negative-") as directory:
        path = Path(directory) / "security_test_policy.json"
        path.write_text(json.dumps(policy) + "\n", encoding="utf-8")
        checker.POLICY_PATH = path
        try:
            checker.read_policy()
        except checker.SecurityFailure:
            return
    raise RuntimeError(f"Rust security checker accepted {label}")


def main() -> None:
    checker = load_checker()
    baseline = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    checker.read_policy()
    cases: dict[str, Callable[[dict[str, Any]], None]] = {
        "an unknown policy field": lambda value: value.update({"schemaVersion": 1}),
        "a mutation survivor allowance": lambda value: value["mutation"].update(
            {"maximumSurvivors": 1}
        ),
        "a zero mutation census": lambda value: value["mutation"]["targets"][0].update(
            {"expectedMutants": 0}
        ),
        "a floating mutation tool version": lambda value: value["mutation"]["tool"].update(
            {"version": "27"}
        ),
        "an unpinned nightly": lambda value: value["fuzz"].update(
            {"toolchain": "nightly"}
        ),
        "an undersized fuzz run": lambda value: value["fuzz"].update({"smokeRuns": 64}),
        "a missing fuzz target": lambda value: value["fuzz"]["targets"].pop(),
        "Miri toolchain drift": lambda value: value["miri"].update(
            {"toolchain": "nightly-2026-08-23"}
        ),
        "an incomplete Miri package census": lambda value: value["miri"]["packages"].pop(),
    }
    for label, mutation in cases.items():
        expect_rejection(checker, baseline, label, mutation)
    print(f"Rust security negative fixtures passed: {len(cases)} invalid cases rejected.")


if __name__ == "__main__":
    main()
