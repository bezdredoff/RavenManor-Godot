# Raven Manor — canonical project status

Last reconciled: **2026-10-27**, including merged PRs #54 and #56, real phone ZIP smoke and CODE-02A component-source audit. Older dated sections are historical snapshots, not current PR-state assertions. Earlier sections preserve their historical milestones. The owner confirmed that the published Prototype Lab and mobile Room Builder open and operate. This is **working preview acceptance**, not production art approval or a complete device-certification report.

## Implemented and merged

- **RM-HUB-001 foundation / navigation / RM-VS-01:** Godot 4.7.2 standalone Raven runtime, atomic Raven save, authored Hall → Corridor → Bedroom graph, VN and three deterministic Match-3 levels, two restorations, clue, first night, resumable progression. PRs #9 and #10 and the associated original RM-HUB-001 work are merged.
- **Continuous season-one map feasibility greybox:** proposed footprints of Entry, Hall, Archive, Corridor, Bedroom, Bathroom, Kitchen and Conservatory; 11 door relations, furniture obstacles, orthogonal AStarGrid2D routes; isolated Match-3 preview. This is **not** approved production geometry and is independent of the accepted vertical-slice authored graph.
- **Mobile camera pilot:** owner-preferred 65° elevation, 0.74× zoom default, 0.68×/0.74×/0.80× comparison, full-screen portrait HUD and scale calibration. Real-device screenshot/occlusion certification still pending.
- **Generated Hall artwork comparison:** PR #17 merged on 2026-10-25 after fixing the art-mode smoke test. Eight original source PNGs (two alternate backgrounds, six prop cutouts), checksums, reconstructed prompts; modes **AI1 / AI2 / ПЛАН / SVG** in Whole Manor Map. Art is **experimental and unaligned** to canonical game geometry.
- **Mobile Room Builder PWA v0.1:** PR #18 merged. Touch-first Canvas editor, asset/tile placement, layers, imported PNG/sprite sheets, local IndexedDB, JSON/PNG export, offline-capable PWA shell and independent draft-only JSON → Godot scene converter.
- **Pages /builder/ 404 fix:** PR #19 merged. Static PWA mirrored under root `builder/` and bundled with Godot Web export; both Pages publication methods now include its entrypoint and assets. User confirmed the editor subsequently opens.
- **CI:** GitHub Actions for PR #17 and the subsequent `main` merge successfully ran project checks and Web export. This validates automated smoke tests, not full art acceptance or real-device interaction behavior.
- **Temporary cast artwork:** Onoe from UPDS remains a noncanonical test placeholder; no final Raven cast identity, styles or production sprites accepted.

## Narrative/gameplay sync (2026-10-26)

- Latest story decisions from the October design chats are now represented in `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md` and machine-readable `data/raven/season1_narrative.json`.
- `RM-VS-01` keeps the existing save schema, rewards, restoration costs and stable `RM-*` IDs, but its playable meaning is corrected: inheritance arrival first; ordinary Ada/Lucas presentation; bedroom sorting/cleanup; bathroom diagnosis and specialist preparation; childhood-object memory fragment; first night with food delivery; next hook to kitchen and Rowan/conservatory.
- VN content now supports per-line speakers so one beat can represent an actual conversation rather than one speaker owning every line.
- The slice intentionally does not explain the town memory effect or explicitly reveal Ada/Lucas/Rowan as ghost/vampire/werewolf. Those remain later narrative gates.
- Room Builder, imported Hall art and map geometry remain unable to mutate narrative/save state implicitly.

## Current next gate

**RM-PIPE-001 — Hall authoring-to-gameplay pipeline proof.** See `docs/NEXT_PLAN.md` and `docs/ROOM_PIPELINE_NEXT_GATE.md`.

1. Validate editor flow on Android (S Pen/touch, save/restore, offline and export; no right-click/keyboard), preserving manual backups.
2. Establish one **approved** Hall plan that respects current architectural constraints and door/world anchors; map Room Builder's flat coordinates explicitly onto the World Map Hall footprint before visual art.
3. Build a reversible, validated JSON → **preview-only** Godot bridge with per-object pivot, layer, state, hotspot and occluder mapping. Never implicitly replace either existing gameplay navigation graph.
4. Produce and evaluate ONE consistent architecture+props+states composite at current 65°/0.74× mobile framing. Preserve AI1/AI2/SVG/plan comparisons, real asset provenance and the previous graphic fallbacks.
5. Review style anchors for Evelyn VN and separately drawn mildly-chibi map art. No bulk cast/room generation until individual calibration gates pass.

## Important unapproved / outstanding

- Generated Hall geometry and individual prop projection do not yet line up with the shared world map; art is for comparison only. Independent chair/table colliders, masks, occlusion, clean/dusty/repaired variants, lighting and door seam alignment are missing.
- Room Builder `exampleProject()` is an illustrative 1000×800 flat plan, **not** the World Map Hall (500,150,700,690) nor an authoritative `RM-ASSET-*` placement register. Its draft converter does not wire runtime routes, story state or collision.
- Full Android browser/stylus/offline/export-reload matrix and real 390×844 portrait recordings are still required; user success opening the tools is recorded without inventing detailed QA evidence.
- The repository has two active GitHub Pages publication mechanisms (branch/Jekyll and custom Actions). The mirrored builder fixes the observed 404; the preferred long-term setting is **Settings → Pages → Source: GitHub Actions** if the owner wishes to remove the redundant branch workflow.
- Original 70-requirement matrix is a pre-Raven implementation UPDS baseline, not current coverage.
- Source of product/game-bible and narrative truth remains `bezdredoff/RavenManor`; executable Godot, preview art and mobile editor reside here.

## References

- `docs/NEXT_PLAN.md`
- `docs/ROOM_PIPELINE_NEXT_GATE.md`
- `docs/DECISIONS.md`
- `docs/assets/RM_HALL_GENERATED_ART_INTEGRATION.md`
- `docs/ROOM_BUILDER_PWA.md`
- `docs/assets/ROOM_OBJECT_REGISTER.csv`

## RM-CAT-001 — linked production inventory (2026-10-25)

