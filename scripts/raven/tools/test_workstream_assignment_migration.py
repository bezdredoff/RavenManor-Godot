"""Stage 3a: exact membership parity of owner shards and historical registries.

This one-time migration gate is replaced with independently writable contract
tests in Stage 3b, before status updates can diverge from static lists.
"""
import json
import unittest

from scripts.raven.tools.progress_shards import ROOT, SHARDS, load_shards


class AssignmentMigration(unittest.TestCase):
    def test_same_80_active_and_44_p2_members(self):
        source = load_shards(SHARDS)
        assignments = {item["id"]: item for item in source["assignments"]}
        old_work = json.loads((ROOT/"data/raven/production/active_workstreams.json").read_text(encoding="utf-8"))
        old_p2 = json.loads((ROOT/"data/raven/production/p2_reentry_policy.json").read_text(encoding="utf-8"))
        expected = {}
        for stream in old_work["workstreams"]:
            for task_id in stream["taskIds"]:
                self.assertNotIn(task_id, expected)
                expected[task_id] = {"id": task_id, "workstreamId": stream["id"]}
        for group in old_p2["groups"]:
            for task_id in group["taskIds"]:
                self.assertNotIn(task_id, expected)
                expected[task_id] = {"id": task_id, "p2ReentryGroup": group["id"]}
        self.assertEqual(assignments, expected)
        self.assertEqual(len(assignments), 124)
        self.assertEqual(len(source["entries"]), 214)

    def test_ownership_same_domain_as_override_and_35_plan_only_members(self):
        index = json.loads((SHARDS/"index.json").read_text(encoding="utf-8"))
        owners = {}
        for filename in index["shards"]:
            shard = json.loads((SHARDS/filename).read_text(encoding="utf-8"))
            owners.update({item["id"]: shard["domain"] for item in shard["entries"]})
        plan_only = []
        for filename in index["shards"]:
            shard = json.loads((SHARDS/filename).read_text(encoding="utf-8"))
            for item in shard.get("assignments", []):
                if item["id"] not in owners:
                    plan_only.append(item["id"])
                else:
                    self.assertEqual(owners[item["id"]], shard["domain"])
        self.assertEqual(len(plan_only), 35)


if __name__ == "__main__":
    unittest.main()
