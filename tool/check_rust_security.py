#!/usr/bin/env python3
"""Validate and execute pinned Rust mutation, fuzz, and Miri gates."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "engine"
POLICY_PATH = ENGINE / "quality/security_test_policy.json"
TOP_LEVEL_KEYS = {"reviewedDate", "mutation", "fuzz", "miri"}
TOOL_KEYS = {"name", "version", "source"}
TARGET_KEYS = {
    "package",
    "file",
    "filter",
    "expectedMutants",
    "testArguments",
}


class SecurityFailure(RuntimeError):
    """An actionable Rust security-gate failure."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["policy", "tools", "mutation", "fuzz", "miri"])
    return parser.parse_args()


def fail(message: str) -> None:
    raise SecurityFailure(message)


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != keys:
        fail(f"{label} fields differ")
    return value


def read_policy() -> dict[str, Any]:
    try:
        policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot read security policy: {error}")
    strict_object(policy, "policy", TOP_LEVEL_KEYS)
    if not isinstance(policy["reviewedDate"], str) or re.fullmatch(
        r"\d{4}-\d{2}-\d{2}", policy["reviewedDate"]
    ) is None:
        fail("reviewedDate must be ISO date")

    mutation = strict_object(
        policy["mutation"], "mutation", {"tool", "maximumSurvivors", "targets"}
    )
    validate_tool(mutation["tool"], "mutation.tool", "cargo-mutants")
    if mutation["maximumSurvivors"] != 0:
        fail("mutation survivors must fail closed at zero")
    targets = mutation["targets"]
    if not isinstance(targets, list) or len(targets) != 4:
        fail("four focused mutation targets are required")
    target_keys: list[tuple[str, str]] = []
    for index, raw_target in enumerate(targets):
        target = strict_object(raw_target, f"mutation.targets[{index}]", TARGET_KEYS)
        if not all(isinstance(target[key], str) for key in ("package", "file", "filter")):
            fail(f"mutation.targets[{index}] string fields differ")
        if not isinstance(target["expectedMutants"], int) or target["expectedMutants"] <= 0:
            fail(f"mutation.targets[{index}] expectedMutants must be positive")
        arguments = target["testArguments"]
        if (
            not isinstance(arguments, list)
            or not arguments
            or not all(isinstance(value, str) for value in arguments)
        ):
            fail(f"mutation.targets[{index}] testArguments differ")
        path = ENGINE / target["file"]
        if not path.is_file() or ENGINE not in path.resolve().parents:
            fail(f"mutation target path is invalid: {target['file']}")
        re.compile(target["filter"])
        target_keys.append((target["package"], target["file"]))
    if target_keys != sorted(set(target_keys)):
        fail("mutation targets must be unique and sorted")

    fuzz = strict_object(
        policy["fuzz"],
        "fuzz",
        {
            "tool",
            "libfuzzerSysVersion",
            "toolchain",
            "smokeRuns",
            "maximumInputBytes",
            "targets",
        },
    )
    validate_tool(fuzz["tool"], "fuzz.tool", "cargo-fuzz")
    if not isinstance(fuzz["libfuzzerSysVersion"], str) or re.fullmatch(
        r"\d+\.\d+\.\d+", fuzz["libfuzzerSysVersion"]
    ) is None:
        fail("libfuzzerSysVersion must be exact")
    if not isinstance(fuzz["toolchain"], str) or re.fullmatch(
        r"nightly-\d{4}-\d{2}-\d{2}", fuzz["toolchain"]
    ) is None:
        fail("fuzz toolchain must be a pinned nightly")
    if (
        not isinstance(fuzz["smokeRuns"], int)
        or fuzz["smokeRuns"] < 1024
        or fuzz["maximumInputBytes"] != 65_536
    ):
        fail("fuzz smoke bounds differ")
    fuzz_targets = fuzz["targets"]
    if (
        not isinstance(fuzz_targets, list)
        or len(fuzz_targets) != 3
        or fuzz_targets != sorted(set(fuzz_targets))
    ):
        fail("fuzz targets must be unique and sorted")
    manifest = (ENGINE / "fuzz/Cargo.toml").read_text(encoding="utf-8")
    if not (ENGINE / "fuzz/Cargo.lock").is_file():
        fail("fuzz lockfile is missing")
    for target in fuzz_targets:
        if not isinstance(target, str) or f'name = "{target}"' not in manifest:
            fail(f"fuzz target is absent from manifest: {target}")
        if not (ENGINE / f"fuzz/fuzz_targets/{target}.rs").is_file():
            fail(f"fuzz target source is missing: {target}")
    if f'libfuzzer-sys = "={fuzz["libfuzzerSysVersion"]}"' not in manifest:
        fail("libfuzzer-sys pin differs")

    miri = strict_object(
        policy["miri"],
        "miri",
        {"toolchain", "rustcVersion", "miriVersion", "packages"},
    )
    if miri["toolchain"] != fuzz["toolchain"]:
        fail("Miri and fuzz must share one pinned nightly")
    if not isinstance(miri["rustcVersion"], str) or not miri["rustcVersion"].startswith(
        "rustc 1.100.0-nightly "
    ):
        fail("Miri rustc version must be the reviewed nightly build")
    if not isinstance(miri["miriVersion"], str) or not miri["miriVersion"].startswith(
        "miri 0.1.0 "
    ):
        fail("Miri version must be exact")
    packages = miri["packages"]
    if (
        not isinstance(packages, list)
        or len(packages) != 3
        or packages != sorted(set(packages))
    ):
        fail("Miri packages must be unique and sorted")
    return policy


