# RM-ROOM-HALL — strict approval sheet v0.1 (REVIEW, NOT APPROVED)

Updated 2026-10-24. **Decision status: pending final owner approval.** This is the active proposed hall spec. Do not claim production art, pixel coordinates or architectural engineering are approved.

## 0. Authority and consistency
- Stage 1 v0.5: large family manor, hall clock, six first-season narrative spaces.
- Stage 2 v0.2: physical hall connections to Entry, Corridor, Archive, East Wing and Upper Floor; season 1 does not enter east/upper.
- Product owner selections in conversation: **grand ceremonial hall**, lived-in historic but **restrained small decoration**, **symmetrical bifurcated staircase**, **east-wing double door under central landing**, clock **left near Archive**, **two upholstered armchairs + small round table** near Archive, **eccentric yet aristocratic ancestor gallery**, **dark wood/burgundy/brass/cream stone**, **cream stone floor with dark geometric ornament and burgundy carpet**, **protective furniture covers on armchairs ONLY**.
- No generic “hall-to-bedroom” physical door. Library is `RM-ROOM-ARCHIVE`, not a new `RM-ROOM-LIBRARY` ID.
- Production anchor coordinates, dimensions, camera framing, actual art style, portraits and detailed repair transitions remain pending validation.

## 1. Spatial contract (required)
This is a *topological* composition, not a metric plan. Facing from the primary entrance into the hall:
1. Far center: high split/bifurcated staircase, two symmetrical flights and upper connecting landing, including balustrade, wall paneling and underside support.
2. **Below** central upper landing: large locked east-wing double door `RM-DOOR-HALL-EAST-WING`. Must have physically plausible usable clearance under the landing; do not simply place a door through stair structure.
3. **Left side / Archive approach**: grandfather clock + a separate seating cluster with two upholstered armchairs, small table and one nearby wall sconce. Both Archive portal and clock inspection anchor must remain clear.
4. **Right side**: entrance into residential corridor `RM-DOOR-HALL-CORRIDOR`, separate from east-wing entrance and its visual hierarchy.
5. Near primary entry: entrance hall console, mirror, umbrella/coat stand and letter/key tray. They must not overlap `RM-DOOR-ENTRY-HALL` approach.
6. Central ceremonial axis from entrance toward stair/door is **unobstructed**. Burgundy carpet occupies axis; avoid a freestanding giant display that obstructs player or occludes doors.
7. Upper floor `RM-DOOR-HALL-UPPER-FLOOR` remains visible from stair but physically unavailable due to structural/electrical safety. East wing same reason; no magical lock explanation.
8. The hall is a large vertical camera space; exact internal dimensions and on-screen visibility await Godot space calibration. Earlier “11×14m” is a **non-approved illustrative scale**, not canon.

### Walk/navigation acceptance
- No free tap-to-move; click hotspot or designated door target → use authored graph routes.
- Route coverage: Entrance ↔ center ↔ Corridor; center ↔ Archive; center ↔ clock; center ↔ ancestor picture; center ↔ stair/east-wing *inspect* anchors; center ↔ seating (only if interactive).
- Distinguish `door locked` from `door nonexistent`. Locked east/upper preserve inspect/locked feedback but never allow travel.
- Two seat silhouettes must not collide with clock, Archive threshold or route. Keep safe landing positions at every portal and hotspot.
- Foreground masks required for near-side stair rails/columns, arch trim, door frame and any furniture that can occlude chibi character.
- Door placement must be synchronized with Stage 2 canonical room graph; do not “fix” old Stage 2 source file silently—document overrides explicitly.

## 2. Asset manifest / placement (production families)
IDs below are **planning-only**. Existing `RM-ASSET-HALL-001..016` from the preliminary registry must be **mapped, not silently replaced**, before importing approved production assets. The `Hxx` keys in this document are approval-sheet local identifiers, not new runtime IDs.

