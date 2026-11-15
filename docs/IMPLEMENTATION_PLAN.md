# RM-HUB-001 — implementation and acceptance record

- PR 1 foundation: merged, implemented, tested.
- PR 2 authored navigation: merged, implemented, tested.
- PR 3 integrated RM-VS-01: merged in PR #9, includes three Raven Match-3 levels, five VN beats, five task hotspots, bedroom/bathroom restorations, clue and resume-safe save.
- Isolated Content Preview: merged in PR #10.
- User accepted Prototype Lab on 2026-10-24.
- GitHub Actions Web export/Pages was verified at `d1a72298` for the accepted slice (historical milestone).

The imported 70-requirement UPDS audit is historical baseline, not an accurate post-PR3 score. The production greybox is **not** approved canonical art. Await first-season asset registry review and unified style lock. See `docs/STATUS.md`, `docs/NEXT_PLAN.md`, `docs/assets/`.

Implementation decisions stay in `docs/DECISIONS.md`: no free tap-to-move, authored navigation anchors, permanently available door after unlock, bedroom gate independent of bathroom repair, bath vignette, Onoe placeholder, human-readable modular documentation.

## Post-slice implementation (2026-10-25)

- `RM-MAP-S1` continuous world prototype/65° mobile HUD and calibration tests are on main, but continuous-world geometry is proposed and its grid preview does not replace the authored `RM-VS-01` navigation graph.
- PR #17 (Hall generated art comparison) is merged after correcting the smoke test for separate chair/table PNGs. AI1/AI2/PLAN/SVG visible in Whole Manor Map; 8 PNGs preserved at original dimensions, checksum manifest and reconstructed prompts in repository. This is exploratory compositing, not final alignment.
- PR #18 (Room Builder PWA v0.1) and #19 (Pages `/builder/` fallback fix) are merged and published; Android user confirms working access. Editor model/importer tests and Godot/Web CI passed, while exhaustive real-device QA, approved perspective transform and gameplay integration remain future work.
- The current actionable plan is `RM-PIPE-001`, documented in `docs/NEXT_PLAN.md` and `docs/ROOM_PIPELINE_NEXT_GATE.md`. It targets tablet composition → validated coordinate/ID mapping → independent layered Godot Hall test → constrained one-room art/state pipeline. **Do not silently replace canonical world data or runtime saves.**

## Narrative/gameplay sync (2026-10-26)

The latest story decisions are now mirrored into the Godot runtime without changing the save schema or stable progression IDs. `RM-VS-01` begins with inheritance/arrival, treats Match-3 as preparation work, keeps bedroom access independent from bathroom repair, makes the bathroom a specialist repair, reaches a first night with delivery while the kitchen is unready, and hooks next into kitchen plus Rowan/conservatory. Multi-speaker VN lines are supported. See `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md` and `data/raven/season1_narrative.json`.

This narrative sync is a guardrail for RM-PIPE work: Hall/room imports, generated art and navigation previews must not create or reorder story state outside the existing reducer/event contract.

## Production delivery snapshot — 2026-10-27 (code/art roadmap authority)

This document retains its `RM-HUB-001` historical implementation record. For **current Season 1 production**, follow `docs/production/CODE_PRODUCTION_ROADMAP_RU.md` and `docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md`; use `data/raven/production/code_work_packages.json` for task scope/dependencies and `data/raven/production/progress/<domain>.json` (15 live domain shards) for current state/evidence. Dashboard is generated, not authoritative; `production_progress.json` is a frozen historical snapshot.

- UPDS actual core imported with [PR #46](https://github.com/bezdredoff/RavenManor-Godot/pull/46); original board-shape/motion/tutorial/easing primitives merged with [PR #54](https://github.com/bezdredoff/RavenManor-Godot/pull/54) (**CODE-02-00 merged**). Full touch/input and animated Match-3 screen **CODE-02-01/02 still in progress**.
- Real phone ZIP-to-PR/CI evidence merged in [PR #56](https://github.com/bezdredoff/RavenManor-Godot/pull/56). `MOB-04` remains partial pending adversarial/phone artifact QA; `/preview/` is CI/artifact review, not a separate-origin playable game.
- Next code PR must extract reusable UPDS Match3Screen input/board cell presenter/cascade/HUD and connect it to Raven theme and existing reducer/saves without importing school-story progression. Parallel GFX-10 art still needs owner acceptance; combined CODE-11 × GFX-11 Hall pilot is the scale-out gate.


## 2026-11-15 — post-calibration implementation handoff

The historical PR 1–3 and 2026-10-27 roadmaps above remain provenance, not the next runnable work queue. For the **current** order, use [NEXT_PLAN.md](NEXT_PLAN.md). The verified main snapshot after #261 contains: separate MAP-QA-08B room routes (#257), physical-door evidence with unresolved real thresholds (#258), isolated hotspot→Match-3→VN QA (#259), fail-closed navigation source boundary (#260) and a distinct TEST_ONLY 09B four-opening architecture blueprint (#261). None enables production movement or approves structural art/occlusion/room-save support.

Next implementation contract: (1) owner/architecture review of HA/HC/CB/CK and floor/foreground/elevation, (2) single-writer bridge↔navigation-source adapter integration with safe checkpoint/Continue tests, (3) reviewed production source activation only after geometry/door/save-catalog approvals, (4) chibi Evelyn and portrait/mobile visual QA. Both the old proposed geometry and the QA in-memory gameplay loop remain independently revertible. Open status-reconciliation PR #262 (manor-map) and #263 (campaign-core) must be considered before updating their live shards.
