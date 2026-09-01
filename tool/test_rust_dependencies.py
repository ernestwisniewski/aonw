#!/usr/bin/env python3
"""Negative fixtures for the pinned Rust dependency gate."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Callable


REPO_ROOT = Path(__file__).resolve().parent.parent
CHECKER = REPO_ROOT / "tool/check_rust_dependencies.py"


class Fixture:
    def __init__(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="aonw-rust-dependencies-"))
        self.policy_path = self.root / "engine/quality/dependency_policy.json"
        self.metadata_path = self.root / "metadata.json"
        self.deny_bin = self.root / "cargo-deny"
        self.policy: dict[str, Any] = {}
        self.metadata: dict[str, Any] = {}
        self.reset()

    def close(self) -> None:
        shutil.rmtree(self.root)

    def reset(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)
        (self.root / "engine/quality").mkdir(parents=True, exist_ok=True)
        (self.root / "engine/Cargo.toml").write_text("[workspace]\n", encoding="utf-8")
        (self.root / "engine/deny.toml").write_text("[licenses]\nallow = []\n", encoding="utf-8")
        self.deny_bin.write_text(
            "#!/usr/bin/env sh\n"
            "if [ \"${1:-}\" = \"--version\" ]; then\n"
            "  echo 'cargo-deny 0.20.2'\n"
            "fi\n"
            "exit 0\n",
            encoding="utf-8",
        )
        os.chmod(self.deny_bin, 0o755)
        self.policy = {
            "reviewedDate": "2099-01-01",
            "cargoDeny": {
                "executable": "cargo-deny",
                "version": "0.20.2",
                "source": "https://crates.io/crates/cargo-deny/0.20.2",
                "config": "engine/deny.toml",
            },
            "workspaceManifest": "engine/Cargo.toml",
            "allowedSources": [
                "registry+https://github.com/rust-lang/crates.io-index"
            ],
            "duplicateAllowlist": [
                {
                    "name": "syn",
                    "versions": ["2.0.0", "3.0.0"],
                    "owner": "engine-foundation",
                    "reason": "synthetic duplicate",
                    "risk": "docs/rust-engine-migration.md#rust-quality-baseline",
                    "expires": "2099-01-01",
                }
            ],
        }
        registry = "registry+https://github.com/rust-lang/crates.io-index"
        self.metadata = {
            "packages": [
                {"name": "workspace", "version": "0.1.0", "source": None, "license": "MIT"},
                {"name": "syn", "version": "2.0.0", "source": registry, "license": "MIT"},
                {"name": "syn", "version": "3.0.0", "source": registry, "license": "MIT"},
            ]
        }
        self.write()

    def write(self) -> None:
        self.policy_path.write_text(json.dumps(self.policy, indent=2) + "\n", encoding="utf-8")
        self.metadata_path.write_text(
            json.dumps(self.metadata, indent=2) + "\n", encoding="utf-8"
        )

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "--repo-root",
                str(self.root),
                "--policy",
                str(self.policy_path),
                "--metadata-file",
                str(self.metadata_path),
                "--deny-bin",
                str(self.deny_bin),
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
        raise RuntimeError(f"dependency checker accepted {label}")
    print(f"Dependency checker rejected {label}.")


def main() -> None:
    fixture = Fixture()
    try:
        baseline = fixture.run()
        if baseline.returncode != 0:
            raise RuntimeError(f"baseline fixture failed: {baseline.stderr}")
        expect_rejection(
            fixture,
            "a different cargo-deny version",
            lambda value: value.policy["cargoDeny"].update({"version": "0.20.1"}),
        )
        expect_rejection(
            fixture,
            "an unapproved package source",
            lambda value: value.metadata["packages"][1].update(
                {"source": "git+https://example.invalid/source"}
            ),
        )
        expect_rejection(
            fixture,
            "a package without a license expression",
            lambda value: value.metadata["packages"][1].update({"license": None}),
        )
        expect_rejection(
            fixture,
            "duplicate dependency drift",
            lambda value: value.metadata["packages"][2].update({"version": "3.1.0"}),
        )
        expect_rejection(
            fixture,
            "an expired duplicate exception",
            lambda value: value.policy["duplicateAllowlist"][0].update(
                {"expires": "2000-01-01"}
            ),
        )
        expect_rejection(
            fixture,
            "an incomplete duplicate exception",
            lambda value: value.policy["duplicateAllowlist"][0].pop("owner"),
        )
        expect_rejection(
            fixture,
            "an unknown policy field",
            lambda value: value.policy.update({"schemaVersion": 1}),
        )
    finally:
        fixture.close()
    print("Rust dependency negative tests passed.")


if __name__ == "__main__":
    main()
