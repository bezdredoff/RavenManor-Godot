# MAP-QA-08A — story-aware navigation target contract

Task IDs: MAP-QA-08A (navigation calibration preparation); CODE-05-02 (P0 parent).
Changes: New standalone DRAFT_ONLY v1 story/POI inventory linking first-slice hotspots and later proposed scene beats to five room navigation islands; all image-pixel coordinates left explicitly null; 11 physical doors remain unresolved. Standalone full-image/CV agent brief; native Godot schema/provenance smoke and existing runner registration. Existing 22/19 baseline, approved art, navigation runtime and campaign remain unchanged.
Verification: MAP-QA-08A Godot smoke will validate story IDs, explicit five first-slice hotspot IDs, map-room IDs, unchanged source draft and unresolved portal IDs; runs once in scripts/check.sh. Exact-head CI not yet verified on initial authoring.
Owner QA: Manual physical PNG visual calibration NOT RUN. This is an evidence/requirements pass only; the subsequent MAP-QA-08B agent must inspect the actual image, generate new candidate room routes and validate Onoe before owner acceptance.
Status impact: Only manor-map domain progress shard updated. CODE-05-02 remains P0 partial; no promotion to accepted navigation, no runtime door geometry changes, no game progression edits.

## Baseline
- Main at branch creation: `d3e631b573839a3e5ca5a127e82c08a0c6cc861a` (PR #255 merged). No open PRs then.
- Source of story IDs: `data/raven/production/map_narrative_routes.json`; canonical overrides: `docs/DECISIONS.md` and `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md`.
- Source of physical topology: `assets/raven/map/first_floor_manifest.v1.json`; image blob b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563.
- Existing candidate `hall_routes_draft.v1.json` remains a historical/provisional QA baseline; MAP-QA-08B may discard its proposed extra route layout in favor of actual visual analysis.
- UPDS comparison: Raven-specific image-pixel POI alignment has no applicable UPDS feature; this PR adds no game UI or runtime component.
- Rollback: revert metadata/test/docs; existing room/map source and all game behavior stay untouched.
