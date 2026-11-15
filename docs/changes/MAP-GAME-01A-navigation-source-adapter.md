# MAP-GAME-01A — navigation-source adapter and integration harness

Task IDs: MAP-GAME-01A (bounded gameplay-integration slice); CODE-05-02 (partial P0 parent).

Changes: Adds an explicit, versioned navigation-source boundary
(`scripts/raven/manor_navigation_source.gd`) and an isolated gameplay harness
(`scripts/raven/manor_gameplay_integration_harness.gd`). The adapter separates
`production` and `qa` modes; the shipped canonical greybox resolves to
`unavailable_geometry` plus a hold object and can never enable movement. QA mode
requires `allowQaCandidate: true`, delegates to the existing MAP-QA-07B/08B
adapter and remains `TEST_ONLY` / `DRAFT_ONLY` / image-pixel. Production mode
requires `PRODUCTION_APPROVED`, `productionReady`, world-plan coordinates, an
approved room-art calibration with hash/version, save-catalog rooms, approved
visual specs and a controller-valid transition contract. Restoration-gated
edges, unknown doors, unsupported rooms and unresolved transition approaches
fail closed. The harness composes only the existing
`ManorRoomTransitionController` + `OnoeSegmentMover`, rejects arbitrary screen
or ground points with `free-tap-to-move-disabled`, and exposes room/camera/
checkpoint proposals without owning a Camera2D or writing a save. New smoke test
covers canonical fail-closed, QA opt-in, valid 08B load, invalid QA document,
unsupported room, missing visuals, invalid transition, restoration edge, saved
room/anchor fallback, real Onoe movement, TEST_ONLY handoff and snapshot
non-mutation. Only `scripts/check.sh` is shared: one smoke registration and the
two new runtime scripts added to the existing parse loop. No production scene,
map, catalog, save schema, reducer or store is changed.

Verification: Local Godot 4.7.2 headless: new
`tests/raven/map_game_01a_navigation_source_smoke.gd` PASS; both new scripts
`--check-only` PASS; existing `manor_navigation_graph_smoke`, MAP-QA-06,
MAP-QA-07B and MAP-QA-08B smokes PASS after a one-time native project import
(`--editor --quit`). MAP-QA-06 exits non-zero locally only from pre-existing
CanvasItem/resource leak warnings after its PASS line. `json.load` validates the
updated `manor-map` shard. Exact-head Linux GitHub Actions verification will be
recorded on the PR after publication; no unexecuted CI success is claimed here.

Owner QA: Manual desktop/mobile hotspot input, camera follow feel, octilinear
art alignment, physical door/footpoint and foreground clearance remain pending.
MAP-QA-09 must approve door thresholds and near-/far-side footpoints before a
production graph can be connected. Actual `production` movement stays disabled
until code-owner geometry approval and an approved room-art calibration exist.

Status impact: Own `manor-map` shard only; `CODE-05-02` remains partial P0 /
`PR_review`. MAP-GAME-01A is a bounded technical slice, not a new canonical
backlog ID, and no task is marked accepted. No merge, no P0 closure, no real door
promotion, no production map replacement.

## Scope and non-goals

- Does **not** replace the production map, alter the shared save schema, add a
  second save authority, invent door connectivity or enable free tap-to-move.
- Does **not** apply the saved production room/anchor to QA candidate geometry;
  QA starts at the candidate's own authored start.
- Does **not** add archives/kitchen to `foundation_catalog.json`. Production
  rooms absent from the save catalog are rejected as
  `unsupported-save-catalog-room:<id>`.
- Does **not** support restoration-gated navigation edges: the existing
  `ManorRoomTransitionController.configure()` rebuilds gates with
  `completedRestorations: []`, so such edges are rejected rather than silently
  mis-gated.

## Versioned contract

Request (`raven-navigation-source-request`, schemaVersion 1):

```
{
  "schemaVersion": 1, "kind": "raven-navigation-source-request",
  "mode": "production" | "qa",
  "snapshot": { ...raw campaign snapshot... },
  "allowQaCandidate": false,
  "qaSourceKind": "project" | "user",
  "qaSourcePath": "",
  "worldPlan": { ...optional approved world plan for fixtures/validation... }
}
```

