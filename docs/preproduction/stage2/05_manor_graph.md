# 05 — Manor graph | Stage 2 v0.2 (architecture approved)

**Provenance:** [Approved by user] old mansion, western portion of FIRST floor only, hall → residential corridor, bedroom/bath adjacent, kitchen at service end → conservatory, library near hall, visible grand staircase and locked future wings. [Proposal] precise physical layout and door placement below, to be verified in greybox. Stage 1 v0.5 is the frozen narrative baseline; this is a **Stage-2 spatial overlay**, not a silent rewrite of its IDs.

## Physical plan (topology, NOT a scale drawing)

```text
                       FRONT STREET / DRIVE
                                |
                           ENTRY/PORCH
                                |
+------------------------------------------------------------------+
|                   GRAND HALL / STAIRS UP (LOCKED)                 |
| LIBRARY ← door        grandfather clock    → EAST WING (LOCKED)  |
|                                |                                 |
|                      WEST RESIDENTIAL CORRIDOR                    |
|                         /        |           \                  |
|                BEDROOM      BATHROOM         KITCHEN              |
|            (private door)  (wet wall)       (service end)         |
+--------------------------------------------------|---------------+
                                                   |
                                            GLAZED VESTIBULE*
                                                   |
                                              CONSERVATORY
                                                   |
                                           GARDEN (FUTURE)
* architectural threshold within door composition, NOT a new master room.
```

Realistic assumptions: bedroom and bathroom share plumbing wall with the kitchen/service plumbing run, possibly via service chase; they have separate corridor doors, not bathroom access through sleeping room. Kitchen receives goods from service-side exterior/future scullery; library near ceremonial hall, no direct bedroom or bathroom doorway. Rear conservatory glazed link must be weatherproof, may include shallow vestibule cut, not a magical portal. Stairs lead physically upstairs and are blocked *beyond* safe landing due to structural/wiring issues; downstairs remains usable. Daylit routes do not require live lights. This is a plausible retrofit of an older mansion; no precise historical floor plan is claimed.

## Edges and doors

| edge_id | door_id | from_room_id | to_room_id | unlock (and prior visibility) | reuse / purpose |
|---|---|---|---|---|---|
| `RM-EDGE-001` | `RM-DOOR-ENTRY-HALL` | `RM-ROOM-ENTRY` | `RM-ROOM-HALL` | open after arrival; visible door/threshold initially except concealed garden side | front double main door |
| `RM-EDGE-009` | `RM-DOOR-HALL-CORRIDOR` | `RM-ROOM-HALL` | `RM-ROOM-CORRIDOR` | open; visible door/threshold initially except concealed garden side | west-wing hall arch/double door |
| `RM-EDGE-010` | `RM-DOOR-CORRIDOR-BEDROOM` | `RM-ROOM-CORRIDOR` | `RM-ROOM-BEDROOM` | two repairs + clue saved; visible door/threshold initially except concealed garden side | private room door; VS portal |
| `RM-EDGE-011` | `RM-DOOR-CORRIDOR-BATHROOM` | `RM-ROOM-CORRIDOR` | `RM-ROOM-BATHROOM` | plumbing certified; visible door/threshold initially except concealed garden side | near-bedroom sanitary door |
| `RM-EDGE-012` | `RM-DOOR-CORRIDOR-KITCHEN` | `RM-ROOM-CORRIDOR` | `RM-ROOM-KITCHEN` | first night; appliances gated by electrician; visible door/threshold initially except concealed garden side | service-end doorway |
| `RM-EDGE-005` | `RM-DOOR-HALL-ARCHIVE` | `RM-ROOM-HALL` | `RM-ROOM-ARCHIVE` | photo entered in journal; visible door/threshold initially except concealed garden side | representative library door |
| `RM-EDGE-013` | `RM-DOOR-KITCHEN-CONSERVATORY` | `RM-ROOM-KITCHEN` | `RM-ROOM-CONSERVATORY` | plant-map clue + Rowan certifies path; visible door/threshold initially except concealed garden side | glazed service/garden door |
| `RM-EDGE-007` | `RM-DOOR-HALL-EAST-WING` | `RM-ROOM-HALL` | `RM-ROOM-EAST-WING` | never season 1; visible door/threshold initially except concealed garden side | future unpowered area |
| `RM-EDGE-008` | `RM-DOOR-HALL-UPPER-FLOOR` | `RM-ROOM-HALL` | `RM-ROOM-UPPER-FLOOR` | never season 1; visible door/threshold initially except concealed garden side | grand stair approach, not literal hinged door |
| `RM-EDGE-014` | `RM-DOOR-KITCHEN-SERVICE` | `RM-ROOM-KITCHEN` | `RM-ROOM-SERVICE-WING` | never season 1; visible door/threshold initially except concealed garden side | future scullery/pantry/service wing |
| `RM-EDGE-015` | `RM-DOOR-CONSERVATORY-GARDEN` | `RM-ROOM-CONSERVATORY` | `RM-ROOM-BACK-GARDEN` | never season 1; visible door/threshold initially except concealed garden side | garden exterior threshold |

