# GFX-08-08 — Approved first-floor image: manifest and calibration scaffold
Task IDs: GFX-08-08 (references GFX-08-01/09/10; no broad closure)

Changes:
- Pinned the owner-selected root PNG by exact Git blob SHA, without changing its pixels or duplicating it.
- Added a versioned **draft** producer manifest of 8 world-plan rooms, 11 world-plan doors, current greybox anchors and proposed per-object foot pivots.
- Separated three coordinate spaces; left image raster dimensions, SHA-256, pixel mappings, foreground, masks and runtime gates unresolved rather than inventing data.
- Added source-byte hydration/validator and isolated unit tests.

Verification:
- GitHub metadata: blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`; file 3,126,732 bytes.
- Local 3 isolated Python unit tests executed PASS on synthetic fixtures (PNG CRC, projection inverse, IDs/path/hash/production gates).
- Real source-byte read: BLOCKED by connector binary content limitation. Exact pixel dimensions / SHA256 not observed; `--hydrate --strict` must run on a full checkout before merging final metadata.
- Godot/device/visual layer QA: NOT_RUN; GH Actions exact-head status pending.

Owner QA:
- Review the *actual* source image with room/floor/door annotations; accept control points, occluders, masks, and artwork provenance separately.
- Agent B/C must review schema and registration method before it becomes a shared consumer contract.

Status impact:
- New `environment-art` entry GFX-08-08: draft partial delivery; no geometry completion or productionReady.
- No other progress shard, scene, navigation, reducer, runtime, CI workflow or root original image changed.

## Visual follow-up 2026-11-08

Changes:
- Measured approved PNG exactly through Godot Runner: 1672×941, SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`; Git blob `b50bc36c...` unchanged.
- Added self-contained annotated reduced JPEG SVG `docs/audits/GFX-08-08-first-floor-visual-review.svg`, 10 coarse regions / 4 tentative visual fiducials. No physical pixel polygons or foreground masks claimed.
- Recorded 11 door/transition audit verdicts, six candidate fiducials, six occlusion review targets and critical 16:9 versus near-portrait old-world mismatch.
- Added fail-closed candidate-only export to Agent B v2 and Agent C v1 in `assets/raven/map/tools/export_first_floor_contracts.py`; no source pixels automatically become world-plan anchors.

Verification:
- Measured source by Godot 4.7.2 CI-run on exact original checkout: https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42503148980
- Unit tests and strict PNG/manifest validation: see exact-head CI evidence; do not claim runtime acceptance.
- Foreground masks, true character/player collision, floor navigation and user approval: NOT_RUN.

Owner QA:
- Confirm missing/unambiguous Hall↔Library, Hall↔Corridor, Corridor↔Bedroom, Hall↔Kitchen physical doors; decide whether art repairs are allowed.
- Confirm covered northeast room identity, stairs/elevation and Kitchen↔Orangery path.
- Approve landscape world-plan calibration with independently matched planar floor points.

Status impact:
- `GFX-08-08`: PR_review / partial, technical metadata measured; geometry, art layer extraction, A↔B/C consumer approvals remain pending; no productionReady or merged/accepted claim.

### Exact test execution — 2026-11-08
- Diagnostic GitHub Actions run [42504664754](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42504664754), source commit `6ef6bf45e433cbd6371dcd6d83ba572f5c9cb90b`: **7/7 Python tests PASS** in Godot Runner, strict real-source PNG/manifest check PASS (CRC, 3,126,732 byte length, source Git blob, SHA-256, dimensions, IDs, link references, 65° projection roundtrip). Adapter summary returns 11 blocked/uncalibrated doors and 13 unapproved anchors. This is tool/data QA, not gameplay/geometry QA.
- Original source PNG load and two review crops executed in [42503148980](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42503148980).
- Temporary `scripts/check.sh` invocation and one-time `probe_first_floor_png.gd` are intentionally removed from final diff after capturing evidence. All persistent code stays in `assets/raven/map/tools/`; regular CI wiring, if desired, belongs to integration/QA owner.
- **Agent B/C schema acceptance:** comments requested on #238/#240; C provided full 13-anchor requirement via #240, implemented here. Neither agent has signed off on painted door geometry.

### Reference contract approval after B/C merge (2026-11-08)

User approved contract reconciliation, not physical level geometry. Main now contains #238 navigation identity audit and #240 read-only Agent A v1 art import. A freezes original source SHA256/size, the eight room/eleven door/thirteen anchor identities and the absence of pixel→world transforms. `RM-DOOR-ENTRY-HALL.sourcePixelPoint` was nullified to meet merged B adapter; estimated front entrance [833,801] remains only in independent review landmarks. Production flags remain `false`. See `assets/raven/map/README.md` for exact handoff and explicitly deferred world-frame and physical map acceptance.

### Confirmed actual merged-consumer integration QA (2026-11-08)

- PR [#238](https://github.com/bezdredoff/RavenManor-Godot/pull/238) and PR [#240](https://github.com/bezdredoff/RavenManor-Godot/pull/240) both merged into `main@955f572a1c72675830cb19daa606b2615d18ef7c`. PR #239 branch merged this baseline without losing any unrelated changes.
- [GitHub Actions run 42506170859](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42506170859): all required CI jobs PASS; **11/11 art Python unit/integration tests PASS**, including exact approved-image A v1→B v2 direct adapter and `import_first_floor_draft.validate_first_floor`, SHA/drift negative tests, manifest reference checks and mandatory 13-anchor export gates; **native Godot C audit smoke PASS** with `idCount=13`, `calibratedCount=0`, `usableNavigationData=false`. Unregistered B draft has `navigationAnchors=[]`, `foregroundObjects=[]`, no pixel-to-world transform.
- New persistent A-domain tests: `assets/raven/map/tools/test_first_floor_consumer_bridge.py` and `test_first_floor_consumer_bridge.gd`. Test invocation was temporarily injected into `scripts/check.sh` to collect evidence and then fully restored to the unchanged main script; no shared CI/qa workflow modification remains in this PR.
- **Approval scope:** producer `raven.first-floor-art/v1` source-data contract and B/C unregistered/audit-only consumers approved for merge. The future `--target builder` registered geometry output remains fail-closed, and C's current `worldRect=[0,0,2150,2250]` freeze is a **known separate constraint** on any future landscape world-plan adjustment.
- **Still NOT approved:** actual painted door portals/thresholds, walkability, free-world geometry, screen projections into source PNG, all 13 navigation XY, foreground cuts/masks and visual/mobile runtime. GFX-08-08 remains `partial`/manual geometry QA pending; no silent domain or milestone closure.
