# 07b — Doors, traversal and portrait map | Stage 2 v0.2

**[Approved physical topology]** Hall→Corridor→Bedroom/Bathroom/Kitchen; Hall→Archive; Kitchen→Conservatory; grand stair and eastern wing locked. **[Proposal]** precise anchors and camera transitions. No full-size output art.

## Primary two-sided door — `RM-DOOR-CORRIDOR-BEDROOM`

- **Near:** `RM-ANCHOR-CORRIDOR-BEDROOM-APPROACH` conceptual (0.28, 0.47), clearance ≥ one avatar radius. **Far:** `RM-ANCHOR-BEDROOM-DOOR` conceptual (0.17, 0.75), inherited from v0.1; refine coordinates in greybox but keep IDs.
- **Unlock:** `RM-REST-001` completed, `RM-REST-002` completed, `RM-HS-004` journal recorded. Legacy identifier `RM-DOOR-HALL-BEDROOM` remains a narrative *alias*, not a physical edge.
- **`locked`:** approach near-side task marker only, no traversal; explain pending bedroom/bath/clue. **`closed`:** unlocked but panel shut, route to near-side anchor. **`opening`:** suspend collision across portal until frame clears, disable duplicate taps. **`open`:** linked navigation passes under corridor jamb foreground, camera pans to room landing; one Evelyn sprite only. **`closing`:** deactivate link only after actor clears opening.
- **Persistence:** `unlocked` and `door_visual_state` separate. Save crossing side/last safe anchor. On reload during opening/closing, restore unlocked-but-closed with avatar at last safe-side anchor; restore `RM-BEAT-01-05` event only once. Reverse travel uses actual opposite-side anchor.

## All physical thresholds and navigation responsibilities

