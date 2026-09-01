#!/usr/bin/env python3
"""Pinned license, source, and duplicate-dependency gate for Rust."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any


POLICY_KEYS = {
    "reviewedDate",
    "cargoDeny",
    "workspaceManifest",
    "allowedSources",
    "duplicateAllowlist",
}


class DependencyFailure(RuntimeError):
    """An actionable dependency-policy failure."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument(
        "--policy", type=Path, default=Path("engine/quality/dependency_policy.json")
    )
    parser.add_argument("--metadata-file", type=Path)
    parser.add_argument("--deny-bin", type=Path)
    parser.add_argument("--report", type=Path)
    return parser.parse_args()


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise DependencyFailure(f"{label} must be an object")
    missing = keys - set(value)
    unknown = set(value) - keys
    if missing or unknown:
        raise DependencyFailure(
            f"{label} keys differ; missing={sorted(missing)}, unknown={sorted(unknown)}"
        )
    return value


def string_list(value: Any, label: str) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise DependencyFailure(f"{label} must be a string list")
    if len(value) != len(set(value)):
        raise DependencyFailure(f"{label} contains duplicates")
    return value


def load_policy(path: Path) -> dict[str, Any]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise DependencyFailure(f"cannot read dependency policy {path}: {error}") from error
    policy = strict_object(raw, "dependency policy", POLICY_KEYS)
    if not isinstance(policy["reviewedDate"], str):
        raise DependencyFailure("reviewedDate must be an ISO date")
    try:
        dt.date.fromisoformat(policy["reviewedDate"])
    except ValueError as error:
        raise DependencyFailure("reviewedDate must be an ISO date") from error
    cargo_deny = strict_object(
        policy["cargoDeny"],
        "cargoDeny",
        {"executable", "version", "source", "config"},
    )
    for key, value in cargo_deny.items():
        if not isinstance(value, str) or not value:
            raise DependencyFailure(f"cargoDeny.{key} must be a non-empty string")
    if not re.fullmatch(r"\d+\.\d+\.\d+", cargo_deny["version"]):
        raise DependencyFailure("cargoDeny.version must be an exact release")
    if not isinstance(policy["workspaceManifest"], str):
        raise DependencyFailure("workspaceManifest must be a string")
    string_list(policy["allowedSources"], "allowedSources")
    allowlist = policy["duplicateAllowlist"]
    if not isinstance(allowlist, list):
        raise DependencyFailure("duplicateAllowlist must be a list")
    names: set[str] = set()
    for index, entry in enumerate(allowlist):
        entry = strict_object(
            entry,
            f"duplicateAllowlist[{index}]",
            {"name", "versions", "owner", "reason", "risk", "expires"},
        )
        for key in ["name", "owner", "reason", "risk", "expires"]:
            if not isinstance(entry[key], str) or not entry[key]:
                raise DependencyFailure(f"duplicateAllowlist[{index}].{key} is required")
        if entry["name"] in names:
            raise DependencyFailure(f"duplicate allowlist repeats {entry['name']}")
        names.add(entry["name"])
        versions = string_list(entry["versions"], f"duplicateAllowlist[{index}].versions")
        if len(versions) < 2 or versions != sorted(versions):
            raise DependencyFailure(f"duplicate versions for {entry['name']} must be sorted")
        try:
            expiry = dt.date.fromisoformat(entry["expires"])
        except ValueError as error:
            raise DependencyFailure(f"invalid expiry for {entry['name']}") from error
        if expiry < dt.date.today():
            raise DependencyFailure(f"duplicate exception expired for {entry['name']}")
    return policy


def repo_path(repo_root: Path, value: str, label: str) -> Path:
    relative = Path(value)
    if relative.is_absolute() or ".." in relative.parts:
        raise DependencyFailure(f"{label} must be repository-relative: {value}")
    resolved = (repo_root / relative).resolve()
    try:
        resolved.relative_to(repo_root)
    except ValueError as error:
        raise DependencyFailure(f"{label} escapes the repository: {value}") from error
    return resolved


def run_command(command: list[str], label: str) -> subprocess.CompletedProcess[str]:
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=False)
    except OSError as error:
        raise DependencyFailure(f"cannot run {label}: {error}") from error
    if result.returncode != 0:
        diagnostic = result.stderr.strip() or result.stdout.strip()
        raise DependencyFailure(f"{label} failed:\n{diagnostic}")
    return result


