# 13 — Stage 2 v0.2: decisions, risks and QA

## Decision register

- **[User approved 2026-10-24]** Hall distributes guests and has the grand staircase; west residential corridor connects private bedroom and bathroom and kitchen; library near ceremonial hall; kitchen links to conservatory; only western first-floor section is S1 playable; rest of mansion exists behind safe technical boundaries.
- **[Approved Stage 1 v0.5]** Six chapters, 24 story beat IDs, five vertical-slice task hotspots, three match-3, bedroom and bathroom core restorer tasks, no supernatural exposition in chapter 1, Ada only resident, Rowan lives separately.
- **[Stage 2 authored proposal]** Door state/anchor coordinates, corridor length, shared service wall plumbing, glazed kitchen→greenhouse portal and the exact greybox framing/camera.
- **[Unverified]** Exact epoch/architectural age of manor; size of foyer and corridor; dimensions/location of riser; garden topography; safety assessment timing; contractor schedule.

## Mandatory consistency / migration

1. Never rename or recycle any Stage-1 `RM-BEAT-*`, `RM-CH-*`, `RM-CHAR-*`, `RM-REST-*`, `RM-LVL-*` or `RM-HS-*` IDs.
2. `RM-ROOM-CORRIDOR` is new navigable support room; not a new chapter or count-breaking master story room. `RM-ROOM-ARCHIVE` remains canonical for library.
3. Physical links formerly from Hall direct to Bedroom/Bath/Kitchen/Conservatory are **removed**. Retain their `RM-EDGE-002/003/004/006` as retired non-reusable IDs and old door names as mapping-only aliases. No physically impossible direct Hall portals may be instantiated.
4. Stage-1 documents remain an immutable approved **narrative baseline**; if a tooling system needs a canonical physical edge for `RM-DOOR-HALL-BEDROOM`, resolve to `RM-DOOR-CORRIDOR-BEDROOM` via v0.2 migration mapping. This is an explicit architectural amendment, not an unrecorded retcon.
5. No single room may be restored by a narrative beat without registering `RM-REST-*` and saved state; no repair currency bypasses safety signoff.

## Source beat audit

Stage 1 currently uses `RM-ROOM-ENTRY`, `RM-ROOM-HALL`, `RM-ROOM-BEDROOM`, `RM-ROOM-BATHROOM`, `RM-ROOM-KITCHEN`, `RM-ROOM-ARCHIVE`, `RM-ROOM-CONSERVATORY`. All remain active. Transit-only `RM-ROOM-CORRIDOR` adds no new story beat. Room IDs are unchanged; physical navigation revised to corridor. Chapter-1 `RM-BEAT-01-03/04/05` remain in destination rooms as narrative contexts, with corridor-side setup and transition.

## QA: acceptance criteria for greybox

| check_id | observable pass condition |
|---|---|
| `RM-QA2-01` | All 24 beats have valid canonical room references; no retired parlor/gallery active. |
| `RM-QA2-02` | All physical door ends meet plausible walls; bedroom and bathroom doors open on corridor; archive opens from hall; conservatory from kitchen. |
| `RM-QA2-03` | Bathroom and kitchen share credible service wall/chase; private rooms have separate doors and privacy. |
| `RM-QA2-04` | `RM-HS-001..005` remain exactly five task hotspots; 3 Match-3 first clears yield total 6 points, spend 2+4 once. |
| `RM-QA2-05` | Arrival→hall→corridor→bedroom traverses through real anchors, no wall-crossing or hidden Hall→Bedroom edge. |
| `RM-QA2-06` | Upper floor/east wing/service wing inaccessible despite excess points; power/plumbing safety separate from story lock. |
| `RM-QA2-07` | Greenhouse path uses kitchen glass door + Rowan clearance, no Hall→greenhouse link. |
| `RM-QA2-08` | Foreground occlusion and portal state reversible, interrupt/reload safe; no duplicated first-night rewards. |
| `RM-QA2-09` | Portrait corridor keeps relevant task markers readable and character recenter accessible. |
| `RM-QA2-10` | Stage-1 legacy gate aliases migrate without new room or double-door; all remaining reference strings resolve. |

**Self-check:** requirements specified, document cross-links aligned. Spatial measurements and real character collision remain to be tested in actual Godot greybox; this text cannot certify runtime passage. **Stage 2 design ready for review**, not an assertion that greybox has been constructed.

## Risks and mitigations

- **R1:** corridor becomes visually monotonous → alcove, differing light and wall portraits, reuse module geometry.
- **R2:** rebuilding suite before physical entry feels artificial → preview cutaway work montage, explain Ada/key supervised preparatory access; reconsider gate only if user changes slice script.
- **R3:** bathroom far from water chase → deliberately align service wall to kitchen in schematic blockout.
- **R4:** access to greenhouse via kitchen seems too domestic for formal conservatory → give kitchen a side service vestibule at glazed threshold; no new master asset.
- **R5:** upstairs appears usable from hall → closed safety rail, warning from professional, no usable upper walkable zone.
- **R6:** narrative Stage-1 gate names differ from physical Stage-2 doors → documented alias registry and migration test.

**Next:** upon design approval, stage 3 reference/game comparison and scene/asset matrix; do not begin until approved.