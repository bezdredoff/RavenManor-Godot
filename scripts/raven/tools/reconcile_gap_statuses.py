#!/usr/bin/env python3
"""Keep discovered-gap status snapshot aligned with authoritative progress.

The CODE planning baseline is intentionally excluded: code_work_packages.json
is an immutable planning proposal, NOT a live implementation ledger.

Usage:
    python3 scripts/raven/tools/reconcile_gap_statuses.py --check
    python3 scripts/raven/tools/reconcile_gap_statuses.py --sync

--sync touches *only* status fields of gap work packages having an explicit
canonical per-module progress entry; unmatched historical proposals are preserved.
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


def drift(gaps: dict, progress: dict) -> list[tuple[str, str, str]]:
    work = gaps.get("workPackages", [])
    entries = progress.get("entries", [])
    gap_ids = [item["id"] for item in work]
    live_ids = [item["id"] for item in entries]
    if len(set(gap_ids)) != len(gap_ids) or len(set(live_ids)) != len(live_ids):
        raise ValueError("duplicate gap or progress task ID")
    live = {item["id"]: item["status"] for item in entries}
    return [(item["id"], item["status"], live[item["id"]])
            for item in work if item["id"] in live and item["status"] != live[item["id"]]]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--sync", action="store_true")
    args = parser.parse_args()
    gaps = json.loads(GAPS.read_text(encoding="utf-8"))
    progress = load_shards()
    differences = drift(gaps, progress)
    if args.sync and differences:
        live = {item["id"]: item["status"] for item in progress["entries"]}
        for item in gaps["workPackages"]:
            if item["id"] in live:
                item["status"] = live[item["id"]]
        GAPS.write_text(json.dumps(gaps, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for task_id, old, new in differences:
        print(f"GAP STATUS {'SYNCHRONIZED' if args.sync else 'DRIFT'}: {task_id}: {old} -> {new}")
    print(f"Gap status audit: {len(gaps['workPackages'])} planning tasks, "
          f"{len(differences)} discrepant live overrides"
          + (" synchronized" if args.sync else ""))
    return 1 if args.check and differences else 0


if __name__ == "__main__":
    raise SystemExit(main())
