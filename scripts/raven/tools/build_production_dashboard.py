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

ROOT = Path(__file__).resolve().parents[3]
PRODUCTION = ROOT / "data/raven/production"
CODE = PRODUCTION / "code_work_packages.json"
GAPS = PRODUCTION / "gap_work_packages.json"
PROGRESS = PRODUCTION / "production_progress.json"
GFX = ROOT / "docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md"
OUT = ROOT / "dashboard/status.json"
STATES = {"proposed", "ready", "in_progress", "PR_review", "merged", "integrated", "device_verified", "accepted", "blocked", "deferred"}


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


def build() -> dict:
    source = load(CODE)
    gap = load(GAPS)
    progress = load(PROGRESS)
    graphics_stages, graphics_tasks = graphics_items(GFX.read_text(encoding="utf-8"))
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
            item.update({k: override[k] for k in ("status", "owner", "updated", "evidence") if k in override})
        item.setdefault("owner", "unassigned")
        item.setdefault("updated", None)
        item.setdefault("evidence", "")
        if item["status"] not in STATES:
            raise ValueError(f"Unsupported {item['id']} status: {item['status']}")
    plan.sort(key=lambda item: ({"CODE": 0, "GFX": 1}.get(item["domain"], 2), item["id"]))
    return {
        "schemaVersion": 1,
        "project": "Raven Manor",
        "release": "Season 1 preproduction/production",
        "updated": progress["updated"],
        "baseline": source["baseline"],
        "taskCount": len(plan),
        "sourceFiles": [str(p.relative_to(ROOT)) for p in (CODE, GFX, GAPS, PROGRESS)],
        "stateVocabulary": sorted(STATES),
        "stages": [{"id": f"CODE-{i:02d}", "domain": "CODE", "title": f"CODE-{i:02d}"} for i in range(14)] + graphics_stages,
        "tasks": plan,
        "notes": [
            "Source plans and current status/evidence are separate; generated dashboard is read-only.",
            "Stage C11 × GFX-11 is the common Hall pilot approval gate.",
            "Merged or tested work is not automatically accepted or phone-approved.",
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
