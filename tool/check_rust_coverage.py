#!/usr/bin/env python3
"""Generate and ratchet line coverage for authoritative Rust engine crates."""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


class CoverageFailure(RuntimeError):
    pass


SCOPE_KEYS = {
    "tool",
    "groups",
    "instrumentedGroups",
    "permittedDependencyCoverageGroups",
    "methodology",
    "sourceRoot",
    "exclusions",
}
TOOL_KEYS = {"name", "version", "source"}
GROUP_NAMES = {"authoritative", "runtime", "adapters", "authoring", "testkit"}
METHODOLOGY = {
    "primaryMetric": "line",
    "changedLines": "enforced-by-full-crate-ratchets",
    "branchCoverage": "diagnostic-until-stable-source-mapping",
    "renames": "explicit-reviewed-baseline-update",
    "macros": "llvm-source-attribution",
    "generatedTestSupport": "excluded-only-by-reviewed-globs",
    "smallCrates": "same-per-crate-ratchets",
}
EXCLUSION_KEYS = {"testAndSupport", "generated", "platform"}
BASELINE_KEYS = {"provenance", "crates"}
BASELINE_PROVENANCE_KEYS = {
    "cargoLlvmCov",
    "source",
    "rustc",
    "cargo",
    "llvmCoverageFormat",
    "scope",
    "reviewedDate",
}
CRATE_BASELINE_KEYS = {
    "group",
    "coveredLines",
    "countedLines",
    "uncoveredLines",
    "sourceFiles",
    "missingFiles",
}
EXECUTABLE_RUST = re.compile(
    r"^\s*(?:pub(?:\([^)]*\))?\s+)?(?:async\s+|const\s+|unsafe\s+|extern\s+\"[^\"]+\"\s+)*fn\s+"
    r"|^\s*(?:pub(?:\([^)]*\))?\s+)?(?:unsafe\s+)?impl\b"
    r"|^\s*(?:pub(?:\([^)]*\))?\s+)?(?:const|static)\s+"
    r"|macro_rules!"
)


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CoverageFailure(f"{label} must be an object")
    unknown = set(value) - keys
    missing = keys - set(value)
    if unknown or missing:
        raise CoverageFailure(
            f"{label} fields differ: missing={sorted(missing)}, unknown={sorted(unknown)}"
        )
    return value


def read_json(path: Path, label: str) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CoverageFailure(f"cannot read {label} {path}: {error}") from error


def run_command(command: list[str], label: str, cwd: Path | None = None) -> str:
    completed = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if completed.returncode != 0:
        raise CoverageFailure(
            f"{label} failed ({completed.returncode}):\n{completed.stdout.rstrip()}"
        )
    return completed.stdout


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["report", "check", "snapshot"])
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--scope", type=Path, default=Path("engine/quality/coverage_scope.json"))
    parser.add_argument("--baseline", type=Path, default=Path("engine/quality/coverage_baseline.json"))
    parser.add_argument("--report", type=Path, default=Path("/tmp/aonw-rust-coverage.json"))
    parser.add_argument("--lcov", type=Path, default=Path("/tmp/aonw-rust-coverage.lcov"))
    parser.add_argument("--snapshot", type=Path, default=Path("/tmp/aonw-rust-coverage-baseline.json"))
    parser.add_argument("--raw-json", type=Path)
    parser.add_argument("--lcov-input", type=Path)
    return parser.parse_args()


def resolve(repo_root: Path, path: Path) -> Path:
    return path if path.is_absolute() else repo_root / path


