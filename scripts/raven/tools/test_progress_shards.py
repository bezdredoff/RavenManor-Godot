"""Raven status shard schema and complete roundtrip regression."""
import json
import tempfile
import unittest
from pathlib import Path

from scripts.raven.tools.progress_shards import load_shards, check_parity, SHARDS, LEGACY


def fixture(root: Path, *, duplicate: bool = False, extra: bool = False) -> dict:
    root.mkdir(parents=True, exist_ok=True)
    original = {"schemaVersion": 1, "updated": "2026-11-05", "authority": "test",
                "rules": ["sample"], "entries": [
                    {"id": "T-01", "status": "merged", "evidence": "PR 10"},
                    {"id": "T-02", "status": "ready", "priority": "P0"}]}
    manifest = {k: original[k] for k in ("schemaVersion", "updated", "authority", "rules")}
    manifest.update(kind="task_progress_index", shards=["alpha.json", "beta.json"])
    (root / "index.json").write_text(json.dumps(manifest), encoding="utf-8")
    for domain, entries in (("alpha", [original["entries"][0]]),
                            ("beta", [original["entries"][0] if duplicate else original["entries"][1]])):
        (root / (domain + ".json")).write_text(json.dumps({
            "schemaVersion": 1, "kind": "task_progress_shard",
            "domain": domain, "entries": entries}), encoding="utf-8")
    if extra:
        (root / "orphan.json").write_text("{}", encoding="utf-8")
    return original


class ShardedProgressTests(unittest.TestCase):
    def test_current_shards_are_complete_and_unique(self):
        progress = load_shards(SHARDS)
        ids = [e["id"] for e in progress["entries"]]
        self.assertGreaterEqual(len(ids), 214)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertIn("shards", progress["authority"])

    def test_roundtrip_ignores_order_not_evidence(self):
        with tempfile.TemporaryDirectory() as path:
            root = Path(path)
            original = fixture(root)
            check_parity(load_shards(root), original)
            modified = json.loads(json.dumps(original))
            modified["entries"][0]["evidence"] = "Wrong PR"
            with self.assertRaisesRegex(ValueError, "evidence drift"):
                check_parity(load_shards(root), modified)

    def test_reject_duplicate_task_id(self):
        with tempfile.TemporaryDirectory() as path:
            root = Path(path)
            fixture(root, duplicate=True)
            with self.assertRaisesRegex(ValueError, "Duplicate task ID"):
                load_shards(root)

    def test_reject_unindexed_shard(self):
        with tempfile.TemporaryDirectory() as path:
            root = Path(path)
            fixture(root, extra=True)
            with self.assertRaisesRegex(ValueError, "Undeclared or missing"):
                load_shards(root)

    def test_reject_removed_tasks(self):
        with tempfile.TemporaryDirectory() as path:
            root = Path(path)
            old = fixture(root)
            old["entries"].append({"id": "T-03", "status": "ready"})
            with self.assertRaisesRegex(ValueError, "Task ID parity drift"):
                check_parity(load_shards(root), old)


if __name__ == "__main__":
    unittest.main()
