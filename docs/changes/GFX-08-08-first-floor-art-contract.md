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
