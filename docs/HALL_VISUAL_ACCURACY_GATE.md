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