| Local ref | Family / instance count | Location / cluster | Initial → later state | Layer and interactions | Status |
|---|---|---|---|---|---|
| H01 | Architectural room shell ×1 | whole hall: tall walls, moulding, oak panels, high ceiling, cream stone/dark geometric inlay | dusty → cleaned overlay; geometry fixed | base | Required |
| H02 | Split staircase ×1 assembly (two flights + landing + balustrade) | far wall | dusty → cleaned; upper access blocked both | base + near rail occluder | Owner selection |
| H03 | East-wing double-door ×1 | under central landing | closed/locked throughout S1 | midground + blocking/inspection | Owner selection |
| H04 | Entry portal ×1 | near front | passage accessible | portal + jamb occluder | Required |
| H05 | Archive portal ×1 | left zone | as story gate | portal + trim | Required |
| H06 | Corridor portal ×1 | right zone | accessible for slice | portal + trim | Required |
| H07 | Grandfather clock ×1 | left near Archive, **not** beneath stair | stopped dusty → clean stopped → repaired ticking/chiming | interactive separate animated hands/pendulum | Owner selection |
| H08 | Upholstered armchairs ×2 | left Archive seating zone, separated from clock | **both covered ONLY in abandoned state** → revealed/clean; later occupied by characters if scripted | furniture + removable textile covers + contact shadows | Owner selection |
| H09 | Small round tea/side table ×1 | between armchairs | dusty → polished; tabletop clutter varies | furniture | Owner selection |
| H10 | Large ancestor portrait ×1 | wall visible along ceremonial axis but no doorway obstruction | dusty → cleaned; optional later clue focus | wall art + inspectable if authored | Proposed focal art |
| H11 | Medium ancestor portraits ×3 | gallery grouped along side wall(s) | dusty → cleaned | wall art | Proposed count |
| H12 | Small/oval ancestor portraits ×2 | adjacent portrait cluster | dusty → cleaned | wall art | Proposed count |
| H13 | Brass chandelier ×1 | high center overhead, no hit targets | dim/off → lit; night grade independent | ceiling + lighting | Proposed |
| H14 | Matching wall sconces ×4 | paired circulation/portrait/seating zones | dim/off → lit | fixed + light FX | Proposed count |
| H15 | Burgundy ceremonial runner/rug ×1 | central circulation axis | partly rolled/skewed → properly laid | floor + overlay | Owner palette |
| H16 | Long entry console ×1 | near entry side wall | dusty/disordered → tidied/lived-in | furniture | Proposed |
| H17 | Wall mirror ×1 | above console | clouded → clean | wall/decor | Proposed |
| H18 | Coat/umbrella stand ×1 + 3–4 items | entry edge, out of portal clearance | dusty → tidied | decor grouped | Proposed |
| H19 | Key tray ×1, mail cluster ×1 | console top | loose notes → sorted/used | modular overlay; do not fake hotspot | Proposed |
| H20 | Vase ×1 and 1 small ornament ×1 | console OR table, not everywhere | dried/empty → refreshed | decor | Proposed restrained cap |
| H21 | Book/letter tray ×1 cluster | small seating table | dusty → neat; later active use | tabletop overlay | Proposed |
| H22 | Clock parts box ×1 | near clock service edge | closed/placed → opened/removed | story prop insert | Source-derived |
| H23 | Family crest / heraldic carving ×1 | over east-wing arch but below/around landing | constant | architectural focal detail | Proposed |
| H24 | Stair warning/repair notice ×1 | by blocked upper route | posted → still posted until later season | interactable warning | Proposed |
| H25 | Small stair-rail / arch foreground masks | near actor intersections | constant, depth tested | foreground alpha masks | Required technical |
| H26 | Light/dust treatment ×1 shared system | global and near windows | dim dusty → clean warm; reduced dust | atmosphere/shader | Required functional |

### Deliberate exclusions
- **No covers on console, clock, paintings, mirrors or all furniture.** Covers exist **only on two armchairs**.
- No separate clock gallery, no parlor, no walkable upper floor or east wing in S1.
- No giant decorative statue or extra central table interrupting movement.
- No large clusters of books/trinkets scattered uniformly across floor. Keep decorative families restrained.
- No added obviously monstrous portraits that spoil the gradual supernatural reveal. Eccentric compositional choices and subtly improbable clues are appropriate.

## 3. Ancestor portrait art contract
- **Tone:** eccentric but aristocratic. Oddly composed sitters, solemn faces with dry humor, eccentric accessories/poses; credible historic oil paintings and consistent frames.
- Gallery planning composition: **one hero, three medium, two small**. This count is a *proposal*, final approval pending owner review.
- Avoid caricature, overt magical transformation, explicit monsters and horror. The portrait must be believable as the family’s collected heritage on first visit.
- Use separate clean and dusty overlays; one portrait may be close-up inspection later if approved in a story beat. Do not bake narrative reveal into every portrait.
- Portrait subjects' exact appearances, time periods and any ties to existing cast are NOT yet approved; do not generate specific canonical ancestors without a follow-up approval.

