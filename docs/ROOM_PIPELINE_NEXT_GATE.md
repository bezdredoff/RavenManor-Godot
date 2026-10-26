# RM-PIPE-001 — Touch-authored Hall to calibrated Godot scene

**Status:** planned (2026-10-25), not yet implemented/approved. **Goal:** a Room Builder scene authored on Android becomes a repeatable editable layered Godot Hall preview, then a controlled ComfyUI art input and independently interactive stateful room scene.

## Existing evidence

- Published Room Builder `/builder/index.html` and `tools/room-builder/`: drag/stamp, layers, imported images, per-object IDs/state fields, local IndexedDB, JSON/PNG exports; `scripts/raven/tools/import_room_builder.py` makes standalone **DRAFT_ONLY** Godot scenes with no runtime integration.
- `RM-ROOM-HALL` is a proposed part of `data/raven/season1_world_map.json`; pilot world rectangle **(500,150,700,690)**. Current Room Builder example is **1000×800 plan-space** with illustrative items and is not a calibrated scene. Do not naïvely add one coordinate system to the other.
- The working continuous map uses 65° floor elevation and 0.74× portrait framing, independent of `data/raven/manor_greybox_graph.json` (accepted vertical-slice navigation); AI1/AI2 assets are not aligned, SVG/plan modes remain useful controls.
- Canonical content references include `docs/assets/ROOM_OBJECT_REGISTER.csv`, `docs/assets/ROOM_FURNISHING_AND_PLACEMENT.md`, `docs/assets/RM_HALL_GENERATED_ART_INTEGRATION.md`, and `docs/assets/CHARACTER_PRODUCTION_BIBLE.md`.

## 1. Editor usability and project data contract (P0)

Capture at least one real Android tablet test and one narrow phone emulation/device check:
- S Pen/touch single selection, move and stamp; two-finger pan and pinch; no context menu or mandatory shortcut.
- Import one PNG and a small sprite sheet; delete/reorder/lock layers; undo/redo; switch state; export JSON, reload browser, import JSON and compare objects/asset IDs/coordinates/embedded pixels; export PNG.
- Check Chrome PWA install and offline reopening **after a successful online load**; record app/version/device/browser and screenshots. Explicitly test IndexedDB persistence and mention storage eviction. User confirmed accessible app, but no full interaction matrix is yet documented.
- Correct example data's **assetRefId semantic mismatch** (e.g. sample armchair points at the Hall console registry ID) rather than blindly trusting draft references; asset-instance IDs must be stable. Separate authored actual placed instances from reusable asset-family IDs.
- Document custom image rights and use only owned/test/public-domain art in test payloads.

## 2. Coordinate and content contract (P0)

Define one versioned mapping `roomPlan → world` with explicit origin, scale, handedness, rotation policy and stable reference corners. Do not silently fit all independent X/Y coordinates or stretched square artwork to the Hall footprint. Author must approve the overlay before data becomes a navigation input.

For every placed object record/validate:
- `instanceId`, `assetRefId` (known registry ID where applicable), `roomId`, `layerId`, visual `state`, rotation, dimensions, draw order, source path/provenance.
- Floor-contact **foot pivot** distinct from 2D sprite center, bounds/blocker shape where needed, interaction anchor and `RM-HS-*` link, optional foreground occlusion polygon/mask.
- Structural doors/portals must remain aligned to the authoritative world map; missing/unrecognized IDs and furniture occupying door threshold must fail validation.
- Separate logical states (`dirty`, `clean`, `repaired`) from purely visual display; preview mode cannot award restoration or alter campaign save.
- Existing accepted navigation graph remains authoritative for the VS; full-map feasibility is separate. Show proposed collision overlays without replacing either one.

Minimum automated checks: schema version/invalid refs/duplicate IDs, round-trip coordinates & states, door seam tolerances at fixed anchors, asset provenance, layer order/foot pivots, no changes to original `season1_world_map.json` and `manor_greybox_graph.json`, Godot project import/test/export. Draft preview must remain independently deletable.

