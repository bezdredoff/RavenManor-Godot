#!/usr/bin/env python3
"""Validate the *planning* backlog against the paired code and graphics roadmaps.

This checker does not inspect game readiness, PR acceptance or story save state.
It only prevents missing/cyclic references and stale milestone/graphic gates.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BACKLOG = ROOT / "data/raven/production/code_work_packages.json"
CODE = ROOT / "docs/production/CODE_PRODUCTION_ROADMAP_RU.md"
ART = ROOT / "docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md"


def main() -> int:
    data = json.loads(BACKLOG.read_text(encoding="utf-8"))
    code = CODE.read_text(encoding="utf-8")
    art = ART.read_text(encoding="utf-8")
    errors: list[str] = []
    items = data.get("workPackages", [])
    known = {}
    if data.get("status") != "PROPOSAL_NOT_RUNTIME":
        errors.append("backlog must not be presented as implemented runtime")
    if not items:
        errors.append("workPackages must not be empty")
    for item in items:
        key = item.get("id")
        if not isinstance(key, str) or key in known:
            errors.append(f"missing or duplicate task ID: {key!r}")
        known[key] = item
        if item.get("status") not in data.get("statusVocabulary", []):
            errors.append(f"{key}: invalid status")
        if item.get("priority") not in data.get("priorities", []):
            errors.append(f"{key}: invalid priority")
        if item.get("size") not in data.get("sizes", []):
            errors.append(f"{key}: invalid size")
        if not item.get("deliverable") or not item.get("acceptance"):
            errors.append(f"{key}: missing deliverable or acceptance")
        stage = item.get("stage", "")
        if f"### {stage} " not in code:
            errors.append(f"{key}: unknown code stage {stage}")
        if not item.get("graphicsDependencies"):
            errors.append(f"{key}: missing graphics integration gate")
        for graphics in item.get("graphicsDependencies", []):
            if f"## {graphics} " not in art:
                errors.append(f"{key}: graphics gate not found in roadmap: {graphics}")

    state = {}
    def visit(key: str):
        if key not in known:
            errors.append(f"missing work package dependency: {key}")
            return
        if state.get(key) == 1:
            errors.append(f"cycle at {key}")
            return
        if state.get(key) == 2:
            return
        state[key] = 1
        for dep in known[key].get("dependsOn", []):
            if dep == key:
                errors.append(f"self-reference at {key}")
            else:
                visit(dep)
        state[key] = 2

    for item in items:
        visit(item["id"])

    if "GFX-11" not in art or "CODE-11" not in code:
        errors.append("missing shared Hall milestone")
    if "GFX-13" not in art or "CODE-13" not in code:
        errors.append("missing paired RC milestone")
    for error in errors:
        print("ERROR:", error)
    print(f"Raven code production plan: {len(items)} packages; "
          f"{sum(len(item.get('dependsOn', [])) for item in items)} dependencies; "
          f"{len(errors)} validation errors")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
