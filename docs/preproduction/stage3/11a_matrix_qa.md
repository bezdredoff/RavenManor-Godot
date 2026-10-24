# 11a — Matrix QA

- Source: **24** Stage 1 v0.5 beats, **15** Stage 2 v0.2 hotspots.
- Matrix: **31** rows = 24 one-to-one original beat rows plus 7 restoration views. Restoration view shares existing beat ID by design; **a repeated beat_id is not a new beat**. Use `(beat_id, source_provenance)` as compound row identity until a separate `RM-VIEW-*` registry is approved.
- Unique beat coverage: **24/24**. No new story beats introduced.
- Room reuse measured as count of source story beats per room; not a count of finished drawn assets: {'RM-ROOM-ENTRY': 1, 'RM-ROOM-HALL': 5, 'RM-ROOM-BEDROOM': 2, 'RM-ROOM-BATHROOM': 1, 'RM-ROOM-KITCHEN': 5, 'RM-ROOM-ARCHIVE': 5, 'RM-ROOM-CONSERVATORY': 5}.
- Character participation measured as beats containing character: {'RM-CHAR-EVELYN': 24, 'RM-CHAR-LUCAS': 7, 'RM-CHAR-ADA': 10, 'RM-CHAR-ROWAN': 7}.
- `new_assets`, lighting, camera, pose and motion fields are **provisional asset families**, NOT verified shot-by-shot approved art requirements. Room states and risk text inherit upstream authored data. A production artist must validate actual variants.
- Highest risk: hands interacting with clock/key/plant/glazing, cross-door mask and NPC repair animations; use close-up prop insert or cutaway first.