# Production Dashboard — maintenance and review runbook

**Model:** copied from the UPDS release dashboard's single-source-of-truth principle (`bezdredoff/UPDS/scripts/build-status-dashboard.mjs`, `docs/release-status.json`, `docs/release-task-details.json`). Raven intentionally uses the pair of CODE/GFX source plans instead of inventing calendar Gantt bars before Hall pilot measurements.

## URLs after this PR is merged and Pages is deployed

- Stable Raven Prototype Lab: `https://bezdredoff.github.io/RavenManor-Godot/`
- Room Builder: `https://bezdredoff.github.io/RavenManor-Godot/builder/`
- **Dashboard:** `https://bezdredoff.github.io/RavenManor-Godot/dashboard/`

CI builds `build/web/dashboard/status.json` from the latest source JSON/graphics Markdown in the same commit as the Godot export. **Do not edit `dashboard/status.json` or commit a separate stale snapshot.**

## Authoritative inputs

- `data/raven/production/code_work_packages.json`: current code task baseline/dependencies/deliverable/acceptance; old static task status inside code plan is historical until overridden by progress.
- `docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md`: numbered GFX tasks and unnumbered production acceptance checklist bullets; generator assigns `GFX-XX-Tnn` to the latter.
- `data/raven/production/gap_work_packages.json`: extra process/Room Builder/RM-PIPE/mobile ZIP/gap tasks found in owner conversations or late audits; remove/merge duplicates after owner approval, not silently.
- `data/raven/production/production_progress.json`: **canonical current task status/owner/date/evidence overrides**; if no override exists, task stays `proposed`.

## Update procedure for any assistant

1. Read repo `main`, open PRs and the relevant task entry. Never trust a previous chat's «merged» statement.
2. Modify only the appropriate canonical task source if scope/dependencies/acceptance change. For status-only changes add/update `production_progress.json`.
3. Put exact PR/commit/CI result/phone screenshot evidence in `evidence`; assign `owner`, `updated` (YYYY-MM-DD) and allowed `status`.
4. `merged` means GitHub PR merged; `accepted` requires owner/device/art explicit approval and evidence. `PR_review` means open PR, not merged.
5. Run:
   ```bash
   python3 scripts/raven/tools/validate_code_plan.py
   python3 scripts/raven/tools/build_production_dashboard.py --check
   python3 -m unittest scripts/raven/tools/test_production_dashboard_mobile.py
   python3 scripts/raven/tools/build_production_dashboard.py --output /tmp/raven-dashboard/status.json
   ```
6. The HTML client loads `status.json` relative to `dashboard/index.html` and can be previewed with a local static server. `node --check dashboard/app.mjs` tests JS syntax.
7. Push scoped branch, open PR, ensure latest head CI green, human review/merge. Pages publishes generated dashboard with the next main build. If a PR is still open, dashboard at stable `/dashboard/` correctly shows the previous merged baseline, not unmerged branch status.

## Display and privacy

The dashboard uses locally stored JSON rendered via DOM textContent — not executable task HTML. It is accessible on a public website. **Never put secrets, raw private screenplay, personal data, unpublished contract details or privately licensed files into statuses/evidence/URLs**. GitHub PRs and CI may be public.

The first version displays searchable tasks, status, stage, priority, size, dependencies, delivery/acceptance, source, evidence and CODE/GFX summary. It intentionally **does not fabricate deadlines or Gantt dates**. Status percent measures accepted tasks, not a guessed game-completion percentage.

## Future extensions, only after measured use

Add saved dashboard filters, cost/capacity and milestone estimates after Hall C11 × GFX-11, stage click-through and actual GitHub issue synchronization only if the team adopts them. They are not prerequisites for basic transparent project status.
