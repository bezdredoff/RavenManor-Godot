# RM-CAT-001 — First-season room inventory ↔ Room Builder PWA

**Status:** production **proposal**, not approved imagery or geometry. Updated 2026-10-25. Code implementation in Room Builder v0.2; manual Android acceptance remains pending.

## Inventory

`docs/assets/ROOM_OBJECT_REGISTER.csv` is the authoritative human-maintained list. It contains **120 uniquely identified planned positions** across eight first-season spaces. Original 117 proposals were preserved and three explicit Hall seating positions were added:

- `RM-ASSET-HALL-017` — first armchair beside the library (covered / dusty / clean).
- `RM-ASSET-HALL-018` — second armchair beside the library (same reusable `RM-FAMILY-VICTORIAN-ARMCHAIR` and pilot PNG as 017, **separate instance ID**).
- `RM-ASSET-HALL-019` — small circular table between them (dusty / polished).

Counts: Entry 8, Hall 19, Corridor 12, Bedroom 16, Bathroom 12, Kitchen 18, Archive 16, Conservatory 19. These are **catalog positions**, not numbers of sprites or physical items: some legacy rows group several lamps, shelves, plants, or cups. A total of **245 textual planned-state labels** appear across the 120 rows, *not* 245 distinct PNG export obligations.

Every row is still `source_status=PROPOSED`; even rooms that render on the current map require further approval of object scale, positioning, style and variants. `P1` and `P2` represent production ordering, not approval status.

## Derived read-only web catalog

Run from repo root:

```bash
python3 scripts/raven/tools/build_room_catalog.py
python3 scripts/raven/tools/build_room_catalog.py --check
```

Generator inputs: CSV; deterministic fields include `id`, `roomId`, `name`, `anchor`, `states[]`, `layer`, `priority`, `approval`, `familyKey`, `plannedInstances`, `pilotImages[]`. The output `tools/room-builder/catalog/room-items.json` is copied to `builder/catalog/room-items.json` for the alternate Pages publisher. CI checks equivalence to the CSV and both static mirrors. **Never hand-edit generated JSON:** change the CSV and generator metadata overrides together.

A record with `pilotImages` has source concept PNG(s) available in `assets/raven/hall/generated_pilot/`; it does **not** certify those images as production-ready or all states generated. Seven Hall catalog positions reference preliminary art (clock, portrait composite, console, runner, two armchair instances, table); only six distinct prop cutout source files are referenced. Two other original Hall backgrounds are comparison room images, not individual standalone catalog props.

## Room Builder behaviour

- Select the named room in the catalog panel; switching saves and retrieves **per-room drafts** locally in IndexedDB (`room:RM-ROOM-*`) while retaining the prior `current` key for backwards compatibility. New rooms start empty with **placeholder 1000×800 plan coordinates**, not a fabricated approved blueprint. Existing older user scenes and imported PNGs remain in place.
- Asset palette filters catalog positions by room and displays count, `P1/P2`, experimental PNG-vs-placeholder status; reusable starter tiles and local PNG imports remain available in every room.
- Selecting an inventory item places an independent `object.id`, with `assetRefId=RM-ASSET-*`, first **planned state** and appropriate draft layer; inspector offers actual enumerated states for that position. Duplicating furniture keeps its family/item meaning but gives it a distinct instance ID.
- No generated concept PNG is automatically loaded or falsely represented as a finished sprite. All catalog artwork on the canvas is schematic. The image reference paths are metadata only; the existing isolated PNG import continues to support owned images.
- JSON/PNG export remains **per room**. Importing older JSON projects is supported, and missing catalog entries are merged non-destructively when possible. The browser does not send anything to GitHub and does not modify a Raven save.

## Gaps that remain before production

1. Approve actual room footprint, each object's source/anchor, instances and cross-room reuse. In particular `exampleProject()` is explicitly illustrative; Hall structural door/seating coordinates are not pixel-certified. `ROOM_FURNISHING_AND_PLACEMENT.md` still contains legacy placement proposals and should not override `docs/DECISIONS.md` or the in-game route graph.
2. Replace schematic sizes with agreed authoring units / floor-contact pivots, blockers, masks, draw order and hotspot mapping. Standalone `import_room_builder.py` outputs **DRAFT_ONLY** scenes without canonical navigation/collision/state integration.
3. Normalize grouped entries to true asset families where needed (e.g. paired bedside tables, several wall lights, three plant families); do **not** automatically multiply PNG counts from a slash-delimited list of planned states.
4. Define state-to-art mapping per object (standalone PNG, overlay, lighting toggle, procedural effect, in-scene logic). `covered`, `dirty`, `clean`, `working`, `repaired`, `open`, etc. have different technical implementation needs.
5. Complete real Android S Pen/touch/offline/large-image retention QA, Godot 65° spatial calibration and final art style review. User confirmation that the prior Room Builder v0.1 opens and works is not the same as comprehensive v0.2 device acceptance.
6. Track asset license, prompt/model/seed/reference hash, state images, production progress and provenance in a future asset-manifest stage after the one-room proof. Do not assume absent images exist.

Next engineering work: `RM-PIPE-001` in `docs/ROOM_PIPELINE_NEXT_GATE.md`. None of these catalog additions alters canonical `manor_greybox_graph.json` or `season1_world_map.json`.

## v0.2.1 hardening and completeness pass (2026-10-25)

- Every one of the 120 positions now has explicit machine-readable `artStatus`, `rightsStatus`, `spatial` (`width`, `height`, `footPivot`, `occlusionMask`, `interactionPoint` all `null` until measured) and one `stateAssets[]` entry per planned state (`renderMethod=undecided`, `approved=false`). This makes missing production decisions visible without inventing a final sprite/pivot/art method.
- Room Builder reports the count of **distinct planned catalog positions present on the draft canvas**, not the total physical quantity or number of PNGs. Optional **only unplaced** filter makes it practical to review an individual room's checklist, leaving reusable local tiles available when the filter is off.
- Old v0.1 Hall sample positions are safely migrated **only when they match the exact illustrative coordinates**; custom user placements are not reinterpreted. Hall left/right chairs retain separate IDs but one shared concept art family.
- Personal imported images are now available when switching to another room, and saving is serialized by immutable room snapshot. A failed save blocks room switching instead of silently discarding changes.
- JSON import explicitly preserves prior draft first, then resets undo history across rooms; PNG export awaits embedded image decode before rasterizing. Catalog-linked RM-ASSET-ID is read-only in the inspector to avoid breaking registry references; decorative/manual shapes may still have free-form IDs.
- The service worker cache version is bumped so `/builder/` receives the updated catalog and editor together. Both deployment methods must include identical files.

**Still deliberately unapproved:** actual world dimensions, geometric placement, state-specific artwork, interaction anchors/trigger IDs, source license acceptance, final per-room unique art counts. The 120 rows form a complete **planned inventory baseline**, not a claim that production assets exist. Do not infer or fabricate approved values solely to complete a table.