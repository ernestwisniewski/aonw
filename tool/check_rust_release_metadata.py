#!/usr/bin/env python3
"""Generate reproducible SBOM and notice files with pinned external Cargo tools."""

from __future__ import annotations

import argparse
import datetime as dt
import difflib
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "engine"
POLICY_PATH = ENGINE / "quality/release_metadata_policy.json"
DEFAULT_OUTPUT = Path("/tmp/aonw-rust-release-metadata")
POLICY_KEYS = {
    "reviewedDate",
    "epochSource",
    "tools",
    "cycloneDx",
    "notices",
    "supportedTargets",
    "artifacts",
}
EXPECTED_PACKAGES = ["aonw_flutter", "aonw_godot", "aonw_map_compiler_cli"]


class ReleaseMetadataFailure(RuntimeError):
    """An actionable release-metadata failure."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["policy", "tools", "check"])
    parser.add_argument("--policy", type=Path, default=POLICY_PATH)
    parser.add_argument("--target")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def fail(message: str) -> None:
    raise ReleaseMetadataFailure(message)


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != keys:
        fail(f"{label} fields differ")
    return value


def string_list(value: Any, label: str) -> list[str]:
    if (
        not isinstance(value, list)
        or not value
        or not all(isinstance(item, str) and item for item in value)
        or value != sorted(set(value))
    ):
        fail(f"{label} must be a non-empty sorted unique string list")
    return value


def repository_path(value: str, label: str) -> Path:
    relative = Path(value)
    if relative.is_absolute() or ".." in relative.parts:
        fail(f"{label} must be repository-relative")
    resolved = (ROOT / relative).resolve()
    try:
        resolved.relative_to(ROOT)
    except ValueError as error:
        raise ReleaseMetadataFailure(f"{label} escapes repository") from error
    if not resolved.is_file():
        fail(f"{label} is missing: {value}")
    return resolved


def load_policy(path: Path = POLICY_PATH) -> dict[str, Any]:
    try:
        policy = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReleaseMetadataFailure(f"cannot read release metadata policy: {error}") from error
    strict_object(policy, "policy", POLICY_KEYS)
    try:
        reviewed_date = dt.date.fromisoformat(policy["reviewedDate"])
    except (TypeError, ValueError) as error:
        raise ReleaseMetadataFailure("reviewedDate must be an ISO date") from error
    if reviewed_date > dt.date.today():
        fail("reviewedDate cannot be in the future")
    if policy["epochSource"] != "git-commit":
        fail("release metadata epoch must come from the git commit")

    tools = strict_object(policy["tools"], "tools", {"cargoCyclonedx", "cargoAbout"})
    expected_tools = {
        "cargoCyclonedx": ("cargo-cyclonedx", "0.5.9", []),
        "cargoAbout": ("cargo-about", "0.9.2", ["cli"]),
    }
    for key, (crate, version, features) in expected_tools.items():
        tool = strict_object(
            tools[key], key, {"version", "source", "installFeatures"}
        )
        if tool["version"] != version:
            fail(f"{key} version must be pinned to {version}")
        if tool["source"] != f"https://crates.io/crates/{crate}/{version}":
            fail(f"{key} source differs")
        if tool["installFeatures"] != features:
            fail(f"{key} install features differ")

    cyclone = strict_object(
        policy["cycloneDx"],
        "cycloneDx",
        {"specVersion", "format", "acceptedNamedLicenses"},
    )
    if cyclone["specVersion"] != "1.5" or cyclone["format"] != "json":
        fail("CycloneDX output contract differs")
    if string_list(
        cyclone["acceptedNamedLicenses"], "acceptedNamedLicenses"
    ) != ["Apache-2.0/MIT", "MIT/Apache-2.0"]:
        fail("accepted named license census differs")

    notices = strict_object(policy["notices"], "notices", {"config", "template"})
    repository_path(notices["config"], "notices.config")
    repository_path(notices["template"], "notices.template")
    targets = string_list(policy["supportedTargets"], "supportedTargets")
    if targets != [
        "aarch64-apple-darwin",
        "x86_64-apple-darwin",
        "x86_64-unknown-linux-gnu",
    ]:
        fail("supported release metadata targets differ")

    artifacts = policy["artifacts"]
    if not isinstance(artifacts, list) or len(artifacts) != len(EXPECTED_PACKAGES):
        fail("release artifact census differs")
    packages: list[str] = []
    stems: list[str] = []
    for index, raw_artifact in enumerate(artifacts):
        artifact = strict_object(
            raw_artifact,
            f"artifacts[{index}]",
            {"package", "manifest", "outputStem"},
        )
        if not all(isinstance(artifact[key], str) for key in artifact):
            fail(f"artifacts[{index}] fields must be strings")
        manifest = repository_path(artifact["manifest"], f"artifacts[{index}].manifest")
        try:
            manifest_package = tomllib.loads(manifest.read_text(encoding="utf-8"))["package"][
                "name"
            ]
        except (OSError, tomllib.TOMLDecodeError, KeyError, TypeError) as error:
            raise ReleaseMetadataFailure(f"cannot read {artifact['manifest']}: {error}") from error
        if manifest_package != artifact["package"]:
            fail(f"artifact package differs for {artifact['manifest']}")
        packages.append(artifact["package"])
        stems.append(artifact["outputStem"])
    if packages != EXPECTED_PACKAGES or stems != sorted(set(stems)):
        fail("release artifacts must be unique and sorted by package")
    return policy


def command(
    arguments: list[str],
    *,
    cwd: Path = ROOT,
    environment: dict[str, str] | None = None,
) -> str:
    try:
        result = subprocess.run(
            arguments,
            cwd=cwd,
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError as error:
        raise ReleaseMetadataFailure(f"cannot run {arguments[0]}: {error}") from error
    if result.returncode != 0:
        diagnostic = result.stderr.strip() or result.stdout.strip()
        fail(f"{' '.join(arguments)} failed:\n{diagnostic}")
    return result.stdout.strip()


def verify_tools(policy: dict[str, Any]) -> None:
    cyclone_version = policy["tools"]["cargoCyclonedx"]["version"]
    if command(["cargo", "cyclonedx", "--version"]) != (
        f"cargo-cyclonedx-cyclonedx {cyclone_version}"
    ):
        fail("cargo-cyclonedx executable version differs")
    about_version = policy["tools"]["cargoAbout"]["version"]
    if command(["cargo", "about", "--version"]) != f"cargo-about {about_version}":
        fail("cargo-about executable version differs")


def host_target() -> str:
    for line in command(["rustc", "-vV"], cwd=ENGINE).splitlines():
        if line.startswith("host: "):
            return line.removeprefix("host: ")
    fail("rustc did not report its host target")


def commit_epoch() -> str:
    epoch = command(["git", "log", "-1", "--format=%ct"], cwd=ROOT)
    if not epoch.isdigit():
        fail("git commit epoch differs")
    return epoch


def copy_engine(destination: Path) -> Path:
    copied = destination / "engine"

    def ignored(_: str, names: list[str]) -> set[str]:
        return {
            name
            for name in names
            if name in {"target", "mutants.out", "mutants.out.old"}
        }

    shutil.copytree(ENGINE, copied, ignore=ignored)
    return copied


def generate_once(
    policy: dict[str, Any], target: str, epoch: str, destination: Path
) -> dict[str, dict[str, Path]]:
    copied_engine = copy_engine(destination)
    environment = os.environ.copy()
    environment["SOURCE_DATE_EPOCH"] = epoch
    cyclone = policy["cycloneDx"]
    cyclone_command = [
        "cargo",
        "cyclonedx",
        "--manifest-path",
        str(copied_engine / "Cargo.toml"),
        "--format",
        cyclone["format"],
        "--all-features",
        "--target",
        target,
        "--override-filename",
        "aonw-release",
        "--license-strict",
        "--spec-version",
        cyclone["specVersion"],
        "--no-build-deps",
    ]
    for license_name in cyclone["acceptedNamedLicenses"]:
        cyclone_command.extend(["--license-accept-named", license_name])
    command(cyclone_command, cwd=copied_engine, environment=environment)

    command(
        [
            "cargo",
            "fetch",
            "--locked",
            "--manifest-path",
            str(copied_engine / "Cargo.toml"),
            "--target",
            target,
        ],
        cwd=copied_engine,
    )
    outputs: dict[str, dict[str, Path]] = {}
    notices = policy["notices"]
    for artifact in policy["artifacts"]:
        relative_manifest = Path(artifact["manifest"]).relative_to("engine")
        manifest = copied_engine / relative_manifest
        generated_sbom = manifest.parent / "aonw-release.json"
        if not generated_sbom.is_file():
            fail(f"cargo-cyclonedx omitted {artifact['package']}")
        sbom = destination / f"{artifact['outputStem']}-{target}.cdx.json"
        canonicalize_sbom(generated_sbom, sbom, copied_engine)
        notice = destination / (
            f"{artifact['outputStem']}-{target}-THIRD-PARTY-NOTICES.txt"
        )
        command(
            [
                "cargo",
                "about",
                "generate",
                "--config",
                str(copied_engine / Path(notices["config"]).relative_to("engine")),
                str(copied_engine / Path(notices["template"]).relative_to("engine")),
                "--manifest-path",
                str(manifest),
                "--all-features",
                "--target",
                target,
                "--locked",
                "--offline",
                "--fail",
                "--output-file",
                str(notice),
            ],
            cwd=copied_engine,
        )
        outputs[artifact["package"]] = {"sbom": sbom, "notices": notice}
    if (copied_engine / "Cargo.lock").read_bytes() != (ENGINE / "Cargo.lock").read_bytes():
        fail("release metadata tools changed Cargo.lock")
    return outputs


def canonicalize_sbom(source: Path, destination: Path, copied_engine: Path) -> None:
    try:
        document = json.loads(source.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReleaseMetadataFailure(f"cannot canonicalize SBOM {source}: {error}") from error
    serialized = json.dumps(document, indent=2)
    local_uris = {
        copied_engine.absolute().as_uri(),
        copied_engine.resolve().as_uri(),
    }
    for local_uri in local_uris:
        serialized = serialized.replace(local_uri, "file:///aonw/engine")
    if any(local_uri in serialized for local_uri in local_uris):
        fail(f"SBOM retained an environment-specific path: {source}")
    destination.write_text(serialized + "\n", encoding="utf-8")


def validate_sbom(path: Path, package: str) -> None:
    try:
        sbom = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReleaseMetadataFailure(f"cannot read SBOM {path}: {error}") from error
    if sbom.get("bomFormat") != "CycloneDX" or sbom.get("specVersion") != "1.5":
        fail(f"SBOM contract differs for {package}")
    if "serialNumber" in sbom:
        fail(f"SBOM serial number is nondeterministic for {package}")
    metadata = sbom.get("metadata")
    if not isinstance(metadata, dict) or metadata.get("component", {}).get("name") != package:
        fail(f"SBOM root component differs for {package}")
    if not isinstance(metadata.get("timestamp"), str):
        fail(f"SBOM timestamp is missing for {package}")
    components = sbom.get("components")
    if not isinstance(components, list) or not components:
        fail(f"SBOM components are missing for {package}")


def validate_notice(path: Path, package: str) -> None:
    try:
        notice = path.read_text(encoding="utf-8")
    except OSError as error:
        raise ReleaseMetadataFailure(f"cannot read notices {path}: {error}") from error
    if not notice.startswith("AoNW Rust Artifact Third-Party Notices\n"):
        fail(f"notice header differs for {package}")
    if "serde " not in notice or "License Texts\n" not in notice:
        fail(f"notice dependency census is incomplete for {package}")
    if len(notice) < 1_000:
        fail(f"notice output is unexpectedly small for {package}")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def reproducibility_difference(first: Path, second: Path) -> str:
    difference = difflib.unified_diff(
        first.read_text(encoding="utf-8").splitlines(),
        second.read_text(encoding="utf-8").splitlines(),
        fromfile="first",
        tofile="second",
        n=2,
    )
    return "\n".join(list(difference)[:40])


def publish_outputs(
    generated: dict[str, dict[str, Path]],
    policy: dict[str, Any],
    target: str,
    epoch: str,
    output_directory: Path,
) -> None:
    if output_directory.exists():
        existing = {path.name for path in output_directory.iterdir()}
        marker = output_directory / "release-metadata-manifest.json"
        if existing:
            try:
                previous = json.loads(marker.read_text(encoding="utf-8"))
                previous_names = {
                    details["file"]
                    for artifact in previous["artifacts"]
                    for details in (artifact["sbom"], artifact["notices"])
                } | {marker.name}
            except (OSError, json.JSONDecodeError, KeyError, TypeError) as error:
                raise ReleaseMetadataFailure(
                    f"refusing to replace unowned output directory: {output_directory}"
                ) from error
            if existing != previous_names:
                fail(f"refusing to replace unowned output directory: {output_directory}")
        for path in output_directory.iterdir():
            if not path.is_file():
                fail(f"release metadata output contains a directory: {path}")
            path.unlink()
    else:
        output_directory.mkdir(parents=True)

    manifest_entries = []
    for artifact in policy["artifacts"]:
        files = generated[artifact["package"]]
        published = {}
        for kind, source in files.items():
            destination = output_directory / source.name
            shutil.copyfile(source, destination)
            published[kind] = {"file": destination.name, "sha256": digest(destination)}
        manifest_entries.append({"package": artifact["package"], **published})
    manifest = {
        "sourceDateEpoch": int(epoch),
        "target": target,
        "artifacts": manifest_entries,
    }
    (output_directory / "release-metadata-manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def check(policy: dict[str, Any], target: str, output_directory: Path) -> None:
    if target not in policy["supportedTargets"]:
        fail(f"unsupported release metadata target: {target}")
    epoch = commit_epoch()
    with tempfile.TemporaryDirectory(prefix="aonw-rust-release-metadata-") as directory:
        root = Path(directory)
        first = generate_once(policy, target, epoch, root / "first")
        second = generate_once(policy, target, epoch, root / "second")
        for artifact in policy["artifacts"]:
            package = artifact["package"]
            validate_sbom(first[package]["sbom"], package)
            validate_notice(first[package]["notices"], package)
            for kind in ("sbom", "notices"):
                if first[package][kind].read_bytes() != second[package][kind].read_bytes():
                    fail(
                        f"{kind} output is not reproducible for {package}:\n"
                        f"{reproducibility_difference(first[package][kind], second[package][kind])}"
                    )
        publish_outputs(first, policy, target, epoch, output_directory.resolve())
    print(
        "Rust release metadata passed: "
        f"{len(policy['artifacts'])} target-specific SBOM/notice pairs for {target}."
    )


def main() -> None:
    args = parse_args()
    policy_path = args.policy if args.policy.is_absolute() else ROOT / args.policy
    policy = load_policy(policy_path)
    if args.mode == "policy":
        print(
            "Rust release metadata policy passed: "
            f"{len(policy['artifacts'])} artifacts and "
            f"{len(policy['supportedTargets'])} targets."
        )
        return
    verify_tools(policy)
    if args.mode == "tools":
        print("Rust release metadata tool versions passed.")
        return
    check(policy, args.target or host_target(), args.output_dir)


if __name__ == "__main__":
    try:
        main()
    except ReleaseMetadataFailure as error:
        print(f"Rust release metadata failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
