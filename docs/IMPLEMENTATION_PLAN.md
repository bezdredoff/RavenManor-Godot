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