def load_scope(path: Path) -> dict[str, Any]:
    scope = strict_object(read_json(path, "coverage scope"), "coverage scope", SCOPE_KEYS)
    tool = strict_object(scope["tool"], "coverage tool", TOOL_KEYS)
    if tool != {
        "name": "cargo-llvm-cov",
        "version": "0.9.0",
        "source": "https://crates.io/crates/cargo-llvm-cov/0.9.0",
    }:
        raise CoverageFailure("coverage tool pin or installation source differs")
    groups = scope["groups"]
    if not isinstance(groups, dict) or set(groups) != GROUP_NAMES:
        raise CoverageFailure("coverage groups must classify all five Rust crate roles")
    classified: list[str] = []
    for group, crates in groups.items():
        if not isinstance(crates, list) or not crates or crates != sorted(set(crates)):
            raise CoverageFailure(f"coverage group {group} must be a sorted unique list")
        if not all(isinstance(crate, str) and crate for crate in crates):
            raise CoverageFailure(f"coverage group {group} contains an invalid crate")
        classified.extend(crates)
    if len(classified) != len(set(classified)):
        raise CoverageFailure("a Rust crate is classified into multiple coverage groups")
    if scope["instrumentedGroups"] != ["authoritative", "runtime"]:
        raise CoverageFailure("instrumented coverage groups must be authoritative and runtime")
    if scope["permittedDependencyCoverageGroups"] != ["testkit"]:
        raise CoverageFailure("only testkit dependency coverage may be present outside the scope")
    methodology = strict_object(
        scope["methodology"], "coverage methodology", set(METHODOLOGY)
    )
    if methodology != METHODOLOGY:
        raise CoverageFailure("coverage methodology differs from the reviewed policy")
    if scope["sourceRoot"] != "src":
        raise CoverageFailure("coverage source root must be src")
    exclusions = strict_object(scope["exclusions"], "coverage exclusions", EXCLUSION_KEYS)
    for name, patterns in exclusions.items():
        if not isinstance(patterns, list) or patterns != sorted(set(patterns)):
            raise CoverageFailure(f"coverage exclusion {name} must be a sorted unique list")
        if not all(isinstance(pattern, str) and pattern for pattern in patterns):
            raise CoverageFailure(f"coverage exclusion {name} contains an invalid pattern")
    return scope


def workspace_crates(engine_root: Path) -> set[str]:
    output = run_command(
        ["cargo", "metadata", "--locked", "--no-deps", "--format-version=1"],
        "cargo metadata",
        cwd=engine_root,
    )
    raw = json.loads(output)
    return {package["name"] for package in raw["packages"]}


def verify_scope_census(scope: dict[str, Any], engine_root: Path) -> None:
    classified = {crate for crates in scope["groups"].values() for crate in crates}
    actual = workspace_crates(engine_root)
    if classified != actual:
        raise CoverageFailure(
            "coverage crate census differs; "
            f"missing={sorted(actual - classified)}, stale={sorted(classified - actual)}"
        )


def verify_tool(scope: dict[str, Any], engine_root: Path) -> dict[str, str]:
    version = run_command(["cargo", "llvm-cov", "--version"], "cargo-llvm-cov version").strip()
    expected = f"cargo-llvm-cov {scope['tool']['version']}"
    if version != expected:
        raise CoverageFailure(f"cargo-llvm-cov pin differs: expected {expected}, got {version}")
    return {
        "cargoLlvmCov": version,
        "source": scope["tool"]["source"],
        "rustc": run_command(["rustc", "--version"], "rustc version", cwd=engine_root).strip(),
        "cargo": run_command(["cargo", "--version"], "cargo version", cwd=engine_root).strip(),
    }


def instrumented_packages(scope: dict[str, Any]) -> list[str]:
    return [
        crate
        for group in scope["instrumentedGroups"]
        for crate in scope["groups"][group]
    ]


def collect_coverage(
    scope: dict[str, Any], engine_root: Path, raw_json: Path, lcov_path: Path
) -> None:
    packages = instrumented_packages(scope)
    package_args = [item for package in packages for item in ["-p", package]]
    run_command(["cargo", "llvm-cov", "clean", "--workspace"], "coverage clean", cwd=engine_root)
    run_command(
        [
            "cargo",
            "llvm-cov",
            "--locked",
            "--all-features",
            "--no-report",
            "--quiet",
            *package_args,
        ],
        "coverage tests",
        cwd=engine_root,
    )
    run_command(
        [
            "cargo",
            "llvm-cov",
            "report",
            "--summary-only",
            "--json",
            "--output-path",
            str(raw_json),
        ],
        "coverage JSON export",
        cwd=engine_root,
    )
    run_command(
        ["cargo", "llvm-cov", "report", "--lcov", "--output-path", str(lcov_path)],
        "coverage LCOV export",
        cwd=engine_root,
    )


