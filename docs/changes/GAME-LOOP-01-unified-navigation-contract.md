# GAME-LOOP-01 â€” G1 unified navigation source

Task IDs: GAME-LOOP-01; related CODE-05-02, CODE-07-02, CODE-11-01.

Changes: The hotspot gameplay bridge consumes one selected ManorNavigationSource instance. It no longer imports or constructs its own graph/session or chooses historical geometry. Source selection is one-shot, copies the request and owns one existing ManorNavigationGraph/ManorRouteSession pair. Refresh rebuilds gates on that graph; reload resets the same session from authored safe geometry. The GAME-LOOP-01A harness explicitly supplies `NavigationSource.historical_qa_request()`; this is TEST_ONLY independent-greybox geometry, requires QA mode and `allowQaCandidate: true`, and never selects 08B/09B by fallback. Missing/invalid requests and unapproved production geometry hold without graph/session or movement. Existing MAP-GAME-01A production validation and candidate transition controller/harness remain intact.

The additive v1 QA source variant returns `routeGraph` for the historical continuous-anchor graph. Existing candidate results still return `contract` for ManorRoomTransitionController. The bridge holds candidate/production transition contracts as `gameplay-transition-handoff-requires-G2`; this is an intentional G1 boundary, not a promise of production gameplay support. No flattened transitions, synthetic physical doors, second movement controller, or second save authority are introduced.

Arrival refreshes store gates/story, verifies the selected hotspot's current confirmed anchor, room membership, settled segment and route from the last confirmed safe point before proposing existing Director events. Locked edges still use RouteSession's direct-edge arrival recheck. Cancel/interruption remove pending actions; pause rejects dispatch/acknowledgement until resumed (the host must pause its existing mover too). Existing reducer/store remain the sole checkpoint/reward/story writers. RM-* identifiers, schema v1, VN/Match-3 UI and economy remain unchanged.

Verification: Godot 4.7.2 local headless GAME-LOOP-01A expanded smoke PASS, including actual F6 scene, physical Onoe legs, RM-HS-005 -> RM-LVL-001 -> RM-HS-002 -> RM-BEAT-01-02, duplicate first-clear/restoration prevention, failed writes/retry, stale story arrival, source rejection/opt-in, source/session identity across reload, locked door at request and mid-segment, pause/repeated commands/duplicate acknowledgement and safe reload fallback. Full isolated-worktree verification and exact-head CI will be recorded below. Shared runners are untouched: regressions extend the existing registered smoke. Initial smoke during unfinished asset import failed on missing imported textures; rerun after completed import passed.

Owner QA: NOT_RUN. Physical geometry/door/art approvals, real desktop/Web/touch, pause/input feel and production Continue remain pending. No acceptance inferred from headless checks.

Status impact: Only campaign-core shard; parent stays partial P0, pending owner approval. This PR supplies G1 contract integration, not G2 activation or Season 1 completion. No foreign shards or generated dashboard changes.

## Audit and source-pinned reuse

Baseline: origin/main `832657cbbed2511a38485ae869b9b021484eb7c8` (merged #266); verified #259 merge `9cfad9f4682f7598dc1fa94de908245f53e07914` and #260 merge `d2fd55625e6af1c7f8448cceb8458ada1d77b990`. GitHub open-PR search at audit returned none. Reviewed root/nested AGENTS, release G1/G2 plan, navigation and multi-agent contracts, gameplay integration, snapshot/reducer/store, existing source/graph/session/controller and both QA harnesses/tests. Concurrent VN edits later appeared in the shared checkout; G1 was moved to an isolated worktree from the baseline and excludes them.

Donor inspected: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`:

| Source path / blob SHA | Behavior / Raven counterpart | Decision |
| --- | --- | --- |
| `scripts/core/story_session.gd` / `ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02` | Injected store, reload, scene/line gate checks and save-failed signal; Raven Director + reducer/store + existing gameplay shell | adapter via existing Raven boundaries; donor scene indexes/content must not replace RM IDs or reducer transactions |
| `scripts/core/save_storage.gd` / `37201dfebbe11854a590ea717ff3b844d2b9c48b` | Key allowlist, temporary write/flush/rename, failed I/O return; Raven existing storage/store | reuse existing Raven storage adapter; no new persistence implementation |

Donor has no authored manor room/anchor/door navigation source. Selection glue is Raven-specific new code around existing graph/session and transition implementations. Existing shared UPDS VN/Match-3 adapters remain reused. No donor content/assets imported and no new parity claim for corrupt-save, locale/device UI or donor narrative. Existing failure/retry and RU/BE/EN unread Skip regressions remain exercised by GAME-LOOP-01A.

## Migration, fallback and rollback

No save migration. Existing persisted room/anchor resolves through existing graph safe-checkpoint rules; invalid, unsafe or unreachable positions use a reachable authored room-safe point (Hall fallback), without writing on load. Callers that previously relied on `Bridge.new(memory)` implicitly enabling greybox must explicitly pass `NavigationSource.historical_qa_request()`; raw graph overrides are now QA request fixtures only. This deliberate constructor tightening prevents accidental production QA selection. The shipped F6 harness and registered tests are migrated together.

Rollback: revert this PR's runtime/harness/test changes together. Saves and canonical catalogs need no repair. Production never gains a map switch from this PR.

G2 dependencies: owner-approved HC/CB geometry, calibrated room art/physical doors from Agent A; explicit production host selection and existing transition-controller handoff; atomic live Continue/New Game and VN/Match-3 return positioning; Agent C dispatch/readiness and any separately reviewed catalog/reducer changes; Agent D walker approval; Agent E integration/device QA and runner coordination. No reducer/store/catalog changes proposed here.

## Executed local checks (2026-11-16, isolated worktree)

Godot `4.7.2.stable.official.ed1daf0bf`, after `--headless --path . --editor --import`: PASS for `tests/raven/{game_loop_01a_hotspot_bridge,map_game_01a_navigation_source,manor_navigation_graph,game_loop_characterization,map_qa_06_room_transitions,map_qa_07a_multi_room,map_qa_07b_integrated_first_floor,map_qa_08b_visual_candidate,map_qa_09_door_review,map_qa_09b_opening_blueprint}_smoke.gd` using `--headless --path . --script <path> --quit-after 1500`. Parse checks (`--check-only --script`) PASS for navigation source, gameplay bridge and GAME-LOOP-01A harness. MAP-QA-06 reports its existing CanvasItem/resource cleanup warnings after the PASS marker; all ten exit 0 with no SCRIPT ERROR.

Python commands from `scripts/check_data.sh` executed individually: narrative validation (normal and `--release`), code plan, progress shards, gap reconciliation, backlog dependencies/workstreams/acceptance, dashboard `--check`, Hall-pilot unittest, PR-governance/UPDS-audit unittests and VNS5 contract unittest PASS. Broader local suite is NOT fully green: `test_sharded_dashboard` assumes `/` in Windows source paths; VNS5 staging reads UTF-8 using Windows cp1252; VNS5 readiness/locked-patch symlink cases hit WinError 1314 (missing local symlink privilege). No shared tooling was changed to mask these failures. Full Linux CI is the merge gate. Full `bash scripts/check.sh` NOT_RUN locally (bash unavailable on PATH); the existing runner registration is exercised by CI.
