#!/usr/bin/env python3
"""Install the pinned Terrain3D addon into the AoNW2 Godot project.

The installer accepts either the official release archive or a local archive,
verifies the pinned SHA-256 digest, and atomically replaces only
``addons/terrain_3d``. It does not enable the editor plugin automatically;
that remains an explicit Godot editor action.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import stat
import sys
import tempfile
import urllib.error
import urllib.request
import zipfile
from pathlib import Path, PurePosixPath

VERSION = "1.0.2-stable"
ARCHIVE_NAME = f"Terrain3D_v{VERSION}.zip"
DOWNLOAD_URL = (
    "https://github.com/TokisanGames/Terrain3D/releases/download/"
    f"v{VERSION}/{ARCHIVE_NAME}"
)
SHA256 = "a071850250ec5e596aa54da61c01d75768774eb379ee997584d426a45f4884a2"
ADDON_PREFIX = PurePosixPath("addons/terrain_3d")


def parse_args() -> argparse.Namespace:
    script_project = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=f"Install Terrain3D {VERSION} for the AoNW2 Godot client."
    )
    parser.add_argument(
        "--project",
        type=Path,
        default=script_project,
        help="Godot project directory (default: directory above tools/).",
    )
    parser.add_argument(
        "--archive",
        type=Path,
        help="Use an already downloaded official release ZIP.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace an existing addons/terrain_3d directory.",
    )
    parser.add_argument(
        "--keep-archive",
        type=Path,
        help="Copy the verified release archive to this path.",
    )
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(destination: Path) -> None:
    request = urllib.request.Request(
        DOWNLOAD_URL,
        headers={"User-Agent": "AoNW2-Terrain3D-Installer/1"},
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            with destination.open("wb") as output:
                shutil.copyfileobj(response, output)
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        raise RuntimeError(
            "Could not download Terrain3D. Download the official release ZIP "
            "manually and rerun with --archive /path/to/Terrain3D.zip. "
            f"Original error: {error}"
        ) from error


def addon_relative_path(member_name: str) -> PurePosixPath | None:
    member = PurePosixPath(member_name)
    parts = member.parts
    marker = ADDON_PREFIX.parts
    for index in range(0, len(parts) - len(marker) + 1):
        if parts[index : index + len(marker)] == marker:
            relative_parts = parts[index + len(marker) :]
            return PurePosixPath(*relative_parts)
    return None


def safe_destination(root: Path, relative: PurePosixPath) -> Path:
    destination = (root / Path(*relative.parts)).resolve()
    root_resolved = root.resolve()
    if destination != root_resolved and root_resolved not in destination.parents:
        raise RuntimeError(f"Unsafe archive member path: {relative}")
    return destination


def extract_addon(archive: Path, destination: Path) -> int:
    extracted = 0
    with zipfile.ZipFile(archive) as package:
        for member in package.infolist():
            relative = addon_relative_path(member.filename)
            if relative is None or not relative.parts:
                continue
            target = safe_destination(destination, relative)
            if member.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            unix_mode = (member.external_attr >> 16) & 0o777777
            if stat.S_ISLNK(unix_mode):
                raise RuntimeError(
                    f"Terrain3D archive contains an unsupported symbolic link: {member.filename}"
                )
            target.parent.mkdir(parents=True, exist_ok=True)
            with package.open(member) as source, target.open("wb") as output:
                shutil.copyfileobj(source, output)
            file_mode = unix_mode & 0o777
            if file_mode:
                target.chmod(file_mode)
            extracted += 1
    return extracted


def validate_project(project: Path) -> Path:
    project = project.expanduser().resolve()
    if not (project / "project.godot").is_file():
        raise RuntimeError(f"No project.godot found in {project}")
    return project


def main() -> int:
    args = parse_args()
    try:
        project = validate_project(args.project)
        target = project / "addons" / "terrain_3d"
        if target.exists() and not args.force:
            raise RuntimeError(
                f"{target} already exists. Re-run with --force to replace it."
            )

        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(
            prefix=".aonw-terrain3d-",
            dir=target.parent,
        ) as temporary:
            temporary_root = Path(temporary)
            archive = (
                args.archive.expanduser().resolve()
                if args.archive
                else temporary_root / ARCHIVE_NAME
            )
            if args.archive:
                if not archive.is_file():
                    raise RuntimeError(f"Archive does not exist: {archive}")
            else:
                print(f"Downloading Terrain3D {VERSION}…")
                download(archive)

            actual_digest = sha256(archive)
            if actual_digest.lower() != SHA256:
                raise RuntimeError(
                    "Terrain3D archive checksum mismatch. "
                    f"Expected {SHA256}, got {actual_digest}."
                )

            if args.keep_archive:
                kept = args.keep_archive.expanduser().resolve()
                kept.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(archive, kept)
                print(f"Verified archive copied to {kept}")

            staged = temporary_root / "terrain_3d"
            staged.mkdir(parents=True)
            extracted = extract_addon(archive, staged)
            if extracted == 0 or not (staged / "plugin.cfg").is_file():
                raise RuntimeError(
                    "The verified archive does not contain addons/terrain_3d/plugin.cfg"
                )

            backup = temporary_root / "terrain_3d.backup"
            if target.exists():
                target.replace(backup)
            try:
                staged.replace(target)
            except Exception:
                if backup.exists() and not target.exists():
                    backup.replace(target)
                raise

        print(f"Installed Terrain3D {VERSION} in {target}")
        print("Next: open Godot → Project Settings → Plugins → enable Terrain3D.")
        print(
            "AoNW2 uses Godot 4.7; verify that this pinned GDExtension loads on "
            "the exact editor and export builds before enabling Terrain3D maps."
        )
        return 0
    except (RuntimeError, OSError, zipfile.BadZipFile) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