## 4. State matrix
| Family | A: neglected | B: tidied | C: lived-in / clock repaired | Animation / event |
|---|---|---|---|---|
| Architecture & stair | dusty muted, undamaged load-bearing form | clean, same geometry | same geometry | dust fade, no staircase remodel |
| Two armchairs | **fabric covers on both** | covers removed, upholstery visible | clean / may be temporarily occupied in scenes | overlay switch + short dust FX |
| Small table | dusty empty/light paper | cleaned neatly arranged | one active-use book/tea tray cluster | low-cost overlay swap |
| Clock | stopped, dusty | clean, stopped | repaired, pendulum + hands moving, chime | independent 2D sub-rig + sound |
| Central carpet | rolled/skewed, non-blocking | laid correctly | remains laid | object state swap |
| Portrait gallery | dust/dim | clean and readable | same, selectively inspectable | highlight for authored clue only |
| Console | disordered papers | letters sorted | a few Evelyn everyday items | small prop overlay swap |
| Chandelier/sconces | low or off | partially usable | warm light on, independent night grade | shader/light fade |
| East-wing doors | visibly locked | locked | locked | no unlocked presentation this season |
| Upper stairs | unsafe/no access | no access | no access | warning/blocked response |
| Other doors | governed by progression | as unlocked | may remain visually open once unlocked | no repeated open/close clips |

State composition is **orthogonal**: restoration, time of day, narrative reveal and interaction availability do not require fully separate room master paintings. Do not conflate repaired clock with cleanup of whole hall; the hall should be clean before clock repair.

## 5. Required animation / technical exports
- Clock pendulum loop, clock hands advancing, optional winding/repair reveal/chime cue; record audio separately.
- Light-on fade for chandelier + four sconces using shared shader/lighting data.
- Removable armchair covers: two before/after layers with optional short transition, not complex physically simulated cloth.
- Dust overlay before/after; ambient dust motes optional and limited.
- Inspect highlight for clock and approved ancestor art. Do not advertise decorative paintings as interactable if they lack corresponding beat/hotspot.
- Room layers: `base_architecture`, `floor_rug`, `door_portals`, `major_furniture`, `decor`, `story_props`, `foreground_occluders`, `repair_overlays`, `lighting`, `atmosphere`.
- Asset acceptance fields per exported item: source, reference/provenance, frame count, native master dimensions, expected on-screen scale, anchor/pivot, depth policy, normal+clean state links and naming manifest.

## 6. Acceptance checklist (room can only be APPROVED after this review)
- [ ] Owner confirms composition of 5 portals/directions and central under-landing east-wing double doors, and physically plausible landing clearance.
- [ ] Owner confirms clockwise order of clock vs seats vs Archive door in left-hand zone after perspective drawing. Current spec fixes *same zone*, not exact meter coordinates.
- [ ] Owner confirms gallery count **1 large + 3 medium + 2 small** and specific presentation of ancestors.
- [ ] Owner confirms chandelier + four wall sconces and practical light placement.
- [ ] Owner confirms whether secondary console/mirror/coat stand/crest/warning signs are all desired.
- [ ] Godot author makes a greybox overlay with actual proposed door widths, approach anchors, camera framing and both map-scale character sizes.
- [ ] Every portal/hotspot path remains traversable in authored graph; locked wings do not appear accessible.
- [ ] Before/after restoration communicates meaningful improvement without unexplained architecture/furniture replacement.
- [ ] 390×844 and narrow/tall portrait camera proof; foreground crossing proof.
- [ ] Exact implementation sprite bounds/anchors reserved before large art production.

## 7. Approval consequences
- This sheet currently records **owner-selected art direction and proposal details**, not a final sign-off.
- Upon explicit owner approval, record approval date + version, then migrate the approved object-state mapping into `docs/assets/ROOM_OBJECT_REGISTER.csv`; keep `RM-ASSET-HALL-*` IDs stable and map new H keys to those IDs.
- Do not start mass room asset generation from this draft. Pilot one composited scene only after owner accepts the sheet.
