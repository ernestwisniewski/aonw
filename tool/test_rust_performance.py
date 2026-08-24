#!/usr/bin/env python3
"""Negative fixtures for the Rust structural-performance gate."""

from __future__ import annotations

import csv
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Callable


REPO_ROOT = Path(__file__).resolve().parent.parent
CHECKER = REPO_ROOT / "tool/check_rust_performance.py"
ENGINE_HEADER = [
    "workload",
    "tiles",
    "units",
    "iterations",
    "allocations",
    "reallocations",
    "allocated_bytes",
    "payload_bytes",
    "frontier_pops",
    "expanded_tiles",
    "examined_edges",
    "heap_pushes",
    "route_records",
    "signature",
    "median_ns",
    "p95_ns",
]
RUNTIME_HEADER = [
    "workload",
    "tiles",
    "units",
    "iterations",
    "allocations",
    "reallocations",
    "allocated_bytes",
    "payload_bytes",
    "signature",
    "median_ns",
    "p95_ns",
]
COLUMNS = [
    "signature",
    "minimumIterations",
    "maxAllocations",
    "maxReallocations",
    "maxAllocatedBytes",
    "maxPayloadBytes",
    "maxFrontierPops",
    "maxExpandedTiles",
    "maxExaminedEdges",
    "maxHeapPushes",
    "maxRouteRecords",
]


class Fixture:
    def __init__(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="aonw-rust-performance-"))
        self.engine_csv = self.root / "engine.csv"
        self.runtime_csv = self.root / "runtime.csv"
        self.stage_path = self.root / "stage.json"
        self.baseline_path = self.root / "baseline.json"
        self.report_path = self.root / "report.json"
        self.engine_row: dict[str, str] = {}
        self.runtime_row: dict[str, str] = {}
        self.stage: dict[str, Any] = {}
        self.baseline: dict[str, Any] = {}
        self.reset()

    def close(self) -> None:
        shutil.rmtree(self.root)

    def reset(self) -> None:
        self.engine_row = {
            "workload": "apply",
            "tiles": "1200",
            "units": "1",
            "iterations": "20",
            "allocations": "10",
            "reallocations": "2",
            "allocated_bytes": "100",
            "payload_bytes": "0",
            "frontier_pops": "3",
            "expanded_tiles": "2",
            "examined_edges": "6",
            "heap_pushes": "7",
            "route_records": "7",
            "signature": "0000000000000001",
            "median_ns": "10",
            "p95_ns": "20",
        }
        self.runtime_row = {
            "workload": "runtime_open",
            "tiles": "1200",
            "units": "1",
            "iterations": "20",
            "allocations": "5",
            "reallocations": "1",
            "allocated_bytes": "50",
            "payload_bytes": "12",
            "signature": "0000000000000002",
            "median_ns": "10",
            "p95_ns": "20",
        }
        self.stage = json.loads(
            (REPO_ROOT / "engine/quality/stage_budgets.json").read_text(encoding="utf-8")
        )
        self.stage["E0"].update(
            {
                "maxMeasuredPayloadBytes": 20,
                "maxMeasuredAllocations": 20,
                "maxMeasuredAllocatedBytes": 200,
                "maxWorkCounters": {
                    "frontierPops": 10,
                    "expandedTiles": 10,
                    "examinedEdges": 10,
                    "heapPushes": 10,
                    "routeRecords": 10,
                },
                "soakIterations": 20,
            }
        )
        self.baseline = {
            "provenance": {
                "rustc": "fixture rustc",
                "cargo": "fixture cargo",
                "allocator": {
                    "name": "stats_alloc",
                    "version": "0.1.10",
                    "source": "https://crates.io/crates/stats_alloc/0.1.10",
                },
                "measurement": {
                    "threads": 1,
                    "setup": "outside",
                    "warmupIterations": 3,
                    "timings": "diagnostic-only",
                },
                "reviewedDate": "2099-01-01",
            },
            "stage": "E0",
            "columns": COLUMNS,
            "ceilings": {
                "engine/apply/1200/1": [
                    "0000000000000001",
                    20,
                    10,
                    2,
                    100,
                    0,
                    3,
                    2,
                    6,
                    7,
                    7,
                ],
                "runtime/runtime_open/1200/1": [
                    "0000000000000002",
                    20,
                    5,
                    1,
                    50,
                    12,
                    0,
                    0,
                    0,
                    0,
                    0,
                ],
            },
        }
        self.write()

    def write_csv(self, path: Path, header: list[str], row: dict[str, str]) -> None:
        with path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=header)
            writer.writeheader()
            writer.writerow(row)

    def write(self) -> None:
        self.write_csv(self.engine_csv, ENGINE_HEADER, self.engine_row)
        self.write_csv(self.runtime_csv, RUNTIME_HEADER, self.runtime_row)
        self.stage_path.write_text(json.dumps(self.stage) + "\n", encoding="utf-8")
        self.baseline_path.write_text(json.dumps(self.baseline) + "\n", encoding="utf-8")

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "check",
                "--repo-root",
                str(REPO_ROOT),
                "--engine-csv",
                str(self.engine_csv),
                "--runtime-csv",
                str(self.runtime_csv),
                "--stage-budgets",
                str(self.stage_path),
                "--baseline",
                str(self.baseline_path),
                "--report",
                str(self.report_path),
            ],
            capture_output=True,
            text=True,
            check=False,
        )


def expect_rejection(fixture: Fixture, label: str, mutation: Callable[[Fixture], None]) -> None:
    fixture.reset()
    mutation(fixture)
    fixture.write()
    result = fixture.run()
    if result.returncode == 0:
        raise RuntimeError(f"performance checker accepted {label}")
    print(f"Performance checker rejected {label}.")


def main() -> None:
    fixture = Fixture()
    try:
        baseline = fixture.run()
        if baseline.returncode != 0:
            raise RuntimeError(f"baseline fixture failed: {baseline.stderr}")
        expect_rejection(
            fixture,
            "result-signature drift",
            lambda value: value.engine_row.update({"signature": "0000000000000003"}),
        )
        expect_rejection(
            fixture,
            "allocation-count regression",
            lambda value: value.engine_row.update({"allocations": "11"}),
        )
        expect_rejection(
            fixture,
            "work-counter regression",
            lambda value: value.engine_row.update({"frontier_pops": "4"}),
        )
        expect_rejection(
            fixture,
            "the stage payload ceiling",
            lambda value: value.runtime_row.update({"payload_bytes": "21"}),
        )
        expect_rejection(
            fixture,
            "the required soak count",
            lambda value: value.runtime_row.update({"iterations": "19"}),
        )
        expect_rejection(
            fixture,
            "a missing workload baseline",
            lambda value: value.baseline["ceilings"].pop("runtime/runtime_open/1200/1"),
        )
        expect_rejection(
            fixture,
            "an unknown stage field",
            lambda value: value.stage["E0"].update({"schemaVersion": 1}),
        )
        expect_rejection(
            fixture,
            "an unknown baseline field",
            lambda value: value.baseline.update({"schemaVersion": 1}),
        )
    finally:
        fixture.close()
    print("Rust performance negative tests passed.")


if __name__ == "__main__":
    main()
