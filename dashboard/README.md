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

## Reconciliation / Dashboard v2 (2026-11-02)

The dashboard defaults to **Оставшаяся работа** rather than showing every historical task. `Все задачи` includes merged work; `Архив / заменённые` includes `not_planned` and `superseded` with a mandatory replacement for superseded IDs. This is filtering, not data deletion.

Three independent fields can be attached to entries in `production_progress.json`: `implementationState` (`partial/delivered`), `qaState` (`automated/manual_pending/device_verified`) and `approvalState` (`art_approved/feature_approved/pending/rejected`). If absent, show **Не зафиксировано**—do not infer successful QA from a merged PR. Status continues to represent the task lifecycle. `supersededBy` references replacement task IDs.

The header's **26/26 approved VN backgrounds** and **62/62 approved character frames** are computed from exact `status=accepted` catalog records. They do **not** imply that every staged pose/emotion exists, a room state has pixel-registered lighting, an interactable map is approved, or native/mobile QA passed. A missing background such as unused `BG-CORRIDOR` is not part of the approved exact-art count. After merging the source+dashboard PR, CI publishes a freshly generated `status.json` to Pages. Do not edit generated output manually.

## Visibility regression / browser test (DASH-RENDER-01, 2026-11-03)

The first section is now a source-derived P0 shortlist, ahead of the long progress panels. Full task listing below renders 24 cards initially, then 24 more per click. Filters reset page size. A visible error directs readers to the canonical status.json when the browser cannot fetch/render the content. On CI the generated Pages artifact is served over local HTTP and opened in real headless Google Chrome or Chromium; the test asserts at least one rendered full task and P0 preview. This prevents "green Python/node syntax but blank visible task list" regressions. Manual iOS/desktop review still required.

### No-JavaScript first-screen task fallback

The Pages build runs `embed_dashboard_priority.py` **after** producing `status.json` and copying the tracked template to `build/web/dashboard/`. It embeds the first six exact P0 open items from the built JSON. A blocked ES module or failed fetch therefore cannot leave the top section completely without task names; each fallback entry links to the canonical backlog. On a normal browser `app.mjs` replaces these links with interactive filters. The tracked source `dashboard/index.html` stays clean; never commit generated dashboard snapshots.
