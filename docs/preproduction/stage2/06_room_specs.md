# 06 — Room specifications | Stage 2 v0.2

**[Approved]** First-floor western occupied area; 6 main playable story spaces (Hall, Bedroom, Bathroom, Kitchen, Archive/Library, Conservatory); plus small Entry and **new corridor passage**. Corridor is architectural/navigation asset, not extra chapter. **[Proposal]** sample framing and anchors must be adjusted only after greybox spatial test; IDs persist.

Common contract: `base_architecture`, `restoration_objects`, `interactive_props`, `foreground_occluders`, `atmosphere`; room repairs are `ruined → stabilized → restored`, plus independent `reveal`. Interactable hit target ≥44 logical CSS px. Positions below are LOCAL normalized conceptual points, not world coordinates. Each camera must work in portrait with side-pan and return-to-character. Floor plan needs wall thickness, safe landings, and no corridor doors opening through each other.

## `RM-ROOM-ENTRY` — threshold/support

- **Beats:** `RM-BEAT-01-01`.
- **Base architecture:** porch doors and stone steps.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. Do not assume this room becomes functional when simply entered.
- **Props/clues:** luggage, inheritance letter.
- **Doors/portals:** `RM-DOOR-ENTRY-HALL`→`RM-ROOM-HALL`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-ENTRY-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** canopy/eaves; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-ENTRY-OVERVIEW` = functional overall view; `RM-CAM-ENTRY-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/evening, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## `RM-ROOM-HALL` — master/public

- **Beats:** `RM-BEAT-01-02`, `RM-BEAT-05-01`, `RM-BEAT-05-02`, `RM-BEAT-05-03`, `RM-BEAT-06-04`.
- **Base architecture:** entry axis, great stair, grandfather clock, west corridor mouth, east double doors.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. Do not assume this room becomes functional when simply entered.
- **Props/clues:** clock, notice board, family portrait.
- **Doors/portals:** `RM-DOOR-ENTRY-HALL`→`RM-ROOM-ENTRY`, `RM-DOOR-HALL-CORRIDOR`→`RM-ROOM-CORRIDOR`, `RM-DOOR-HALL-ARCHIVE`→`RM-ROOM-ARCHIVE`, `RM-DOOR-HALL-EAST-WING`→`RM-ROOM-EAST-WING`, `RM-DOOR-HALL-UPPER-FLOOR`→`RM-ROOM-UPPER-FLOOR`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-HALL-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** balustrade, arch and stair posts; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-HALL-OVERVIEW` = functional overall view; `RM-CAM-HALL-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/evening/clock reveal, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## `RM-ROOM-CORRIDOR` — passage/light master

- **Beats:** transit only; no new story beat.
- **Base architecture:** continuous floor/wainscot, bedroom/bath/kitchen faces, narrow windows and service chase.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. No paid major restoration; use reusable corridor furnishing states.
- **Props/clues:** door labels, wall lamp, family photo.
- **Doors/portals:** `RM-DOOR-HALL-CORRIDOR`→`RM-ROOM-HALL`, `RM-DOOR-CORRIDOR-BEDROOM`→`RM-ROOM-BEDROOM`, `RM-DOOR-CORRIDOR-BATHROOM`→`RM-ROOM-BATHROOM`, `RM-DOOR-CORRIDOR-KITCHEN`→`RM-ROOM-KITCHEN`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-CORRIDOR-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** door jambs and near-wall pilaster; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-CORRIDOR-OVERVIEW` = functional overall view; `RM-CAM-CORRIDOR-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/evening, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## `RM-ROOM-BEDROOM` — master/private

- **Beats:** `RM-BEAT-01-03`, `RM-BEAT-01-05`.
- **Base architecture:** window, bed wall, fireplace or radiator; adjacent wet-wall shaft.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. Do not assume this room becomes functional when simply entered.
- **Props/clues:** trunks, bed, childhood height marks/toy.
- **Doors/portals:** `RM-DOOR-CORRIDOR-BEDROOM`→`RM-ROOM-CORRIDOR`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-BEDROOM-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** bed canopy/post; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-BEDROOM-OVERVIEW` = functional overall view; `RM-CAM-BEDROOM-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/evening/night, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## `RM-ROOM-BATHROOM` — micro-set/private

- **Beats:** `RM-BEAT-01-04`.
- **Base architecture:** tub/shower, WC, basin, wall chase adjacent kitchen.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. Do not assume this room becomes functional when simply entered.
- **Props/clues:** tap, cracked supply joint, tools.
- **Doors/portals:** `RM-DOOR-CORRIDOR-BATHROOM`→`RM-ROOM-CORRIDOR`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-BATHROOM-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** door frame/shower curtain; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-BATHROOM-OVERVIEW` = functional overall view; `RM-CAM-BATHROOM-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/evening, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## `RM-ROOM-KITCHEN` — master/service

