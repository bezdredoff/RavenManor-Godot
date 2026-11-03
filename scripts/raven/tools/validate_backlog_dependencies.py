#!/usr/bin/env python3
"""Validate the *live* task DAG while preserving historical CODE/GAP plans.

Canonical status and current priority are resolved by build_production_dashboard.
No task gets implementation/owner approval from this audit.
"""
from __future__ import annotations

from build_production_dashboard import build

TERMINAL = {"merged", "integrated", "accepted", "device_verified", "superseded", "not_planned"}


def inspect(tasks: list[dict]) -> dict:
    by_id = {item["id"]: item for item in tasks}
    if len(by_id) != len(tasks):
        raise ValueError("Duplicate task IDs in dashboard")
    errors: list[str] = []
    historic_edges: list[tuple[str, str]] = []
    for task in tasks:
        deps = task.get("dependsOn", [])
        if len(deps) != len(set(deps)):
            errors.append(f"{task['id']}: duplicate dependsOn")
        for dep in deps:
            if dep not in by_id:
                errors.append(f"{task['id']}: unknown dependency {dep}")
                continue
            if dep == task["id"]:
                errors.append(f"{task['id']}: self-reference")
            if task["status"] in TERMINAL and by_id[dep]["status"] not in TERMINAL:
                historic_edges.append((task["id"], dep))
            if task["status"] not in TERMINAL and by_id[dep]["status"] in {"superseded", "not_planned", "deferred"}:
                errors.append(f"{task['id']}: active task depends on retired/deferred task {dep}")
        required_open = ([dep for dep in deps if dep in by_id and by_id[dep]["status"] not in TERMINAL]
                         if task["status"] not in TERMINAL else [])
        if task.get("openDependsOn") != required_open:
            errors.append(f"{task['id']}: incorrect active blockers: {task.get('openDependsOn')} != {required_open}")
        if task["priority"] == "P0" and task["status"] in TERMINAL:
            errors.append(f"{task['id']}: closed task still tagged current P0")

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(key: str, path: list[str]) -> None:
        if key in visited:
            return
        if key in visiting:
            errors.append("Dependency cycle: " + " -> ".join(path[path.index(key):] + [key]))
            return
        visiting.add(key)
        for dep in by_id[key].get("dependsOn", []):
            if dep in by_id:
                visit(dep, path + [dep])
        visiting.remove(key)
        visited.add(key)

    for id_ in by_id:
        visit(id_, [id_])

    return {"errors": sorted(set(errors)), "tasks": len(tasks),
            "edges": sum(len(x.get("dependsOn", [])) for x in tasks),
            "historicalDeliveredEdges": historic_edges,
            "activeP0": sorted(x["id"] for x in tasks if x["priority"] == "P0" and x["status"] not in TERMINAL)}


def main() -> int:
    result = inspect(build()["tasks"])
    for error in result["errors"]:
        print("ERROR:", error)
    print(f"Backlog dependency audit: {result['tasks']} tasks, {result['edges']} authored edges, "
          f"{len(result['historicalDeliveredEdges'])} historical delivered-to-open edges, "
          f"{len(result['activeP0'])} current P0, {len(result['errors'])} errors")
    return int(bool(result["errors"]))


if __name__ == "__main__":
    raise SystemExit(main())
