#!/usr/bin/env python3
"""Read/validate independent Raven task-progress shards.

Migration stage 1: production_progress.json remains authoritative; shards must
match it record-for-record. In stage 2 this loader becomes the dashboard source.
Do not edit manually generated dashboard/status.json.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
SHARDS = ROOT / "data/raven/production/progress"
LEGACY = ROOT / "data/raven/production/production_progress.json"
SHARD_NAME = re.compile(r"[a-z][a-z0-9-]*\.json")
INDEX_KEYS = ("schemaVersion", "updated", "authority", "rules")


def load_shards(directory: Path = SHARDS) -> dict:
    index_path = directory / "index.json"
    index = json.loads(index_path.read_text(encoding="utf-8"))
    if index.get("kind") != "task_progress_index" or index.get("schemaVersion") != 1:
        raise ValueError("Invalid progress shard index version/kind")
    if any(key not in index for key in INDEX_KEYS):
        raise ValueError("Progress shard index missing legacy metadata")
    shards = index.get("shards")
    if not isinstance(shards, list) or not shards or any(
        not isinstance(name, str) or not SHARD_NAME.fullmatch(name) or name == "index.json"
        for name in shards
    ) or len(shards) != len(set(shards)):
        raise ValueError("Invalid/duplicate progress shard filenames")
    actual = {p.name for p in directory.glob("*.json") if p.name != "index.json"}
    if actual != set(shards):
        raise ValueError(f"Undeclared or missing progress shards: {sorted(actual ^ set(shards))}")
    entries: list[dict] = []
    seen: set[str] = set()
    for name in shards:
        record = json.loads((directory / name).read_text(encoding="utf-8"))
        if record.get("schemaVersion") != 1 or record.get("kind") != "task_progress_shard":
            raise ValueError(f"Invalid progress shard version/kind: {name}")
        if record.get("domain") != name[:-5] or not isinstance(record.get("entries"), list):
            raise ValueError(f"Wrong domain or entries in progress shard: {name}")
        for task in record["entries"]:
            if not isinstance(task, dict) or not isinstance(task.get("id"), str) or not task["id"]:
                raise ValueError(f"Invalid task record in {name}")
            if task["id"] in seen:
                raise ValueError(f"Duplicate task ID across shards: {task['id']}")
            if not isinstance(task.get("status"), str) or not task["status"]:
                raise ValueError(f"Task lacks status: {task['id']}")
            seen.add(task["id"])
            entries.append(task)
    result = {key: index[key] for key in INDEX_KEYS}
    result["entries"] = entries
    return result


def check_parity(sharded: dict, legacy: dict) -> None:
    """Exact task records and metadata, ignoring only irrelevant list ordering."""
    for key in INDEX_KEYS:
        if sharded.get(key) != legacy.get(key):
            raise ValueError(f"Legacy/shard progress metadata drift: {key}")
    def indexed(document: dict, label: str) -> dict:
        records = document.get("entries")
        if not isinstance(records, list):
            raise ValueError(f"{label} must have an entries array")
        task_ids = [item.get("id") for item in records]
        if len(task_ids) != len(set(task_ids)):
            raise ValueError(f"Duplicate task IDs in {label}")
        return {item["id"]: item for item in records}
    current = indexed(sharded, "shards")
    old = indexed(legacy, "legacy")
    if current.keys() != old.keys():
        raise ValueError(f"Task ID parity drift, missing={sorted(old.keys() - current.keys())}, "
                         f"new={sorted(current.keys() - old.keys())}")
    for task_id in sorted(old):
        if current[task_id] != old[task_id]:
            raise ValueError(f"Task progress/evidence drift: {task_id}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-parity", action="store_true",
                        help="Stage 1: verify exact parity with authoritative legacy JSON")
    args = parser.parse_args()
    data = load_shards()
    if args.check_parity:
        check_parity(data, json.loads(LEGACY.read_text(encoding="utf-8")))
    print(f"Raven progress shards PASS: {len(data['entries'])} unique tasks in "
          f"{len(list(SHARDS.glob('*.json'))) - 1} domains"
          + ("; exact legacy parity" if args.check_parity else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
