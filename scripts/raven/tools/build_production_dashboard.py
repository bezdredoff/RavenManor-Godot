#!/usr/bin/env python3
"""Build the Raven Manor status dashboard from authoritative code/art/process sources.

Similar to UPDS scripts/build-status-dashboard.mjs: JSON is the editable source,
HTML is only a view. No invented scheduling dates or implied acceptance.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

try:
    from scripts.raven.tools.progress_shards import SHARDS, load_shards
except ModuleNotFoundError:
    from progress_shards import SHARDS, load_shards

ROOT = Path(__file__).resolve().parents[3]
PRODUCTION = ROOT / "data/raven/production"
CODE = PRODUCTION / "code_work_packages.json"
GAPS = PRODUCTION / "gap_work_packages.json"
LEGACY_PROGRESS = PRODUCTION / "production_progress.json"  # frozen read-only baseline
GFX = ROOT / "docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md"
OUT = ROOT / "dashboard/status.json"
BG = PRODUCTION / "vn_background_catalog.json"
CHAR_ART = PRODUCTION / "vn_character_catalog.json"
WORKSTREAMS = PRODUCTION / "active_workstreams.json"
P2_REENTRY = PRODUCTION / "p2_reentry_policy.json"
STATES = {"proposed", "ready", "in_progress", "PR_review", "merged", "integrated", "device_verified", "accepted", "blocked", "deferred", "not_planned", "superseded"}


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def graphics_items(text: str) -> tuple[list[dict], list[dict]]:
    stage_re = re.compile(r"^## (GFX-\d\d) — (.*)$")
    named_re = re.compile(r"^(?:-\s*)?\x60(GFX-\d\d-[A-Za-z0-9]+)\x60\s*(.*)$")
    stages, tasks = [], []
    current = None
    unnamed_index = 0
    for line in text.splitlines():
        stage_match = stage_re.match(line.strip())
        if stage_match:
            current = stage_match.group(1)
            stages.append({"id": current, "title": stage_match.group(2), "domain": "GFX"})
            unnamed_index = 0
            continue
        if current is None:
            continue
        if line.startswith("## ") or line.startswith("# "):
            current = None
            continue
        if not line.startswith("- "):
            continue
        text_line = line[2:].strip()
        match = named_re.match(text_line)
        if match:
            id_, desc = match.group(1), match.group(2).strip()
        else:
            # Untagged production work exists in GFX-09/13 and must not vanish
            # from the dashboard just because it lacks a numbered bullet.
            unnamed_index += 1
            id_, desc = f"{current}-T{unnamed_index:02d}", text_line
        desc = desc.removeprefix("— ").strip()
        if not desc:
            continue
        tasks.append({
            "id": id_, "stage": current, "title": desc,
            "description": desc, "domain": "GFX",
            "priority": "P0" if current in {"GFX-00","GFX-01","GFX-02","GFX-03","GFX-04","GFX-05","GFX-11"} else "P1" if current in {"GFX-06","GFX-07","GFX-08","GFX-09","GFX-10","GFX-12"} else "P2",
            "size": "unestimated", "status": "proposed",
            "dependsOn": [], "graphicsDependencies": [],
            "deliverable": desc, "acceptance": "Review according to the gate in the graphics roadmap and exact accepted asset contract.",
            "source": "docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md",
        })
    return stages, tasks


def build(progress_override: dict | None = None) -> dict:
    """Render live shards; legacy progress override is available only for migration QA."""
    source = load(CODE)
    gap = load(GAPS)
    progress = load_shards() if progress_override is None else progress_override
    graphics_stages, graphics_tasks = graphics_items(GFX.read_text(encoding="utf-8"))
    bg_catalog = load(BG)
    character_catalog = load(CHAR_ART)
    plan = []
    for item in source["workPackages"]:
        plan.append({**item, "domain": "CODE", "description": item.get("deliverable", ""), "source": item.get("sourceDecision", str(CODE.relative_to(ROOT)))})
    for item in gap["workPackages"]:
        plan.append({**item, "stage": item.get("domain", "process").upper()})
    plan.extend(graphics_tasks)
    overrides = {entry["id"]: entry for entry in progress["entries"]}
    known_ids = {item["id"] for item in plan}
    if len(known_ids) != len(plan):
        raise ValueError("Duplicate dashboard task IDs")
    if not set(overrides).issubset(known_ids):
        raise ValueError("Progress references unknown task IDs: " + str(sorted(set(overrides) - known_ids)))
    for item in plan:
        override = overrides.get(item["id"])
        if override:
            # Source plans preserve historical CODE/GAP/GFX definitions and
            # priorities. Only an explicit, reviewed production-progress
            # override may change the *current* task priority.
            if "priority" in override and override["priority"] not in {"P0", "P1", "P2"}:
                raise ValueError(f"Invalid task priority override: {item['id']}")
            item.update({k: override[k] for k in ("status", "priority", "owner", "updated", "evidence", "implementationState", "qaState", "approvalState", "supersededBy", "followUpTaskIds") if k in override})
        item.setdefault("owner", "unassigned")
        item.setdefault("updated", None)
        item.setdefault("evidence", "")
        item.setdefault("implementationState", "not_recorded")
        item.setdefault("qaState", "not_recorded")
        item.setdefault("approvalState", "not_recorded")
        item.setdefault("supersededBy", [])
        item.setdefault("followUpTaskIds", [])
        if item["status"] == "superseded" and not item["supersededBy"]:
            raise ValueError(f"Superseded task lacks a replacement: {item['id']}")
        if not isinstance(item["supersededBy"], list):
            raise ValueError(f"Invalid supersededBy references: {item['id']}")
        remaining = item["followUpTaskIds"]
        if not isinstance(remaining, list) or any(not isinstance(ref, str) for ref in remaining) or len(set(remaining)) != len(remaining):
            raise ValueError(f"Invalid followUpTaskIds: {item['id']}")
        if set(remaining) - known_ids or item["id"] in remaining:
            raise ValueError(f"Unknown/self follow-up IDs for {item['id']}: {remaining}")
        if item["status"] not in STATES:
            raise ValueError(f"Unsupported {item['id']} status: {item['status']}")
    # Dependencies on delivered tasks remain visible as planning history,
    # but they are not *active blockers* in the dashboard. For example, an
    # old merged CODE-02 migration can list a not-yet-accepted UI gate without
    # implying it must be implemented again. No original source edges deleted.
    task_by_id = {item["id"]: item for item in plan}
    terminal = {"merged", "integrated", "accepted", "device_verified", "superseded", "not_planned"}
    for item in plan:
        deps = item.get("dependsOn", [])
        item["openDependsOn"] = (
            [dep for dep in deps if dep in task_by_id and task_by_id[dep]["status"] not in terminal]
            if item["status"] not in terminal else []
        )
    # The active delivery work is grouped by one shared QA/build gate, not
    # collapsed into a fictitious single task. P2/future tasks stay visible
    # without a current workstream; the group registry enforces exact coverage.
    stream_source = load(WORKSTREAMS)
    workstreams = stream_source["workstreams"]
    streams_by_id = {}
    member_to_stream = {}
    for workstream in workstreams:
        stream_id = workstream["id"]
        if stream_id in streams_by_id:
            raise ValueError(f"Duplicate active workstream ID: {stream_id}")
        if workstream["phase"] not in {"QA-first", "Audit-first", "Build+QA", "New assets"}:
            raise ValueError(f"Unknown active workstream phase: {stream_id}")
        streams_by_id[stream_id] = workstream
        for task_id in workstream["taskIds"]:
            if task_id in member_to_stream:
                raise ValueError(f"Task in two workstreams: {task_id}")
            if task_id not in task_by_id:
                raise ValueError(f"Unknown workstream member {task_id}: {stream_id}")
            member_to_stream[task_id] = stream_id
    active_ids = {item["id"] for item in plan
                  if item["priority"] in {"P0", "P1"} and item["status"] not in terminal}
    if set(member_to_stream) != active_ids:
        raise ValueError(f"Active workstream scope mismatch: "
                         f"missing={sorted(active_ids - set(member_to_stream))}, "
                         f"inactive={sorted(set(member_to_stream) - active_ids)}")
    for item in plan:
        stream = streams_by_id.get(member_to_stream.get(item["id"]))
        item["workstreamId"] = stream["id"] if stream else ""
        item["workstreamName"] = stream["title"] if stream else ""
        item["workstreamPhase"] = stream["phase"] if stream else ""
    p2_source = load(P2_REENTRY)
    p2_groups = p2_source["groups"]
    p2_members = {}
    p2_ids = {item["id"] for item in plan
              if item["priority"] == "P2" and item["status"] not in terminal}
    for group in p2_groups:
        if not group["id"].startswith("P2-"):
            raise ValueError(f"Invalid P2 policy group: {group['id']}")
        for task_id in group["taskIds"]:
            if task_id in p2_members:
                raise ValueError(f"Duplicate P2 task in re-entry policy: {task_id}")
            if task_id not in task_by_id:
                raise ValueError(f"Unknown P2 task: {task_id}")
            p2_members[task_id] = group["id"]
    if set(p2_members) != p2_ids:
        raise ValueError(f"P2 re-entry coverage mismatch: "
                         f"missing={sorted(p2_ids - set(p2_members))}, "
                         f"inactive={sorted(set(p2_members) - p2_ids)}")
    for item in plan:
        item["p2ReentryGroup"] = p2_members.get(item["id"], "")
    for workstream in workstreams:
        matrix = workstream.get("acceptancePlan")
        if not isinstance(matrix, dict) or any(
            not isinstance(matrix.get(field), list) or not matrix[field] or
            any(not isinstance(v, str) or not v.strip() for v in matrix[field])
            for field in ("automatedChecks", "ownerChecks", "newWorkIfFailed")
        ) or not isinstance(matrix.get("decision"), str) or not matrix["decision"].strip():
            raise ValueError(f"Missing distinct automated/owner/new-work acceptance fields: {workstream['id']}")
    # Asset approval is a separate owner decision; it is not inferred from merge,
    # gameplay staging or CI. Only exact imported catalog records are counted.
    backgrounds = bg_catalog.get("entries", [])
    portraits = character_catalog.get("entries", [])
    assert bg_catalog.get("variantCount") == len(backgrounds)
    assert len({x["id"] for x in backgrounds}) == len(backgrounds)
    assert len({x["id"] for x in portraits}) == len(portraits)
    approval_summary = {
        "backgrounds": {"total": len(backgrounds), "artApproved": sum(x.get("status") == "accepted" for x in backgrounds)},
        "characterFrames": {"total": len(portraits), "artApproved": sum(x.get("status") == "accepted" for x in portraits)},
        "note": "Owner approved exact imported images; staging/animation/mobile/device acceptance remains separate.",
    }
    plan.sort(key=lambda item: ({"CODE": 0, "GFX": 1}.get(item["domain"], 2), item["id"]))
    return {
        "schemaVersion": 1,
        "project": "Raven Manor",
        "release": "Season 1 preproduction/production",
        "updated": progress["updated"],
        "baseline": source["baseline"],
        "taskCount": len(plan),
        "assetSummary": approval_summary,
        "openTaskCount": sum(x["status"] not in {"merged", "integrated", "accepted", "device_verified", "superseded", "not_planned"} for x in plan),
        "sourceFiles": [str(p.relative_to(ROOT)) for p in (
            CODE, GFX, GAPS, *( [SHARDS / "index.json", *[SHARDS / name for name in load(SHARDS / "index.json")["shards"]]]
                if progress_override is None else [LEGACY_PROGRESS] ),
            BG, CHAR_ART, WORKSTREAMS, P2_REENTRY)],
        "p2Groups": [
            {**{k: value for k, value in group.items() if k != "taskIds"},
             "taskCount": len(group["taskIds"])}
            for group in p2_groups
        ],
        "workstreams": [
            {**{k: value for k, value in workstream.items() if k != "taskIds"},
             "taskCount": len(workstream["taskIds"]),
             "p0Count": sum(task_by_id[task_id]["priority"] == "P0" for task_id in workstream["taskIds"]),
             "p1Count": sum(task_by_id[task_id]["priority"] == "P1" for task_id in workstream["taskIds"])}
            for workstream in workstreams
        ],
        "stateVocabulary": sorted(STATES),
        "stages": [{"id": f"CODE-{i:02d}", "domain": "CODE", "title": f"CODE-{i:02d}"} for i in range(14)] + graphics_stages,
        "tasks": plan,
        "notes": [
            "Source plans and current status/evidence are separate; generated dashboard is read-only.",
            "Stage C11 × GFX-11 is the common Hall pilot approval gate.",
            "Merged or tested work is not automatically accepted or phone-approved.",
            "Owner art approval applies only to exact imported catalog images, not every staged pose/state or the entire game.",
            "Dates are last status updates, never synthetic project deadlines.",
        ]
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, default=OUT)
    ap.add_argument("--check", action="store_true", help="Validate sources and generated schema without writing")
    args = ap.parse_args()
    data = build()
    if args.check:
        assert data["taskCount"] >= 120, "Expected CODE + GFX + gap worklist"
        assert "CODE-01-01" in {item["id"] for item in data["tasks"]}
        assert "RM-GAP-002" in {item["id"] for item in data["tasks"]}
        print(f"Raven dashboard PASS: {data['taskCount']} tasks, {len(data['stages'])} stages")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Raven dashboard generated: {data['taskCount']} tasks -> {args.output}")


if __name__ == "__main__":
    main()
