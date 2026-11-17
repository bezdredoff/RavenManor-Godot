Task IDs: GAME-LOOP-01, CODE-08-01 (campaign-core integration); existing upstream GFX-07-01, VN-RUNTIME-01/02, GAME-QA-01/02, MAP-PROD-01 and GAME-LOOP-02 are references, not new live task records.

Changes: Consolidate existing PR commits, fix actual map compilation and runner registration, compile an inactive calibrated world plan, validate physical routes, separate portal contacts from safe checkpoint ground, and exercise the real menu/map/Evelyn/VN/Match-3/store path. Keep production activation and owner acceptance disabled.

Verification: Godot 4.7.2 focused map, menu, candidate, production-contract E2E, historical G2 host and VN dispatch PASS locally. Full check.ps1 PASS in an isolated Windows profile. scripts/check.sh runtime suite and exact-head integration Actions are recorded below when complete. No device acceptance inferred.

Owner QA: RM-DEC-029 Evelyn unchanged and approved. RM-DEC-030 positions unchanged. Replacement overlays, structural headroom, physical-device QA and production G2 acceptance remain pending. Seven new portraits remain 0/7; no fake Ada art or canonical Chapter II–III promotion.

Status impact: Only campaign-core's GAME-LOOP-01 parent becomes in_progress/partial with actual integration evidence. Preserve all other domains' upstream status corrections. No completed/accepted parent, fake task assignment, generated dashboard edit or save schema change.

# G2-03 production integration evidence

Baseline: `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24`. Clean worktree `RavenManor-G2-03`; branch `integration/G2-03-production-unification`. The original worktrees and their uncommitted changes were preserved.

The integration branch merges the existing upstream commit histories. Draft #287–289 remain drafts; this consolidation does not bypass their review boundary. Repository API reports main unprotected and no rulesets. The connector cannot read administration-only branch-protection details (403); no protection override was used. Explicit user authorization covers sequential merges of ready, independently green PRs.

| PR | Exact reviewed head | CI | Integration result |
|---|---|---|---|
| #281 | `a34d04cb0c752a29802a27bc85433b5b4dec9e4f` | [44106188147 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44106188147) | Merged `4cd6ffb7637671d55945f538d92a3cda5fd5bc95` |
| #282 | `032074ca6241b3b0e935a8d23506a9266a13332c` | [44105585322 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44105585322) | Merged `2d3927077589d4ccfa82bb5b23c465b1729d0557` |
| #283 | `124097ef8a3f6a5989b95c0c8368c1b426ce04e5` | [44106228350 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44106228350) | Merged `4e5f7ef665c29c5a10ea16f406c46e980ab68332` |
| #284 | `16a73064c8beb14810294575d931d18c0d28fede` | [44106142677 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44106142677) | Merged `8bea90949069eb25ee2aaf0ca76df1f1f9aa119c` |
| #285 | `d52aed00ddd13322cd9345c2a30923b740a84839` | [44141597044 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44141597044) | Governance headings repaired; removed unregistered live task/assignment and retained reference-audit evidence under existing GFX-05-08. Draft documentation only, 0/7 portraits; not merged as art. |
| #286 | `b0776e45027ffe7b3c46010096218cbc22e279c0` | [44139343934 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44139343934) | Updated against status reconciliation, preserving partial QA parent; merged `424d4a5175c83e43f1a0ef2a13af0176e7afb3a2` |
| #287 | `bae4eb466c8ae9af5fa8a154e6248976387988bf` | [44108576635 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44108576635) | Existing safe physical-arrival dispatch integrated here; draft owner review remains. |
| #288 | `6291f1c222131c76a1eafe7e2a649be8416ca495` | [44142770951 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44142770951), [render QA 44142770914 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44142770914) | Corrected existing candidate's full-body masks and bad floor sample; all activation flags remain false. Draft owner review remains. |
| #289 | `924522ff992e3840a1706629143f0d968782f705` | [44142621801 SUCCESS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44142621801) | Existing branch updated with main, real map parse fix, exact-once smoke registration and registration contract. Draft remains. |

All six required jobs passed on the merged PR heads. Job logs were inspected, including functional PASS markers; historical dashboard snapshot failures are explicitly advisory in the canonical runner. Main shard/dashboard validation passed after each status merge and again after #286. Main/full integration Actions remain separate evidence from these heads.