def validate_tool(raw: Any, label: str, expected_name: str) -> None:
    tool = strict_object(raw, label, TOOL_KEYS)
    if tool["name"] != expected_name:
        fail(f"{label} name differs")
    if not isinstance(tool["version"], str) or re.fullmatch(
        r"\d+\.\d+\.\d+", tool["version"]
    ) is None:
        fail(f"{label} version must be exact")
    expected_source = f"https://crates.io/crates/{expected_name}/{tool['version']}"
    if tool["source"] != expected_source:
        fail(f"{label} source differs")


def output(command: list[str], cwd: Path = ROOT) -> str:
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        diagnostic = result.stderr.strip() or result.stdout.strip()
        fail(f"{' '.join(command)} failed:\n{diagnostic}")
    return result.stdout.strip()


def run(
    command: list[str],
    cwd: Path = ROOT,
    env: dict[str, str] | None = None,
    quiet: bool = False,
) -> None:
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        capture_output=quiet,
        text=quiet,
        check=False,
    )
    if result.returncode != 0:
        diagnostic = ""
        if quiet:
            diagnostic = (result.stderr or result.stdout).strip()
        suffix = f":\n{diagnostic}" if diagnostic else ""
        fail(f"{' '.join(command)} failed with exit {result.returncode}{suffix}")


def check_mutation_tool(policy: dict[str, Any]) -> None:
    mutation = policy["mutation"]["tool"]
    if output(["cargo", "mutants", "--version"]) != f"cargo-mutants {mutation['version']}":
        fail("cargo-mutants executable version differs")


def check_fuzz_tool(policy: dict[str, Any]) -> None:
    fuzz = policy["fuzz"]
    if output(["cargo", f"+{fuzz['toolchain']}", "fuzz", "--version"]) != (
        f"cargo-fuzz {fuzz['tool']['version']}"
    ):
        fail("cargo-fuzz executable version differs")


def check_miri_tool(policy: dict[str, Any]) -> None:
    miri = policy["miri"]
    if output(["rustc", f"+{miri['toolchain']}", "--version"]) != miri["rustcVersion"]:
        fail("pinned nightly rustc version differs")
    if output(["cargo", f"+{miri['toolchain']}", "miri", "--version"]) != miri["miriVersion"]:
        fail("Miri executable version differs")