- Added three Hall seating positions (two separately addressable armchairs, shared art family; one round table), expanding the human-owned CSV registry to **120 PROPOSED positions across eight rooms**. 245 textual state labels are recorded, not approved PNG exports.
- Room Builder v0.2 loads generated room-filtered catalog JSON, supplies proposed states/priority/concept-PNG status, and stores distinct local drafts by room ID. Previous v0.1 projects are preserved and migrated on load; experimental art remains references, not baked into production sprite slots.
- See `docs/ROOM_CATALOG_PRODUCTION.md` and `docs/assets/ROOM_OBJECT_REGISTER.csv`. This is an editor/catalog engineering addition, **not** an approval of room coordinates, media variants, camera, licensed source art or Android end-to-end QA.

## RM-EDITOR-002: game-projected Room Builder pilot (2026-10-25)

Room Builder defaults to a **65° projected, directly editable game-floor view** and now also has a deterministic **65°/45° volumetric room cutaway**. Four closed wall sides become a room; adjacent rectangles share their existing wall, and doors/arches remain attached to that wall. Plan and Godot views retain the same reversible stored coordinates. A 0.74× preset and optional copied Godot Hall AI1 background/door guides remain available when the draft room matches the proposed 700×690 map geometry. Old projects remain untouched. No final height/occlusion/character/prop-art or collision certification is inferred. See `docs/ROOM_BUILDER_GAME_PROJECTION.md` and `docs/ROOM_BUILDER_VOLUMETRIC_ROOMS.md`.


## 2026-10-25 — RM-PIPE experimental Hall rendering parity v0.4

The PWA and Godot Whole Manor Map now share a versioned preview-only 7-sprite Hall visual manifest, the original source PNGs, bottom-centre foot pivots, **upright screen-space visual height**, actor-floor foot projection and draw-order splitting around Onoe. A temporary front CanvasItem renders props in front of the game actor. Builder's new aligned Hall draft seeds the exact pilot layout; a manual exported JSON → \`sync_hall_preview.py\` conversion can override Godot **visual placement** while leaving world route/collider/save untouched. All seven artworks and unrendered state variants remain *unapproved*, and real device/per-pixel/mask/collider parity remains pending.

## 2026-10-25 · Room Builder v0.4.1 regression fix

Fixed user-reported empty new Hall (async manifest dependency), missing pilot thumbnails despite available source PNGs, and actor button that only armed a tool without placing Onoe. Added atomic 7-object seeding, explicit empty-draft recovery, built-in Hall layout fallback, and Node unit regression checks. Android screenshot acceptance remains user-side; this change does not approve art or physics.

## 2026-10-25: Room Builder v0.5 character/panel editing

Independent desktop/tablet palette and properties collapse controls; characters are standard movable/deletable room objects, including editable Onoe and user-imported character PNGs. Hall new drafts seed seven proposed pilot sprites and one temporary character. Old preview actor positions migrate once. Navigation and campaign state remain unchanged; browser and Android UI validation required.

## RM-PIPE-002: Room Builder game-scene importer (2026-10-25)

Added 65° projected Builder JSON → separate Godot preview .tscn, resolving Hall pilot/source art, embedded user PNGs, preserving instance IDs/states and ignoring test characters. A sample import runs in Godot CI and appears as Prototype Lab option 6 when generated. This is **not** live game collision/navigation/story integration; layout/doors/occlusion remain approval gates. See `docs/ROOM_BUILDER_TO_GODOT_IMPORT.md`.

## Original Hall mirrored back into Builder + Godot (2026-10-26)

Recreated initial seven art placements directly from existing Godot pilot manifest and six world-map collision/stair rectangles, including five door markers. Reproducible Builder JSON at `examples/room_builder_hall_original.json` and generated 65° Godot review scene; `ReferenceGeometry` is toggleable/hidden/non-physical. Does **not** horizontally flip or replace authored gameplay Hall. Godot and regression checks assert original scene geometry.

## 2026-10-26 — RM-PIPE-003: imported Hall becomes Whole Manor Map's default art

The active map reads the actual committed Builder-generated scene in **Импорт** mode. Runtime rejects stale door/physics coordinates, excludes legacy duplicated Hall furniture/runner, and retains current character, navigation and Raven saves. The AI1 art comparison remains; final doorway/staircase pixel calibration and collider upgrades remain unapproved. See `docs/HALL_LIVE_IMPORT_PARITY.md`.

## RM-PIPE-004: measured Hall QA controls (2026-10-26)

