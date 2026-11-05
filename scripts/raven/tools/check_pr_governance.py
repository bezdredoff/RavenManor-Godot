#!/usr/bin/env python3
"""Author PR evidence and functional ownership gate for independent agents.

Only numeric candidate/mobile-<run> branches use the separate vetted
read-only ZIP import review path. No normal PR edits generated or legacy status.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

NOTE_RE = re.compile(r"^docs/changes/[A-Za-z0-9][A-Za-z0-9._-]*\.md$")
NOTE_FIELDS = ("Task IDs:", "Changes:", "Verification:", "Owner QA:", "Status impact:")
NOTE_REQUIRED = "A unique docs/changes/<TASK-ID>-<topic>.md evidence record"
SHARD_RE = re.compile(r"^data/raven/production/progress/([a-z][a-z0-9-]*)\.json$")
AGENT_RE = re.compile(r"^agent/([a-z][a-z0-9-]*)/.+$")
PROTECTED = {
    "dashboard/status.json",
    "data/raven/production/production_progress.json",
}


def is_candidate(ref: str) -> bool:
    return re.fullmatch(r"candidate/mobile-[0-9]+", ref) is not None


def notes(changed: set[str]) -> list[str]:
    return sorted(path for path in changed if NOTE_RE.fullmatch(path))


def missing_files(changed: set[str], head_ref: str) -> set[str]:
    if is_candidate(head_ref):
        return set()
    errors = set()
    for path in PROTECTED & changed:
        errors.add("Do not edit generated/frozen status: " + path)
    if not notes(changed):
        errors.add(NOTE_REQUIRED)
    match = AGENT_RE.fullmatch(head_ref)
    if match:
        domain = match.group(1)
        required = f"data/raven/production/progress/{domain}.json"
        touched = {m.group(1) for path in changed if (m := SHARD_RE.fullmatch(path))}
        if required not in changed:
            errors.add(f"Agent branch must update its domain status: {required}")
        for other_domain in touched - {domain}:
            errors.add(f"Agent {domain} cannot edit another progress shard: {other_domain}")
        if "data/raven/production/progress/index.json" in changed:
            errors.add("Only integration owner may modify the progress shard index")
        for shared in ("data/raven/production/active_workstreams.json",
                       "data/raven/production/p2_reentry_policy.json"):
            if shared in changed:
                errors.add("Agent cannot edit shared QA policy metadata: " + shared)
    return errors


def invalid_notes(changed: set[str], root: Path) -> list[str]:
    errors = []
    for path in notes(changed):
        file = root / path
        if not file.is_file():
            errors.append(path + ": evidence file not found")
            continue
        source = file.read_text(encoding="utf-8")
        for field in NOTE_FIELDS:
            if not re.search("^" + re.escape(field) + r"\s+\S", source, re.MULTILINE):
                errors.append(path + ": missing/nonempty " + field)
    return errors


def check_pr(base_sha: str, head_ref: str) -> int:
    changed = set(subprocess.run(
        ["git", "diff", "--name-only", base_sha, "HEAD"], check=True,
        text=True, capture_output=True).stdout.splitlines())
    if is_candidate(head_ref):
        print("Raven governance SKIP: numeric mobile candidate; separate security/human QA")
        return 0
    errors = sorted(missing_files(changed, head_ref)) + invalid_notes(changed, Path.cwd())
    if errors:
        print("Raven PR governance FAILED:\n" + "\n".join("  - " + e for e in errors),
              file=sys.stderr)
        return 1
    print("Raven PR governance PASS: isolated evidence, shard ownership and frozen sources")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-sha", required=True)
    parser.add_argument("--head-ref", required=True)
    args = parser.parse_args()
    return check_pr(args.base_sha, args.head_ref)


if __name__ == "__main__":
    raise SystemExit(main())
