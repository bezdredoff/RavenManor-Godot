import tempfile
from pathlib import Path
import unittest

from scripts.raven.tools.report_web_pck import analyze, packed_paths, report


class WebPckAuditTests(unittest.TestCase):
    def fixture(self, root):
        web = root / "build/web"
        web.mkdir(parents=True)
        (web / "index.pck").write_bytes(b"PCKBLOB")
        (web / "index.wasm").write_bytes(b"WASMBLOB")
        (web / "dashboard").mkdir()
        (web / "dashboard/index.html").write_text("ok")
        source = root / "assets/raven/characters/evelyn/base_neutral.webp.import"
        source.parent.mkdir(parents=True)
        source.write_text('[remap]\npath="res://.godot/imported/base_neutral.webp-abc.ctex"\n')
        imported = root / ".godot/imported/base_neutral.webp-abc.ctex"
        imported.parent.mkdir(parents=True)
        imported.write_bytes(b"texture data")
        return web

    def test_real_import_path_is_attributed_to_original_source(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            web = self.fixture(root)
            log = (
                "[ 89% ] Storing File: res://.godot/imported/base_neutral.webp-abc.ctex\x1b[39m\n"
                "Storing File: res://project.binary\n"
                + "\n".join(f"Storing File: res://scripts/core/file{i}.gdc" for i in range(9))
            )
            data = analyze(root, web, log)
            self.assertEqual(data["packed_entries"], 11)
            self.assertEqual(data["pck_bytes"], 7)
            self.assertEqual(data["texture_raw_bytes"], 12)
            self.assertEqual(data["texture_groups"], [("assets/raven/characters", 12)])
            self.assertIn("index.pck", report(data))

    def test_excluded_editor_and_progress_sources_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            web = self.fixture(root)
            for forbidden in (
                "addons/vn_studio/plugin.gdc",
                "data/raven/production/progress/match3.json",
                "data/raven/production/code_work_packages.json",
                "examples/room_builder_hall_original.json",
            ):
                log = "\n".join(["Storing File: res://" + forbidden]
                    + [f"Storing File: res://scripts/file{i}.gdc" for i in range(10)])
                with self.subTest(path=forbidden), self.assertRaisesRegex(
                        ValueError, "still packed"):
                    analyze(root, web, log)

    def test_missing_export_entry_list_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            web = self.fixture(root)
            with self.assertRaisesRegex(ValueError, "did not list enough"):
                analyze(root, web, "Export succeeded but no entries listed")
        self.assertEqual(packed_paths("Storing File: res://a.txt\n"), ["a.txt"])


if __name__ == "__main__":
    unittest.main()
