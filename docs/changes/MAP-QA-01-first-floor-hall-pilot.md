# MAP-QA-01 — isolated first-floor Hall calibration pilot

Task IDs: **MAP-QA-01** (bounded QA experiment supporting **GFX-08-08**, CODE-05-01, CODE-05-02; no task closure).

Changes:
- Added a source-image-pixel-only Hall pilot JSON with seven footpoints, seven authored undirected edges, one lower Hall walkable polygon and five explicit no-go polygons.
- The approved original root PNG remains untouched. The image is already in perspective: no second 65-degree transform is allowed.
- Kept all 13 canonical RM-NAV identity/room/kind references without copying canonical world/greybox coordinates. The Hall→Corridor QA portal is explicitly virtual, missing its far-side coordinate, and cannot change door gates.
- Added original-image HTML overlay and isolated Python/Godot data validation; no scene/player controller/store/Room Builder changes.
- Unique handoff documentation: `docs/MAP_QA_01_HALL_CALIBRATION.md`.

Verification:
- Baseline: `main@8d0207f0e473644de6564a57b0ad990a85b3908f` and successful `https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42510547439` (seven jobs) before this PR.
- Image metadata: approved 1672×941, SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`, blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`, previously verified by #239 GitHub Runner.
- Source-level route sampling before uploading JSON: PASS (all seven points and seven segments inside draft walkable polygon and outside no-go zones, 13 refs present).
- New Python/Godot targeted validation: **NOT_RUN locally in a full GitHub checkout**, requires commands in handoff; do not confuse creation of test files with execution.
- Exact-head GitHub Actions: **PENDING** until PR is opened and CI completes.

Owner QA:
- Visual Godot 4.7.2 review at full PNG resolution of all footpoints, conservative walking polygon and stair/tea/planter avoidance, and 390×844 / 412×915 / 430×932 plus tablet.
- Confirm virtual QA portal does not appear as an actual painted Hall→Corridor door; real Corridor far-side/registration and masked foreground remain unapproved.
- No approval of pixel→world transformation, production collisions, foreground masks, gameplay movement or art rewriting.

Status impact:
- `GFX-08-08` remains **partial**, geometry owner/manual QA pending; reference-only schema from #239 remains the approved scope. MAP-QA-01 is isolated follow-up evidence, not a new canonical source task or completed runtime feature.
- Update only `environment-art` progress shard; no other domain shard, frozen progress snapshot, generated dashboard or shared gameplay/CI files touched.

UPDS reuse:
- **Not applicable** to static Raven-specific map image-pixel calibration data and overlay. Existing Raven Onoe/RouteSession hosts are referenced only; no new animation, gameplay, input or shared component implemented.
