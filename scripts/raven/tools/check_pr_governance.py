#!/usr/bin/env python3
"""Enforce task/status/docs in each authored Raven Manor PR.

Only auto-generated, untrusted candidate/mobile-<run> ZIP import PRs are
excluded: they pass independent security/test checks before a human can merge.
"""
from __future__ import annotations

import argparse
import subprocess
import sys

REQUIRED = frozenset({
    "docs/STATUS.md",
    "data/raven/production/production_progress.json",
})


def missing_files(changed: set[str], head_ref: str) -> set[str]:
    if head_ref.startswith("candidate/mobile-"):
        return set()
    return REQUIRED.difference(changed)


def check_pr(base_sha: str, head_ref: str) -> int:
    result = subprocess.run(
        ["git", "diff", "--name-only", base_sha, "HEAD"],
        check=True, text=True, capture_output=True,
    )
    changed = set(result.stdout.splitlines())
    missing = missing_files(changed, head_ref)
    if missing:
        print(
            "PR governance FAILED: update source-of-truth documentation/status "
            "in the SAME PR, even when the work is documentation-only. Missing:\n"
            + "\n".join(f"  - {item}" for item in sorted(missing)),
            file=sys.stderr,
        )
        print(
            "If a task has no status change, record a dated no-change rationale "
            "in STATUS.md and an evidence entry on the relevant task. "
            "Never edit generated dashboard/status.json.",
            file=sys.stderr,
        )
        return 1
    print("Raven PR governance PASS: canonical STATUS and progress included"
          if not head_ref.startswith("candidate/mobile-")
          else "Raven PR governance SKIP: untrusted mobile ZIP candidate (manual review required)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-sha", required=True)
    parser.add_argument("--head-ref", required=True)
    args = parser.parse_args()
    return check_pr(args.base_sha, args.head_ref)


if __name__ == "__main__":
    raise SystemExit(main())