## Reuse and scope

UPDS donor checked at `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, `scripts/ui/main_menu.gd` blob `76e47a354b1ca42b4f029278382ad1e0070e7d09`: `_begin_new_game`, `_continue_game`, `_open_story`, confirmation and session ownership. Decision **adapter**: preserve existing Raven menu, onboarding, VN shell, persisted read-only Skip, Match-3 session/presenter/preferences/settings and reducer/store; add small navigation seams so tests mount those same real views with isolated storage. UPDS story scene indexes cannot express Raven room/door/safe-anchor semantics. The world-plan compiler is **new Raven-owned geometry adaptation**, using existing 09B authored design as an offline input, not another runtime graph, route controller, mover or save authority. No donor story/art imported.

Exact scope is the existing upstream files plus this branch's map/source/host/menu integration, candidate/acceptance JSON, offline compiler, focused test adapters/E2E/render capture, two runners and registration contract, dashboard path portability, release plan and this evidence note. Reducer, snapshot schema, catalog/story approvals, Evelyn atlas and approved source PNG are unchanged.

## Production calibration and activation boundary

`build_g2_production_candidate.py --check` reproduces `data/raven/manor_production_candidate.v1.json` from the pinned 09B authoring source. Runtime consumes ordinary room-owned world-plan anchors/edges through `ManorNavigationSource`, `ManorNavigationGraph`, `ManorRoomTransitionController` and the existing Evelyn mover, in production mode. It does not use QA movement or QA door mappings.

Image → world is `world = image + (128,128)`, inverse is explicit subtraction. Four control points include HC `(824,400)→(952,528)`, CB `(528,376)→(656,504)`, Hall spawn `(824,760)→(952,888)` and Bedroom `(440,344)→(568,472)`. Image bounds/art-layer origin are `(128,128)` in all three rooms. No second projection is applied to the painted 65° source.

The documented design scale is 40 source pixels/metre, 48px/1.2m nominal door width and 12px/0.3m foot radius. This is a **design target, not a surveyed structural measurement or certified headroom**. Every edge is sampled at ≤1px against room walkable polygons and all NO-GO boundaries with 12px clearance. Four HC/CB cross-room edges have coincident contacts and reciprocal transitions. Other rooms/doors are absent.

Portal contacts explicitly forbid checkpointing. After a zero-jump handoff, the host follows the same authored room route to Hall spawn, Corridor centre or Bedroom centre before saving. Saved portal/unknown anchors fall back to verified room-safe ground. Gates refresh only from the Raven snapshot. Bedroom access comes from RM-HS-005; RM-HS-002 buys restoration only after physical entry; bathroom repair never gates access.

The shipped selector still uses historical unapproved canonical geometry. Candidate flags are false, `PRODUCTION_ACTIVATION_ENABLED=false`, and a separate acceptance receipt is empty/ownerApproved=false. Editing candidate metadata cannot select it. The disabled patch in `docs/production/G2_03_ACTIVATION_DISABLED.patch` changes only the selector switch and cannot enable production without real owner evidence and exact plan/layer hashes in the receipt, plus validated approved geometry. Do not apply it before acceptance.

## VN and player flow

Normal New Game preserves onboarding and all four opening VN beats. With unapproved geometry it reaches an explicit hold with a Return to Menu button and cannot grant map actions. Continue selects opening/pending legacy activity or the approved manor entry using saved campaign state. The map's real view loads the approved PNG and Evelyn, applies aligned candidate floor/foreground layers only through an approved source visual contract, and retains Pause/Resume/Cancel/Settings/Menu and authored touch targets.

Bedroom Match-3 waits for physical room entry. Existing presentations share the host's store. Physical route arrival rechecks story availability; speculative/cancelled clicks grant no event. The host calls `next_scene_at_confirmed_hotspot()` only after actual authored runtime-hotspot arrival, or to restore a saved VN cursor at that same verified safe hotspot. Hall Tea cannot auto-dispatch at Chapter I completion. All eight canonical Chapter II–III scenes remain non-executable; no fake portrait registry entries were added.

## Render evidence and findings

Downloaded artifact `map-prod-01-HC-CB-rendered-review`, ID `14341720755`, [run 44111379440](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44111379440), head `6db9f0719a84fc8645791e9f2c73274c8e8c7323`. Archive SHA-256 verified: `0bb01bd5855d96cdddf0151177960ba22d722361cb1ad395d11189115ad340a9`. Both original PNGs were visually inspected. Thin bars crossed the actor without establishing full body occlusion; the HC parquet source included dark wall material, and the CB cut omitted the wall's painted vertical rise.

V3 restores the real raised HC landing and railings in foreground over the tunnel, samples actual Hall parquet, clears the CB painted body-height opening, and uses a full-height near jamb. Actual GPU scene execution generated both review captures plus `G2-player-map-390x844.png`, forward/return HC contact and under-landing frames, and forward/return CB contact frames. Captures are in `build/map-prod-01/` locally and the map review workflow uploads them. Source and Evelyn hashes are preserved. The under-landing frame shows the landing correctly occluding Evelyn's head/body, with feet emerging below; contact frames show zero-jump room ownership changes.

**Remaining visual blockers:** parquet/jamb finish is visibly a procedural candidate, the CB vertical strip needs owner art review, and 2D masks do not certify a structural under-stair section/headroom. Camera framing, live movement legibility and device performance need owner/physical-phone review. These screenshots are evidence for review, not approval.

## Repeatable verification

- Focused: `godot --headless --path . --script res://tests/raven/game_loop_g2_production_integration_smoke.gd --quit-after 1000`; new menu, player-map and candidate smokes also PASS. Existing isolated G2 and canonical VN dispatch smokes PASS.
- Windows: `./check.ps1 -GodotPath <Godot-4.7.2-console>` **PASS** in a fresh isolated APPDATA profile. Fixed Start-Process argument quoting for this workspace's spaces and Unicode path. Existing immutable VN-export tests require a fresh profile; an initial reused-profile run failed honestly before isolation.
- Bash runtime on Windows: `RAVEN_SKIP_DATA_CHECKS=1 GODOT_BIN=<Godot-4.7.2> bash scripts/check.sh`, fresh separate APPDATA profile. Result recorded at final closeout; this is not a Linux execution claim.
- `bash scripts/check_data.sh` executed locally. Windows initially exposed sourceFiles backslash mismatch (fixed generator to use portable POSIX paths), default code-page decoding (rerun with PYTHONUTF8=1), then lack of Windows symlink privilege in existing security fixtures. No tests disabled/skipped; exact-head Linux CI must supply complete data result. Existing dashboard snapshot advisories remain nonblocking by canonical policy.
- `py -m unittest discover -s tests/raven -p test_game_qa_release_gate.py` PASS; new and old critical tests registered once in each runner.
- Shard/dashboard generator validation PASS; all 15 shards inspected. Only campaign-core's additional live evidence is authored here; foreign ownership handoffs are the existing upstream PRs and this table.
- GPU: `godot --path . --rendering-method gl_compatibility --script res://tests/raven/game_loop_g2_visual_capture.gd`; native RTX 3080 Laptop/OpenGL 3.3 capture executed. CI uses xvfb. Not a physical-phone test.

The E2E mounts the actual real map/UI/actor and plays real legal Match-3 swaps, then uses the existing presentation completion, reducer and store. It covers fresh opening in the companion menu smoke, unapproved and synthetic-approved entry, Hall→Corridor→Bedroom→Corridor→Hall, locks, physical arrival, pause/cancel, first-clear 2 and restoration cost 2 once, VN line resume, exact safe-anchor Continue, corrupt-save preservation and failed writes, and RU/BE/EN. Existing full runners retain Prototype Lab, optional Match-3, historical Onoe, 09B/09D, localization and VN regressions.

## Rollback and handoff

Revert shared integration fixes to return to the separately reviewed #287–289 implementations. Keep the production selector disabled; no migration or save-key change exists. Revert an individual upstream status merge only if its factual evidence proves wrong. Do not revert or regenerate approved Evelyn/first-floor PNG.

Owner handoff: inspect new HC/CB renders and movement at game scale, approve/reject the actual painted openings and structural headroom, then supply physical-device evidence and separate G2 acceptance. Character-art handoff remains seven actual expression variants, especially Ada offer_tray/dry_amused; #285 is documentation only. The final integration PR is reviewable with all production gates disabled, not a production G2 acceptance claim.
