# MAP-QA-09 — physical door evidence review

Task IDs: MAP-QA-09 (first physical-door review slice); CODE-05-02 (partial P0 parent).

Changes: Reconciles merged #257 and the owner's explicit room-route/editor QA confirmation.
Independent 11-door review JSON, original-PNG contact sheet/evidence map and a crop/room-side
inspection panel inside the existing integrated QA scene. Existing room picker reflects
active QA room after reset. Manifest/art/topology/08B graph/campaign/save remain unchanged.
Historical 08B unapproved threshold guesses are retained as evidence, not real openings.

Verification: Targeted Godot 4.7.2 `map_qa_09_door_review_smoke.gd` EXECUTED_PASS.
Checks all 11 doors and available room-side approaches using the existing physical actor,
source refusal, room ownership, no mid-flight reset, invalid metadata rejection and unchanged
art/route/manifest. Prior QA/editor runner calls retained; new runner registered exactly once.
Full isolated runtime suite: 129 stages PASS, zero script errors. Full check.sh attempted:
existing Windows path-separator assertion in test_sharded_dashboard stops data phase.
Final panel changes rechecked by the targeted test. Native UI iterated after observing an
unrendered native subwindow: use embedded CanvasLayer and an opaque panel for readable crops
and controls. Exact-head CI will be recorded in the published PR. Local progress/code/dashboard
validators PASS.
Native desktop evidence: `docs/qa/map-qa-09/native-door-review.jpg`, final embedded inspector
shows the original entrance crop, unresolved contacts and disabled crossing with readable controls.

Owner QA: 08B room routes/editor confirmed in chat after merged PR #257. **No real door
threshold approval inferred.** All 11 remain UNRESOLVED, crossing disabled. Physical near/far
contacts, width, elevation, collision and foreground masks are absent/unverified. The enlarged
PNG and approved manifest show missing/ambiguous openings; architecture/art-layer decisions
are required before real crossing implementation. This PR does not close MAP-QA-09 or P0.

Status impact: Only manor-map shard updated. Verified #257 merge at main 20e17e1 and bounded
owner QA recorded; CODE-05-02 remains partial P0 while the new review slice is active.
No dashboard edits, production promotion, save migration, gate changes or auto-merge.

## Scope and reuse

- New door-review JSON; two Raven QA scripts; bounded `first_floor_integrated_qa.gd`
  panel/picker integration; new test and single check.sh registration; QA docs/images,
  docs INDEX, this evidence and own progress shard.
- Original PNG and magnified west-Hall / bedroom-partition / bath / stair-landing crops
  inspected. Approved manifest explicitly records apparent solid Hall↔Archive wall,
  unlocated bedroom opening and noncontiguous kitchen/glasshouse. No fabricated bridge.
- Donor `bezdredoff/UPDS-godot` HEAD reverified unchanged at
  `3deed628efd6c22bcd1717f7c545b7d3ca865781`. Previously inspected native
  `scripts/ui/main_menu.gd` blob `76e47a354b1ca42b4f029278382ad1e0070e7d09`
  `_ready`/screen actions use donor story/save systems, not Raven map evidence.
  Decision: not-applicable for this QA inspector; reuse existing Raven scene, source picker,
  graph/session/transition host/Onoe, Godot CanvasLayer/PanelContainer/AtlasTexture controls. No gameplay engine
  or controller is copied/replaced. Production game UI is unaffected.
- No schema migration: separate DRAFT_ONLY evidence format. Changing this JSON cannot
  grant movement authority; guarded loader rejects fabricated contacts/approval.
- Rollback removes the new evidence/panel/test hook. 08B accepted room graph remains intact.

## Published review

PR https://github.com/bezdredoff/RavenManor-Godot/pull/258 is open, not merged.
Own manor-map shard records PR_review with the real URL. Native entrance/Archive crop
inspection and the explicit Archive-side QA reset + existing route were observed;
these are not physical crossing or owner geometry acceptance. Final CI is recorded in PR.
