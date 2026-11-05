#!/usr/bin/env python3
"""Validate GAP planning records; live status belongs exclusively to shards.

--check is retained for existing CI compatibility. --sync is intentionally
removed: it would create cross-agent write conflicts and a second status ledger.
Historical planning 'status' fields are baseline defaults only, overridden in
the dashboard by the matching per-domain progress entry.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    from scripts.raven.tools.progress_shards import load_shards
except ModuleNotFoundError:
    from progress_shards import load_shards

ROOT = Path(__file__).resolve().parents[3]
GAPS = ROOT / "data/raven/production/gap_work_packages.json"


def validate(gaps: dict, progress: dict) -> list[str]:
    tasks = gaps.get("workPackages", [])
    if not isinstance(tasks, list):
        return ["GAP workPackages must be a list"]
    ids = [t.get("id") for t in tasks]
    errors = []
    if len(ids) != len(set(ids)):
        errors.append("Duplicate GAP planning IDs")
    if not all(isinstance(t.get("status"), str) and t["status"] for t in tasks):
        errors.append("GAP baseline task lacks planning status")
    live_ids = [t["id"] for t in progress["entries"]]
    if len(live_ids) != len(set(live_ids)):
        errors.append("Duplicate canonical progress IDs")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate planning baseline only")
    args = parser.parse_args()
    gaps = json.loads(GAPS.read_text(encoding="utf-8"))
    progress = load_shards()
    errors = validate(gaps, progress)
    for error in errors:
        print("ERROR:", error)
    print(f"GAP planning audit: {len(gaps.get('workPackages', []))} baseline entries; "
          f"{len(progress['entries'])} current shard overrides; {len(errors)} structural errors")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
