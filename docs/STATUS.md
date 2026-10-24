# Raven Manor — canonical project status

Last reconciled: 2026-10-24.

This file is the current status entry point for `RavenManor-Godot`. Historical audits and preserved Stage 1–3 source packages remain evidence, but they do not override this file or `DECISIONS.md`.

## Current repository state

- Godot 4.7.2 standalone project is present and imports successfully.
- `RM-HUB-001` PR 1 foundation is implemented: stable Raven IDs, snapshot v1, wallet, first-clear rewards, restorations, door/hotspot/clue/story state, idempotent reducer and separate save/recovery keys.
- `RM-HUB-001` PR 2 navigation greybox is implemented: `RM-ROOM-HALL` → `RM-ROOM-CORRIDOR` → `RM-ROOM-BEDROOM`, authored `AStar2D` graph, five interaction anchors, gated `RM-DOOR-CORRIDOR-BEDROOM`, foreground lintel, camera follow and reload-safe access.
- Prototype Lab is the main scene. Foundation and navigation can be tested independently or together through one Raven save.
- GitHub Pages is enabled with a pinned Godot 4.7.2 Web build and deploy workflow.
- `RM-VS-01` is implemented in Prototype Lab: early bedroom access, five VN beats, three deterministic Raven Match-3 levels, two restorations, one clue, first-night episode, shared save/reload and completed-state resume.
- Navigation anchors are explicitly marked greybox-only. A guard rejects any production-ready claim without approved room-art calibration metadata.
- Onoe walk sheets are authorized owner-created technical placeholders. They are not canonical Evelyn art.
- `https://github.com/bezdredoff/RavenManor` is the source of game-bible, narrative, design and source materials; this repository is the canonical Godot runtime and deployment layer.

## Verification evidence

- `check.ps1`: project import, all Raven script parses, foundation smoke, navigation graph/provenance smoke, Prototype Lab smoke and complete `RM-VS-01` flow/resume smoke pass.
- Local Web export produces `index.html`, JavaScript, WASM and PCK.
- GitHub Actions run `40123820130`: build and Pages deploy passed from `main`.
- Published Prototype Lab: <https://bezdredoff.github.io/RavenManor-Godot/>.
- Visual evidence: `docs/evidence/rm_hub_001_greybox_locked.png` and `docs/evidence/rm_hub_001_greybox_unlocked.png`.

## Audit interpretation

The imported 70-requirement audit reports 12 IMPLEMENTED, 30 PARTIAL, 6 PLACEHOLDER, 21 MISSING, 1 UNKNOWN and 0/13 verified `RM-VS-01` steps. Those numbers describe the earlier `UPDS-godot` repository before the standalone Raven foundation and navigation PRs. They are retained as a baseline, not presented as the current score.

A fresh requirement-by-requirement rerun is required after PR 3. Until then, do not silently edit the old counts or claim that the full vertical slice passes.

## Art and Character Cloner status

- The existing ComfyUI character PNGs are diagnostic prototypes, not approved Raven cast assets.
- `evelyn_neutral_00001_.png` was visibly rejected: later VNCCS output regenerated a different character instead of preserving the reference identity.
- Generated names such as Evelyn Blackwood, Lord Adrian Vale, Lucian Blackwood and Mara Bell do not replace canonical `RM-CHAR-EVELYN`, `RM-CHAR-ADA`, `RM-CHAR-LUCAS` and `RM-CHAR-ROWAN`.
- Installed VNCCS copies were documented as 3.1.2. Upstream 3.2.x/3.3.0 compatibility was analyzed, but no clean accepted reference-transfer run exists.
- Previous wrapper/full-flow results are diagnostic only. No output proves stable face, hair and clothing across poses/emotions.
- No shared character/background/prop style anchor board has been accepted.

Therefore mass character, room or prop generation remains blocked. Until canonical Evelyn art is produced in a later joint production stage, Onoe remains the explicitly non-canonical technical runtime placeholder. The next art action is later selection/creation of canonical Evelyn, one clean reference-transfer control, then a small cross-asset style board and Godot composite—not a batch.

## Current blockers

1. Browser/touch visual QA and GitHub Pages deployment of the merged PR 3 build remain to be confirmed.
2. No accepted canonical Evelyn identity reference or reproducible VNCCS result exists; Onoe is temporary only.
3. No accepted cross-asset style anchor board exists.

## Next milestone

Review and merge `RM-HUB-001` PR 3, confirm the deployed browser build on mouse and touch, then proceed to the narrow art-feasibility gate. Do not expand to the full season or mass art.
