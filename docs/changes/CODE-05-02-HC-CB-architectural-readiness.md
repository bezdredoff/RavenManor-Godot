# CODE-05-02 — HC/CB architectural readiness (09D owner decision candidate)

**PR:** https://github.com/bezdredoff/RavenManor-Godot/pull/278 (draft; unmerged)
**Domain:** manor-map · **Priority:** P0 · **State:** DRAFT_ONLY / partial, owner decision outstanding.
**Base:** main 0d1886b0d01491047dbd900b260757623c6ef9bc; reconciles merged #258/#261/#270/#272.

## Diff
- Added independent HC/CB architectural *review record* with source-PNG coordinates, physical constraints, proposed floor/wall/jamb/foreground layers and explicit production gate.
- Added two non-destructive, image-referencing before/after SVG crops; the approved PNG and 09B fixture remain unchanged.
- Added isolated Godot map-only smoke driving the **existing 09B TEST_ONLY** paired sill in both directions and refusing locked and disconnected movement; no controller/actor/scene changes.
- Reconciled the manor-map live shard only. No generated dashboard, CI runner, story, save, gameplay bridge, shared contracts or production geometry edits.

## Architectural outcome
CB wall cut at [528,376], 48px remains a concrete candidate **pending owner visual and mask approval**. HC under-landing path [824,400] cannot be certified as physically plausible: the central landing is painted, but underside/headroom and passage elevation are not demonstrated. A right-side x~992 shortcut crosses the recorded 09B stair NO-GO; do **not** invent a working hidden passage. Present HC structural underpass approval versus an explicit visible ground-level architectural rework as the owner decision.

## Verification and limitations
JSON contract/canonical G1 coordinates can be checked mechanically. New Godot 09D smoke is **authored but not executed in this connected environment**; shared check.sh registration is **not** part of manor-map ownership, so request Agent E/integrator to register and run it before treating CI as full new test coverage. Prior 09B smoke has historical passing CI; this does not prove 09D or final art. Binary approved PNG is referenced by SHA-256/blob but could not be rendered or pixel-inspected by this connected agent; original crop correctness/actual foreground appearance requires local owner/art review. No physical-phone QA, gameplay-integrated masks, 62px headroom, confirmed 65° scene occlusion or owner acceptance is claimed.

## Owner QA and dependencies
Open the SVGs from a local checkout; inspect HC elevation and structural section; approve/reject HC option or provide a visible alternative. Inspect CB cut, threshold and masks. **Agent B may not switch production navigation** until both owner decisions, rendered foreground/backfill, collision/route validation and device QA. Bedroom/bathroom independence remains untouched (RM-DEC-006).

## Rollback
Revert this PR. It changes only independent draft metadata, evidence SVG/README, one map test, unique change note and manor-map progress; original 08B/09B/09C, manifest, PNG and production systems remain intact.
