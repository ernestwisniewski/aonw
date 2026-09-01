#!/usr/bin/env python3
"""Negative fixtures for the fail-closed Rust release-metadata policy."""

from __future__ import annotations

import importlib.util
import json
import tempfile
from copy import deepcopy
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[1]
CHECKER_PATH = ROOT / "tool/check_rust_release_metadata.py"
POLICY_PATH = ROOT / "engine/quality/release_metadata_policy.json"


def load_checker() -> Any:
    spec = importlib.util.spec_from_file_location("aonw_release_metadata", CHECKER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load release metadata checker")
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
    with tempfile.TemporaryDirectory(prefix="aonw-release-metadata-negative-") as directory:
        path = Path(directory) / "policy.json"
        path.write_text(json.dumps(policy) + "\n", encoding="utf-8")
        try:
            checker.load_policy(path)
        except checker.ReleaseMetadataFailure:
            return
    raise RuntimeError(f"release metadata checker accepted {label}")


def main() -> None:
    checker = load_checker()
    baseline = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    checker.load_policy(POLICY_PATH)
    cases: dict[str, Callable[[dict[str, Any]], None]] = {
        "an unknown policy field": lambda value: value.update({"schemaVersion": 1}),
        "a floating SBOM tool version": lambda value: value["tools"][
            "cargoCyclonedx"
        ].update({"version": "0.5"}),
        "cargo-about without its CLI feature": lambda value: value["tools"][
            "cargoAbout"
        ].update({"installFeatures": []}),
        "an older CycloneDX contract": lambda value: value["cycloneDx"].update(
            {"specVersion": "1.4"}
        ),
        "a missing named license": lambda value: value["cycloneDx"][
            "acceptedNamedLicenses"
        ].pop(),
        "an unreviewed target": lambda value: value["supportedTargets"].append(
            "wasm32-unknown-unknown"
        ),
        "an incomplete artifact census": lambda value: value["artifacts"].pop(),
        "an artifact manifest path escape": lambda value: value["artifacts"][0].update(
            {"manifest": "../Cargo.toml"}
        ),
    }
    for label, mutation in cases.items():
        expect_rejection(checker, baseline, label, mutation)
    print(
        "Rust release metadata negative fixtures passed: "
        f"{len(cases)} invalid cases rejected."
    )


if __name__ == "__main__":
    main()
