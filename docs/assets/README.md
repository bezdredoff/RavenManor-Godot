# Raven Manor — first-season complete asset planning register v0.1

**Scope and evidence:** Based on Stage 1 v0.5 (24 beats, four primary characters), Stage 2 v0.2 (six narrative spaces plus entry and corridor), Stage 3 v0.2 (initial production matrix). This inventory **expands earlier sparse asset budgeting**. Source-established object functions are inherited; proposed set dressing, counts, state variants, placements, clip lists and mildly-chibi ratio need artistic approval.

## Files
- `CHARACTER_PRODUCTION_BIBLE.md`: detailed role descriptions, VN poses/emotions and independent map-scale mildly-chibi animation sheets.
- `CHARACTER_VARIANTS.csv`: individual proposed pose, emotion, reference angle and map-clip deliverables.
- `ROOM_FURNISHING_AND_PLACEMENT.md`: all eight active/support area composition plans, clustered props and state variants.
- `ROOM_OBJECT_REGISTER.csv`: per-object ID, room, relational placement, state list, layer and production priority.

## Composition and layering
1. Establish camera/architecture base, horizon and walkable footprint.
2. Place core furniture and mandatory repair silhouettes. Fixed architecture does not shift between repair stages unless explicitly designed.
3. Add secondary decor in **functional clusters** (bedside, washstand, reading desk, service counter, garden bench), not uniform random scatter.
4. Keep narrative hotspot recognisable, less-important props visually subordinate; preserve player routes/doorways and approach anchor visibility.
5. Split into `base_architecture`, `restoration_objects`, `interactive_props`, `foreground_occluders`, `atmosphere`, `lighting` and clue insert assets.
6. Independently express physical restoration (ruined / stabilized / restored), story reveal, light (day/evening/night) and interaction states (hidden / available / inspected / consumed); do not bake every combination as separate full room image.
7. Collision, floor contact, prop depth and viewpoint must be authored alongside artwork, not inferred later.
8. For greybox bath use a vignette; full playable bathroom still can be added later, if required.

## Deliverable rules
- Each asset: canonical `RM-ASSET-*` planning ID, one approved reference sheet, base master dimensions/transparent alpha when layered, location anchor, pivot/depth/occlusion, optional animation clips, state transition references, source/provenance and QA.
- The existing `RM-ROOM-*`, `RM-HS-*`, `RM-REST-*`, `RM-BEAT-*` stay unchanged; new proposed `RM-ASSET-*` and `RM-CA-*` IDs are **planning IDs pending approval**, not registrations in runtime.
- Reuse generic families (books, tableware, curtains, crates, potted plants) via controlled variations; avoid making every duplicate its own unique illustration.
- Lighting/shadow family: daylight/evening and chapter-specific night where necessary; shadows, particles, dust, curtain flutter and clock hands can be shader/rig-driven instead of full-frame prerenders.
- Doors: locked panel vs unlocked open or hidden; do **not** manufacture five animation states per door, since new owner decision superseded prior stage docs.

## Planned quantity
- 117 placement/object-family rows across 8 architectural areas (including narrative props, furniture, architectural elements and decor); row counts represent reusable *families*, not unique PNG files nor quantities of copies.
- 97 proposed character deliverable variants across 4 main characters, representing 2 scales. Not all require unique images if compatible face/layer rigs share bases.
- Further cross-room shared effects/UI markers and hand-held clue close-ups should be derived into a generation manifest only after validation of style, layer masks and frame formats.

## Story versus new proposal
Four core cast and roles, six principal narrative spaces, scene beats, and clues/clock/key plot devices are established by prior Stage 1/2 material. Furniture fill and grouping (e.g. mirror, mats, books, dishes, vases), precise variant lists, and proportions are *production proposals*. Specialist actors are supported as narrative functions only, not a fully approved NPC roster.

## Acceptance
A room is not ready if all props are random or if it contains only its single story object; it is not ready if furniture blocks doors/hotspot approach. Review full-room overview, interaction close-up, blocked/open state, before/after restoration, foreground on top of chibi character, and composition with VN overlays in 390×844 plus narrow/tall portrait ratios.
