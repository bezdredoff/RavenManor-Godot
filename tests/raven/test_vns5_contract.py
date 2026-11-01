import copy
import json
import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts/raven/tools"))
from audit_vns5_contract import SOURCES, audit


class ContractAuditTest(unittest.TestCase):
    def test_real_sources_are_structural_and_read_only(self):
        before = {name: (ROOT / "data/raven/production" / name).read_bytes() for name in SOURCES.values()}
        report = audit(ROOT)
        self.assertEqual(report["counts"], {"scenes": 28, "lines": 280, "masters": 11,
            "shots": 28, "backgroundCandidates": 20, "characters": 4, "cues": 280, "routes": 28})
        self.assertTrue(all(not scene["transitions"] for scene in report["proposedSceneAdapters"]))
        self.assertEqual(before, {name: (ROOT / "data/raven/production" / name).read_bytes() for name in SOURCES.values()})

    def test_duplicate_and_broken_reference_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp) / "data/raven/production"
            folder.mkdir(parents=True)
            for name in SOURCES.values():
                (folder / name).write_bytes((ROOT / "data/raven/production" / name).read_bytes())
            dialogue_path = folder / SOURCES["dialogue"]
            original = json.loads(dialogue_path.read_text(encoding="utf-8"))
            for mutate in (
                lambda d: d["entries"][1].update(id=d["entries"][0]["id"]),
                lambda d: d["entries"][0].update(sceneId="RM-BEAT-UNKNOWN"),
            ):
                changed = copy.deepcopy(original)
                mutate(changed)
                dialogue_path.write_text(json.dumps(changed), encoding="utf-8")
                with self.assertRaises(ValueError):
                    audit(Path(tmp))


if __name__ == "__main__":
    unittest.main()
