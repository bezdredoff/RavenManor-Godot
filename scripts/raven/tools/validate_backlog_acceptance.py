#!/usr/bin/env python3
"""Ensure P2 reentry and active workstream QA matrices have truthful coverage.

This is a planning audit, not proof of native-device or owner acceptance.
"""
from __future__ import annotations

from build_production_dashboard import build

TERMINAL = {"merged", "integrated", "device_verified", "accepted", "superseded", "not_planned"}
REQUIRED_GATES = {"CODE-13-01", *(f"GFX-13-T{i:02}" for i in range(1, 12))}


def audit(data: dict) -> list[str]:
    errors: list[str] = []
    tasks = data["tasks"]
    by_id = {x["id"]: x for x in tasks}
    p2 = {x["id"] for x in tasks if x["priority"] == "P2" and x["status"] not in TERMINAL}
    mapped = {x["id"] for x in tasks if x.get("p2ReentryGroup")}
    if mapped != p2:
        errors.append(f"P2 coverage mismatch: {sorted(p2 ^ mapped)}")
    groups = data.get("p2Groups", [])
    if len(groups) != 4:
        errors.append(f"Expected 4 explicit P2 re-entry categories, got {len(groups)}")
    if len(p2) != 44:
        errors.append(f"Unexpected P2 item count: {len(p2)}")
    group_count = sum(x["taskCount"] for x in groups)
    if group_count != len(p2):
        errors.append(f"Duplicated or missing P2 membership: {group_count} vs {len(p2)}")
    for group in groups:
        if not all(isinstance(group.get(key), str) and group[key].strip() for key in ("label","trigger","action")):
            errors.append(f"Incomplete P2 policy: {group.get('id')}")
    for task_id in REQUIRED_GATES:
        if by_id[task_id].get("p2ReentryGroup") != "P2-FULL-SEASON-RELEASE":
            errors.append(f"Full-season release QA cannot be forgotten: {task_id}")
        if by_id[task_id]["status"] not in {"proposed", "ready"}:
            errors.append(f"Unexpected false completion of full-season gate: {task_id}")
    if by_id["VNS5-08"]["status"] != "deferred" or by_id["RM-GAP-004"]["status"] != "deferred":
        errors.append("Explicit deferrals were silently reactivated")

    streams = data.get("workstreams", [])
    if len(streams) != 10:
        errors.append(f"Expected 10 active delivery streams, got {len(streams)}")
    for stream in streams:
        matrix = stream.get("acceptancePlan", {})
        for field in ("automatedChecks", "ownerChecks", "newWorkIfFailed"):
            if not isinstance(matrix.get(field), list) or not matrix[field]:
                errors.append(f"Missing {field} in {stream['id']}")
        if not matrix.get("decision"):
            errors.append(f"Missing owner exit decision in {stream['id']}")
        if stream["phase"] == "New assets" and not matrix.get("newWorkIfFailed"):
            errors.append(f"New-asset stream claims QA-only completion: {stream['id']}")
    return errors


def main() -> int:
    data = build()
    errors = audit(data)
    for error in errors:
        print("ERROR:", error)
    print(f"P2 and acceptance audit: {len(data['p2Groups'])} P2 categories / "
          f"{sum(x['taskCount'] for x in data['p2Groups'])} open P2 items / "
          f"{len(data['workstreams'])} distinct QA matrices / {len(errors)} errors")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