### Immutable ID handling / compatibility

- Keep `RM-EDGE-001`, `RM-EDGE-005`, `RM-EDGE-007`, `RM-EDGE-008`, and their door IDs because their physical links are unchanged.
- **Retire**, never reuse, old direct-Hall edges `RM-EDGE-002`, `RM-EDGE-003`, `RM-EDGE-004`, `RM-EDGE-006` and door IDs `RM-DOOR-HALL-BEDROOM`, `RM-DOOR-HALL-BATHROOM`, `RM-DOOR-HALL-KITCHEN`, `RM-DOOR-HALL-CONSERVATORY`. They now resolve as *legacy narrative gate aliases* or migration references only, and must not be instantiated as physical doors. Persist a legacy→current mapping where needed. `RM-EDGE-009..015` and corresponding `RM-DOOR-*` IDs are new.
- `RM-ROOM-CORRIDOR` is a **new** room ID, a lightweight reusable passage environment (not an extra season story chapter). Keep `RM-ROOM-ARCHIVE` for the library. `RM-ROOM-PARLOR`, `RM-ROOM-GALLERY` and `RM-DOOR-HALL-PARLOR` remain reserved.
- Old Stage-1 `next_gate` named `RM-DOOR-HALL-BEDROOM` is fulfilled by *new physical* `RM-DOOR-CORRIDOR-BEDROOM`; no duplicate door. Old `RM-DOOR-HALL-CONSERVATORY` corresponds to `RM-DOOR-KITCHEN-CONSERVATORY`. Stage-1 narrative reference remains unchanged, but implementation resolves the gateway through alias table.

### Service/infrastructure zones

| utility zone | scope | status at start | safety rule |
|---|---|---|---|
| `RM-UTILITY-LIVE` | hall, corridor, bedroom lights | old but usable limited circuit after basic visual inspection | not permission to power heavy equipment |
| `RM-UTILITY-WET` | bathroom + kitchen riser/chase | water isolated pending plumber; kitchen outlets pending electrician | disable taps/cooking until respective professional signoff |
| `RM-UTILITY-DAYLIGHT` | archive and conservatory | may inspect with daylight, but unsafe props/glazing/circuits block work | access independent of power; no night work before suitable lighting |
| `RM-UTILITY-ISOLATED` | east wing, upstairs, service wing | shut off and/or uninspected | not enterable in S1 even with excess work points |

**Traversal invariant:** new shortest path bedroom→kitchen is `bedroom → corridor → kitchen`; hall→conservatory is `hall → corridor → kitchen → conservatory`. No teleport or hidden direct Hall door. Rowan normally uses garden/service exterior for his work; Evelyn discovers gardenward access through kitchen after its service path is made safe.