## 3. Spatial calibration of Hall (P0)

Owner-reviewable input:
- Floor plan plus preview with split staircase, locked double doors under the central landing, Entry at front, Archive/library left, residential Corridor right.
- Clock at left near library; two separately movable armchairs and round table, burgundy runner, one ancestral gallery focal element; useful circulation width and legible hotspot anchors at 390×844.
- Show actor feet, furniture footprints/alpha, and 65° perspective with 0.68×/0.74×/0.80× zoom comparison. Capture from the actual game to ensure that portals, blockers, hit targets and foreground occlusion line up.
- Keep source PNG/AI1/AI2/SVG/PLAN references intact until new geometric composite is accepted.

**Approval gate:** owner acknowledges revised plan, mobile view, paths and clickable anchors. This is distinct from approving art style.

## 4. Controlled illustrative assets and restoration (P1)

Use a fixed layout conditioning reference plus exact mask/edge/depth controls when comparing Qwen/local ComfyUI workflows with alternatives. Record workflow file/version, model/LoRA references and license, seed, prompts, source refs, generation date, accepted/rejected outputs and alpha/pivot tests.

Prove one architecture-only image (no furniture baked in), clock, TWO independent instances of the chair and separate table, one restoration-relevant furnishing with **old/dirty → clean/repaired** states. Keep object shape/footprint fixed across variants. Add lighting and contact shadows/depth masks only after test-scale portrait readability.

No mass generation, unlicensed uploads, undocumented regenerated history or claims of automatically matched geometry.

## Exit checklist

- [ ]  Real-device input+offline+JSON round-trip evidence.
- [ ]  Mapping data contract with tested dimensions, asset/hotspot IDs and isolated Godot draft import.
- [ ]  Layout accepted after 65° mobile view and all three door connections/path checks.
- [ ]  One layered Hall composite where each major object is independently movable/restateable and actor visibility behaves correctly.
- [ ]  Reproducible art provenance and one successfully switched restore state without affecting game save in preview mode.
- [ ]  Final review decides whether to scale to Bedroom or require another calibration pass.

## Projection editor pilot (0.3.0)

The current 65° Godot floor transform now powers Room Builder's default editable view with inverse picking and exported image dimensions. This completes a **projection-math pilot** only. The default Hall example remains 1000×800, whereas the Godot whole-season Hall is 700×690; the PWA does not distort an old room to hide that mismatch. Align a backed-up fresh Hall draft to Godot reference dimensions, then address asset pivots, foreground masks, true independent seats, fixed doorway seams and in-engine parity before marking `RM-PIPE-001` finished.

## RM-PIPE-002: actual Builder-to-Godot scene importer

The new `import_room_builder_game.py` generates a separately runnable Godot scene that matches the Builder's 65° floor projection and supported PNG sprites; imported user art is extracted and genuine but unapproved states remain visibly marked. It validates the proposed world room bounds; no test actor placement, navigation graph or physical collision is transferred. The sample export is now exercised in Godot CI and reviewable in Prototype Lab entry 6. Next milestone is approving a real tablet-exported Hall and bringing its accepted render layer into the live map. See `docs/ROOM_BUILDER_TO_GODOT_IMPORT.md`.

## Next gate after live import (RM-PIPE-003)

Generated Builder Hall .tscn is displayed directly in the live Whole Manor Map, with fail-closed geometry validation, preserved AI1 comparison and unchanged gameplay obstacles. Before changing physical geometry, calibrate five real door pixel openings, both stair marches, occlusion masks and prop pivots against game screenshots. See `docs/HALL_LIVE_IMPORT_PARITY.md`.

## RM-PIPE-004 · calibration diagnostics and test-only seats

The Hall now supports a world-source-validated portal/stair overlay and a strictly opt-in 3-object footbox navigation experiment that keeps the canonical combined seats blocker by default. Godot tests check footprint containment, route safety and toggling back; image-door/stair visual alignment and architecture masks remain unapproved. Acceptance detail: `docs/HALL_VISUAL_CALIBRATION_PLAN.md`.
