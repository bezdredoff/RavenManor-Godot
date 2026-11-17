# CODE-05-02 / MAP-CHAPTERS-01 — Chapter II–III spatial access audit

**Task IDs:** `CODE-05-02` (registered manor-map parent, partial P0); `MAP-CHAPTERS-01` (P1 scoped delivery label; **not** a separate registered task or progress entry).  
**Domain / branch:** `manor-map` / `agent/manor-map/CODE-05-02-chapter-ii-iii-spatial-readiness`.  
**Base:** `main` `32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a` after verified merged PR #291, Nov 17 2026.  
**Changes:** read-only audit of Entry, Corridor→Kitchen CK, Hall→Library/Archive HA spatial dependencies; explicit scene→room/door/prop/NPC/QA-anchor mapping; geometry/footpoint/65°/NO-GO/save/return/foreground review matrix; staged activation and test commands. Reuse already-authored 09B QA-only HA/CK blueprint; **no new QA geometry fixture**, because 09B is sufficient for the technical preview and Entry lacks a credible approved exterior crossing.  
**Owner QA:** expansion architecture **NOT_APPROVED**, phone/browser/physical return **NOT_RUN**; HC/CB V4 visual approval RM-DEC-031 is *not* HA/CK/Entry approval.  
**Verification (this PR):** GitHub API source/read cross-check completed. Local Godot 4.7.2, check.sh, device and exact new-head GitHub Actions: **NOT_RUN / PENDING** until CI executes. Do not label tests as PASS solely from reading them.  
**Status impact:** only `data/raven/production/progress/manor-map.json` CODE-05-02 updated, keep `implementationState=partial` and broad parent `priority=P0`. The historical `PR_review` references to #278 were stale: [#278](https://github.com/bezdredoff/RavenManor-Godot/pull/278) **merged** as `2484f59afd542ce8640c1f9020c49d2109f854c9`; [#290](https://github.com/bezdredoff/RavenManor-Godot/pull/290) **merged** as `28064c09da7cf451b6812974a6374b2bc2624328`; [#291](https://github.com/bezdredoff/RavenManor-Godot/pull/291) **merged** as `32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a`. Their merge status **does not** mean new rooms approved. New PR enters `PR_review` only after the actual Draft PR URL exists.

## Verified observations

1. `data/raven/manor_production_candidate.v1.json`: **119 anchors** only in Hall 58, Corridor 41, Bedroom 20; **120 edges**, of which exactly **4 directed cross-room edges** are HC and CB reverse pairs. New three rooms have no production anchors/safe room starts/visual calibration; inherited 09B Kitchen/Archive polygon records in `physicalConstraints` do **not** enable them.
2. `data/raven/foundation_catalog.json`: production-known rooms only Hall/Corridor/Bedroom/Bathroom; production-known doors HC/CB. Planned `RM-ROOM-ENTRY`, `RM-ROOM-KITCHEN`, `RM-ROOM-ARCHIVE`, `RM-DOOR-ENTRY-HALL`, `RM-DOOR-CORRIDOR-KITCHEN` and `RM-DOOR-HALL-ARCHIVE` are manifested **reference IDs**, not presently registered in the reducer/store ID catalog. Any production migration is integration-owner-only and requires new provenance/approval.
3. `map_narrative_routes.json` & `vn_chapters_ii_iii_readiness.json`: `RM-BEAT-02-02..03-04` use proposed `npc_tap`, `object_tap`, `specialist_result`, `door_tap` gates; no permission to activate from visual map targets. `story_props.json` registers `PROP-HOUSEHOLD-LEDGER`, `PROP-FAMILY-ALBUM`, `PROP-LIBRARY-DESK` etc but all relevant `existingHotspotId` values are null, thus explicit integration mapping required.
4. `assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json`: HA paired contact [608,608] and CK paired contact [1112,480] in *image-pixel*, each `TEST_ONLY` and `physicalPortalApproved=false`. Prior technical QA smoke checks 48px proposed threshold/no-jump and 12px foot proxy, **not** physically accepted openings. The Entry source is exterior stairs/elevation and the story POI is unlocated.
5. `docs/DECISIONS.md`: RM-DEC-030/-031 owner approval is **only** HC/CB V4. `manor_production_acceptance.v1.json` still says `physicalDeviceVerified=false`, `finalG2Acceptance=false`. No new art, SHA/receipt, reducer/store, game host, VN cue, story ID or production route changed.

## Diff boundary

**New:** `docs/production/CHAPTERS_II_III_MAP_ACCESS_READINESS.md`, this change record.  
**Updated:** only `data/raven/production/progress/manor-map.json`.  
**No other files changed.** Protected original PNG, approved Evelyn, HC/CB production candidate/receipt/activation switch, `raven_ids.gd`, reducer/store, `raven_player_map.gd`, `manor_navigation_source.gd`, canonical VN staging/cues, shared CI workflows and 09B QA fixture remain untouched. No save-schema migration. UPDS-first: **not applicable to a documentation-only Raven-specific map-geometry audit**; existing Raven source/QA tooling reused, no new gameplay/UI implementation.

## Verification commands for reviewer

~~~sh
python3 scripts/raven/tools/build_g2_production_candidate.py --check
godot --headless --path . --script res://tests/raven/map_qa_09b_opening_blueprint_smoke.gd
godot --headless --path . --script res://tests/raven/map_game_01a_navigation_source_smoke.gd
godot --headless --path . --script res://tests/raven/game_loop_g2_production_integration_smoke.gd
godot --headless --path . --script res://tests/raven/vn_chapters_ii_iii_readiness_fixture.gd
python3 scripts/raven/tools/progress_shards.py
python3 scripts/raven/tools/build_production_dashboard.py --check
bash scripts/check_data.sh
RAVEN_SKIP_DATA_CHECKS=1 bash scripts/check.sh
~~~

All commands are **NOT_RUN in the GitHub-only authoring environment**; CI evidence must be collected at the exact Draft PR head. Review unchanged G2 source snapshot (3 operational rooms, only HC/CB) and failed-open protection for HA/CK/Entry. Device tests and future owner geometry review are separate.

## Follow-ups / rollback

1. **Integration owner:** catalog/save and story-to-hotspot mapping contracts only through a separate reviewed PR, coordinating VN-GATES-01 and VN-HALL-TEA-01. No new authority.
2. **Map owner/artist:** new overlays, route/collision and door-specific owner review for HA, CK and exterior Entry; physical 65° foreground/headroom/cabinetry/elevation evidence. Each production geometry change requires new SHA/provenance and dedicated owner activation signoff.
3. **QA:** bidirectional open/locked/relocked, pause/replan, 12px feet and full-body foreground, zero-jump, saves/Continue/unknown-room failure, three locales, desktop/browser/phone real run.

**Rollback of this PR:** revert docs and the single manor-map progress-shard update; it is behavior-neutral. Do not auto-merge.