def excluded(relative_source: str, exclusions: dict[str, list[str]]) -> bool:
    return any(
        fnmatch.fnmatch(relative_source, pattern)
        for patterns in exclusions.values()
        for pattern in patterns
    )


def source_census(
    scope: dict[str, Any], engine_root: Path
) -> tuple[dict[str, list[str]], dict[str, str]]:
    sources: dict[str, list[str]] = {}
    groups: dict[str, str] = {}
    exclusions = scope["exclusions"]
    for group in scope["instrumentedGroups"]:
        for crate in scope["groups"][group]:
            crate_root = engine_root / "crates" / crate
            source_root = crate_root / scope["sourceRoot"]
            files = []
            for path in sorted(source_root.rglob("*.rs")):
                relative_source = path.relative_to(crate_root).as_posix()
                if not excluded(relative_source, exclusions):
                    files.append(path.relative_to(engine_root).as_posix())
            if not files:
                raise CoverageFailure(f"coverage scope contains no production sources for {crate}")
            sources[crate] = sorted(files)
            groups[crate] = group
    return sources, groups


def crate_for_path(path: Path, engine_root: Path) -> tuple[str, str]:
    try:
        relative = path.resolve().relative_to(engine_root.resolve())
    except ValueError as error:
        raise CoverageFailure(f"coverage includes source outside engine workspace: {path}") from error
    parts = relative.parts
    if len(parts) < 4 or parts[0] != "crates" or parts[2] != "src":
        raise CoverageFailure(f"coverage includes unclassified source path: {relative.as_posix()}")
    return parts[1], relative.as_posix()


def parse_lcov_sources(lcov_path: Path, engine_root: Path) -> set[str]:
    try:
        lines = lcov_path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise CoverageFailure(f"cannot read LCOV {lcov_path}: {error}") from error
    sources = set()
    for line in lines:
        if line.startswith("SF:"):
            _, relative = crate_for_path(Path(line[3:]), engine_root)
            if relative in sources:
                raise CoverageFailure(f"duplicate LCOV source: {relative}")
            sources.add(relative)
    if not sources:
        raise CoverageFailure("LCOV report has no source files")
    return sources


