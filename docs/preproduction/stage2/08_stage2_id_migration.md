# Stage 2 v0.2 — Immutable IDs and physical-door migration

Stage 1 narrative IDs are untouched. These are **aliases for interpreting already approved gate references**, not names to be used for newly authored physical edges.

| old edge (retired) | old door (legacy only) | physical canonical edge | physical canonical door |
|---|---|---|---|
| `RM-EDGE-002` | `RM-DOOR-HALL-BEDROOM` | `RM-EDGE-010` | `RM-DOOR-CORRIDOR-BEDROOM` |
| `RM-EDGE-003` | `RM-DOOR-HALL-BATHROOM` | `RM-EDGE-011` | `RM-DOOR-CORRIDOR-BATHROOM` |
| `RM-EDGE-004` | `RM-DOOR-HALL-KITCHEN` | `RM-EDGE-012` | `RM-DOOR-CORRIDOR-KITCHEN` |
| `RM-EDGE-006` | `RM-DOOR-HALL-CONSERVATORY` | `RM-EDGE-013` | `RM-DOOR-KITCHEN-CONSERVATORY` |

Physical identifiers `RM-EDGE-001`, `RM-EDGE-005`, `RM-EDGE-007`, `RM-EDGE-008` and door IDs remain as authored in v0.1. New `RM-EDGE-009` is Hall→Corridor; `RM-EDGE-014/015` are service-wing and garden future thresholds.

**Reserved unchanged:** `RM-ROOM-PARLOR`, `RM-ROOM-GALLERY`, `RM-DOOR-HALL-PARLOR`. **New:** `RM-ROOM-CORRIDOR`. `RM-ROOM-ARCHIVE` is canonical library room. No stage-1 story beat IDs have been changed.