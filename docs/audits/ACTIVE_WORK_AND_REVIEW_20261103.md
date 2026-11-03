# Raven Manor — audit of active / review task states (2026-11-03)

## Exact GitHub snapshot

- **Repository:** `bezdredoff/RavenManor-Godot`, `main@82c6f0b64e9b27457dcb495a0650cb1217965f88` immediately after merged PR #139.
- **Open PRs:** **0**; branches: `main`, `incoming` only (no active feature branches).
- Source of truth: `data/raven/production/production_progress.json`, checked against CODE and GAP source work packages and GFX roadmap. Audit covers every effective `in_progress` / `PR_review` override, **not** all 234 backlog entries.
- Before: **32 `in_progress`**, **3 `PR_review`** = **35 stale work-status records**. A task can have partly merged code and still not have any work happening today.
- After: **29 `ready`**, **1 `blocked`**, **2 `merged`**, **2 `integrated`**, **1 `accepted`**; 0 retained `in_progress` / `PR_review` from the pre-audit snapshot. **Future genuine activity can and should have these statuses again**, with a current branch/PR as evidence.

These are workflow snapshots, **not** percentage-complete or proof of completed device QA. An agent's unpushed local branch cannot be proven absent from GitHub; tasks are reset to ready, not declared abandoned. The full story/playable Hall, original UPDS Match-3 presentation and exact HTML-v5 parity are still outstanding. Owner accepted the uploaded VN art separately; no new prop images are manufactured.

## Every reclassified task

| ID | Before | After | Basis and remaining gate |
|---|---|---|---|
| `VNS5-06D2C` | `PR_review` | `merged` | PR #120; merged implementation, not approved runtime scene |
| `PROC-003` | `in_progress` | `ready` | #55 pilot; #108/#109; security regression and distinct-origin preview |
| `RM-GAP-009` | `in_progress` | `merged` | PR #138; manual requirement acceptance remains open |
| `MOB-04` | `in_progress` | `ready` | PRs #108–#110; remaining ZIP attack cases and mobile QA |
| `CODE-02-01` | `in_progress` | `ready` | owner 2026-10-27; retest touch/mouse and donor parity |
| `CODE-02-03` | `in_progress` | `ready` | owner 2026-10-27; modal help, tutorial and visuals |
| `CODE-02-05` | `in_progress` | `ready` | owner 2026-10-27; one-tap route and UI regression |
| `CODE-02-06` | `PR_review` | `ready` | branch missing, no PR; Web/mobile swipe, hint and modal help QA |
| `GFX-08-06` | `in_progress` | `ready` | #82; catalog; source prompt/provenance completion |
| `GFX-08-07` | `in_progress` | `ready` | catalog 26/26; cross-state compositing technique |
| `VNS5-07F` | `in_progress` | `ready` | issue #129; native screenshot parity owner acceptance |
| `RM-GAP-013` | `in_progress` | `ready` | PRs #135/#136; full UI localization/device QA |
| `CODE-01-02` | `in_progress` | `ready` | PR #46; seeded donor parity |
| `CODE-03-01` | `in_progress` | `ready` | PRs #46/#112/#120; full VN controller and history QA |
| `CODE-03-02` | `in_progress` | `ready` | PRs #97/#123; pose-emotion state and motion |
| `CODE-03-03` | `in_progress` | `ready` | PR #112; Hall Tea parity, save, replay |
| `CODE-04-01` | `in_progress` | `ready` | PR #46; settings and locale UI |
| `CODE-05-01` | `in_progress` | `ready` | importer/tests; Hall geometry approval |
| `CODE-05-02` | `in_progress` | `ready` | route tests; no free-move route QA |
| `CODE-08-01` | `in_progress` | `ready` | PR #9; full season graph progression |
| `CODE-09-01` | `in_progress` | `ready` | catalog 26/62; stateful prop asset contract |
| `CODE-09-02` | `in_progress` | `ready` | PR #103; asset alpha-pivot and import QA |
| `CODE-10-01` | `in_progress` | `ready` | PR #127; cross-system device checks |
| `CODE-10-02` | `in_progress` | `ready` | CI/Web; offline and diagnostics |
| `GFX-00-01` | `in_progress` | `ready` | registry baseline; joint CODE/GFX acceptance |
| `GFX-00-02` | `in_progress` | `ready` | production catalog; all-domain asset inventory |
| `GFX-00-03` | `in_progress` | `ready` | catalog hashes; full format/metadata conventions |
| `GFX-00-06` | `in_progress` | `ready` | PR #103; ComfyUI sheet automation |
| `GFX-06-08` | `in_progress` | `ready` | PRs #112/#132; real character keyframe/animation QA |
| `GFX-06-09` | `in_progress` | `ready` | FX source; accessibility checks |
| `GFX-08-01` | `in_progress` | `ready` | Hall guides; final Hall footprint |
| `GFX-08-02` | `in_progress` | `blocked` | documented alternatives; owner production method decision |
| `DASH-RECON-01` | `in_progress` | `integrated` | PRs #137/#138; separate ongoing native QA |
| `PROC-DASH-V2` | `in_progress` | `integrated` | PR #137; unrelated roadmap QA not implied |
| `DASH-RENDER-01` | `PR_review` | `accepted` | PR #139; owner 2026-11-03; non-visibility site QA separate |

## Policy for future updates

1. `in_progress` requires verifiable **current** development (active PR branch/commit or explicitly declared local work, with date, owner and current evidence). Earlier merged/green CI on partial scope is **not** proof of present work.
2. `PR_review` requires a **currently open** PR linked in evidence. On merge/close, reconcile this status before treating `main` as the current snapshot. PRs #120 and #139 were merged but their tasks still said review.
3. `ready` means known residual scope with no active branch/PR; `blocked` means a named dependency or decision prevents next work; `merged` and `integrated` reflect shipped scoped implementation, **not** final game acceptance; `accepted` requires explicit user acceptance of that task's criterion.
4. Preserve `implementationState`, `qaState`, `approvalState` independently; do not use `in_progress` merely because `implementationState=partial` or `qaState=manual_pending`.
5. Dashboard now exposes separate **В работе** and **На ревью** counters. Zero means the source snapshot contains no verified active work, not that all planned work is finished. Re-audit these counters against live GitHub after PR merges.

**Rollback:** revert the progress overrides and dashboard counters/docs in this PR. No story, save, art, gameplay scene or Godot code changed.
