from __future__ import annotations

import hashlib
import stat
import tempfile
import unittest
import zipfile
from pathlib import Path, PurePosixPath

import install_terrain3d as installer


class Terrain3DInstallerTest(unittest.TestCase):
    def test_addon_relative_path_accepts_release_and_assetlib_layouts(self) -> None:
        self.assertEqual(
            installer.addon_relative_path(
                "Terrain3D-1.0.2/project/addons/terrain_3d/plugin.cfg"
            ),
            PurePosixPath("plugin.cfg"),
        )
        self.assertEqual(
            installer.addon_relative_path("addons/terrain_3d/bin/libterrain3d.so"),
            PurePosixPath("bin/libterrain3d.so"),
        )
        self.assertIsNone(
            installer.addon_relative_path("Terrain3D-1.0.2/project/demo/demo.tscn")
        )

    def test_safe_destination_rejects_parent_traversal(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "addon"
            root.mkdir()
            with self.assertRaisesRegex(RuntimeError, "Unsafe archive member path"):
                installer.safe_destination(root, PurePosixPath("../outside"))

    def test_extract_addon_copies_only_addon_files_and_preserves_mode(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "terrain3d.zip"
            destination = root / "out"
            destination.mkdir()
            with zipfile.ZipFile(archive, "w") as package:
                plugin = zipfile.ZipInfo(
                    "Terrain3D/project/addons/terrain_3d/plugin.cfg"
                )
                plugin.external_attr = (stat.S_IFREG | 0o644) << 16
                package.writestr(plugin, "[plugin]\nname=\"Terrain3D\"\n")

                executable = zipfile.ZipInfo(
                    "Terrain3D/project/addons/terrain_3d/bin/helper"
                )
                executable.external_attr = (stat.S_IFREG | 0o755) << 16
                package.writestr(executable, b"binary")
                package.writestr("Terrain3D/project/demo/demo.tscn", "ignored")

            self.assertEqual(installer.extract_addon(archive, destination), 2)
            self.assertTrue((destination / "plugin.cfg").is_file())
            self.assertEqual((destination / "bin/helper").read_bytes(), b"binary")
            self.assertFalse((destination / "demo/demo.tscn").exists())
            self.assertEqual(
                stat.S_IMODE((destination / "bin/helper").stat().st_mode),
                0o755,
            )

    def test_extract_addon_rejects_symbolic_links(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "terrain3d.zip"
            destination = root / "out"
            destination.mkdir()
            with zipfile.ZipFile(archive, "w") as package:
                link = zipfile.ZipInfo(
                    "Terrain3D/project/addons/terrain_3d/bin/current"
                )
                link.external_attr = (stat.S_IFLNK | 0o777) << 16
                package.writestr(link, "libterrain3d.so")

            with self.assertRaisesRegex(RuntimeError, "symbolic link"):
                installer.extract_addon(archive, destination)

    def test_sha256_streams_the_complete_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "archive.zip"
            payload = b"AoNW Terrain3D\x00" * 100_000
            path.write_bytes(payload)
            self.assertEqual(
                installer.sha256(path),
                hashlib.sha256(payload).hexdigest(),
            )

    def test_validate_project_requires_project_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with self.assertRaisesRegex(RuntimeError, "No project.godot"):
                installer.validate_project(root)
            (root / "project.godot").write_text("config_version=5\n")
            self.assertEqual(installer.validate_project(root), root.resolve())


if __name__ == "__main__":
    unittest.main()
