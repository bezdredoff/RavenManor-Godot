"""Fail-closed tests for untracked background .import descriptor Web overrides."""
from pathlib import Path
import json
import tempfile
import unittest

from scripts.raven.tools.prepare_web_background_imports import (
    prepare, backgrounds_from_catalog,
)

IMPORT = (
    '[remap]\nimporter="texture"\n'
    '[deps]\nsource_file="res://assets/raven/vn_backgrounds/hall/evening_dusty.webp"\n'
    '[params]\ncompress/mode=0\nmipmaps/generate=true\n'
    'process/fix_alpha_border=true\nprocess/size_limit=0\n'
)


class BackgroundWebImportTests(unittest.TestCase):
    def fixture(self, root: Path, descriptor: bool = True) -> tuple[Path, Path]:
        src = root / "assets/raven/vn_backgrounds/hall/evening_dusty.webp"
        src.parent.mkdir(parents=True)
        src.write_bytes(b"unchanged full-resolution accepted WebP")
        if descriptor:
            src.with_suffix(".webp.import").write_text(IMPORT)
        catalog = root / "data/raven/production/vn_background_catalog.json"
        catalog.parent.mkdir(parents=True)
        catalog.write_text(json.dumps({"entries": [{
            "id": "BG-HALL:evening:dusty",
            "status": "accepted", "approved": "2026-11-02",
            "path": "res://assets/raven/vn_backgrounds/hall/evening_dusty.webp",
            "width": 1080, "height": 1920
        }]}))
        return src, catalog

    def test_only_import_descriptors_change_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, catalog = self.fixture(root)
            source_before, catalog_before = source.read_bytes(), catalog.read_bytes()
            self.assertEqual(prepare(root, minimum_count=1),
                             {"catalogued": 1, "modified": 1, "max_long_side": 1080})
            descriptor = source.with_suffix(".webp.import").read_text()
            self.assertIn("process/size_limit=1080", descriptor)
            self.assertIn("compress/mode=0", descriptor)
            self.assertIn("mipmaps/generate=true", descriptor)
            self.assertIn("process/fix_alpha_border=true", descriptor)
            self.assertEqual(source.read_bytes(), source_before)
            self.assertEqual(catalog.read_bytes(), catalog_before)
            self.assertEqual(prepare(root, minimum_count=1)["modified"], 0)

    def test_missing_generated_descriptor_fails_with_instructions(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.fixture(root, descriptor=False)
            with self.assertRaisesRegex(FileNotFoundError, "Run 'godot"):
                prepare(root, minimum_count=1)

    def test_unapproved_and_path_escape_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, catalog = self.fixture(root)
            j = json.loads(catalog.read_text())
            j["entries"][0]["status"] = "candidate"
            catalog.write_text(json.dumps(j))
            with self.assertRaisesRegex(ValueError, "Unapproved"):
                prepare(root, minimum_count=1)
            j["entries"][0]["status"] = "accepted"
            j["entries"][0]["path"] = "res://assets/raven/vn_backgrounds/../../../outside.webp"
            catalog.write_text(json.dumps(j))
            with self.assertRaises(ValueError):
                backgrounds_from_catalog(root, minimum_count=1)

    def test_invalid_import_and_long_edge_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src, _ = self.fixture(root)
            imp = src.with_suffix(".webp.import")
            imp.write_text(IMPORT.replace("compress/mode=0", "compress/mode=1"))
            with self.assertRaisesRegex(ValueError, "not lossless"):
                prepare(root, minimum_count=1)
            self.assertIn("process/size_limit=0", imp.read_text())
            with self.assertRaisesRegex(ValueError, "locked"):
                prepare(root, max_side=960, minimum_count=1)


if __name__ == "__main__":
    unittest.main()
