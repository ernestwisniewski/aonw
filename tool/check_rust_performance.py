#!/usr/bin/env python3
"""Structural Rust performance, allocation, payload, and work-counter gate."""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


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
WORK_COUNTER_KEYS = {
    "frontierPops",
    "expandedTiles",
    "examinedEdges",
    "heapPushes",
    "routeRecords",
}
STAGE_KEYS = {
    "target",
    "capabilities",
    "fixtureIds",
    "maxEventsPerCommand",
    "maxMeasuredPayloadBytes",
    "maxMeasuredAllocations",
    "maxMeasuredAllocatedBytes",
    "maxWorkCounters",
    "soakIterations",
    "workloadPrefixes",
}
BASELINE_COLUMNS = [
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
BASELINE_PROVENANCE_KEYS = {"rustc", "cargo", "allocator", "measurement", "reviewedDate"}


class PerformanceFailure(RuntimeError):
    """An actionable structural-performance failure."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["report", "check", "snapshot"])
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument(
        "--baseline", type=Path, default=Path("engine/quality/performance_baseline.json")
    )
    parser.add_argument(
        "--stage-budgets", type=Path, default=Path("engine/quality/stage_budgets.json")
    )
    parser.add_argument("--report", type=Path, default=Path("/tmp/aonw-rust-performance.json"))
    parser.add_argument("--snapshot", type=Path, default=Path("/tmp/aonw-rust-performance-baseline.json"))
    parser.add_argument("--engine-csv", type=Path)
    parser.add_argument("--runtime-csv", type=Path)
    return parser.parse_args()


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise PerformanceFailure(f"{label} must be an object")
    missing = keys - set(value)
    unknown = set(value) - keys
    if missing or unknown:
        raise PerformanceFailure(
            f"{label} keys differ; missing={sorted(missing)}, unknown={sorted(unknown)}"
        )
    return value


def read_json(path: Path, label: str) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PerformanceFailure(f"cannot read {label} {path}: {error}") from error


def run_command(command: list[str], label: str) -> str:
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        diagnostic = result.stderr.strip() or result.stdout.strip()
        raise PerformanceFailure(f"{label} failed:\n{diagnostic}")
    return result.stdout


def bench_csv(repo_root: Path, package: str, benchmark: str, fixture: Path | None) -> str:
    if fixture is not None:
        path = fixture if fixture.is_absolute() else repo_root / fixture
        try:
            return path.read_text(encoding="utf-8")
        except OSError as error:
            raise PerformanceFailure(f"cannot read {benchmark} CSV fixture: {error}") from error
    return run_command(
        [
            "cargo",
            "bench",
            "--manifest-path",
            str(repo_root / "engine/Cargo.toml"),
            "--locked",
            "-p",
            package,
            "--bench",
            benchmark,
        ],
        f"{benchmark} benchmark",
    )


def unsigned(row: dict[str, str], field: str, label: str) -> int:
    value = row.get(field)
    if value is None or re.fullmatch(r"\d+", value) is None:
        raise PerformanceFailure(f"{label}.{field} must be an unsigned integer")
    return int(value)


def parse_csv(source: str, scope: str, header: list[str]) -> tuple[dict[str, Any], dict[str, Any]]:
    reader = csv.DictReader(io.StringIO(source))
    if reader.fieldnames != header:
        raise PerformanceFailure(
            f"{scope} CSV header differs; expected={header}, actual={reader.fieldnames}"
        )
    stable: dict[str, Any] = {}
    timings: dict[str, Any] = {}
    for row_number, row in enumerate(reader, start=2):
        if None in row or any(value is None for value in row.values()):
            raise PerformanceFailure(f"{scope} CSV row {row_number} is malformed")
        workload = row["workload"]
        if re.fullmatch(r"[a-z][a-z0-9_]*", workload) is None:
            raise PerformanceFailure(f"invalid workload name at {scope}:{row_number}")
        tiles = unsigned(row, "tiles", scope)
        units = unsigned(row, "units", scope)
        key = f"{scope}/{workload}/{tiles}/{units}"
        if key in stable:
            raise PerformanceFailure(f"duplicate structural workload: {key}")
        signature = row["signature"]
        if re.fullmatch(r"[0-9a-f]{16}", signature) is None:
            raise PerformanceFailure(f"invalid signature for {key}")
        work = {
            "frontierPops": unsigned(row, "frontier_pops", scope),
            "expandedTiles": unsigned(row, "expanded_tiles", scope),
            "examinedEdges": unsigned(row, "examined_edges", scope),
            "heapPushes": unsigned(row, "heap_pushes", scope),
            "routeRecords": unsigned(row, "route_records", scope),
        } if scope == "engine" else {key: 0 for key in sorted(WORK_COUNTER_KEYS)}
        stable[key] = {
            "workload": workload,
            "tiles": tiles,
            "units": units,
            "iterations": unsigned(row, "iterations", scope),
            "allocations": unsigned(row, "allocations", scope),
            "reallocations": unsigned(row, "reallocations", scope),
            "allocatedBytes": unsigned(row, "allocated_bytes", scope),
            "payloadBytes": unsigned(row, "payload_bytes", scope),
            "workCounters": work,
            "signature": signature,
        }
        timings[key] = {
            "medianNs": unsigned(row, "median_ns", scope),
            "p95Ns": unsigned(row, "p95_ns", scope),
        }
    if not stable:
        raise PerformanceFailure(f"{scope} CSV has no workloads")
    return stable, timings


def load_stages(path: Path) -> dict[str, dict[str, Any]]:
    raw = read_json(path, "stage budgets")
    if not isinstance(raw, dict) or set(raw) != {"E0", "T1", "U2"}:
        raise PerformanceFailure("stage budgets must contain exactly active stages E0, T1 and U2")
    expected = {
        "E0": {
            "target": "rust-foundation-check",
            "capabilities": [
                "CancelUnitAction",
                "FortifyUnit",
                "MoveUnit",
                "SkipUnitTurn",
            ],
            "fixtureCount": 9,
        },
        "T1": {
            "target": "rust-turn-kernel-check",
            "capabilities": [
                "EndTurn",
                "FinalizeTimedOutTurn",
                "KickParticipant",
                "SubmitTurn",
            ],
            "fixtureCount": 8,
        },
        "U2": {
            "target": "rust-movement-logistics-check",
            "capabilities": [
                "AssignMerchantTradeRoute",
                "AutoExploreUnit",
                "DetachTroop",
                "MoveMerchantToCity",
            ],
            "fixtureCount": 7,
        },
    }
    stages: dict[str, dict[str, Any]] = {}
    for name, requirements in expected.items():
        stage = strict_object(raw[name], f"stage {name}", STAGE_KEYS)
        if stage["target"] != requirements["target"]:
            raise PerformanceFailure(f"{name} target differs from its required Make target")
        if stage["capabilities"] != requirements["capabilities"]:
            raise PerformanceFailure(f"{name} capability set differs from its active surface")
        fixtures = stage["fixtureIds"]
        if (
            not isinstance(fixtures, list)
            or len(fixtures) != requirements["fixtureCount"]
            or fixtures != sorted(set(fixtures))
        ):
            raise PerformanceFailure(
                f"{name} fixtureIds must contain "
                f"{requirements['fixtureCount']} sorted unique cases"
            )
        prefixes = stage["workloadPrefixes"]
        if (
            not isinstance(prefixes, list)
            or not prefixes
            or prefixes != sorted(set(prefixes))
            or any(re.fullmatch(r"[a-z][a-z0-9_/]*", value) is None for value in prefixes)
        ):
            raise PerformanceFailure(f"stage {name} workloadPrefixes must be sorted and unique")
        for key in [
            "maxEventsPerCommand",
            "maxMeasuredPayloadBytes",
            "maxMeasuredAllocations",
            "maxMeasuredAllocatedBytes",
            "soakIterations",
        ]:
            if not isinstance(stage[key], int) or stage[key] <= 0:
                raise PerformanceFailure(f"stage {name} {key} must be a positive integer")
        counters = strict_object(
            stage["maxWorkCounters"], f"stage {name} work counters", WORK_COUNTER_KEYS
        )
        if not all(isinstance(value, int) and value >= 0 for value in counters.values()):
            raise PerformanceFailure(f"stage {name} work counters must be non-negative integers")
        stages[name] = stage
    return stages


def validate_e0_fixtures(stage: dict[str, Any], repo_root: Path) -> None:
    command_names = {
        "cancelUnitAction": "CancelUnitAction",
        "fortifyUnit": "FortifyUnit",
        "moveUnit": "MoveUnit",
        "skipUnitTurn": "SkipUnitTurn",
    }
    fixture_root = repo_root / "engine/fixtures/canonical_commands"
    capabilities: set[str] = set()
    for fixture_id in stage["fixtureIds"]:
        path = fixture_root / f"{fixture_id}.json"
        fixture = read_json(path, f"stage fixture {fixture_id}")
        if not isinstance(fixture, dict) or fixture.get("id") != fixture_id:
            raise PerformanceFailure(f"stage fixture identity differs for {fixture_id}")
        try:
            command_type = fixture["input"]["command"]["type"]
            events = fixture["expected"]["events"]
        except (KeyError, TypeError) as error:
            raise PerformanceFailure(f"stage fixture structure differs for {fixture_id}") from error
        capability = command_names.get(command_type)
        if capability is None:
            raise PerformanceFailure(f"stage fixture has an unclassified command: {fixture_id}")
        capabilities.add(capability)
        if not isinstance(events, list):
            raise PerformanceFailure(f"stage fixture events must be a list: {fixture_id}")
        if len(events) > stage["maxEventsPerCommand"]:
            raise PerformanceFailure(
                f"event budget exceeded for {fixture_id}: "
                f"{len(events)} > {stage['maxEventsPerCommand']}"
            )
    if sorted(capabilities) != stage["capabilities"]:
        raise PerformanceFailure("stage fixture capabilities differ from the E0 manifest")


def validate_t1_fixtures(stage: dict[str, Any], repo_root: Path) -> None:
    manifest = read_json(
        repo_root / "engine/fixtures/turn_kernel/manifest.json", "T1 fixture manifest"
    )
    if not isinstance(manifest, dict) or manifest.get("capability") != "turn-kernel-ready":
        raise PerformanceFailure("T1 fixture manifest capability differs")
    fixtures = manifest.get("fixtures")
    if not isinstance(fixtures, list):
        raise PerformanceFailure("T1 fixture manifest has no fixture list")
    ids = sorted(fixture.get("id") for fixture in fixtures if isinstance(fixture, dict))
    if ids != stage["fixtureIds"]:
        raise PerformanceFailure("T1 fixture IDs differ from the stage budget")
    maximum_events = 0
    for fixture in fixtures:
        expected_event_count = fixture.get("expectedEventCount")
        if not isinstance(expected_event_count, int) or expected_event_count < 0:
            raise PerformanceFailure("T1 fixtures require non-negative expectedEventCount")
        maximum_events = max(maximum_events, expected_event_count)
    if maximum_events > stage["maxEventsPerCommand"]:
        raise PerformanceFailure("T1 fixture event count exceeds the reviewed stage budget")


def validate_u2_fixtures(stage: dict[str, Any], repo_root: Path) -> None:
    manifest = read_json(
        repo_root / "engine/fixtures/movement_logistics/manifest.json",
        "U2 fixture manifest",
    )
    if not isinstance(manifest, dict) or manifest.get("capability") != "movement-logistics-ready":
        raise PerformanceFailure("U2 fixture manifest capability differs")
    cases = manifest.get("cases")
    if not isinstance(cases, list) or sorted(cases) != stage["fixtureIds"]:
        raise PerformanceFailure("U2 fixture IDs differ from the stage budget")
    command_names = {
        "assignMerchantTradeRoute": "AssignMerchantTradeRoute",
        "autoExploreUnit": "AutoExploreUnit",
        "detachTroop": "DetachTroop",
        "moveMerchantToCity": "MoveMerchantToCity",
    }
    commands = manifest.get("commands")
    if not isinstance(commands, list):
        raise PerformanceFailure("U2 fixture manifest has no command inventory")
    capabilities = sorted(command_names.get(command, "") for command in commands)
    if capabilities != stage["capabilities"]:
        raise PerformanceFailure("U2 fixture capabilities differ from the stage budget")
    if stage["maxEventsPerCommand"] < 2:
        raise PerformanceFailure("U2 event budget cannot cover auto-exploration")


def validate_stages(
    stages: dict[str, dict[str, Any]], stable: dict[str, Any], repo_root: Path
) -> None:
    validate_e0_fixtures(stages["E0"], repo_root)
    validate_t1_fixtures(stages["T1"], repo_root)
    validate_u2_fixtures(stages["U2"], repo_root)
    for name, stage in stages.items():
        selected = {
            key: workload
            for key, workload in stable.items()
            if any(key.startswith(prefix) for prefix in stage["workloadPrefixes"])
        }
        if not selected:
            raise PerformanceFailure(f"stage {name} has no measured workload")
        for key, workload in selected.items():
            if workload["iterations"] < stage["soakIterations"]:
                raise PerformanceFailure(f"soak iterations below {name} budget for {key}")
            if workload["payloadBytes"] > stage["maxMeasuredPayloadBytes"]:
                raise PerformanceFailure(f"payload budget exceeded for {name} workload {key}")
            if workload["allocations"] > stage["maxMeasuredAllocations"]:
                raise PerformanceFailure(
                    f"allocation count budget exceeded for {name} workload {key}"
                )
            if workload["allocatedBytes"] > stage["maxMeasuredAllocatedBytes"]:
                raise PerformanceFailure(
                    f"allocated byte budget exceeded for {name} workload {key}"
                )
            for counter, value in workload["workCounters"].items():
                if value > stage["maxWorkCounters"][counter]:
                    raise PerformanceFailure(f"{counter} budget exceeded for {name} workload {key}")


def provenance() -> dict[str, Any]:
    rustc = run_command(["rustc", "--version"], "rustc version").strip()
    cargo = run_command(["cargo", "--version"], "cargo version").strip()
    return {
        "rustc": rustc,
        "cargo": cargo,
        "profile": "bench",
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
    }


def build_report(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    sources = list((repo_root / "engine/crates/aonw_engine/benches/movement").glob("*.rs"))
    sources.extend([
        repo_root / "engine/crates/aonw_engine/benches/movement.rs",
        repo_root / "engine/crates/aonw_local_runtime/benches/runtime.rs",
    ])
    for source in sources:
        text = source.read_text(encoding="utf-8")
        if re.search(r"\b(?:thread::spawn|rayon|tokio)::?", text):
            raise PerformanceFailure(f"background threading is forbidden in measured harness: {source}")
    engine_stable, engine_timings = parse_csv(
        bench_csv(repo_root, "aonw_engine", "movement", args.engine_csv),
        "engine",
        ENGINE_HEADER,
    )
    runtime_stable, runtime_timings = parse_csv(
        bench_csv(repo_root, "aonw_local_runtime", "runtime", args.runtime_csv),
        "runtime",
        RUNTIME_HEADER,
    )
    stable = {**engine_stable, **runtime_stable}
    if len(stable) != len(engine_stable) + len(runtime_stable):
        raise PerformanceFailure("engine/runtime workload keys overlap")
    stages = load_stages(
        args.stage_budgets if args.stage_budgets.is_absolute() else repo_root / args.stage_budgets
    )
    validate_stages(stages, stable, repo_root)
    return {
        "provenance": provenance(),
        "stage": "U2",
        "stable": dict(sorted(stable.items())),
        "diagnosticTimings": dict(sorted({**engine_timings, **runtime_timings}.items())),
    }


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_compact_baseline(path: Path, baseline: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "{",
        f'  "provenance": {json.dumps(baseline["provenance"], sort_keys=True)},',
        f'  "stage": {json.dumps(baseline["stage"])},',
        f'  "columns": {json.dumps(baseline["columns"])},',
        '  "ceilings": {',
    ]
    items = list(sorted(baseline["ceilings"].items()))
    for index, (key, values) in enumerate(items):
        suffix = "," if index + 1 < len(items) else ""
        lines.append(f"    {json.dumps(key)}: {json.dumps(values)}{suffix}")
    lines.extend(["  }", "}"])
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_snapshot(report: dict[str, Any]) -> dict[str, Any]:
    ceilings = {}
    for key, workload in report["stable"].items():
        ceilings[key] = [
            workload["signature"],
            workload["iterations"],
            workload["allocations"],
            workload["reallocations"],
            workload["allocatedBytes"],
            workload["payloadBytes"],
            workload["workCounters"]["frontierPops"],
            workload["workCounters"]["expandedTiles"],
            workload["workCounters"]["examinedEdges"],
            workload["workCounters"]["heapPushes"],
            workload["workCounters"]["routeRecords"],
        ]
    return {
        "provenance": {
            "rustc": report["provenance"]["rustc"],
            "cargo": report["provenance"]["cargo"],
            "allocator": report["provenance"]["allocator"],
            "measurement": report["provenance"]["measurement"],
            "reviewedDate": "2026-08-24",
        },
        "stage": report["stage"],
        "columns": BASELINE_COLUMNS,
        "ceilings": ceilings,
    }


def check_baseline(report: dict[str, Any], baseline_path: Path) -> None:
    baseline = read_json(baseline_path, "performance baseline")
    baseline = strict_object(
        baseline,
        "performance baseline",
        {"provenance", "stage", "columns", "ceilings"},
    )
    baseline_provenance = strict_object(
        baseline["provenance"],
        "performance baseline provenance",
        BASELINE_PROVENANCE_KEYS,
    )
    if baseline_provenance["allocator"] != report["provenance"]["allocator"]:
        raise PerformanceFailure("performance baseline allocator provenance differs")
    if baseline_provenance["measurement"] != report["provenance"]["measurement"]:
        raise PerformanceFailure("performance baseline measurement provenance differs")
    for field in ["rustc", "cargo", "reviewedDate"]:
        if not isinstance(baseline_provenance[field], str) or not baseline_provenance[field]:
            raise PerformanceFailure(f"performance baseline {field} provenance is required")
    if baseline["stage"] != report["stage"]:
        raise PerformanceFailure("performance baseline stage differs")
    if baseline["columns"] != BASELINE_COLUMNS:
        raise PerformanceFailure("performance baseline columns differ")
    ceilings = baseline["ceilings"]
    if not isinstance(ceilings, dict) or set(ceilings) != set(report["stable"]):
        raise PerformanceFailure(
            "performance workload census differs; "
            f"missing={sorted(set(ceilings) - set(report['stable']))}, "
            f"new={sorted(set(report['stable']) - set(ceilings))}"
        )
    for key, workload in report["stable"].items():
        values = ceilings[key]
        if not isinstance(values, list) or len(values) != len(BASELINE_COLUMNS):
            raise PerformanceFailure(f"performance ceiling {key} has invalid columns")
        ceiling = dict(zip(BASELINE_COLUMNS, values, strict=True))
        if not isinstance(ceiling["signature"], str) or not all(
            isinstance(ceiling[column], int) and ceiling[column] >= 0
            for column in BASELINE_COLUMNS[1:]
        ):
            raise PerformanceFailure(f"performance ceiling {key} has invalid values")
        if workload["signature"] != ceiling["signature"]:
            raise PerformanceFailure(f"result signature drifted for {key}")
        comparisons = {
            "allocations": "maxAllocations",
            "reallocations": "maxReallocations",
            "allocatedBytes": "maxAllocatedBytes",
            "payloadBytes": "maxPayloadBytes",
        }
        for field, ceiling_field in comparisons.items():
            if workload[field] > ceiling[ceiling_field]:
                raise PerformanceFailure(
                    f"{field} regressed for {key}: {workload[field]} > {ceiling[ceiling_field]}"
                )
        if workload["iterations"] < ceiling["minimumIterations"]:
            raise PerformanceFailure(f"iteration count regressed for {key}")
        counters = {
            "frontierPops": ceiling["maxFrontierPops"],
            "expandedTiles": ceiling["maxExpandedTiles"],
            "examinedEdges": ceiling["maxExaminedEdges"],
            "heapPushes": ceiling["maxHeapPushes"],
            "routeRecords": ceiling["maxRouteRecords"],
        }
        for counter, value in workload["workCounters"].items():
            if value > counters[counter]:
                raise PerformanceFailure(
                    f"{counter} regressed for {key}: {value} > {counters[counter]}"
                )


def run() -> None:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    report = build_report(args, repo_root)
    report_path = args.report if args.report.is_absolute() else repo_root / args.report
    write_json(report_path, report)
    if args.mode == "check":
        baseline = args.baseline if args.baseline.is_absolute() else repo_root / args.baseline
        check_baseline(report, baseline)
        print(f"Rust structural performance check passed: {len(report['stable'])} workloads.")
    elif args.mode == "snapshot":
        snapshot = args.snapshot if args.snapshot.is_absolute() else repo_root / args.snapshot
        write_compact_baseline(snapshot, make_snapshot(report))
        print(f"Wrote Rust performance baseline candidate to {snapshot}.")
    else:
        print(f"Wrote Rust performance report to {report_path}.")


if __name__ == "__main__":
    try:
        run()
    except (OSError, PerformanceFailure) as error:
        print(f"Rust performance check failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
