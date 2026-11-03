#!/usr/bin/env python3
"""Fast PR preflight: run before opening or updating an authored PR.

Usage: python3 scripts/raven/tools/pr_preflight.py --base-ref origin/main --head-ref feat/my-work
"""
import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts" / "raven" / "tools"))
from check_pr_governance import missing_files


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-ref", default="origin/main")
    parser.add_argument("--head-ref", required=True)
    args = parser.parse_args()
    diff = subprocess.run(
        ["git", "diff", "--name-only", f"{args.base_ref}...HEAD"],
        cwd=ROOT, text=True, capture_output=True,
    )
    if diff.returncode:
        print("Cannot compare against base: " + diff.stderr, file=sys.stderr)
        return 2
    changed = set(diff.stdout.splitlines())
    missing = missing_files(changed, args.head_ref)
    if missing:
        print("PR preflight FAILED — missing required files: " + ", ".join(sorted(missing)), file=sys.stderr)
        return 1
    for path in ("docs/STATUS.md", "data/raven/production/production_progress.json"):
        if not (ROOT / path).is_file():
            print("PR preflight FAILED — absent " + path, file=sys.stderr)
            return 1
    print("PR preflight PASS: canonical documentation and progress are changed.")
    print("Next: bash scripts/check.sh; then review Godot import/export and device QA.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
