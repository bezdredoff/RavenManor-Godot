# PROC-006 — Prevent false foreign-shard changes in PR governance

Task IDs: PROC-006; follow-up to multi-agent PR governance and scope enforcement.
Changes: In the PR-only `data-contracts` workflow, compare changed files against the **first parent of the checked-out GitHub PR merge commit**, rather than `github.event.pull_request.base.sha`. The latter may be stale when main advances after a PR opened. The check still uses the original `check_pr_governance.py` path allowlists and full-file evidence validation. If the checkout is not a two-parent PR merge, fail closed rather than guessing a base.
Verification: Diagnosed recent PR #267 head 8fc09ae (run 43961359975) and PR #269 head f4dc151 (run 43961861958). Their GitHub Actions merge checkout used current main `2cad1ca` while event BASE_SHA remained historical `832657c`, causing CI to misattribute merged campaign-core and manor-map changes to unrelated agents. All existing guard tests remain unchanged and blocking. New exact-head CI is pending.
Owner QA: NOT_REQUIRED for this CI-only correction; gameplay/visual/device acceptance is unaffected and never implied.
Status impact: No task statuses or live progress shards changed. PROC-006's previously merged technical scope remains historical; this is a narrowly scoped regression fix, not renewed owner acceptance.

Rollback: revert this workflow-only change; doing so reintroduces the false positive for older PRs after main advances. Do not loosen multi-agent domain ownership validation.