Result (`raven-navigation-source`, schemaVersion 1) always carries `ok`,
`status`, `reason`, `blockers`, `approval`, `draftOnly`, `productionReady`,
`movementEnabled`, `freeTapToMove: false`, `inputPolicy:
"authored-hotspot-only"`, `snapshotMutation: false`, `saveAuthority:
"raven_campaign_store"`, `coordinateSpace`, `contract`, `visuals`, `starts`,
`initialRoomId`, `initialAnchorId`, `spawnFallback`,
`spawnFallbackReason`, `savedPositionApplied`, `hold` and `source`.

Statuses: `ready`, `unavailable_geometry`, `invalid_route`, `invalid_source`,
`invalid_request`, `qa_requires_opt_in`.

Safe start resolution (`resolve_snapshot_start`): unknown saved room → first
authored room safe anchor with `unknown-saved-room`; invalid/unsafe/unreachable
saved anchor → that room's safe anchor with `invalid-saved-anchor` /
`unreachable-saved-anchor`; empty saved anchor → normal room start. The returned
proposal is never written by this adapter.

## Harness boundary

- `configure(source, snapshot)` accepts only a ready source; production gates
  are rebuilt from the authoritative snapshot.
- `request_hotspot(id)` and `request_transition(id)` delegate to the existing
  controller; `request_screen_point(point)` always fails.
- `advance()`/`drive()` run the existing Onoe mover deterministically.
- `commit_transition()` delegates the physically-confirmed handoff.
- `room_state()`, `camera_proposal()` and `checkpoint_proposal(event_id)` are
  proposals. A host must persist checkpoints through
  `raven_campaign_store.gd` + reducer; the harness has no store reference.

## UPDS reuse decision

Donor: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`
(the same pinned donor used by the merged MAP-QA-02/06/08B slices). The donor
has no authored manor navigation source, room-transition or hotspot route
controller; its Onoe VN portraits are not walking movement code. Reuse
decision: **not-applicable** for this boundary. Raven's existing graph, route
session, transition controller, Onoe mover and MAP-QA-07B/08B adapter are
reused unchanged. No donor story, save, asset or UI logic is imported.

## Dependencies and gates

- **MAP-QA-09**: physical door thresholds, near-/far-side footpoints, locks and
  foreground occlusion. Until approved, `production` movement remains
  unavailable and QA transitions stay `TEST_ONLY` mocks.
- **Owner geometry approval**: `PRODUCTION_APPROVED` world plan and approved
  per-room art calibration. The canonical greybox is intentionally unapproved.
- **Save catalog**: `RM-ROOM-HALL`, `RM-ROOM-CORRIDOR`, `RM-ROOM-BEDROOM`,
  `RM-ROOM-BATHROOM`. Archive/Kitchen production geometry cannot be connected
  without a reviewed catalog/save decision.
- **Restoration edges**: unsupported until the controller accepts
  snapshot-derived `completedRestorations`.
- **Input gap**: existing MAP-QA-03 supports desktop/touch drag-pan and wheel
  zoom but no pinch zoom; this slice does not add mobile camera gestures.

## Files and rollback

New: `scripts/raven/manor_navigation_source.gd`,
`scripts/raven/manor_gameplay_integration_harness.gd`,
`tests/raven/map_game_01a_navigation_source_smoke.gd`.
Shared coordinated edit: `scripts/check.sh` (one registration + parse list).
Evidence/status: this record and `data/raven/production/progress/manor-map.json`.
Rollback is deleting the two scripts, smoke and registration and reverting the
`CODE-05-02` evidence entry; runtime behavior is otherwise unaffected.

## Review and PR evidence

Branch: `agent/manor-map/MAP-GAME-01A-navigation-source-adapter`, based on
`main` `20e17e1` (PR #257 merged). PR URL and exact-head GitHub Actions result
are added here after publication. This PR must not auto-merge.