| door_id | pair | starting presentation | two-sided traverse in S1? | special handling |
|---|---|---|---|---|
| `RM-DOOR-ENTRY-HALL` | RM-ROOM-ENTRY ↔ RM-ROOM-HALL | open after arrival | yes after gate | front double main door; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-HALL-CORRIDOR` | RM-ROOM-HALL ↔ RM-ROOM-CORRIDOR | open | yes after gate | west-wing hall arch/double door; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-CORRIDOR-BEDROOM` | RM-ROOM-CORRIDOR ↔ RM-ROOM-BEDROOM | two repairs + clue saved | yes after gate | private room door; VS portal; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-CORRIDOR-BATHROOM` | RM-ROOM-CORRIDOR ↔ RM-ROOM-BATHROOM | plumbing certified | yes after gate | near-bedroom sanitary door; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-CORRIDOR-KITCHEN` | RM-ROOM-CORRIDOR ↔ RM-ROOM-KITCHEN | first night; appliances gated by electrician | yes after gate | service-end doorway; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-HALL-ARCHIVE` | RM-ROOM-HALL ↔ RM-ROOM-ARCHIVE | photo entered in journal | yes after gate | representative library door; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-KITCHEN-CONSERVATORY` | RM-ROOM-KITCHEN ↔ RM-ROOM-CONSERVATORY | plant-map clue + Rowan certifies path | yes after gate | glazed service/garden door; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-HALL-EAST-WING` | RM-ROOM-HALL ↔ RM-ROOM-EAST-WING | never season 1 | no | future unpowered area; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-HALL-UPPER-FLOOR` | RM-ROOM-HALL ↔ RM-ROOM-UPPER-FLOOR | never season 1 | no | grand stair approach, not literal hinged door; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-KITCHEN-SERVICE` | RM-ROOM-KITCHEN ↔ RM-ROOM-SERVICE-WING | never season 1 | no | future scullery/pantry/service wing; independent near/far anchor, collision and foreground mask if traversable |
| `RM-DOOR-CONSERVATORY-GARDEN` | RM-ROOM-CONSERVATORY ↔ RM-ROOM-BACK-GARDEN | never season 1 | no | garden exterior threshold; independent near/far anchor, collision and foreground mask if traversable |

**Door alias migration:** keep `RM-DOOR-HALL-BEDROOM`, `RM-DOOR-HALL-BATHROOM`, `RM-DOOR-HALL-KITCHEN`, `RM-DOOR-HALL-CONSERVATORY` in legacy reference registry only; map these to `RM-DOOR-CORRIDOR-BEDROOM`, `RM-DOOR-CORRIDOR-BATHROOM`, `RM-DOOR-CORRIDOR-KITCHEN`, `RM-DOOR-KITCHEN-CONSERVATORY` respectively. Do not repurpose their string values as new real doors. Legacy `RM-EDGE-002/003/004/006` retired; never reuse their IDs. A story `next_gate` can remain a legacy label with explicit resolver table.

## Portrait-first floor traversal

**Prototype target [Assumption]:** logical viewport 390×844, adaptable safe areas; a corridor can be 2–3 vertical camera focus panels rather than one miniature full-floor map. Room compositions pan about 1.2–1.6 viewport widths; corridor navigates continuously, no instantaneous leap from Hall to Kitchen. A minimap can show accessible first-floor west zone only; do not expose future floor interiors.

| camera_preset | center/focus | mandatory visible affordances |
|---|---|---|
| `RM-CAM-HALL-HUB` | main stair + clock + west corridor mouth | west route and locked future wing visibly distinct |
| `RM-CAM-CORRIDOR-RESIDENTIAL` | bedroom and bathroom doors | both repair objectives, avatar, recenter |
| `RM-CAM-CORRIDOR-SERVICE` | kitchen door | kitchen objective and return direction |
| `RM-CAM-BEDROOM-REPAIR` | door cutaway / bed | silhouette change + clue insert without full traversal |
| `RM-CAM-BATHROOM-WORK` | fixture close-up | single repair stage and professional signoff |
| `RM-CAM-KITCHEN-REAR` | service counter and glazed door | greenhouse transition after safety gate |
| `RM-CAM-HALL-CLOCK` | grandfather clock | hands/clock repair story in CH05 |
| `RM-CAM-ARCHIVE-LEDGER` | shelf and table | clue + exit access |
| `RM-CAM-CONSERVATORY-PLANT` | bench and path | safe route vs blocked glass |

**Pan/zoom:** drag to local room bounds; auto-focus only when player taps a hotspot; button recenters camera to Evelyn; clamped accessibility zoom target ~0.9–1.25×. Touch targets at least 44 logical CSS px, no critical clue behind top/bottom VN UI. Jambs, columns, leaves and stair balustrade are foreground occluders with separated hit-test geometry. During occlusion show temporary avatar position hint. Never draw full upstairs/wing interior before unlock.

## First-slice traversable sequence

`RM-ROOM-ENTRY` → `RM-ROOM-HALL` → `RM-ROOM-CORRIDOR` → corridor-side bedroom/bath task hotspots → prep bedroom via insert + plumber bathroom vignette → journal clue → `RM-DOOR-CORRIDOR-BEDROOM` first crossing → first night. Exactly five **task** hotspots `RM-HS-001..005`; architecture door controls are not additional restoration/clue tasks. The corridor is freely traversable before bedroom becomes livable. First night's reward and narrative beat persist once; no repeat after reload.

## Greybox edge cases

- Load in the hall: NPC path cannot route straight through bedroom wall; it must use corridor first.
- Character at corridor intersection with three door faces: nearest anchored door identity wins; never traverse through closed one.
- Camera tracks real Hall→Corridor doorway, not a room jump; transition crosses threshold with door frame occlusion.
- Tap from far side after load or interrupted animation: no teleport, safe restore anchor, clear blocked text for locked door.
- Backtracking bedroom→corridor→hall→archive works without remounting story rewards.
- Kitchen→conservatory no traversal before Rowan certifies path, even if a plant-map clue has unlocked door inspection.
- Stair collision blocks access to unsafe upper flight; future locked spaces have no far-side arrival anchor.
- Small-screen task HUD does not hide bedroom+bath markers simultaneously in residential corridor focus.