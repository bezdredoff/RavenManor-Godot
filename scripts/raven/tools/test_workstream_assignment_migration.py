"""Stage 3b: validate stable owner-shard assignment shape, not frozen memberships."""
import json
import unittest

from scripts.raven.tools.progress_shards import SHARDS, load_shards
from scripts.raven.tools.build_production_dashboard import build


class AssignmentContracts(unittest.TestCase):
    def test_all_group_assignments_are_unique_and_known_to_dashboard(self):
        source = load_shards(SHARDS)
        assignments = source["assignments"]
        self.assertEqual(len(assignments), len({a["id"] for a in assignments}))
        dashboard = build()
        by_id = {t["id"]: t for t in dashboard["tasks"]}
        self.assertTrue(assignments)
        for assignment in assignments:
            self.assertIn(assignment["id"], by_id)

    def test_assignment_shares_domain_with_optional_live_override(self):
        index = json.loads((SHARDS / "index.json").read_text(encoding="utf-8"))
        by_id = {}
        for filename in index["shards"]:
            shard = json.loads((SHARDS / filename).read_text(encoding="utf-8"))
            for entry in shard["entries"]:
                self.assertNotIn(entry["id"], by_id)
                by_id[entry["id"]] = shard["domain"]
        for filename in index["shards"]:
            shard = json.loads((SHARDS / filename).read_text(encoding="utf-8"))
            for assignment in shard.get("assignments", []):
                if assignment["id"] in by_id:
                    self.assertEqual(by_id[assignment["id"]], shard["domain"])

    def test_shared_metadata_never_owns_membership_lists(self):
        from scripts.raven.tools.build_production_dashboard import WORKSTREAMS, P2_REENTRY
        streams = json.loads(WORKSTREAMS.read_text(encoding="utf-8"))
        groups = json.loads(P2_REENTRY.read_text(encoding="utf-8"))
        self.assertTrue(streams["workstreams"])
        self.assertTrue(groups["groups"])
        self.assertTrue(all("taskIds" not in s for s in streams["workstreams"]))
        self.assertTrue(all("taskIds" not in g for g in groups["groups"]))


if __name__ == "__main__":
    unittest.main()