def unsigned(value: Any, label: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value < 0:
        raise CoverageFailure(f"{label} must be a non-negative integer")
    return value


def build_report(
    raw_path: Path,
    lcov_path: Path,
    scope: dict[str, Any],
    engine_root: Path,
    provenance: dict[str, str],
) -> dict[str, Any]:
    raw = read_json(raw_path, "LLVM coverage JSON")
    if not isinstance(raw, dict) or raw.get("type") != "llvm.coverage.json.export":
        raise CoverageFailure("LLVM coverage JSON type differs")
    if not isinstance(raw.get("version"), str) or not raw["version"]:
        raise CoverageFailure("LLVM coverage JSON version is missing")
    data = raw.get("data")
    if not isinstance(data, list) or len(data) != 1 or not isinstance(data[0], dict):
        raise CoverageFailure("LLVM coverage JSON must contain one data set")
    files = data[0].get("files")
    if not isinstance(files, list) or not files:
        raise CoverageFailure("LLVM coverage JSON has no files")

    source_files, groups = source_census(scope, engine_root)
    instrumented = set(source_files)
    permitted = {
        crate
        for group in scope["permittedDependencyCoverageGroups"]
        for crate in scope["groups"][group]
    }
    lcov_sources = parse_lcov_sources(lcov_path, engine_root)
    measured: dict[str, dict[str, dict[str, int]]] = {crate: {} for crate in instrumented}
    seen: set[str] = set()
    ignored_dependency_files = 0
    for entry in files:
        if not isinstance(entry, dict) or set(entry) != {"filename", "summary"}:
            raise CoverageFailure("LLVM coverage file entry fields differ")
        filename = entry["filename"]
        if not isinstance(filename, str) or not filename:
            raise CoverageFailure("LLVM coverage filename is invalid")
        crate, relative = crate_for_path(Path(filename), engine_root)
        if relative in seen:
            raise CoverageFailure(f"duplicate LLVM coverage source: {relative}")
        seen.add(relative)
        if relative not in lcov_sources:
            raise CoverageFailure(f"LCOV is missing LLVM coverage source: {relative}")
        if crate in permitted:
            ignored_dependency_files += 1
            continue
        if crate not in instrumented:
            raise CoverageFailure(f"coverage includes unclassified dependency crate: {crate}")
        if relative not in source_files[crate]:
            relative_source = Path(relative).relative_to("crates", crate).as_posix()
            if excluded(relative_source, scope["exclusions"]):
                continue
            raise CoverageFailure(f"coverage source is absent from production census: {relative}")
        summary = entry["summary"]
        if not isinstance(summary, dict) or "lines" not in summary:
            raise CoverageFailure(f"coverage line summary missing for {relative}")
        lines = summary["lines"]
        if not isinstance(lines, dict):
            raise CoverageFailure(f"coverage lines are invalid for {relative}")
        counted = unsigned(lines.get("count"), f"counted lines for {relative}")
        covered = unsigned(lines.get("covered"), f"covered lines for {relative}")
        if covered > counted:
            raise CoverageFailure(f"covered lines exceed counted lines for {relative}")
        measured[crate][relative] = {"covered": covered, "counted": counted}

    unexpected_lcov = lcov_sources - seen
    if unexpected_lcov:
        raise CoverageFailure(f"LCOV contains files absent from LLVM JSON: {sorted(unexpected_lcov)}")
    crate_reports: dict[str, Any] = {}
    for crate in sorted(instrumented):
        counted = sum(value["counted"] for value in measured[crate].values())
        covered = sum(value["covered"] for value in measured[crate].values())
        if counted <= 0:
            raise CoverageFailure(f"coverage has no counted production lines for {crate}")
        missing = sorted(set(source_files[crate]) - set(measured[crate]))
        crate_reports[crate] = {
            "group": groups[crate],
            "coveredLines": covered,
            "countedLines": counted,
            "uncoveredLines": counted - covered,
            "ratio": f"{covered}/{counted}",
            "sourceFiles": source_files[crate],
            "missingFiles": missing,
            "files": dict(sorted(measured[crate].items())),
        }
    return {
        "provenance": {
            **provenance,
            "llvmCoverageFormat": raw["version"],
            "scope": "authoritative-plus-runtime",
        },
        "methodology": scope["methodology"],
        "ignoredDependencyFiles": ignored_dependency_files,
        "crates": crate_reports,
    }


def snapshot_from(report: dict[str, Any]) -> dict[str, Any]:
    crates = {}
    for crate, current in report["crates"].items():
        crates[crate] = {
            key: current[key]
            for key in [
                "group",
                "coveredLines",
                "countedLines",
                "uncoveredLines",
                "sourceFiles",
                "missingFiles",
            ]
        }
    return {
        "provenance": {
            **report["provenance"],
            "reviewedDate": "2026-08-30",
        },
        "crates": crates,
    }


def validate_baseline_crate(crate: str, value: Any) -> dict[str, Any]:
    baseline = strict_object(value, f"coverage baseline crate {crate}", CRATE_BASELINE_KEYS)
    for field in ["coveredLines", "countedLines", "uncoveredLines"]:
        unsigned(baseline[field], f"baseline {field} for {crate}")
    if baseline["countedLines"] <= 0:
        raise CoverageFailure(f"baseline counted lines must be positive for {crate}")
    if baseline["uncoveredLines"] != baseline["countedLines"] - baseline["coveredLines"]:
        raise CoverageFailure(f"baseline line totals disagree for {crate}")
    for field in ["sourceFiles", "missingFiles"]:
        values = baseline[field]
        if not isinstance(values, list) or values != sorted(set(values)):
            raise CoverageFailure(f"baseline {field} must be a sorted unique list for {crate}")
    if not set(baseline["missingFiles"]).issubset(baseline["sourceFiles"]):
        raise CoverageFailure(f"baseline missing files are outside source census for {crate}")
    return baseline


def declarative_source(engine_root: Path, relative: str) -> bool:
    try:
        source = (engine_root / relative).read_text(encoding="utf-8")
    except OSError as error:
        raise CoverageFailure(f"cannot inspect missing coverage source {relative}: {error}") from error
    return not any(EXECUTABLE_RUST.search(line) for line in source.splitlines())


def check_baseline(report: dict[str, Any], baseline_path: Path, engine_root: Path) -> None:
    raw = strict_object(read_json(baseline_path, "coverage baseline"), "coverage baseline", BASELINE_KEYS)
    provenance = strict_object(
        raw["provenance"], "coverage baseline provenance", BASELINE_PROVENANCE_KEYS
    )
    if provenance["cargoLlvmCov"] != report["provenance"]["cargoLlvmCov"]:
        raise CoverageFailure("coverage baseline cargo-llvm-cov version differs")
    if provenance["source"] != report["provenance"]["source"]:
        raise CoverageFailure("coverage baseline tool source differs")
    if provenance["scope"] != "authoritative-plus-runtime":
        raise CoverageFailure("coverage baseline scope differs")
    crates = raw["crates"]
    if not isinstance(crates, dict) or set(crates) != set(report["crates"]):
        raise CoverageFailure("coverage baseline crate census differs")
    for crate, current in report["crates"].items():
        baseline = validate_baseline_crate(crate, crates[crate])
        if current["group"] != baseline["group"]:
            raise CoverageFailure(f"coverage group changed for {crate}")
        removed_sources = set(baseline["sourceFiles"]) - set(current["sourceFiles"])
        if removed_sources:
            raise CoverageFailure(f"production source files were removed from {crate}: {sorted(removed_sources)}")
        new_missing = set(current["missingFiles"]) - set(baseline["missingFiles"])
        executable_missing = {
            source for source in new_missing if not declarative_source(engine_root, source)
        }
        if executable_missing:
            raise CoverageFailure(
                f"executable missing-file set grew for {crate}: {sorted(executable_missing)}"
            )
        if current["uncoveredLines"] > baseline["uncoveredLines"]:
            raise CoverageFailure(
                f"uncovered lines grew for {crate}: "
                f"{current['uncoveredLines']} > {baseline['uncoveredLines']}"
            )
        if current["coveredLines"] * baseline["countedLines"] < (
            baseline["coveredLines"] * current["countedLines"]
        ):
            raise CoverageFailure(
                f"line coverage ratio decreased for {crate}: "
                f"{current['coveredLines']}/{current['countedLines']} < "
                f"{baseline['coveredLines']}/{baseline['countedLines']}"
            )


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def run() -> None:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    engine_root = repo_root / "engine"
    scope = load_scope(resolve(repo_root, args.scope))
    verify_scope_census(scope, engine_root)
    provenance = verify_tool(scope, engine_root)
    report_path = resolve(repo_root, args.report)
    lcov_path = resolve(repo_root, args.lcov)
    if args.raw_json is None:
        with tempfile.TemporaryDirectory(prefix="aonw-rust-coverage-") as temp_dir:
            raw_path = Path(temp_dir) / "llvm-coverage.json"
            collect_coverage(scope, engine_root, raw_path, lcov_path)
            report = build_report(raw_path, lcov_path, scope, engine_root, provenance)
    else:
        if args.lcov_input is None:
            raise CoverageFailure("--lcov-input is required with --raw-json")
        raw_path = resolve(repo_root, args.raw_json)
        lcov_path = resolve(repo_root, args.lcov_input)
        report = build_report(raw_path, lcov_path, scope, engine_root, provenance)
    write_json(report_path, report)
    if args.mode == "check":
        check_baseline(report, resolve(repo_root, args.baseline), engine_root)
        print(f"Rust coverage check passed: {len(report['crates'])} ratcheted crates.")
    elif args.mode == "snapshot":
        write_json(resolve(repo_root, args.snapshot), snapshot_from(report))
        print(f"Wrote Rust coverage baseline candidate to {resolve(repo_root, args.snapshot)}")
    else:
        print(f"Wrote Rust coverage report to {report_path}")


if __name__ == "__main__":
    try:
        run()
    except CoverageFailure as error:
        print(f"Rust coverage check failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
