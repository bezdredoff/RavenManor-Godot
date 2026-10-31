"""Synthetic UPDS audit tests; no private donor content is committed."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("audit_upds_vn", TOOLS / "audit_upds_vn.py")
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class UpdsAuditTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        documents = {
            "data/prologue.json": {
                "sceneId": "SCENE_0", "sceneIndex": 0, "background": "room",
                "lines": [{
                    "id": "VN0001", "hidden": True,
                    "actors": [{"character": "miku", "pose": "neutral", "layout": "left"}],
                    "localized": {loc: {"speaker": "A", "emotion": "neutral", "text": "test"}
                                  for loc in ("ru", "en", "be")}
                }]
            },
            "data/save_contract.json": {
                "storySceneIds": ["SCENE_0"], "levelIds": [], "storyChoiceGateIds": []
            },
            "data/actor_layouts.json": {
                "frames": {"miku": {}}, "placements": {"left": {"x": 10}}
            },
            "data/asset_catalog.json": {
                "assets": {"backgrounds": {"room": "res://room.webp"}}
            }
        }
        self.manifest = {
            "donor": {"repository": "synthetic"},
            "scenes": [], "references": [],
            "expected": {
                "scenes": 1, "lineOccurrences": 1, "hiddenOccurrences": 1,
                "variantScenes": 0, "choiceGateScenes": 0, "match3GateScenes": 0,
                "endingScenes": 0, "branchRoutes": 0
            }
        }
        for path, data in documents.items():
            p = self.root / path
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(json.dumps(data), encoding="utf-8")
            raw = p.read_bytes()
            item = {"path": path, "blobSha": audit.blob_sha(raw), "bytes": len(raw)}
            if path.endswith("prologue.json"):
                item.update({"lineOccurrences": 1, "hiddenOccurrences": 1})
                self.manifest["scenes"].append(item)
            else:
                self.manifest["references"].append(item)

    def test_source_is_never_modified(self):
        p = self.root / "data/prologue.json"
        original = p.read_bytes()
        report, errors = audit.scan(self.root, self.manifest)
        self.assertEqual(errors, [])
        self.assertEqual(report["lineOccurrences"], 1)
        self.assertEqual(report["distinctCharacters"], ["miku"])
        self.assertEqual(p.read_bytes(), original)

    def test_sha_drift_blocks_approval(self):
        p = self.root / "data/prologue.json"
        p.write_text(p.read_text() + "\n", encoding="utf-8")
        _, errors = audit.scan(self.root, self.manifest)
        self.assertTrue(any("SHA drift" in msg for msg in errors))

    def test_missing_locale_fails(self):
        p = self.root / "data/prologue.json"
        doc = json.loads(p.read_text())
        del doc["lines"][0]["localized"]["be"]
        p.write_text(json.dumps(doc), encoding="utf-8")
        _, errors = audit.scan(self.root, self.manifest)
        self.assertTrue(any("missing/extra locale" in msg for msg in errors))

    def test_invalid_route_fails(self):
        p = self.root / "data/prologue.json"
        doc = json.loads(p.read_text())
        doc["nextSceneIndex"] = 17
        p.write_text(json.dumps(doc), encoding="utf-8")
        _, errors = audit.scan(self.root, self.manifest)
        self.assertTrue(any("bad target" in msg for msg in errors))

    def test_unsafe_path_rejected(self):
        with self.assertRaises(ValueError):
            audit.safe_file(self.root, "data/../../outside.json")

    def test_choice_variant_groups_are_separate(self):
        choice = {"variants": {
            "A": [{"id": "VN0041A"}],
            "B": [{"id": "VN0041B"}],
            "C": [{"id": "VN0041C"}]
        }}
        groups = audit.read_scenes(choice)
        self.assertEqual([name for name, _ in groups],
                         ["variant:A", "variant:B", "variant:C"])


if __name__ == "__main__":
    unittest.main()
