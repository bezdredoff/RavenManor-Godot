Task IDs: CODE-02-03 (match3), VN-EDITOR-07 (vn-studio) — post-merge reconciliation.

Changes:
- data/raven/production/progress/match3.json: CODE-02-03 status PR_review -> merged; evidence appended with PR #230 and merge commit f1943f2 (final head 43c1947).
- data/raven/production/progress/vn-studio.json: VN-EDITOR-07 evidence appended with PR #229 and merge commit 5028f23; status stays ready (broad parent task, not complete); updated -> 2026-11-07.

Verification:
- gh pr view 229 / 230 confirmed merged; merge commits 5028f23 (PR #229) and f1943f2 (PR #230) read from origin/main.
- Both shards re-parsed as valid JSON after the edit.

Owner QA: not performed; status-only reconciliation, no runtime/art/save change.

Status impact: CODE-02-03 -> merged (technical delivery, NOT owner/device accepted). VN-EDITOR-07 stays ready/partial.
