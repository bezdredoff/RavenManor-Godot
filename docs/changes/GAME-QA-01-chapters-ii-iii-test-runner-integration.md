# GAME-QA-03B — Mandatory Chapter II–III smoke registration

Task IDs: GAME-QA-01 (registered qa-infrastructure task); GAME-QA-03B is a follow-up delivery label.
**PR dependency:** stacked onto [GAME-QA-03 #294](https://github.com/bezdredoff/RavenManor-Godot/pull/294) at `28fc69fa80694ceede97d4c25f160e581fcb8aeb`; `main` baseline `32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a`.
**Governance:** integration branch because `scripts/check.sh` and `check.ps1` are shared CI runners; no gameplay, scene, canonical data, assets, workflow or other domain shard edits.

Changes: Register one existing standalone Chapter II–III smoke in both mandatory runners.

## Changes
- Register existing standalone `tests/raven/vn_chapters_ii_iii_production_gate_smoke.gd` **exactly once** in both required local runners, next to `vn_production_runtime_dispatch_smoke.gd`.
- Validate the test's precise success line via the normal `run_check` and `Invoke-GodotCheck` expected-output assertions.
- No second test system; #294 remains the canonical QA test and acceptance matrix.

Verification: Exact-head CI PENDING; local Godot and PowerShell NOT_RUN.

## Verification
- **Read-only source verification:** both runners previously omitted the script. Each now invokes the standalone script with `--quit-after 240` and checks its exact success marker.
- **Standalone Godot 4.7.2:** NOT_RUN locally: the connected execution container has no Godot executable/repository checkout; network clone fails DNS.
- **Linux full suite / exact-head GitHub Actions:** PENDING after stacked PR is opened. Do not treat existing green #294 Actions as proof this standalone test ran.
- **Windows PowerShell / Windows Godot:** NOT_RUN: `pwsh` and Windows Godot are absent; static command registration is not execution evidence.
- **Portrait PR #292:** OPEN as of 2026-11-18. Test recalculates real missing-art conditions from sources and remains fail-closed; no fake accepted asset and no production scene promotion.

Owner QA: Pending exact-head executed Godot logs; physical-device and game acceptance NOT_RUN.

## Owner QA
Pending: exact-head Linux GitHub Actions log must show the new test's execution and PASS text. Phone, normal player-facing Hall Tea navigation, Web/offline and Windows require independent evidence; none is accepted here.

Status impact: GAME-QA-01 remains PR_review / partial; no acceptance or merge.

## Status impact
The registered GAME-QA-01 entry remains `PR_review` / partial until the integration suite actually passes and the owner verifies the merged result. Do not auto-merge. Revert this branch to remove runner registration without modifying the QA test in #294.
