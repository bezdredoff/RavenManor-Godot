#!/usr/bin/env python3
"""Authored PR evidence gate; numeric mobile incoming candidates retain separate reviews."""
import argparse
import re
import subprocess
import sys
from pathlib import Path

LEGACY_STATUS = frozenset({"docs/STATUS.md", "data/raven/production/production_progress.json"})
NOTE_RE = re.compile(r"^docs/changes/[A-Za-z0-9][A-Za-z0-9._-]*\.md$")
NOTE_FIELDS = ("Task IDs:", "Changes:", "Verification:", "Owner QA:", "Status impact:")
NOTE_REQUIRED = "docs/changes/<TASK-ID>-<topic>.md OR both canonical status files"


def is_candidate(ref: str) -> bool:
    return re.fullmatch(r"candidate/mobile-[0-9]+", ref) is not None


def notes(changed: set[str]) -> list[str]:
    return sorted(p for p in changed if NOTE_RE.fullmatch(p))


def missing_files(changed: set[str], head_ref: str) -> set[str]:
    if is_candidate(head_ref):
        return set()
    errors = set()
    if "dashboard/status.json" in changed:
        errors.add("Do not modify generated dashboard/status.json")
    if not notes(changed) and not LEGACY_STATUS.issubset(changed):
        errors.add(NOTE_REQUIRED)
    return errors


def invalid_notes(changed: set[str], root: Path) -> list[str]:
    errors = []
    for p in notes(changed):
        f = root / p
        if not f.is_file():
            errors.append(p + ": evidence file not found")
            continue
        source = f.read_text(encoding="utf-8")
        for field in NOTE_FIELDS:
            if not re.search("^" + re.escape(field) + r"\s+\S", source, re.MULTILINE):
                errors.append(p + ": missing/nonempty " + field)
    return errors


def check_pr(base_sha: str, head_ref: str) -> int:
    changed = set(subprocess.run(["git", "diff", "--name-only", base_sha, "HEAD"],
                                 check=True, text=True, capture_output=True).stdout.splitlines())
    if is_candidate(head_ref):
        print("Raven governance SKIP: numeric mobile candidate; separate security/human QA")
        return 0
    errors = sorted(missing_files(changed, head_ref)) + invalid_notes(changed, Path.cwd())
    if errors:
        print("Raven PR governance FAILED:\n" + "\n".join("  - " + e for e in errors), file=sys.stderr)
        return 1
    print("Raven PR governance PASS: individual evidence or legacy canonical pair")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-sha", required=True)
    ap.add_argument("--head-ref", required=True)
    args = ap.parse_args()
    return check_pr(args.base_sha, args.head_ref)


if __name__ == "__main__":
    raise SystemExit(main())
