"""Unit tests for Web-only, lossless-alpha preserving Godot import overrides."""
from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from scripts.raven.tools.prepare_web_portrait_imports import (
    prepare, selected_paths, with_import_limit, WEB_MAX_SIDE,
)

IMPORT = (
    '[remap]\nimporter="texture"\n'
    '[deps]\nsource_file="res://assets/raven/characters/evelyn/base_neutral.webp"\n'
    '[params]\ncompress/mode=0\ncompress/lossy_quality=0.7\n'
    'mipmaps/generate=true\nprocess/fix_alpha_border=true\n'
    'process/size_limit=0\n'
)


class WebPortraitImportTests(unittest.TestCase):
    def fixture(self, root: Path) -> tuple[Path, Path]:
        p = root / "assets/raven/characters/evelyn/base_neutral.webp"
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(b"approved transparent portrait source bytes")
        p.with_suffix(".webp.import").write_text(IMPORT)
        catalog = root / "data/raven/production/vn_character_catalog.json"
        catalog.parent.mkdir(parents=True)
        catalog.write_text(json.dumps({"entries": [{
            "id": "RM-VN-EVELYN-BASE-NEUTRAL",
            "path": "res://assets/raven/characters/evelyn/base_neutral.webp",
            "status": "accepted", "approved": "2026-11-02"
        }]}))
        return p, catalog

    def test_overrides_only_import_descriptors_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, catalog = self.fixture(root)
            source_bytes = source.read_bytes()
            catalog_bytes = catalog.read_bytes()
            result = prepare(root, expected_count=1)
            self.assertEqual(result, {"catalogued": 1, "modified": 1, "limit": 1024})
            descriptor = source.with_suffix(".webp.import").read_text()
            self.assertIn("process/size_limit=1024", descriptor)
            self.assertIn("compress/mode=0", descriptor)
            self.assertIn("mipmaps/generate=true", descriptor)
            self.assertIn("process/fix_alpha_border=true", descriptor)
            self.assertEqual(source.read_bytes(), source_bytes)
            self.assertEqual(catalog.read_bytes(), catalog_bytes)
            self.assertEqual(prepare(root, expected_count=1)["modified"], 0)

    def test_bad_import_settings_fail_before_any_mutation(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, _ = self.fixture(root)
            source.with_suffix(".webp.import").write_text(
                IMPORT.replace("compress/mode=0", "compress/mode=1"))
            with self.assertRaisesRegex(ValueError, "not lossless"):
                prepare(root, expected_count=1)
            self.assertIn("process/size_limit=0",
                          source.with_suffix(".webp.import").read_text())

    def test_invalid_paths_or_unapproved_entries_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            _, catalog = self.fixture(root)
            data = json.loads(catalog.read_text())
            data["entries"][0]["path"] = "res://assets/raven/characters/../outside.webp"
            catalog.write_text(json.dumps(data))
            with self.assertRaises((ValueError, FileNotFoundError)):
                selected_paths(root, expected_count=1)
            data["entries"][0]["path"] = (
                "res://assets/raven/characters/evelyn/base_neutral.webp")
            data["entries"][0]["status"] = "candidate"
            catalog.write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, "Unapproved"):
                prepare(root, expected_count=1)

    def test_wrong_source_and_size_limit_refused(self):
        with self.assertRaisesRegex(ValueError, "Unexpected .import source"):
            with_import_limit(IMPORT, "res://elsewhere.webp", 1024)
        with self.assertRaisesRegex(ValueError, "Unexpected existing import"):
            with_import_limit(IMPORT.replace("size_limit=0", "size_limit=256"),
                              "res://assets/raven/characters/evelyn/base_neutral.webp", 1024)
        with self.assertRaisesRegex(ValueError, "locked"):
            with tempfile.TemporaryDirectory() as temp:
                prepare(Path(temp), max_side=512, expected_count=1)


if __name__ == "__main__":
    unittest.main()
