# GAME-LOOP-02 — normal New Game / Continue to production-gated manor map

**Domain:** campaign-core (single runtime integration owner)  
**Baseline:** `main` `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24`, merged #280  
**Branch:** `agent/campaign-core/GAME-LOOP-02-production-map-host`  
**Status:** bounded implementation PR, NOT production geometry acceptance.

## What changed

1. New actual player scene `scenes/raven/manor_player_map.tscn` with `scripts/raven/raven_player_map.gd`. It instantiates the existing `RavenGameplayHost` (never builds a second store, route session, mover, VN or Match-3). Uses approved source visuals, authored interaction anchors/door transitions, Evelyn, camera following physical feet, a compact portrait HUD, Pause/Cancel/Settings/Menu, distinct locked feedback and RU/BE/EN labels.
2. `raven_player_map_entry.gd` is the **single normal-flow gate**. It requires the opening `RM-BEAT-01-01` VN to be completed AND `ManorNavigationSource.resolve()` to confirm canonical `PRODUCTION_APPROVED` geometry with movement enabled. There is no QA opt-in, external worldPlan, draft flag override or fallback navigation data. The scene's host repeats this check at configure.
3. `main_menu.gd` Continue opens the real map for post-opening activities only when that production gate succeeds; else it retains the existing vertical-slice player flow. New Game still starts the full onboarding and opening VN in the existing slice. Prototype Lab and optional Match-3 menu entry are unchanged.
4. `vertical_slice.gd` hands off when the story reaches the first map-bound action (`access` or `restore1`) and the gate is open. The same scene can be mounted by G2 host as a VN / Match-3 overlay, preserving the original store, cursor, bounded Skip, rewards and checkpoint recovery. Embedded presentation cannot press the legacy `ВЫПОЛНИТЬ` debug action for map-bound `access`/`restore1`; returns to map on those steps. Its pause dialog also has a Return to Map action that does not mark story completion.
5. Production-only `ManorRoomTransitionController.refresh_production_doors()` and `RavenGameplayHost._load_state()` reconcile door gates from the authoritative saved `unlockedDoors` without reconstructing Evelyn/session or moving the actor. A gate closing during a segment pauses the leg and holds fail-closed. No TEST_ONLY unlock API is involved.

## UPDS-first reuse pin

Current authoritative native donor: **`bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`** (main, 2026-10-22). Inspected:

| Donor (blob SHA) | Current Raven counterpart | Decision |
|---|---|---|
| `scripts/ui/main_menu.gd` (`76e47a354b1ca42b4f029278382ad1e0070e7d09`) menu New Game, Continue, save-status | `scripts/raven/main_menu.gd` | **adapt** existing donor-derived Raven menu; add canonical map routing only |
| `scripts/ui/phone_frame.gd` (`3656f7568ef5b1a8bc65c293b70386df4b467e64`) max 430×932, viewport fit | `scripts/raven/vertical_slice.gd`, responsive map HUD | **adapt** existing Raven layout patterns; no new donor screen |
| `scripts/ui/settings_screen.gd` (`2373147596c296631e01e43f8958a5e3a9a5fe00`) preferences, locale, audio | `scripts/raven/raven_settings_dialog.gd` | **reuse-as-is** already adapted Raven runtime dialog |
| `scripts/core/save_storage.gd` (`37201dfebbe11854a590ea717ff3b844d2b9c48b`) storage read/write/remove | `scripts/core/save_storage.gd`, `raven_campaign_store.gd` | **reuse-as-is**, Raven keys/schema/reducer remain sole authority |

The **new** map view/controller is Raven-specific authored spatial UI with no suitable UPDS equivalent; it delegates all shared gameplay/session/persistence and presentation instead of copying them. No UPDS story/scene index or private artwork was imported.

## Geometry / activation dependency

