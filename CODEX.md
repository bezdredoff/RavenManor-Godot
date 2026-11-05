# Codex entrypoint — Raven Manor

Follow `AGENTS.md`, `docs/process/AGENT_ORCHESTRATION_RU.md` and the closest `AGENTS.md` files for **all paths** being edited. Work on a separate clean worktree/branch `agent/<domain>/<task-id>-topic` from fresh `origin/main`; check remote, dirty worktree, competing PRs and source contracts first.

1. Choose one domain of the 15 in `docs/process/AGENT_ORCHESTRATION_RU.md` and an exact runtime/data/tests allowlist; cross-domain/core changes require a coordinated integration PR.
2. For VN/Match-3/UI/settings/audio inspect actual `bezdredoff/UPDS-godot` source, pin donor SHA and decide reuse/extract/adapter/new with justification.
3. Implement scoped change, relevant regression tests and unique `docs/changes/<TASK-ID>-topic.md`; update only the matching `data/raven/production/progress/<domain>.json`.
4. Never edit historical `production_progress.json`, `dashboard/status.json`, manually maintain workstream/P2 member lists, or mark an open PR `merged`.
5. Wait for all exact-head CI jobs and request human merge approval. After verified merge, record technical closeout in the same domain shard via a later small scoped change. Manual/device/asset acceptance remains separate.
6. For phone ZIP fallback use `docs/process/MOBILE_ZIP_PIPELINE_RU.md` and follow existing security gates.

Use `docs/process/TASK_AND_PR_TEMPLATE_RU.md` for handoff; never auto-merge.
