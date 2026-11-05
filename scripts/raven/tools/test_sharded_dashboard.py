"""Stage 2: shadow dashboard comparison and canonical source read tests."""
import json
import unittest
from scripts.raven.tools import build_production_dashboard as dashboard
from scripts.raven.tools.progress_shards import LEGACY, load_shards

class ShardedDashboardTests(unittest.TestCase):
    def test_canonical_shards_and_provenance(self):
        data = dashboard.build()
        self.assertEqual(data["updated"], load_shards()["updated"])
        self.assertEqual(data["taskCount"], len(data["tasks"]))
        self.assertTrue(any(p.endswith("/progress/index.json") for p in data["sourceFiles"]))
        self.assertTrue(any(p.endswith("/progress/vn-studio.json") for p in data["sourceFiles"]))
        self.assertFalse(any(p.endswith("/production_progress.json") for p in data["sourceFiles"]))
        self.assertIn("PROC-007", {t["id"] for t in data["tasks"]})

    def test_shadow_render_same_except_source_files(self):
        """One-time Stage 2 migration gate; remove in Stage 3 before independent edits."""
        new = dashboard.build()
        old = dashboard.build(progress_override=json.loads(LEGACY.read_text(encoding="utf-8")))
        new.pop("sourceFiles")
        old.pop("sourceFiles")
        self.assertEqual(new, old)

    def test_override_is_read_only_and_has_no_effect_on_live_source(self):
        historical = load_shards()
        synthetic = json.loads(json.dumps(historical))
        target = next(t for t in synthetic["entries"] if t["id"] == "CODE-04-01")
        target["status"] = "accepted" # both merged and accepted are terminal; no active workstream drift
        overridden = dashboard.build(progress_override=synthetic)
        live = dashboard.build()
        get = lambda obj: next(t["status"] for t in obj["tasks"] if t["id"] == "CODE-04-01")
        self.assertEqual(get(live), "merged")
        self.assertEqual(get(overridden), "accepted")

if __name__ == "__main__":
    unittest.main()
