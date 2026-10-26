# Hall visual accuracy gate after PR #31

Status: **measured draft; no art, collision or route approval** (26 October 2026).

## Plan and evidence

1. Keep `season1_world_map.json` and the generated Builder scene as separate authorities: the former owns doors, navigation, prop selection and saves; the latter owns draft pixels. PR #31 already verifies five markers and six original obstacle rectangles.
2. Measure the unretouched 1254×1254 Hall PNG against the fixed 700×690 world rectangle. `data/raven/hall_render_calibration.json` records all five door targets, the visible openings, and both stair runs. The measurements are approximate guides for review, never input to navigation.
3. Exercise actor depth around each imported upright sprite, and make furniture base footprints available for isolated path trials. Keep the new `precise_seating_collision` switch off by default until path and interaction review confirms it. It is runtime-only, absent from campaign saves.
4. Replace/repaint the background and author alpha foreground masks only after a screenshot review confirms five distinct architectural intents and the two stair runs. A regenerated image must retain a reproducible provenance record and pass the same measurements at 390×844, 412×915 and 430×932.

## Measured mismatch

The front entry aligns within roughly 7 world units. The library arch is painted near (527,343) but the map crossing is (500,550); the corridor arch is painted near (1173,343) but its crossing is (1200,585). The central painted double door near (850,343) visually serves **both** future map markers (850,350) and (850,320), although the upper-floor target is a staircase approach rather than a hinged door. These are pixel/semantics mismatches; moving map anchors to those painted arches would break routes. The two painted stair runs roughly match their horizontal map footprints but start at the top of the image instead of map Y=190. The calibration data and the **Габариты** view show green map points connected to coral painted estimates. No false portal or stair access is added.

## Render and depth acceptance criteria

- Capture actual Whole Manor Map at the three portrait sizes, at 65° and 0.74×, with default **Импорт** and **Габариты**. Save screenshots and compare to the committed generated scene and PNG. The five map markers must land in five clearly understandable portal/stair intentions. Any intentionally shared visual opening needs an explicit design decision.
- Inspect actor in front of and behind each chair, table, clock, console and gallery. Sprite sorting uses each imported upright's world foot Y; the overlay is above the actor and draws only sprites whose foot is closer to camera. Verify all pixels and shadows, since full-sprite sorting is not an alpha mask.
- Provide separate alpha masks for archive/corridor jambs and both stair balustrades. Only then can the actor pass behind those features without incorrect full-image occlusion. Current background is a single opaque texture and **does not pass this criterion**.
- Compare old one-piece seating blocker with three opt-in base footprints. Verify a reachable path to each door and clock at all viewport sizes, approach to the seating interaction, and no walk through chair legs/table base. Keep the flag off if any path fails or a visual foot pivot is ambiguous.
- Confirm unchanged `RM-DOOR-*` IDs, locked future stairs/east wing, saved story progress, Match-3 rewards, and Bedroom via Corridor route. No save migration is authorized by this draft.

## Verification and next steps

The real Godot 4.7.2 OpenGL renderer produced [390×844](evidence/hall_import_390x844.png), [412×915](evidence/hall_import_412x915.png) and [430×932](evidence/hall_import_430x932.png) captures from the committed imported scene. The 390×844 capture visibly confirms the single central painted door, the approximate left arch, two stair flights and the actor among separately drawn furniture. It also shows why the image cannot yet certify door placement: the right corridor arch is outside the opening viewport and both future markers overlay that central door. The other captures keep the same issue. The command is `RAVEN_HALL_CAPTURE_DIR=<output directory> godot --path . --rendering-method gl_compatibility --script res://tests/raven/hall_render_capture.gd`; rendering requires a display driver, since Godot's headless dummy driver has no screenshot texture.

Godot smoke tests check the five map coordinates, imported scene counts, front/back sorting and both collision policies. Python importer tests and browser smoke remain CI gates. These checks establish data and runtime behavior; they cannot certify painted openings or alpha quality. The next art pass needs a geometry-conditioned background, separate foreground cutouts, measured screenshot evidence and explicit owner approval before default collision changes or art approval.


## October 26 follow-up: usable in-game QA controls

The previous instrumented parity report measured the image but did not provide in-game toggles for the proposed seating model. **Whole Manor Map → Настр.** now exposes a third row with:

- **Стыки: СКР / ВИД:** shows orange/coral estimated painted stair rects against cyan map bounds, six provisional tread guides per flight, the old seat group and green proposed furniture contact outlines. Door discrepancy arrows (green = fixed world marker, coral = measured painting) are visible when this is enabled, without turning on every unrelated debug bounding box.
- **Кресла: ОРИГ. / 3 ТЕСТ:** swaps the large original seating collision for three smaller *unapproved* contact rectangles in temporary AStar memory, and clears any queued actor movement. The toggle rebuilds navigation and can immediately restore the original geometry; it never changes JSON source or campaign saves. It is off each time the room is loaded.

Before either tool activates, a runtime validity gate verifies the calibration file's exact five canonical door IDs and positions, two staircase bounds, and that all three candidate footprints lie inside the existing combined seating obstacle. If the world map changes without recalibration, the buttons are disabled and default collision remains intact.

### Current decision record

**Delivered and checked:** numerical source parity, real Godot render evidence for three portrait sizes, quantified discrepancy of painted side arches, reversible test navigation, interactive visualization of stair and door mismatches, actor foot-depth front/back tests.

**Intentionally deferred:** repainting the 1254×1254 source background, generating true transparent balustrade/doorframe foreground mattes, approving individual physics footprints, creating clean/damaged sprites or modifying story/interaction state. The side arches' vertical painted displacement exceeds 200 world units; hiding it with a 2D offset or moving canonical door markers would be inaccurate. New geometry-conditioned art and explicit sign-off are prerequisites for these corrections.

### Final acceptance gate

For each of five doors and two stair flights, require an updated *source image* plus a recorded painted opening/edge location that aligns with the fixed corresponding map anchor, with an explicitly agreed pixel tolerance at 0.74×/65°; compare at 390×844, 412×915 and 430×932. Check front/back alpha masks and character routes in default collision and candidate contact modes. Only after signoff promote three separate collision footprints and the architecture occluders into production. No such approval has been given yet.