- **Beats:** `RM-BEAT-02-01`, `RM-BEAT-02-02`, `RM-BEAT-02-03`, `RM-BEAT-02-04`, `RM-BEAT-03-03`.
- **Base architecture:** counters, sink tied to shared riser, stove, rear glazed exterior access.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. Do not assume this room becomes functional when simply entered.
- **Props/clues:** delivery bags, album box, outlets.
- **Doors/portals:** `RM-DOOR-CORRIDOR-KITCHEN`→`RM-ROOM-CORRIDOR`, `RM-DOOR-KITCHEN-CONSERVATORY`→`RM-ROOM-CONSERVATORY`, `RM-DOOR-KITCHEN-SERVICE`→`RM-ROOM-SERVICE-WING`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-KITCHEN-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** cupboard fronts, counter shelf; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-KITCHEN-OVERVIEW` = functional overall view; `RM-CAM-KITCHEN-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/evening, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## `RM-ROOM-ARCHIVE` — master/public

- **Beats:** `RM-BEAT-03-01`, `RM-BEAT-03-02`, `RM-BEAT-03-04`, `RM-BEAT-06-01`, `RM-BEAT-06-02`.
- **Base architecture:** bookshelves, reading table, tall daylit windows.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. Do not assume this room becomes functional when simply entered.
- **Props/clues:** family ledger, photograph, plant map, niche correspondence.
- **Doors/portals:** `RM-DOOR-HALL-ARCHIVE`→`RM-ROOM-HALL`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-ARCHIVE-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** foreground bookcase edge; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-ARCHIVE-OVERVIEW` = functional overall view; `RM-CAM-ARCHIVE-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/evening, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## `RM-ROOM-CONSERVATORY` — master/garden

- **Beats:** `RM-BEAT-04-01`, `RM-BEAT-04-02`, `RM-BEAT-04-03`, `RM-BEAT-04-04`, `RM-BEAT-06-03`.
- **Base architecture:** glazed annex, plant beds, walkable safe path, rear garden face.
- **States:** `ruined`: blocked/unused surfaces; `stabilized`: safe walkable/essential functionality; `restored`: full seasonal readable silhouette (not just dust removal). `reveal`: independent contextual clues/characters, does not overwrite repair state.
- **Restoration zones:** major work local to architecture and larger furniture; maintain one safe passage route. Do not assume this room becomes functional when simply entered.
- **Props/clues:** seed capsule, plant tag, glass repair.
- **Doors/portals:** `RM-DOOR-KITCHEN-CONSERVATORY`→`RM-ROOM-KITCHEN`, `RM-DOOR-CONSERVATORY-GARDEN`→`RM-ROOM-BACK-GARDEN`.
- **Walkable zones:** continuous central polygon with a non-walkable perimeter and fixed furniture collisions; corridor width proposal ≥1.2 m clear, turning/landing pocket at 3 adjacent doors; no overlap of door swing, route and hotspot.
- **Navigation anchors:** `RM-ANCHOR-CONSERVATORY-CENTER`, plus dedicated near/far anchors for each listed portal, at least 1 character radius away from a panel swing. **Interaction anchors** opposite primary prop/safe working face; specialist tasks occur only after authorized work order.
- **Foreground:** leaves/glass framing; masks separate from click targets; character should never visually pass through solid wall.
- **Camera:** `RM-CAM-CONSERVATORY-OVERVIEW` = functional overall view; `RM-CAM-CONSERVATORY-FOCUS` = active clue/restoration; pan clamped to room bounds, character recenter accessible. Light/atmosphere: day/overcast, atmosphere reusable low-cost particles only.
- **Residents & visits:** Evelyn traverses when unlocked; Ada may appear where relevant; Rowan visits kitchen/conservatory as external gardener; Lucas arrives for appointments; no added resident. **Unlock:** graph/door gates in `05` and progression table `07`.
- **Reuse / risk:** reuse surfaces and door family, but unique silhouette of major restoration; specialist tool/hand actions preferably offscreen or VN insert; high-risk first-person perspective where tight space occludes character.

## Future silhouettes (not seasonal playable rooms)

`RM-ROOM-UPPER-FLOOR`: visible grand stair and upper balcony barrier, no walkable upstairs navmesh; `RM-ROOM-EAST-WING`: shut double doors and visible unpowered branch; `RM-ROOM-SERVICE-WING`: kitchen rear locked service passage; `RM-ROOM-BACK-GARDEN`: visible beyond greenhouse glazing. Each has a door/visual boundary but **no generated interior**, no future-level camera and no seasonal restoration.

## Plumbing/electrical layout realism QA

Bathroom and kitchen must share a service chase/stack even if their corridor-facing doors are on opposing wall axes; draw them back-to-back or run aligned pipes in a short service wall. Corridor cannot be an endlessly straight tube: slight bends/alcoves are compatible with believable wing conversion and screen pan. Conservatory attaches to rear service side of kitchen via glazed weather-sealed opening, not to internal hall. All doors have accessible near-side approach/return anchors and no furnishings block emergency egress.