As of baseline #280, `data/raven/manor_greybox_graph.json` has `productionReady=false` and no approved room-art calibration. Its canonical resolver fails closed. RM-DEC-030 approves HC/CB proposed architecture, **not** artwork/door jamb, foreground, collision, cut, elevation or accepted world-plan transformation. `map_qa_09*` image-pixel test drafts cannot be promoted by metadata flags.

When Agent A's reviewed production candidate is merged and visual/structural tests pass, the existing source contract must provide a validated world-plan and `visuals[room]` with `texturePath`, `bounds=[world_x,world_y,world_width,world_height]`, `cameraZoom` matching the canonical graph's world positions. This PR makes no calibration/art/route change, and adds no synthetic geometry to normal saves. UI camera and hotspot buttons use ONLY these approved source coordinates.

## Verification (truthful)

- **Previously confirmed on main**: #280 exact-head CI success at `7fe865b19654c9e0d2b2308103dd4241db04b3a1` (six required jobs). Those are baseline tests, not evidence that this new scene ran.
- **Authored, not locally executed:** `tests/raven/game_loop_02_player_map_smoke.gd` tests prologue gate, real scene inclusion, RU/BE/EN, no injected fake plan, production-only gate refresh with stable room/anchor. Run:
  `godot --headless --path . --script res://tests/raven/game_loop_02_player_map_smoke.gd --quit-after 240`
- **Required checks:** `bash scripts/check.sh`; `python3 scripts/raven/tools/progress_shards.py`; `python3 scripts/raven/tools/build_production_dashboard.py --check`; exact-head PR Actions including all six jobs. This environment has no Godot binary or direct GitHub clone access: do NOT claim local Godot or physical-device PASS.
- Existing QA G2 tests use isolated memory adapters; this PR never routes those adapters to `user://`.

## Manual acceptance after geometry is production-approved

1. Launch **normal application**, not F6; at 320×568, 390×844 and 430×932 verify full New Game onboarding and **letter → road → gates → arrival VN** before seeing Hall with approved Evelyn; repeat in RU/BE/EN.
2. Tap only authored doors/hotspots. Reject tapping unmarked ground. Verify Hall → Corridor and show blocked Corridor → Bedroom until successful physical arrival at `RM-HS-005` (bathroom repair is irrelevant).
3. Tap RM-HS-005; observe authored route, unlock applied through one Raven reducer/store, Match-3 `RM-LVL-001` overlays on the map, reward once only, no speculative reward on cancel. Verify same actor stays at physical interaction point as the bedroom door becomes available.
4. Enter Bedroom via approved CB; tap `RM-HS-002` from the physically correct room/anchor; verify `RM-REST-001` costs 2 work points once, bedroom VN plays, read-only Skip stops at unread/choice and persists cursor. Exit Bedroom → Corridor → Hall and check camera/foreground masking.
5. Pause during a segment, Resume, Cancel during a leg, dismiss/resume VN or Match-3, return to menu. Continue from a safe Bedroom/Corridor/Hall anchor. Check exact last room, door unlock, VN line, Match-3 checkpoint; no mid-wall spawn, no double reward.
6. Corrupt save, failed read and failed write: confirm refusal/recovery rather than silent overwrite. Also confirm optional Match-3 levels and Prototype Lab unchanged. Capture phone screenshots/recording and performance.

**Unverified at this PR stage:** physical HC/CB production art, foreground/collision/occlusion, normal playable loop on a device, screenshots/video capture, frame pacing, all-locale visual safe areas and end-to-end room traversal. These remain owner/Agent A/E acceptance gates. Never auto-merge or activate unsupported routes.

## Status / rollback

This is a **partial implementation candidate**. Single Raven save/reducer schema and story/door/RM IDs unchanged. Revert this scoped PR to restore the previous main-menu→vertical-slice behavior; no save migration. Related parent workstream: `GAME-LOOP-01` (existing campaign-core shard). `GAME-LOOP-02` is a scoped follow-up ID not yet in the shared canonical task catalog; do not create an unknown progress entry or edit foreign/shared catalog as a side effect.