The already measured Hall art discrepancies (PR #32) now have accessible source-validated in-map **Стыки** guide overlays and an in-memory reversible **Кресла: 3 ТЕСТ** navigation button. The default one-piece seat collider, five real door points, fixed routes, game art and saves are unchanged. New Godot smoke tests cover both buttons and portrait layout. Architectural image re-authoring and alpha foreground masks remain unapproved; see `docs/HALL_VISUAL_ACCURACY_GATE.md`.

## Hall wall parity draft (2026-10-26)

The generated Builder/Godot Hall now contains ten measured wall/balustrade segments, five separate canonical portal intents and both exact staircase rectangles. The live map validates and draws the generated wall nodes; four schematic rail strokes render in the foreground pass for actor-depth review. Real 390×844, 412×915 and 430×932 OpenGL captures are committed. Routes, saves, door states and default collision remain unchanged; the pilot painting, final transparent masks and three-piece seating collision are still unapproved. See `docs/HALL_WALL_PARITY.md`.

## ComfyUI wall-art production package (2026-10-26)

A deterministic 52-job Flux2 Klein batch now covers the full approved first-act wall budget: 28 structural pieces, 12 door states, five windows, three arch states and four staircase balustrades. Each job has an exact prompt, seed, guide silhouette and stable filename; the runner validates live ComfyUI nodes/models and saves raw plus alpha candidates. It does not auto-promote generated images. See `docs/RAVEN_WALL_COMFYUI_WORKFLOW.md`.

## 2026-10-26 — wall batch executed locally, mechanically reviewed

The 52-candidate wall batch was rendered on this workstation (ComfyUI Desktop 0.42.5 on `127.0.0.1:8000`, Flux2 Klein 9B, `flux2-vae`, `BiRefNet_toonout`). Every job produced a raw PNG and an RGBA alpha PNG at 1024×1024.

The first real run — not the earlier dry run — exposed two defects that would have wasted the whole batch:

- the graph referenced `VNCCS_RMBG2`, a node installed in no local pack, so preflight aborted the run; the alpha node is now `BiRefNetRMBG` with the installed `BiRefNet_toonout` option;
- negated prompt nouns ("no characters") are rendered as content by this CFG-free sampler, and ring-shaped opening guides became black backdrop plaques. The prompt contract is now positive-only and every guide is a solid silhouette.

The runner validates the complete API graph (classes, inputs, enum values, links, required inputs) against live `/object_info` before queueing. A new `review_wall_asset_batch.py` records filename, SHA-256, seed, guide box and alpha metrics in `data/raven/comfyui_wall_asset_review.json`, keeps human decisions when a file is unchanged and resets them when a candidate is regenerated.

Result of the completed pass: 52/52 candidates, 0 missing, 0 mechanically flagged, all `pending`. The contact sheet at `docs/evidence/comfyui_wall_kit/` shows the honest art-direction split — straight walls, doors, windows, arches and balustrades are usable candidates; **all 16 corner pieces and four end pillars render as room corners or black plates and need a guide redesign, not another prompt tweak**. `door_glazed_double_*` and `window_conservatory_section` also miss their object type. No candidate is art-approved, and Godot art, routes, saves, collision and story data are unchanged.

## 2026-10-26 — constructed wall tileset prototype

`scripts/raven/tools/build_wall_tileset.py` inverts the structural half of the wall pipeline: one AI render supplies the material patches (mahogany, carved trim, damask), and all seven shapes are composed from a single 160×160 framed module whose four edges are pixel-identical. Result: seven `grand` shapes in 0.03 s, seam edge delta 0.0, exact rectangle/L alpha, identical trim height, no room scenes or black plates. This is a **prototype for review**, not an integrated tileset: corners are butt-jointed rather than mitred, there is no wall-top/cap convention yet, and nothing is wired into the Room Builder or Godot. Comparison and limits: `docs/WALL_TILESET_PIPELINE.md`; evidence `docs/evidence/wall_tileset/`.



## Production coordination / late October 2026 (source reconciliation)

- **Merged in `main` since the older 2026-10-26 snapshot:** PR #45 introduced the provisional Chapter II Hall tea VN art pilot (not final production sprites); PR #46 introduced source-preserving UPDS Match-3 rules, paging and preferences reuse with Raven adapters, **not** the full UPDS Match-3/VN screen; PR #47 introduced the paired CODE-00…CODE-13 production roadmap and 36 engineering work packages. Their merge state was verified from GitHub.
- **PR #48 merged into main on 2026-10-27:** unified ChatGPT/Codex/DeepSeek workflow, machine-readable semantic status/evidence ledger, generated CODE/GFX/gap dashboard at `/dashboard/`, and ZIP packager/read-only validator. Last main Pages/Godot build succeeded. These are integrated process tools, not device-approved gameplay/art.
- **Additional uncovered production obligations** now tracked in `data/raven/production/gap_work_packages.json`: Room Builder 65° editing parity/touch panels/NPC drag, scene-import round-trip, Qwen/MOSS/FLUX object-state trial and Art Job Pack, wall/door/stair calibration, private canon-public build separation, localization, phone acceptance and narrative unresolved questions.
- **Task status authority:** code roadmap + GFX roadmap + supplemental gaps define scope; `data/raven/production/production_progress.json` records actual owner/date/status/evidence. The dashboard is a generated view and **cannot itself approve** art, functionality, Web device QA, or release. Preserve original `RM-VS-01` saves and map gating until explicitly migrated.

Older historical milestones and acceptance statements above remain in place, but do not supersede newer reconciled dates, commits and merge evidence.

## 2026-10-27 — mobile ZIP importer MOB-01/02 engineering candidate

- Existing `feature/mobile-zip-import-candidate-preview` was reviewed and extended instead of rewriting from scratch. It adds a GitHub Actions `incoming` ZIP validator, checksum-pinned candidate branch/PR builder and explicit Godot/Room Builder/Web verification dispatch. `pages.yml` builds untrusted PR/candidate source with **contents: read only**, leaving Pages/OIDC write permissions solely to the `main` deploy job. The candidate writer never runs candidate game scripts.
- The workflow now uses an explicit `incoming` ref, verifies pinned `main` again before writing, and waits for independent CI result. ZIP preflight rejects symlinked output ancestors before extracting. Test coverage includes real packager round-trip and protected workflow constraints.
- **Not completed/accepted yet:** workflow merge into default branch, bootstrap of `incoming` from trusted updated main, GitHub Actions PR-creation setting verification, a real benign phone ZIP upload and actual candidate PR/independent CI evidence. `MOB-03` separate `/preview/` and `MOB-04` full device acceptance remain pending. Candidate workflow testing through normal PR CI does **not** prove GitHub Actions can create PRs yet.
- `production_progress.json` reconciles PR #48 merged statuses and records MOB-01/MOB-02 as implementation in progress. No production user save/room/scene change is made by this infrastructure work.

## 2026-10-27 — completed synthetic ZIP-incoming test and safe preview candidate

- After merged PR #49, the `incoming` branch received a real harmless ZIP blob on GitHub. [Import run 40538610191](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/40538610191) passed read-only validation and created `candidate/mobile-40538610191`. Automatic PR creation was **blocked by the repository-level GitHub Actions setting**, not by archive validation. Synthetic [PR #50](https://github.com/bezdredoff/RavenManor-Godot/pull/50) was created through the connected GitHub tool, independent Godot/Room Builder/Web checks passed, then the PR was closed **unmerged**.
- New candidate work branch `feature/mobile-preview-artifact-and-handoff` creates an independent read-only Web build **artifact** for candidate CI and a **trusted** `/preview/` artifact/review portal. It intentionally does not run untrusted candidate JavaScript on the same origin as the stable game. This is a reviewer tool, not playable /preview/.
- A separate origin is required for any future runnable candidate preview. Owner must enable **Settings → Actions → General → Allow GitHub Actions to create and approve pull requests** if automatic PR creation is desired. Manual PR fallback remains valid; full iPhone/Android handoff not yet tested.
- Progress statuses for MOB-01/02/03/04 now reflect the real blockers and evidence. Do not claim full MOB-04 acceptance or complete mobile preview capability from this infrastructure PR.

## 2026-10-27 — GitHub Actions mobile candidate PR setting verified (MOB-01/02/03)

- Owner enabled GitHub Actions creation of PRs; real synthetic ZIP `MOB04-AUTO-PR-R3` was uploaded to `incoming` on GitHub, rebased to latest `main` after PR #51 merged. Import [Actions run 40544933737](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/40544933737): read-only validation, safe candidate branch, **automatic GitHub Actions-created [PR #52](https://github.com/bezdredoff/RavenManor-Godot/pull/52)** and independent test orchestration all successful.
- Candidate test [Actions run 40545034376](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/40545034376) passed Godot / UPDS / Room Builder / Web export and produced `raven-candidate-web-40545034376` for seven-day retention. Candidate deployment to stable Pages was **skipped**. PR #52 was closed **unmerged** and ZIP removed from `incoming`.
- Dashboard status now reflects **integrated** MOB-01 (automatic PR), MOB-02 (CI) and MOB-03 (trusted review portal + non-deployed Web artifact). This is **not** full MOB-04 acceptance: no physical phone ZIP upload, no exhaustive adversarial live integration test, no playable preview on a distinct origin.
- The first R2 ZIP failed safely because `main` changed during the test (PR #51 merged); R3 was rebased against latest SHA and succeeded. This proves stale-base protection, not an unexplained defect.

## 2026-10-27 — MOB-04 real phone upload verified (partial acceptance)

- **Owner-confirmed physical phone upload:** ZIP `RM-MOB04_PHONE_R1.zip` (752 B) committed under `incoming/`. The archive contains only `docs/evidence/mobile_phone_upload_20261027.txt`; no gameplay/art/runtime data.
- [Import workflow 40554280539](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/40554280539) completed its **read-only validation, candidate creation, automatic PR #55 and isolated CI dispatch** successfully. [PR #55](https://github.com/bezdredoff/RavenManor-Godot/pull/55) automatically created by GitHub Actions, reviewed as exactly one harmless text-file addition and deliberately **closed without merge**.
- Both normal PR CI and [dispatched independent candidate CI 40554457157](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/40554457157) succeeded: Godot / UPDS / Room Builder / Web export; candidate Web artifact `raven-candidate-web-40554457157` uploaded for seven days, **candidate Pages deploy skipped**. Disposable ZIP removed from `incoming` while retaining the stable upload folder README.
- **MOB-04 remains in progress** until live malformed-archive rejection, phone-based review/download usability and remaining device acceptance are evidenced. Current `/preview/` lists CI artifacts, not playable candidate JavaScript. The automated, permitted phone-to-PR delivery path itself is operational.

## 2026-10-27 — CODE-02A after merged PR #54; roadmap/status reconciliation

- [PR #54](https://github.com/bezdredoff/RavenManor-Godot/pull/54) is **merged in main** (2026-10-27T18:07:19Z). The original UPDS `match3_board_shape.gd`, `match3_tile_motion_layer.gd`, `match3_tutorials.gd`, `css_motion.gd` and `match3_tile_motion_layer.tscn` are now committed alongside `tests/raven/upds_match3_visual_primitives_smoke.gd`, Linux/Windows checks and source blob SHA documentation.
- **Scope distinction:** `CODE-02-00` = **merged** reusable primitives. `CODE-02-01` (input/touch/swipe and full board UI) and `CODE-02-02` (full cascades/feedback/specials renderer) remain **in_progress**; current playable vertical slice still uses the old Raven Match-3 greybox. GFX-10 tile/blocker/FX approval is independent and still pending.
- [PR #56](https://github.com/bezdredoff/RavenManor-Godot/pull/56) is **merged** (2026-10-27T18:07:46Z), recording the owner-confirmed phone ZIP upload, automatic [PR #55](https://github.com/bezdredoff/RavenManor-Godot/pull/55) and independent green Actions runs. PR #55 was deliberately closed unmerged; `incoming/` ZIP cleaned. MOB-04 remains **in_progress**, not accepted, until live adversarial cases and phone artifact/device review are verified.
- The paired engineering/graphics roadmaps remain **scope and acceptance plans**, while `data/raven/production/production_progress.json` overrides runtime/progress statuses for the dashboard. No change to save economy, story IDs, approved art or map navigation from these two PRs.

## 2026-10-27 — CODE-02 shared interactive board candidate

- [PR #58](https://github.com/bezdredoff/RavenManor-Godot/pull/58) (unmerged at authoring; branch `code/code-02-upds-match3-interactive-board`) reuses UPDS swipe thresholds/direction/neighbour bounds (source blob `76b42df35d4857f242d3f6bc06b9f989d43ad0a3`), UPDS rules/frames and the previously merged tile motion/shape scene. It replaces the click-only Match-3 grid in playable `RM-VS-01` with a touch/mouse board and frame-driven animations; theme remains temporary Raven colors/glyphs.
- Match3 `level_won` still updates **only** the existing Raven reducer/store; no second save authority, campaign migration or story ID change. Hints highlight rather than autoplay an artificial best move.
- `CODE-02-01/02` remain **PR_review**, not accepted. Complete phone QA, advanced special/help/UI polish and GFX-10 visual acceptance remain open. This section is provisional until review/merge/CI confirmation.

## 2026-10-27 — CODE-02B candidate for Match-3 guidance, specials and retry

- [PR #58](https://github.com/bezdredoff/RavenManor-Godot/pull/58) merged: the playable `RM-VS-01` board now consumes UPDS drag and frame contract; original UPDS engine remains unchanged.
- The `code/code-02b-match3-help-blockers-results` candidate extends that shared presenter with Raven-only contextual help, explicit loss/retry that **does not award level_won**, reduced-motion toggle, distinct five UPDS special symbols and layer-count blocker badges, plus progress for all UPDS objectives.
- New tests: `tests/raven/upds_match3_presentation_states_smoke.gd` added to `scripts/check.sh` and `check.ps1`. Pending CI and manual mobile QA. `CODE-02-01/02` stay `in_progress`; `CODE-02-03` is `PR_review`, not completed. Eight themed tiles are placeholders; **GFX-10 approval remains separate**.


## 2026-10-27 — CODE-02C original UPDS motion segment/impact parity candidate

- [PR #59](https://github.com/bezdredoff/RavenManor-Godot/pull/59) **merged**. Temporary Raven Match-3 help, five specials, blockers and explicit retry are present in main; the larger task `CODE-02-03` is merged, not art/device-accepted.
- `code/code-02c-special-impact-segment-motion` adds a pure visual adapter for existing UPDS `segmentTop/segmentBottom` per tile fall; passes `clipRect` to the **unchanged UPDS tile motion layer** so visual copies cannot pass through blocker/hole rows. Original UPDS clear/settle/cascade snapshots drive temporary special-specific impact flashes and concise feedback; reduced-motion bypasses visual transitions.
- CI candidate `tests/raven/upds_match3_frame_fx_smoke.gd` exercises real UPDS direct special combo, segment bounds and effect cleanup. No balance, story, first-clear work points or save schema changes. Await CI + review. Real device safe area/gestures, persisted motion setting and approved GFX-10 sprites remain pending.


## 2026-10-27 — CODE-02D and mandatory per-PR dashboard status policy (candidate)

- [PR #60](https://github.com/bezdredoff/RavenManor-Godot/pull/60) merged 2026-10-27T19:17:44Z: UPDS segment-bounded falls and special clear overlay; CODE-02-02 ledger reconciled from stale PR_review to **merged**, but GFX-10/mobile QA remains outstanding.
- [CODE-02D PR #61](https://github.com/bezdredoff/RavenManor-Godot/pull/61) (`code/code-02d-mobile-hud-governance`): new task `CODE-02-04` adds mobile widths 320/390/412/430, dynamic board reflow, objective wrapping, two-column footer, 44px actions and native mobile safe insets. Godot HUD/layout smoke added; **awaiting CI and physical-device screenshots/gestures**; no GFX-10 approval.
- **PROC-005** in [PR #61](https://github.com/bezdredoff/RavenManor-Godot/pull/61), added to process backlog: each authored code/art/docs/process PR must update **both** `docs/STATUS.md` and `data/raven/production/production_progress.json` plus relevant backlog/roadmap when scope changes. `scripts/raven/tools/check_pr_governance.py` is wired into Actions pull-request builds with Python regression tests. Automatic untrusted `candidate/mobile-<run>` inbox PRs are the only technical exception pending human review. Do not edit generated dashboard JSON as authority.


## 2026-10-27 — CODE-02-05: fix QA entry after user could not reach Match-3

- Owner QA reported: after finishing a VN scene, a **walkable map** appears instead of Match-3, contradicting previous test instructions. Code audit: in true `RM-VS-01`, `raven_slice_director.gd` sequences **letter → road → gates → arrival → access ("Освободить дверь спальни", "ВЫПОЛНИТЬ") → first Match-3 RM-LVL-001**. Its `vertical_slice.gd` does *not* automatically navigate to the map at this point. A separate Hall VN pilot `hall_tea_vn.gd` **does** return to `manor_greybox.tscn`. Therefore the user likely entered a different demo; the precise original click path was not confirmed.
- Actual QA blocker discovered: Prototype Lab `4 · Content Preview` still rendered **legacy 50px click-grid**, not the real `Match3Board` delivered in merged #58–61. This prevented targeted testing of the production candidate after story/map confusion.
- CODE-02-05 candidate branch `fix/match3-qa-entry-content-preview-parity` introduces a prominent `0 · MATCH-3 QA` launcher button to open `RM-LVL-001` immediately, without prologue, map traversal, unlocks, or changing Raven-save. Content Preview now renders **the same UPDS-powered `match3_board_presenter.gd` and Raven theme** for `RM-LVL-001..003`, including calls from the map's selected object, while keeping isolated QA result text and 320px-friendly scrolling. Actual prologue, map, director order and canonical story are unchanged.
- Regression `tests/raven/content_preview_match3_qa_smoke.gd` tests one-shot QA metadata, correct shared presenter, real UPDS level completion with no campaign reward, menu switching, map preview compatibility. Must pass CI; physical iPhone QA remains open.
- Reconciled previously merged [PR #61](https://github.com/bezdredoff/RavenManor-Godot/pull/61): `CODE-02-04` and `PROC-005` marked `merged` (not accepted) in production progress. New `CODE-02-05` added to code backlog as `PR_review`. This fix updates both mandatory docs/progress sources in same PR.


## 2026-10-27 — CODE-02 real-phone QA FAILED; recovery in progress

The owner tested merged PR #62 in real Web browsers and reported: (1) no working swipes on iPhone **or desktop**; (2) hint visually only highlights one tile; (3) 'Как играть' opens an inline accordion instead of UPDS modal; (4) visual design is markedly different both from UPDS and the older https://bezdredoff.github.io/RavenManor/ PWA. Prior green Godot CI tests incorrectly described an accepted/faithful UPDS port. Do **not** call CODE-02-01/03/05 accepted. These states have been reopened as `in_progress`.

Audit found Godot's Raven Match3 UI was largely a newly authored simplified button-based `match3_board_presenter.gd`, **not** a source-identical transplant of the polished UPDS `match3_screen.gd` presentation. Its global-only `_input` handler was not tied to individual tile `gui_input`, and the help was an inline PanelContainer. The hints showed two indices in data, but their button visual styling was too weak and lacked proper disabled-state consistency. This branch `fix/code02-input-help-parity-recovery` adds per-cell GUI event listeners, merges drag release into one path, a centered modal dialog, stronger two-tile visual indication, and a Godot regression for cell event path and modal help.

**Not yet accepted:** The complete visual style/design and feature parity must be planned against BOTH polished UPDS Godot/Web help/board interfaces and the original Raven Manor PWA art. No claim the current prototype matches either. Acceptance requires testing the **built Web version on real iPhone/desktop** and user screenshots, plus side-by-side design parity before closing CODE-02. Asset/GFX-10 approval independent.

## RM-GFX-WATERCOLOR-001 — candidate watercolor VN A/B pilot (2026-10-28)

Candidate feature/vn-watercolor-pilot-rebased adds separate Evelyn/Ada tea scene under original launcher card; no campaign mutation. Pending CI/Web/mobile verification. See docs/VN_WATERCOLOR_PILOT.md.

## 2026-10-29 — RM-GFX-WATERCOLOR-001 rejected and retired

Owner inspected the deployed watercolor shader duplicate of Evelyn/Ada tea VN from merged PR #66 and found the visual result unsatisfactory. This approach is **not accepted** as the game's art style. Remove the experimental duplicate scene, runtime shader and launcher entry, retaining the original tea VN and all unrelated functionality. Preserve the trial outcome in docs/VN_WATERCOLOR_PILOT.md and dashboard task status `deferred`; do not present the experiment as pending approval.


## 2026-10-31 — VN-EDITOR-00: Godot-native VN Studio specification ([PR #68](https://github.com/bezdredoff/RavenManor-Godot/pull/68), open)

Owner requested **inside-Godot** PowerPoint-like visual VN editor supporting both Raven and legacy **UPDS-godot**. Proposed `docs/VN_STUDIO_EDITOR_SPEC.md` defines EditorPlugin main screen, scene/staging/dialogue/character/timeline/graph UX, common CODE-03 VN runtime adapters, versioned data model, read-only UPDS 45-index viewer, conflict-safe overlays, deterministic converter with save mapping, parity+rollback gates. Agent/human workflow documented in `docs/process/VN_STUDIO_AGENT_GUIDE_RU.md`. Nine `VN-EDITOR-00..08` tasks are proposed in the CODE-03 backlog, dashboard derives from source JSON. **Documentation/design only:** no plugin, game logic, donor content migration, imported private assets, actual UPDS full-corpus audit, Godot test, CI or device evidence claimed. `VN-EDITOR-00` is `PR_review` in [PR #68](https://github.com/bezdredoff/RavenManor-Godot/pull/68), not merged or accepted; all runtime/editor implementation and acceptance gates pending.


## 2026-10-31 — VN-EDITOR-00 merged / VN-EDITOR-01 UPDS donor audit candidate

PR [#68](https://github.com/bezdredoff/RavenManor-Godot/pull/68) **merged** at `81353fdb8d72b191fbf1e8c53dc131618321349c`; it delivered **only** the VN Studio plugin/migration specification and tracked proposed tasks. Historic note above about an open #68 reflects its then-current PR review; current source-of-truth is production_progress.

For **VN-EDITOR-01** we inspected all **45 scene JSON files** of the *private canonical* `bezdredoff/UPDS-godot` source (commit `3deed628efd6c22bcd1717f7c545b7d3ca865781`): **1,026 line occurrences** across branch variants, **213 hidden stage-direction occurrences**, 3 locales (RU/EN/BE), **22 Match-3 gates**, **8 embedded choice gates + initial A/B/C variant scene**, **3 ending scenes**. These are not necessarily unique dialogue IDs. See `docs/UPDS_VN_CORPUS_AUDIT.md` and source-only hashes in `data/raven/production/upds_vn_corpus_manifest.json`. No private screenplay text, image or assets were copied into public Raven. Added a read-only audit checker and six synthetic tests, wired to Linux check; **real donor checkout Python execution, Godot visual/choice parity, imported game data, save migration, human acceptance and full E0 sign-off remain unverified**. VN Studio EditorPlugin does not exist yet. This branch is intended as its own reviewable PR, not production runtime integration.

**Review link:** [PR #69](https://github.com/bezdredoff/RavenManor-Godot/pull/69) is open for VN-EDITOR-01. `production_progress.json` status `PR_review` reflects this review step, not implementation acceptance.


## 2026-10-31 — VN-EDITOR-02 native Godot read-only Legacy Viewer candidate

Godot 4.7.2 EditorPlugin `addons/vn_studio/` adds a **VN Studio** main workspace. The initial **read-only** viewer asks the human for a **local private UPDS-godot root**, uses `data/save_contract.json` to order its 45 scene IDs (including missing locker sceneIndex), reads `data/*.json`, `data/asset_catalog.json`, `data/actor_layouts.json` and displays selectable scenes, A/B/C branch lines, three locales, hidden stage directions, character asset/pose metadata, scene gates and a **rough** visual stage with original local images. It does not write source, run story progression or import private content into Raven. Godot project plugin enabled, synthetic headless smoke added to Linux/Windows check scripts. See `addons/vn_studio/README.md` for usage and limitations. **Not implemented:** editing/dragging, exact Godot VN runtime parity, save migration, asset conversion, approval. Manual native editor QA on a clean authorized UPDS checkout still required.

**PR review:** [#70](https://github.com/bezdredoff/RavenManor-Godot/pull/70) remains open, tracked `VN-EDITOR-02 = PR_review`. Do not claim merged/accepted or UPDS full-asset editor validation until verified.


## 2026-10-31 — VN-EDITOR-03 native Godot draft authoring (candidate)

Owner merged VN-EDITOR-02 [PR #70](https://github.com/bezdredoff/RavenManor-Godot/pull/70) at `7d198e94ee8e56a8c64a418ade07337dc857b82a`; existing manual private-donor editor QA still outstanding. This branch adds `addons/vn_studio/editor/draft_store.gd` and upgrades `studio_view.gd`: localized `speaker`/`emotion`/`text` edits, per-line actor pose chooser from donor catalog, mouse drag for approximate position, per-scene Undo/Redo, explicit local draft save/reopen. Legacy donor source remains immutable. Draft path: private local `user://vn_studio_drafts/v1/<source-root-fingerprint>/<sceneIndex>.json`, version `vn-studio-legacy-overlay-v1` pinned by original scene SHA. Stale/incompatible overlay fails closed; no commit of edited private screenplay to public Raven. Adds headless **synthetic** round-trip/save/sha-drift smoke and Linux/Windows runner entries. **Not implemented:** full runtime preview, drag asset creation, exact UPDS layout parity, choices authoring, migration, campaign save changes, private donor copy. Native editor visual QA and acceptance must follow actual CI and user review; this is an authored PR candidate, not a merged feature.

**PR review:** [#71](https://github.com/bezdredoff/RavenManor-Godot/pull/71) is open for VN-EDITOR-03, `PR_review`, not merged/accepted. CI on latest head and manual donor UI QA required.


## 2026-10-31 — VN-EDITOR-04 character catalog / animation preview candidate

[PR #71](https://github.com/bezdredoff/RavenManor-Godot/pull/71) merged as `83e7bcd78dc1fcce000d89b4a65682f16f68d12e` (VN-EDITOR-03) with green CI. No manual UPDS-Godot editor acceptance reported. **VN-EDITOR-04** adds an editor-only character library in the existing `VN Studio` tab: local donor catalog from `data/asset_catalog.json` (17 real character IDs, with flat pose/expression portraits, icon and special assets), lazy portrait thumbnails, missing-art flags, controlled pose application **only to a matching actor on the selected line**, and preview-only `soft_idle/fade_in` effects disabled by default with Reduced Motion enabled. These effects are **not saved** to draft or runtime; absence of outfit IDs and layered expressions is explicit (no invented content). Same private UPDS `assets/` location rules; no private content committed. Synthetic test `tests/raven/vn_studio_catalog_smoke.gd` and Linux/Windows check scripts added. **Not implemented:** costume/outfit authoring, full layered expression rig, production motion API, true renderer parity, donor write-back or migration. CI latest head and desktop visual QA pending. Status `VN-EDITOR-04 = PR_review` only after PR created.

**VN-EDITOR-04 PR review:** [PR #72](https://github.com/bezdredoff/RavenManor-Godot/pull/72) opened; tracked `PR_review`. Pending latest CI and real private UPDS editor visual QA. Not merged or accepted yet.


## 2026-10-31 — VN-EDITOR-05 Story Graph candidate (read-only)

Owner merged [PR #72](https://github.com/bezdredoff/RavenManor-Godot/pull/72) at `1cc99d93e3066d0ecc4003f3dde086e8148cb8dc` (VN-EDITOR-04), CI previously passed; no local private-donor visual QA acceptance recorded. Proposed **VN-EDITOR-05** adds `addons/vn_studio/editor/story_graph_model.gd` and native `GraphEdit` tab `story_graph_view.gd`, synchronized with scene navigation and RU/EN/BE. Nodes: all 45 legacy scenes, variant A/B/C sequences, 8 inline choice gates, 22 Match-3 levels and 3 ending outcomes; actual counts to be verified from private donor after manual open. Source semantics retained: `nextSceneIndex`, `onWinSceneIndex`, branch route targets, ending success requirements/fallback. Incoming/outgoing edges remain **read-only**; branch changes, story state, match-3 results and saves not mutated. Approximate Godot graph layout with local pan/zoom, focused neighborhood and entire story views. Synthetic test of a 45-scene corpus with branches/gates/fallback and widget UI added to both CI scripts. Existing VN staged authoring/drafts unaffected. **Not accepted:** private donor graph render/choice fidelity, migration/export, interactive conditions authoring or CODE-03 full runtime parity; human QA and green CI required. Status remains PR candidate, not merged until owner review.

**VN-EDITOR-05 review:** [PR #73](https://github.com/bezdredoff/RavenManor-Godot/pull/73) open; dashboard task `PR_review`. No claim of merge, end-to-end private UPDS inspection or user visual acceptance. Latest CI pending.


## 2026-10-31 — VN-EDITOR-06 private conversion dry-run candidate (partial work package)

Owner merged [PR #73](https://github.com/bezdredoff/RavenManor-Godot/pull/73) at `c29dea932c21eda0d68fc9477ed5699cd766cf79`; main [CI 41226672594](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41226672594) passed after initial missing-index bug fix. Existing graph implementation is **read-only** and unverified in private donor desktop visual QA.

This candidate adds `addons/vn_studio/editor/conversion_bundle.gd` and `migration_review_view.gd` for the VN Studio **Migration & Review** tab. Dry-run reads the 45 validated UPDS-godot scenes and local SHA-pinned drafts without writing donor, generates a deterministic `vn-studio-scene-v1` bridge wrapper for each scene containing `legacyOriginal` and draft-applied `payload`; a `conversion_manifest.json` lists source/output SHA and changes, and `save_migration_map.json` gives candidate numeric-scene-index/variant-line mappings. Explicit confirmation allows a **new no-overwrite private** export under local `user://vn_studio_conversions/v1/`. Preview invalidated by edits; stale sources/drafts block export. No assets copied, no Raven/UPDS story state mutated, no runtime switch or user-save write. Test `tests/raven/vn_studio_migration_smoke.gd` generates artificial 45-scene corpus, validates RU/EN/BE + variants, private local draft application, deterministic hashes, explicit export/no-overwrite, source drift rejection. Linux/Windows check scripts updated.

**Partial task only:** no executable generic VN runtime for bundle, no real save migration (map explicitly unverified), no full text-level side-by-side diff, no private donor import/parity, no asset reference QA, no roundtrip into authoritative editable UPDS source, no rollback operation beyond unconnected export. Full `VN-EDITOR-06` acceptance remains pending `VN-EDITOR-07` and CODE-03 work; mark progress `PR_review` only after PR created and CI evidence.

**VN-EDITOR-06A review:** [PR #74](https://github.com/bezdredoff/RavenManor-Godot/pull/74) open. Dashboard `VN-EDITOR-06 = PR_review` reflects first *partial* migration gate, not full task acceptance; CI latest head and real UPDS donor/full-save parity outstanding.


## 2026-10-31 — VN-EDITOR-06B legacy save-position inspection (candidate)

[PR #74](https://github.com/bezdredoff/RavenManor-Godot/pull/74) merged as `65cfee2bd8fc1496aaab8e3271353d03237b1b02`; it delivered only private bridge export, not a runtime-converted story or real-save import. This candidate adds `save_position_inspector.gd` to inspect owner-selected **private UPDS JSON saves in-memory only**, resolving numeric scene/line using the versioned map, `choice` A/B/C for first variant scene, storyChoices for later gate/ending routes, read history, completed Match-3 IDs and allowed ending boundary. Invalid/foreign saveKey/schema/index/line/choices fail closed; hidden lines flagged. Godot Migration & Review shows a position preview but has **no apply-save action**. `conversion_bundle.gd` also emits deterministic `changePaths` with allowed-field whitelist, rejecting unintended mutation of narrative topology. CI synthetic unit smoke introduced on both Linux/Windows; no private data published. **Remaining**: runtime replay and compare with actual UPDS `StorySession`, real saved-state migration/rollback into playable runtime, full 45-scene parity, actual donor desktop QA. VN-EDITOR-06 remains in progress; PR/CI pending.

**VN-EDITOR-06B review:** [PR #75](https://github.com/bezdredoff/RavenManor-Godot/pull/75) open. Status `PR_review` applies to this bounded increment only; full save migration and real UPDS parity unverified.

**VN-EDITOR-06B passing CI:** [run 41228302230](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41228302230) passed on implementation head `f9cecceb0c79576c096189da144d567c93ffeb14`, including new legacy save-position/semantic-diff smoke, all prior Godot tests, dashboard and PR governance. EditorFileDialog headless incompatibility was corrected to FileDialog. PR #75 still requires review; no full private donor or game save compatibility certification claimed. Later documentation-only head changes may trigger their own run.


## 2026-10-31 — VN-EDITOR-06C semantic replay data-parity candidate

VN-EDITOR-06B [PR #75](https://github.com/bezdredoff/RavenManor-Godot/pull/75) merged to `main` at `f236f6449dd44f5dd03e1833cb32067877dab00a`; actual importer into new runtime is not implemented. The next review candidate implements `addons/vn_studio/editor/story_semantic_parity.gd` and `tests/raven/vn_studio_story_semantics_smoke.gd`, comparing **UPDS source scene dictionaries** against `vn-studio-scene-v1.payload` across 45 scenes, every branch/line, unresolved/resolved choice checkpoints, first A/B/C locker jump, hidden/resume, Match-3 win scene metadata and three ending routes with donor `ending_outcomes.json` trust/evidence/fallback rules. Revalidates dry-run against current SHA, protects immutable `legacyOriginal`, rejects all unintended changes in fields outside the authoring whitelist. Godot `Migration & Review` now has **«Сравнить переходы и концовки»**; private export is disabled in GUI until successful replay. Linux/Windows Godot synthetic check scripts updated.

**Evidence limits:** this is only deterministic *data semantics parity*, not executing the donor's actual `StorySession`, not a runnable new VN engine or real save import, and not full user-reviewed 45-scene visual QA; `CampaignData` clue awarding and real persisted state remain untested. `VN-EDITOR-06` is still unfinished. New PR and CI pending.

**VN-EDITOR-06C review:** [PR #76](https://github.com/bezdredoff/RavenManor-Godot/pull/76) open; `VN-EDITOR-06 = PR_review` is for this bounded candidate only. CI pending. Not an independent UPDS StorySession oracle or complete save migration.

**VN-EDITOR-06C verified CI:** [run 41229807616](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41229807616) passed on implementation head `a2ad482c8c4a8957343ad6a6888f8fdfabf6c427`: new synthetic `VN Studio semantic replay parity passed`, existing 6 VN Studio smokes, dashboard/PR governance and browser QA; logs show no SCRIPT ERROR. CI initially caught JSON numeric representation false mismatches in immutableOriginal and nested route/ending dictionaries; both normalized before comparison, while actual unsafe route mutation test remains fail-closed. **PR #76 remains review candidate; no independent runtime replay or true old-save migration.**


## 2026-10-31 — RAVEN-VN-EDITOR-01: project-owned Raven script inside VN Studio

Merged [PR #76](https://github.com/bezdredoff/RavenManor-Godot/pull/76) at `41f78a786d8d8b37d0d90e7ac7bb93b3fa9333eb`; post-merge main CI [41231531095](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41231531095) and [41231531685](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41231531685) succeeded. `VN-EDITOR-06` implementation is merged but independent UPDS StorySession parity, real old-save import and manual UI approval remain incomplete.

**RAVEN-VN-EDITOR-01 candidate:** adds `addons/vn_studio/editor/raven_story_store.gd` and `raven_story_view.gd` with a separate project-owned **Raven Manor** tab (does NOT require UPDS donor). This tab reads the existing `data/raven/production/season1_dialogue_catalog.json`: 28 scenes / 280 lines, scene and line status, RU texts, BE/EN translations with explicit RU fallback, and read-only stage/cue/trigger metadata from `vn_staging.json`, `line_performance_cues.json`, `map_narrative_routes.json`. Only user-modified `localized.ru/be/en.text` is locally persisted under `user://raven_story_studio/v1/<root-fingerprint>/draft.json` with a strict source SHA lock, an explicit **Export JSON candidate** action creates a separate no-overwrite full catalog under `user://raven_story_studio/v1/exports/`. Neither action changes Raven runtime `rm_vs_01_content.json`, UPDS donor, public Git source or save state. Candidate JSON needs review/promotion in a later PR. This is NOT a playable new VN engine, new art pipeline or full visual stage designer. `tests/raven/vn_studio_raven_story_smoke.gd` tests real 28/280 source loading, synthetic fixture local draft roundtrip, fallback locale, export immutable and SHA drift. Linux/Windows runners wired; **CI/PR and human editor QA pending**.

**RAVEN-VN-EDITOR-01 PR review:** [PR #77](https://github.com/bezdredoff/RavenManor-Godot/pull/77) open. Dashboard `PR_review`; latest CI and Godot desktop visual QA required. Candidate JSON export remains outside tracked project until explicitly reviewed and promoted.

**RAVEN-VN-EDITOR-01 CI evidence:** [run 41235837433](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41235837433) succeeded on implementation head `4d31131e0527f341dfa84a9885f33b1100a34271`, with `VN Studio Raven Manor authoring passed`, successful Raven production narrative smoke, old UPDS tests, dashboard and web export. The earlier red run lacked a registered task ID in `gap_work_packages.json`; fixed in this branch. Next documentation-only commit will create a new CI run. Manual Godot editor/visual acceptance remains outstanding; PR remains review, not merged.


## 2026-10-31 — Raven VN Studio visual stage: clean main integration

Raven screenplay PR #77 is merged into `main`. Visual stage PR #78 was merged into the older feature branch **after** #77 merged, so its code was not in `main`. A direct promotion PR #79 conflicts (`mergeable_state=dirty`). This clean main-based integration branch contains only the actual stage designer changes, source-locked local drafts, synthetic tests and canonical docs/dashboard updates, without replaying #77 commits. Target: main, PR pending.

Godot `VN Studio → Raven Manor → Постановка` supports selected catalog background, up to three approved actor cards, selected pose/emotion, mouse dragging with normalized x/y and Undo/Redo snapshots. Saves `user://raven_story_studio/v1/<root-sha>/draft.json` and exports separate reviewed staging JSON candidate (never overwrites game source). Missing art explicitly placeholders, real Hall/Evelyn/Ada pilot where available. Staging changes source-hash-locked; source drift blocks saving. Original UPDS files and gameplay runtime untouched. Human editor UI acceptance still pending. Test suite: `vn_studio_raven_story_smoke.gd` plus scripts/check.sh and check.ps1. Merge clean PR then user can Pull main in GitHub Desktop or `git pull --ff-only origin main`.


## 2026-10-31 — RAVEN-VN-EDITOR-03: scene preview UX (PR #81)

Owner confirmed the Raven VN editor works locally and requested readable character choices, browseable background variants, a toggleable pixel grid, and a preview of the current VN dialogue. PR #81 adds a compact 3-column scrollable UPDS character-pose gallery and a size slider for Raven character cards. The Raven stage background browser lists all 11 canonical masters, while lighting and room-state dropdowns use only their declared lightingVariants/stateLayers. Invalid combinations fail schema validation. Only the known hall pilot illustration is used as a reference; missing states remain ART PENDING.

Two editor-only switches render numbered 390x844 logical-pixel grid lines and selected localized line/speaker UI on top of the staged actors. These overlays and the actor preview size never persist to JSON. Existing draft save and stage candidate export preserve backgroundId/lighting/roomState and positions, but cannot change runtime, artwork or actual saves. Added smoke coverage for new controls and forbidden variants. Source-of-truth: addons/vn_studio/README.md (legacy stage docs) and canonical production gap_work_packages/production_progress. CI and manual Godot visual acceptance are required before merging.
