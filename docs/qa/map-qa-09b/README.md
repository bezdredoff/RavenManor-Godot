# MAP-QA-09B — editable opening and connecting-floor blueprint

Base main `dbe864f416300397a50620a97456a58f38ede93d` (#258 merged).
This is an **AI_PROPOSED_ARCHITECTURE / DRAFT_ONLY** greybox layer over the approved PNG,
not a claim that the painted walls already contain openings. The owner authorized proceeding
from door evidence to concrete placement proposals; final architecture/art acceptance is
still separate. No production graph, art file, story flag or save is changed.

## Concrete placement proposal

See [full blueprint](opening-blueprint.jpg). Blue polygons are NEW proposed floor/backfill;
gold marks an opening; purple dashed lines are concepts without runtime movement.

| ID | Door / shared sill px | Proposal and art cost |
|---|---|---|
| HA | Hall ↔ Archive `(608,608)` | Cut a 48px opening through the west partition and provide short clear floor approaches. New jamb/foreground and wall backfill required. |
| HC | Hall ↔ Corridor `(824,400)` | A 48px passage **under the landing**, approached via the left side of the flower table, then north. Blue column replaces hidden wall/landing pixels only in the prototype. Real elevation, backfill, support structure and stair foreground need an art/architecture decision. |
| CB | Corridor ↔ Bedroom `(528,376)` | New 48px opening in the bedroom partition. Existing physical-jam narrative gate stays external and independent of bathroom repair. |
| CK | Corridor ↔ Kitchen `(1112,480)` | New service vestibule along the **western edge of the covered northeast room**. Requires moving the covered cabinet/foreground prop, painting new floor and enclosure, then opening the kitchen's north wall. It does not unlock the covered room as a playable room. |

These are inspectable proposals, not final artwork. The original PNG is immutable and the
accepted 08B JSON / 09 evidence remain byte-for-byte unchanged.

Kitchen ↔ Conservatory remains **NEEDS_FLOOR_REVEAL**: purple concept north through a
separately designed service passage and then toward exterior glasshouse access. Its floor,
sill, garden/elevation and plant clearance are not visible enough to invent a runtime graph.
Entry needs stair elevation; Bathroom remains corridor vignette. East wing, service future
rooms and upstairs stay closed. No new topology/room IDs are silently made canonical.

## Editable source and runtime

`assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json` is RouteDocument v1:
**34 waypoints, 29 cell-authored bidirectional routes, 15 WALKABLE polygons (10 proposed
patches + 5 existing envelopes), 19 NO-GO**. All new geometry has AI_DRAFT provenance.
Existing routes are resampled onto the supported **8px grid, origin [4,4]** so old 08B
points remain exactly in place while the new threshold routes have enough precision.
No NO-GO was removed to force a path through existing furniture.

Optional `sharedDoorContacts` pairs two differently room-owned Door Approach IDs at
one global image-pixel point. This metadata creates no graph edge by itself. Ordinary
route edges still cannot connect different rooms. Freehand may touch both room boundaries
only at an exactly coincident paired endpoint; the rest of the stroke remains room-owned
and subject to all WALKABLE/NO-GO/cell constraints. Old v1 files require no migration.

The existing QA adapter creates **8 TEST_ONLY directional transitions**, gates **closed
by default**. Each handoff has identical approach/entry XY. Onoe physically walks to the
sill, the existing controller switches room graph at that exact point, and selecting a
destination then walks away on the new graph. No actor teleport or second movement engine.
Source/target contacts must coincide before an edited draft can run; a mismatched pair
fails closed with an explicit error. No campaign flag unlock is emitted.

The code-native overlay reads the editable floor polygons and contact waypoint positions;
it is not a hidden collision layer. Width/normal metadata draws the proposed gold jamb
markers; it is not an additional hard-coded movement restriction. Gold markers are not
production foreground masks. Final body occlusion / elevation / masks are not proven by
the greybox and must not be inferred from passing movement tests.

## Review in Godot

1. Navigation / Routes → **Load 09B opening blueprint**. Inspect/edit all 15 WALKABLE and
   19 NO-GO polygons, paired points and route cells. Source 08B stays separately selectable.
2. Save a user draft for experiments; project export targets the selected 09B file.
   Moving a threshold requires keeping both room-owned contact points aligned and
   redrawing affected route cells as necessary. Deliberately incomplete edits may be
   saved but QA refuses a noncoincident handoff. Undo/Redo and AI-clear remain available.
   Delete connected routes first, then a threshold waypoint; its pairing is removed
   automatically, so no JSON edit is needed to remove a proposed contact.
3. F6 `first_floor_integrated_qa.tscn`, explicitly choose **09B opening blueprint** or
   **Saved user**. The opaque blue floor patches are intentional new-architecture markers.
4. Select a proposed contact in the new row → **QA open + cross proposed sill**. This
   opens only that TEST_ONLY gate. Check slow approach and room switch with no position
   jump. Choose a waypoint to walk clear of the sill. Use the reverse contact to return.
   **QA close gate**, Pause/Resume and Cancel should behave normally.
5. HA starts in Hall; HC gets to Corridor; CB branches to Bedroom; CK reaches Kitchen.
   All four QA gates closed initially; future doors and purple concepts have no crossing.
   Legacy mock-transition buttons are hidden in this source and remain available in old sources.
6. Review whether HC underpass and CK vestibule are acceptable architecture, not only
   whether the actor can walk. HC needs stair-foreground/elevation design; CK needs prop
   relocation/enclosure art. Reject or reshape these before any production promotion.

## Verification

- New native smoke drives both directions of all four contacts using 0.025s substeps,
  checks max movement 3.25px/step across every handoff (no relocation), allowed floor and
  ≥12px feet-proxy NO-GO clearance; gates initially locked, closure mid-approach, Pause/Resume.
- Save/load round-trip, edited user draft, aligned-room checks, wrong-room metadata and
  mismatched physical contact rejection, freehand shared seam, editor source selection,
  AI clear/Undo; accepted 08B source unchanged.
- Local isolated runtime suite completed 130 stages with zero SCRIPT ERROR; final additions
  rechecked by targeted tests. Full local check.sh / exact-head Linux CI results in PR.
- Tests prove only the declared greybox plane. Production masks, projected elevation,
  final character overlap, tablet/phone view and owner approval remain pending.
- Native desktop source selection and Hall→Archive sill handoff observed:
  [screenshot](native-blueprint.jpg). This confirms the greybox UI, not final architecture.
- Full local `bash scripts/check.sh` attempted: the existing Windows backslash assertion
  in test_sharded_dashboard stops data phase; local progress/code/dashboard validators PASS.

Rebuild the diagnostic image using `python -X utf8 docs/qa/map-qa-09b/build_blueprint.py`.
Rollback removes the new proposal source/overlay/QA hook and optional authoring metadata;
old 08B and 09 workflows remain independent. CODE-05-02 remains partial P0.