def load_metadata(
    repo_root: Path, manifest: Path, metadata_file: Path | None
) -> dict[str, Any]:
    if metadata_file is not None:
        path = metadata_file if metadata_file.is_absolute() else repo_root / metadata_file
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise DependencyFailure(f"cannot read metadata fixture: {error}") from error
    else:
        result = run_command(
            [
                "cargo",
                "metadata",
                "--manifest-path",
                str(manifest),
                "--locked",
                "--all-features",
                "--format-version",
                "1",
            ],
            "cargo metadata",
        )
        try:
            raw = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            raise DependencyFailure(f"cargo metadata returned invalid JSON: {error}") from error
    if not isinstance(raw, dict) or not isinstance(raw.get("packages"), list):
        raise DependencyFailure("metadata must contain a packages list")
    return raw


def verify_tool(binary: str, version: str) -> None:
    result = run_command([binary, "--version"], "cargo-deny version check")
    expected = f"cargo-deny {version}"
    if result.stdout.strip() != expected:
        raise DependencyFailure(
            f"cargo-deny version differs: {result.stdout.strip()!r}, expected {expected!r}"
        )


def analyze_packages(
    metadata: dict[str, Any], policy: dict[str, Any]
) -> tuple[dict[str, list[str]], dict[str, list[str]], dict[str, list[str]]]:
    licenses: dict[str, list[str]] = defaultdict(list)
    sources: dict[str, list[str]] = defaultdict(list)
    versions: dict[str, set[str]] = defaultdict(set)
    allowed_sources = set(policy["allowedSources"])
    for package in metadata["packages"]:
        if not isinstance(package, dict):
            raise DependencyFailure("metadata contains a malformed package")
        name = package.get("name")
        version = package.get("version")
        source = package.get("source")
        license_expression = package.get("license")
        if not isinstance(name, str) or not isinstance(version, str):
            raise DependencyFailure("metadata package requires name and version")
        identity = f"{name}@{version}"
        versions[name].add(version)
        if source is None:
            continue
        if not isinstance(source, str) or source not in allowed_sources:
            raise DependencyFailure(f"unapproved source for {identity}: {source!r}")
        if not isinstance(license_expression, str) or not license_expression.strip():
            raise DependencyFailure(f"missing license expression for {identity}")
        sources[source].append(identity)
        licenses[license_expression].append(identity)
    duplicates = {
        name: sorted(values)
        for name, values in versions.items()
        if len(values) > 1
    }
    expected_duplicates = {
        entry["name"]: entry["versions"] for entry in policy["duplicateAllowlist"]
    }
    if duplicates != expected_duplicates:
        raise DependencyFailure(
            f"duplicate dependency ratchet differs; expected={expected_duplicates}, actual={duplicates}"
        )
    return (
        {key: sorted(value) for key, value in sorted(licenses.items())},
        {key: sorted(value) for key, value in sorted(sources.items())},
        duplicates,
    )


def write_report(
    path: Path,
    policy: dict[str, Any],
    licenses: dict[str, list[str]],
    sources: dict[str, list[str]],
    duplicates: dict[str, list[str]],
) -> None:
    report = {
        "reviewedDate": policy["reviewedDate"],
        "tool": {
            "name": "cargo-deny",
            "version": policy["cargoDeny"]["version"],
            "source": policy["cargoDeny"]["source"],
        },
        "licenses": licenses,
        "sources": sources,
        "duplicates": [
            {
                **entry,
                "versions": duplicates[entry["name"]],
            }
            for entry in policy["duplicateAllowlist"]
        ],
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def run() -> None:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    policy_path = args.policy if args.policy.is_absolute() else repo_root / args.policy
    policy = load_policy(policy_path)
    cargo_deny = policy["cargoDeny"]
    manifest = repo_path(repo_root, policy["workspaceManifest"], "workspaceManifest")
    config = repo_path(repo_root, cargo_deny["config"], "cargoDeny.config")
    deny_binary = str(args.deny_bin) if args.deny_bin is not None else cargo_deny["executable"]
    verify_tool(deny_binary, cargo_deny["version"])
    metadata = load_metadata(repo_root, manifest, args.metadata_file)
    licenses, sources, duplicates = analyze_packages(metadata, policy)
    run_command(
        [
            deny_binary,
            "--manifest-path",
            str(manifest),
            "--config",
            str(config),
            "--all-features",
            "--locked",
            "check",
            "licenses",
            "bans",
            "sources",
        ],
        "cargo-deny policy check",
    )
    if args.report is not None:
        report = args.report if args.report.is_absolute() else repo_root / args.report
        write_report(report, policy, licenses, sources, duplicates)
    package_count = sum(len(entries) for entries in sources.values())
    print(
        "Rust dependency check passed: "
        f"{package_count} external packages, {len(licenses)} license expressions, "
        f"{len(duplicates)} reviewed duplicate."
    )


if __name__ == "__main__":
    try:
        run()
    except DependencyFailure as error:
        print(f"Rust dependency check failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
