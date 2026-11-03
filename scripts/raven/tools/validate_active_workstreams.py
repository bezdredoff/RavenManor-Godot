#!/usr/bin/env python3
"""Audit exact active P0/P1 grouping, preserving independent task acceptance.

Live statuses/priorities come only from production_progress.json overrides. 
These workstreams are delivery/QA grouping labels, not new implementation
claims and not a replacement for existing task IDs.
"""
from __future__ import annotations

from build_production_dashboard import build

TERMINAL = {"merged", "integrated", "accepted", "device_verified", "superseded", "not_planned"}


def audit(data: dict) -> list[str]:
    errors: list[str] = []
    tasks = data["tasks"]
    by_id = {item["id"]: item for item in tasks}
    seen: set[str] = set()
    for stream in data.get("workstreams", []):
        stream_id = stream["id"]
        members = [task for task in tasks if task["workstreamId"] == stream_id]
        if not members:
            errors.append(f"Empty workstream: {stream_id}")
        if len(members) != stream["taskCount"]:
            errors.append(f"Wrong workstream member count: {stream_id}")
        if sum(m["priority"] == "P0" for m in members) != stream["p0Count"]:
            errors.append(f"Wrong workstream P0 count: {stream_id}")
        if sum(m["priority"] == "P1" for m in members) != stream["p1Count"]:
            errors.append(f"Wrong workstream P1 count: {stream_id}")
        for task in members:
            if task["id"] in seen:
                errors.append(f"Duplicate task in active stream: {task['id']}")
            seen.add(task["id"])
            if task["status"] in TERMINAL or task["priority"] not in {"P0", "P1"}:
                errors.append(f"Inactive task grouped as a live gate: {task['id']}")
            if task["workstreamName"] != stream["title"] or task["workstreamPhase"] != stream["phase"]:
                errors.append(f"Wrong workstream label: {task['id']}")

    active = {task["id"] for task in tasks
              if task["status"] not in TERMINAL and task["priority"] in {"P0", "P1"}}
    if seen != active:
        errors.append(f"Ungrouped/misgrouped active tasks: {sorted(active ^ seen)}")

    important = {"VNS5-08": ("deferred", "P2"), "VNS5-09": ("merged", "P2")}
    for task_id, (state, priority) in important.items():
        task = by_id[task_id]
        if (task["status"], task["priority"]) != (state, priority):
            errors.append(f"Release scope regression: {task_id}")
    if by_id["GFX-08-05"]["approvalState"] != "art_approved":
        errors.append("Previously approved VN background art was invalidated")
    if data["assetSummary"]["backgrounds"]["artApproved"] != 26 or data["assetSummary"]["characterFrames"]["artApproved"] != 62:
        errors.append("Exact approved art total changed without an owner art decision")

    return errors


def main() -> int:
    data = build()
    errors = audit(data)
    for error in errors:
        print("ERROR:", error)
    active = [task for task in data["tasks"]
              if task["status"] not in TERMINAL and task["priority"] in {"P0", "P1"}]
    print(f"Active workstreams: {len(data['workstreams'])} groups / "
          f"{len(active)} active tasks / "
          f"{sum(x['priority'] == 'P0' for x in active)} P0 / "
          f"{sum(x['priority'] == 'P1' for x in active)} P1 / "
          f"{len(errors)} errors")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
