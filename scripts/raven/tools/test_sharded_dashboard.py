"""Stage 3b: live dashboard is derived from independent domain task shards."""
import copy
import unittest

from scripts.raven.tools import build_production_dashboard as dashboard
from scripts.raven.tools.progress_shards import load_shards


def task(data, task_id):
    return next(x for x in data["tasks"] if x["id"] == task_id)


class ShardedDashboardTests(unittest.TestCase):
    def test_canonical_shards_and_provenance(self):
        data = dashboard.build()
        self.assertEqual(data["updated"], load_shards()["updated"])
        self.assertEqual(data["taskCount"], len(data["tasks"]))
        self.assertTrue(any(p.endswith("/progress/index.json") for p in data["sourceFiles"]))
        self.assertTrue(any(p.endswith("/progress/vn-studio.json") for p in data["sourceFiles"]))
        self.assertFalse(any(p.endswith("/production_progress.json") for p in data["sourceFiles"]))
        self.assertIn("PROC-007", {t["id"] for t in data["tasks"]})
        self.assertEqual(
            sum(w["taskCount"] for w in data["workstreams"]),
            sum(t["status"] not in dashboard.TERMINAL_STATES and t["priority"] in ("P0", "P1")
                for t in data["tasks"]))
        self.assertEqual(
            sum(g["taskCount"] for g in data["p2Groups"]),
            sum(t["status"] not in dashboard.TERMINAL_STATES and t["priority"] == "P2"
                for t in data["tasks"]))

    def test_closing_one_task_updates_dashboard_without_shared_registry(self):
        canonical = dashboard.build()
        status = copy.deepcopy(load_shards())
        target = next(e for e in status["entries"]
                      if task(canonical, e["id"])["workstreamId"]
                      and task(canonical, e["id"])["status"] not in dashboard.TERMINAL_STATES)
        old_stream = task(canonical, target["id"])["workstreamId"]
        target["status"] = "merged"
        target["evidence"] = "Simulated merged PR for unit test only"
        simulated = dashboard.build(progress_override=status)
        self.assertEqual(task(simulated, target["id"])["workstreamId"], "")
        self.assertEqual(task(simulated, target["id"])["status"], "merged")
        before = next(w["taskCount"] for w in canonical["workstreams"] if w["id"] == old_stream)
        after = next(w["taskCount"] for w in simulated["workstreams"] if w["id"] == old_stream)
        self.assertEqual(after, before - 1)
        self.assertEqual(task(dashboard.build(), target["id"])["status"], task(canonical, target["id"])["status"])

    def test_p2_completion_updates_group_automatically(self):
        canonical = dashboard.build()
        status = copy.deepcopy(load_shards())
        target = next(e for e in status["entries"]
                      if task(canonical, e["id"])["p2ReentryGroup"]
                      and task(canonical, e["id"])["status"] not in dashboard.TERMINAL_STATES)
        old_group = task(canonical, target["id"])["p2ReentryGroup"]
        target["status"] = "merged"
        simulated = dashboard.build(progress_override=status)
        self.assertEqual(task(simulated, target["id"])["p2ReentryGroup"], "")
        before = next(w["taskCount"] for w in canonical["p2Groups"] if w["id"] == old_group)
        after = next(w["taskCount"] for w in simulated["p2Groups"] if w["id"] == old_group)
        self.assertEqual(after, before - 1)

    def test_reprioritization_requires_only_same_shard_assignment(self):
        status = copy.deepcopy(load_shards())
        p2_id = next(x["id"] for x in status["assignments"] if "p2ReentryGroup" in x
                     and any(t["id"] == x["id"] and t["status"] not in dashboard.TERMINAL_STATES
                             for t in status["entries"]))
        override = next(x for x in status["entries"] if x["id"] == p2_id)
        override["priority"] = "P1"
        with self.assertRaisesRegex(ValueError, "Change group assignment"):
            dashboard.build(progress_override=status)
        assignment = next(x for x in status["assignments"] if x["id"] == p2_id)
        assignment.pop("p2ReentryGroup")
        assignment["workstreamId"] = "WS-CAMPAIGN"
        changed = dashboard.build(progress_override=status)
        self.assertEqual(task(changed, p2_id)["workstreamId"], "WS-CAMPAIGN")

    def test_missing_assignment_is_blocking(self):
        status = copy.deepcopy(load_shards())
        member = next(a for a in status["assignments"] if "workstreamId" in a)
        status["assignments"].remove(member)
        with self.assertRaisesRegex(ValueError, "Active workstream scope mismatch"):
            dashboard.build(progress_override=status)


if __name__ == "__main__":
    unittest.main()