def mutation_gate(policy: dict[str, Any]) -> None:
    caught_total = 0
    unviable_total = 0
    for target in policy["mutation"]["targets"]:
        common = [
            "cargo",
            "mutants",
            "--no-config",
            "--no-shuffle",
            "--jobs",
            "1",
            "--timeout",
            "180",
            "--minimum-test-timeout",
            "30",
            "--all-features",
            "--package",
            target["package"],
            "--file",
            target["file"],
            "--re",
            target["filter"],
        ]
        mutants = output([*common, "--list"], ENGINE).splitlines()
        if len(mutants) != target["expectedMutants"]:
            fail(
                f"mutation census differs for {target['file']}: "
                f"expected {target['expectedMutants']}, actual {len(mutants)}"
            )
        run([*common, "--", *target["testArguments"]], ENGINE)
        outcomes_path = ENGINE / "mutants.out/outcomes.json"
        try:
            outcomes = json.loads(outcomes_path.read_text(encoding="utf-8"))["outcomes"]
        except (OSError, KeyError, TypeError, json.JSONDecodeError) as error:
            fail(f"cannot read mutation outcomes for {target['file']}: {error}")
        summaries = [
            outcome["summary"]
            for outcome in outcomes
            if isinstance(outcome.get("scenario"), dict) and "Mutant" in outcome["scenario"]
        ]
        caught = summaries.count("CaughtMutant")
        unviable = summaries.count("Unviable")
        if caught == 0:
            fail(f"mutation target produced no viable caught mutant: {target['file']}")
        if caught + unviable != target["expectedMutants"]:
            fail(f"mutation outcomes differ for {target['file']}: {summaries}")
        caught_total += caught
        unviable_total += unviable
    expected_total = sum(
        target["expectedMutants"] for target in policy["mutation"]["targets"]
    )
    print(
        "Rust mutation gate passed: "
        f"{expected_total} generated, {caught_total} caught, "
        f"{unviable_total} unviable, 0 survivors."
    )


def fuzz_gate(policy: dict[str, Any]) -> None:
    fuzz = policy["fuzz"]
    with tempfile.TemporaryDirectory(prefix="aonw-rust-fuzz-") as artifacts:
        for target in fuzz["targets"]:
            run(
                [
                    "cargo",
                    f"+{fuzz['toolchain']}",
                    "fuzz",
                    "run",
                    target,
                    "--",
                    f"-runs={fuzz['smokeRuns']}",
                    f"-max_len={fuzz['maximumInputBytes']}",
                    "-timeout=5",
                    f"-artifact_prefix={artifacts}/",
                ],
                ENGINE,
                quiet=True,
            )
    print(f"Rust fuzz smoke passed: {len(fuzz['targets'])} targets.")


def miri_gate(policy: dict[str, Any]) -> None:
    miri = policy["miri"]
    for package in miri["packages"]:
        run(
            [
                "cargo",
                f"+{miri['toolchain']}",
                "miri",
                "test",
                "--locked",
                "--package",
                package,
                "--lib",
            ],
            ENGINE,
            quiet=True,
        )
    print(f"Rust Miri gate passed: {len(miri['packages'])} pure boundary crates.")


def main() -> None:
    args = parse_args()
    policy = read_policy()
    if args.mode == "policy":
        mutation_count = sum(
            target["expectedMutants"] for target in policy["mutation"]["targets"]
        )
        print(
            "Rust security policy passed: "
            f"{mutation_count} mutants, 3 fuzz targets, 3 Miri crates."
        )
        return
    if args.mode == "tools":
        check_mutation_tool(policy)
        check_fuzz_tool(policy)
        check_miri_tool(policy)
        print("Rust security tool versions passed.")
    elif args.mode == "mutation":
        check_mutation_tool(policy)
        mutation_gate(policy)
    elif args.mode == "fuzz":
        check_fuzz_tool(policy)
        fuzz_gate(policy)
    elif args.mode == "miri":
        check_miri_tool(policy)
        miri_gate(policy)


if __name__ == "__main__":
    try:
        main()
    except (OSError, re.error, SecurityFailure) as error:
        print(f"Rust security gate failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
