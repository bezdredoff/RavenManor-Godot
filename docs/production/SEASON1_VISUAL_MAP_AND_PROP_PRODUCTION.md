# Raven Manor — Season 1 VN staging, props, map and production plan

**Status:** production proposal built from the merged season-one screenplay, 2026-10-26. Not an imported authored room layout; no new gameplay flags or save keys approved by this file. The runtime first slice and Stage 1/2 decisions remain authoritative.

## Source / what is already grounded

- Full screenplay: `docs/NARRATIVE_SCRIPT_READABLE.md` (all six chapters, approved for continuation).
- Existing asset proposals: `docs/assets/CHARACTER_PRODUCTION_BIBLE.md`, `ROOM_OBJECT_REGISTER.csv`, `ROOM_FURNISHING_AND_PLACEMENT.md`.
- Working VS navigation: `data/raven/manor_greybox_graph.json` (Hall → Corridor → Bedroom, authored edges and stable hotspots).
- Whole-season eight-room preview: `data/raven/season1_world_map.json` (**feasibility only**, world coordinates and legacy prop-level associations are not approved).
- Art approval constraint: `docs/ROOM_PIPELINE_NEXT_GATE.md`; AI Hall previews not accepted calibrated art.
- Locale donor: see `docs/production/LOCALIZATION_UPDS_ADAPTATION.md`.

## 1 — Character art budget (four principal cast members)

**Asset strategy:** layered visual-novel sprites with common body poses, independently swapped eyes/mouth/eyebrows, detachable held props, shared blink/talk/breathing/idle micro rig. Three base poses and six face expressions per main cast member; distinctive characters use specific gesture cues so they do not behave as one clone. **Do not generate 3×6×micro permutations as finished full-size pictures.** Separate mildly-chibi map sprites are required; VN-scale poses cannot merely be resized for the map.

| Actor | Three VN base poses | Six expressions | Distinctive micro-animations | Map role |
|---|---|---|---|---|
| Эвелин | relaxed, investigate, decide | neutral, skeptical, curious, amused, worried, determined | evelyn_hair_tuck, evelyn_note_glance, evelyn_firm_exhale | full_traversal |
| Ада | composed, offer_tray, apron_reach | neutral, dry_amused, stern, warm, concerned, regretful | ada_apron_reach, ada_precise_straighten, ada_long_paused_blink | short_traversal |
| Лукас | formal, folder_present, explain | neutral, professional, polite_smile, reserved_worry, dry_amused, serious | lucas_glasses_adjust, lucas_page_align, lucas_deliberate_pause | stationary_with_entry_exit |
| Роуэн | work_ready, rest_tool, point_route | neutral, wry, friendly, concerned, focused, nostalgic | rowan_sleeve_wipe, rowan_tool_lower, rowan_weight_shift | limited_traversal |

The `data/raven/production/line_performance_cues.json` registry annotates **all 280 dialogue lines**, and marks only selected lines for discrete signature gestures. Mouth movement and blinking should be procedural, not an imported animation file per line. Slot/portrait emotions establish a scene default, with future editorial freedom to fine-tune dramatic beats. Every asset must have an idle/reduced-motion fallback. No early fang/wolf/ghost variants visible in Season 1.

**Supporting cast budget:** no new fully animated electrician, plumber, glazier, structural engineer, clockmaker or courier by default. Employ a service notification, contextual insert, sound, tool and before/after map states; promote to a full portrait only if a new dialogue scene is approved. The unknown voice in the final childhood memory is **offscreen** and must not be given a revealing portrait.

## 2 — Reusable background masters, light/state variants and VN placement

Total plan: **11 master families** (not 28 unique painted backgrounds). There are eight conceptual map-room areas, plus compact exterior/road/apartment coverage; bathroom remains a narrow focus vignette. The existing library is `RM-ROOM-ARCHIVE` in the map. The garden is a proposed exterior zone, not yet a certified world-map room.

| Master | Anchored world room | Allowed lighting | Reusable dressing/state overlays |
|---|---|---|---|
| `BG-APARTMENT` | prologue/exterior not yet mapped | day | packed_boxes |
| `BG-ROAD` | prologue/exterior not yet mapped | dusk | mist |
| `BG-ENTRY` | RM-ROOM-ENTRY | day, dusk | overgrown, approachable |
| `BG-HALL` | RM-ROOM-HALL | day, evening, night | dusty, habitable, storm |
| `BG-CORRIDOR` | RM-ROOM-CORRIDOR | day, night | blocked, clear |
| `BG-BEDROOM` | RM-ROOM-BEDROOM | day, night | covered, livable |
| `BG-BATH-VIGNETTE` | RM-ROOM-BATHROOM | day | wet_unsafe, specialist_fixed |
| `BG-KITCHEN` | RM-ROOM-KITCHEN | day, evening | power_off, partial_lighting |
| `BG-LIBRARY` | RM-ROOM-ARCHIVE | day, evening, night | shut_dusty, usable, storm_leak |
| `BG-GARDEN` | prologue/exterior not yet mapped | day, dusk | unsafe_path, partly_repaired, after_storm |
| `BG-CONSERVATORY` | RM-ROOM-CONSERVATORY | day, dusk, storm | broken, partially_safe, storm_damage |

One background family = base composition + independent light/color grading + named art overlays (dust, cobwebs, repair damage, curtains/shutters, candle/sconce lights, leak, storm). **No unique background painting for each story beat.** A view may reuse a master with a focal crop/character plate, but must remain aligned to the approved Room Builder architecture. VN 2D camera/framing is its own art surface; do not stretch top-down map images into eye-level VN plates.

Portrait-first layout uses `left/center/right` slot IDs for **1–3 visible characters**; slot calibrations use foot/ground reference, no character swapping identity on reuse. A two-person shot usually uses left/right; a three-person shot all three. Offscreen lines can keep the current visible cast without a new portrait. The final memory voice and Ada at the bedroom door are offscreen.

### Scene-by-scene VN art sheet

| Scene | Background state | Visible actor slots and key pose/emotion/gesture | How scene is entered |
|---|---|---|---|
| `RM-BEAT-00-01` | `BG-APARTMENT` · day/packed_boxes | 1: Эвелин (center, relaxed/neutral, evelyn_hair_tuck) | auto_new_game → envelope |
| `RM-BEAT-00-02` | `BG-ROAD` · dusk/mist | 1: Эвелин (center, relaxed/curious, evelyn_hair_tuck) | scene_complete → road_transition |
| `RM-BEAT-00-03` | `BG-ENTRY` · dusk/overgrown | 2: Эвелин (left, relaxed/neutral, evelyn_hair_tuck); Ада (right, offer_tray/dry_amused, ada_precise_straighten) | scene_complete → estate_gate |
| `RM-BEAT-01-01` | `BG-HALL` · evening/dusty | 3: Лукас (left, folder_present/professional, lucas_page_align); Эвелин (center, relaxed/skeptical, evelyn_hair_tuck); Ада (right, composed/dry_amused, ada_long_paused_blink) | scene_complete → entry_to_hall |
| `RM-BEAT-01-02` | `BG-BEDROOM` · day/livable | 2: Эвелин (left, relaxed/neutral, evelyn_hair_tuck); Ада (right, composed/dry_amused, ada_long_paused_blink) | restoration_done → RM-HS-002 |
| `RM-BEAT-01-03` | `BG-BATH-VIGNETTE` · day/wet_unsafe | 2: Эвелин (left, relaxed/neutral, evelyn_hair_tuck); Ада (right, composed/dry_amused, ada_long_paused_blink) | first_clear → RM-HS-003 |
| `RM-BEAT-01-04` | `BG-HALL` · night/habitable | 2: Эвелин (left, relaxed/neutral, evelyn_hair_tuck); Ада (right, composed/dry_amused, ada_long_paused_blink) | clue_recorded → RM-HS-004 |
| `RM-BEAT-01-05` | `BG-HALL` · day/habitable | 2: Ада (left, composed/dry_amused, ada_long_paused_blink); Эвелин (right, relaxed/neutral, evelyn_hair_tuck) | scene_complete → RM-ROOM-HALL |
| `RM-BEAT-02-01` | `BG-HALL` · day/habitable | 2: Эвелин (left, relaxed/neutral, evelyn_hair_tuck); Ада (right, offer_tray/dry_amused, ada_precise_straighten) | scene_complete → hall_chair_table |
| `RM-BEAT-02-02` | `BG-ENTRY` · day/approachable | 3: Роуэн (left, point_route/wry, rowan_weight_shift); Эвелин (center, relaxed/neutral, evelyn_hair_tuck); Ада (right, composed/dry_amused, ada_long_paused_blink) | npc_tap → entry |
| `RM-BEAT-02-03` | `BG-KITCHEN` · day/power_off | 2: Эвелин (left, investigate/curious, evelyn_note_glance); Ада (right, composed/dry_amused, ada_long_paused_blink) | object_tap → kitchen_table |
| `RM-BEAT-02-04` | `BG-KITCHEN` · evening/partial_lighting | 2: Эвелин (left, relaxed/neutral, evelyn_hair_tuck); Ада (right, composed/dry_amused, ada_long_paused_blink) | specialist_result → kitchen |
| `RM-BEAT-03-01` | `BG-LIBRARY` · evening/shut_dusty | 3: Лукас (left, folder_present/professional, lucas_page_align); Эвелин (center, investigate/neutral, evelyn_note_glance); Ада (right, composed/dry_amused, ada_long_paused_blink) | door_tap → library |
| `RM-BEAT-03-02` | `BG-LIBRARY` · evening/usable | 3: Эвелин (left, investigate/neutral, evelyn_note_glance); Ада (center, composed/dry_amused, ada_long_paused_blink); Лукас (right, explain/professional, lucas_glasses_adjust) | object_tap → library_desk |
| `RM-BEAT-03-03` | `BG-LIBRARY` · evening/usable | 2: Эвелин (left, investigate/worried, evelyn_note_glance); Лукас (right, explain/serious, lucas_glasses_adjust) | npc_tap → library |
| `RM-BEAT-03-04` | `BG-LIBRARY` · day/usable | 2: Эвелин (left, investigate/worried, evelyn_note_glance); Ада (right, composed/stern, ada_long_paused_blink) | object_tap → library_drawer |
| `RM-BEAT-04-01` | `BG-GARDEN` · day/unsafe_path | 2: Эвелин (left, relaxed/amused, evelyn_hair_tuck); Роуэн (right, rest_tool/focused, rowan_tool_lower) | npc_tap → garden_fence |
| `RM-BEAT-04-02` | `BG-CONSERVATORY` · day/partially_safe | 2: Эвелин (left, investigate/neutral, evelyn_note_glance); Роуэн (right, work_ready/focused, rowan_weight_shift) | specialist_result → conservatory |
| `RM-BEAT-04-03` | `BG-CONSERVATORY` · day/partially_safe | 2: Эвелин (left, investigate/neutral, evelyn_note_glance); Роуэн (right, point_route/focused, rowan_weight_shift) | object_tap → conservatory_bench |
| `RM-BEAT-04-04` | `BG-CONSERVATORY` · dusk/partially_safe | 2: Эвелин (left, relaxed/neutral, evelyn_hair_tuck); Роуэн (right, work_ready/nostalgic, rowan_weight_shift) | scene_complete → conservatory_evening |
| `RM-BEAT-05-01` | `BG-HALL` · night/storm | 2: Эвелин (left, relaxed/worried, evelyn_hair_tuck); Ада (right, composed/dry_amused, ada_long_paused_blink) | time_phase → hall |
| `RM-BEAT-05-02` | `BG-LIBRARY` · night/storm_leak | 2: Эвелин (left, investigate/neutral, evelyn_note_glance); Ада (right, apron_reach/regretful, ada_apron_reach) | object_tap → library_window |
| `RM-BEAT-05-03` | `BG-LIBRARY` · night/usable | 2: Эвелин (left, investigate/worried, evelyn_note_glance); Ада (right, composed/concerned, ada_long_paused_blink) | clue_recorded → library |
| `RM-BEAT-05-04` | `BG-HALL` · day/habitable | 3: Эвелин (left, decide/neutral, evelyn_firm_exhale); Роуэн (center, rest_tool/friendly, rowan_tool_lower); Ада (right, offer_tray/dry_amused, ada_precise_straighten) | time_phase → hall |
| `RM-BEAT-06-01` | `BG-LIBRARY` · evening/usable | 2: Лукас (left, folder_present/reserved_worry, lucas_page_align); Эвелин (right, decide/determined, evelyn_firm_exhale) | npc_tap → library_evening |
| `RM-BEAT-06-02` | `BG-HALL` · day/habitable | 3: Эвелин (left, decide/determined, evelyn_firm_exhale); Роуэн (center, point_route/focused, rowan_weight_shift); Ада (right, composed/dry_amused, ada_long_paused_blink) | object_tap → hall |
| `RM-BEAT-06-03` | `BG-BEDROOM` · night/livable | 1: Эвелин (center, decide/neutral, evelyn_firm_exhale) | scene_complete → bedroom_night |
| `RM-BEAT-06-POST` | `BG-LIBRARY` · evening/usable | 2: Лукас (left, folder_present/professional, lucas_page_align); Ада (right, composed/warm, ada_long_paused_blink) | optional_postcredits → library_evening |

**QA:** verify foreground masks, door frame occlusion, camera crop and actor feet against 390×844 and tablet. Changes to art layers **must not** grant or remove story flags.

## 3 — Props, inserts and map-state-linked objects

Use one identity/provenance record per prop; a VN hand-overlay, zoomed evidence insert and a map item are different **presentations of the same story object**, not separate lore items. First-season asset expansion should prioritize reusable groups rather than 37 individually painted large items. The identifiers below are logical prop families and link existing `RM-ASSET-*` registry IDs where available.

| Prop family | Meaning | Visual/state variants | Existing registered asset |
|---|---|---|---|
| `PROP-LETTER` | конверт с наследством | sealed → opened → read | `RM-ASSET-ENTRY-006` |
| `PROP-SUITCASE` | дорожный чемодан | packed → arrived → unpacked | `RM-ASSET-ENTRY-005` |
| `PROP-TEA-TRAY` | поднос Ады | full → cup_removed | новый insert/overlay |
| `PROP-TEACUP` | фарфоровая чашка | empty → filled → left_untouched | новый insert/overlay |
| `PROP-NOTARY-FOLDER` | папка Лукаса | closed → opened → papers_offered | новый insert/overlay |
| `PROP-BEDROOM-DOOR` | заклинившая дверь | jammed → cleared_open | `RM-ASSET-CORRIDOR-002` |
| `PROP-BED` | кровать и матрас | covered → clean_made | `RM-ASSET-BEDROOM-001` |
| `PROP-CHILD-TRUNK` | сундук детских вещей | closed → opened → searched | `RM-ASSET-BEDROOM-006` |
| `PROP-CHILDHOOD-OBJECT` | детская памятная вещь | hidden → found → recorded | `RM-ASSET-BEDROOM-014` |
| `PROP-BATH-PIPES` | ванная сантехника | leaking → exposed → specialist_fixed | `RM-ASSET-BATHROOM-001` |
| `PROP-KITCHEN-CIRCUIT` | электрощит и проводка | unsafe → inspected → safe_circuits_enabled | `RM-ASSET-CORRIDOR-010` |
| `PROP-KITCHEN-TABLE` | кухонный стол | cluttered → cleared | `RM-ASSET-KITCHEN-002` |
| `PROP-KITCHEN-LIGHT` | кухонный свет | off → lit_safe | `RM-ASSET-KITCHEN-008` |
| `PROP-HOUSEHOLD-LEDGER` | хозяйственная книга | closed → open_dates → indexed | `RM-ASSET-KITCHEN-010` |
| `PROP-HALL-CLOCK` | напольные часы | stopped → repaired | `RM-ASSET-HALL-002` |
| `PROP-LIBRARY-DOOR` | дверь библиотеки | closed_unsafe → opened | `RM-ASSET-HALL-005` |
| `PROP-LIBRARY-SHELVES` | полки библиотеки | dusty_unsafe → supported_clean | `RM-ASSET-ARCHIVE-001` |
| `PROP-LIBRARY-DESK` | письменный стол | covered → cleared → drawer_open | `RM-ASSET-ARCHIVE-005` |
| `PROP-FAMILY-ALBUM` | семейный альбом | closed → opened | `RM-ASSET-ARCHIVE-006` |
| `PROP-FADED-PHOTO` | выцветшая фотография | face_down → date_visible → envelope | новый insert/overlay |
| `PROP-UNSENT-POSTCARDS` | неотправленные открытки | hidden → inspected → journaled | новый insert/overlay |
| `PROP-UNSIGNED-LETTER` | записка без подписи | hidden → read → journaled | новый insert/overlay |
| `PROP-GARDEN-FENCE` | ограждение сада | broken → fixed | новый insert/overlay |
| `PROP-HAMMER` | молоток Роуэна | in_hand → in_toolbox | новый insert/overlay |
| `PROP-THERMOS` | термос и две кружки | carried → poured → put_away | новый insert/overlay |
| `PROP-CONSERVATORY-GLASS` | рамы оранжереи | broken_unsafe → specialist_safe → storm_damaged | `RM-ASSET-CONSERVATORY-001` |
| `PROP-CONSERVATORY-BENCH` | каменная скамья | dusty → clean | `RM-ASSET-CONSERVATORY-010` |
| `PROP-CHILDHOOD-BOX` | детская коробка | hidden_under_bench → found → opened | новый insert/overlay |
| `PROP-CHILDHOOD-MAP` | нарисованная детская карта | folded → revealed → diary_reference | новый insert/overlay |
| `PROP-LANTERN` | фонарь Ады | unlit → lit | новый insert/overlay |
| `PROP-WET-DOCUMENTS` | намокшие листы | wet → hung_if_sturdy → laid_flat_delicate → safe | новый insert/overlay |
| `PROP-APRON-SUPPLIES` | карман фартука: бечёвка, прищепки, связка писем | unseen → twine_reveal → letters_reveal | новый insert/overlay |
| `PROP-RESTORATION-COSTS` | предварительная смета | filed → presented | новый insert/overlay |
| `PROP-ESTATE-FORMS` | документы управления поместьем | unsigned → signed | новый insert/overlay |
| `PROP-DIARY` | дневник воспоминаний | blank → facts_added → staying_entry → memory_quote | новый insert/overlay |
| `PROP-STAIRCASE` | лестница в верхний этаж | unsafe → future_pro_inspection | `RM-ASSET-HALL-001` |
| `PROP-WEST-WING` | западное крыло | unsafe_closed → future_inspection | `RM-ASSET-HALL-003` |

**High-priority close-ups:** letter and raven crest, photographic caption/date, household ledger date page, unposted cards, unsigned letter, childhood keepsake, childhood box/map, Ada's apron string/pegs/letters, wet archive pages, Lucas's repair cost sheet and signed estate management document, Evelyn's diary. **Prop interaction rules:** wet papers are protected and handled carefully; no hazardous amateur electrical or plumbing work; do not give the childhood-object clue and the later childhood photograph the same persistent ID without specific narrative approval.

**Map states:** `blocked/clear`, `dirty/clean`, `power_off/partial_lighting`, `broken/specialist_safe`, `hidden/discovered`, `unsafe/future_inspection`. Tie each meaningful state to a story event through the reducer, and keep cosmetic layers read-only. A professional repair occurs after appropriate preparation, not because a `rose` match magically repairs a window.

## 4 — Map interaction → VN / Match-3 / restore order

**Primary rule:** clicking a valid object/NPC/door selects the target; Evelyn walks along authored graph edges to that target's approach anchor; when she arrives, show a short localized inspect popup. If prerequisites are met, it offers `Talk`, `Prepare`, `Inspect` or `Restore` as appropriate. Only a completed VN scene emits its beat-seen event. Revisiting an object shows brief context, not the entire mandatory cutscene.

Production sequencing: `data/raven/production/map_narrative_routes.json` contains 28 beat triggers and all chapter links. Prologue letter/road/gates play automatically; arrival follows gates. The VS remains **bedroom access → bedroom level/restoration → bathroom prep/specialist → childhood clue → first night/next morning**. Chapter II is kitchen; III library; IV safe garden/conservatory; V storm and archive; VI Lucas's evening decision and the final diary.

Stable existing approach anchors include `RM-NAV-HALL-SPAWN`, `RM-NAV-HS-001`, `RM-NAV-HS-005`, `RM-NAV-HS-002`, `RM-NAV-HS-004` and `RM-NAV-CORRIDOR-CENTER` from the accepted VS greybox. Future target names in the scene route manifest **are semantic placeholders and not validated graph nodes**. For an authoring pass, the builder must provide a nearby approach anchor with an unobstructed route and a separately authored idle anchor if NPC is present. The eight-room continuous-map pilot's prop `level` references do not supersede RM-VS-01 progression.

**Popup copy:** 28 independent interactive object/NPC popups in `data/raven/production/hotspot_popup_copy.json`, all written in RU/BE/EN. They are short first-person Evelyn observations, not lore encyclopaedia entries. State-specific locked/available CTAs come from gating logic. One-time popups must never disclose upcoming clues or character identities prematurely.

## 5 — Characters moving/standing on the meta map

- **Evelyn:** the only mandatory full four-direction walker. Reuse accepted authored target routes in Hall → Corridor → Bedroom, then extend the same graph after room calibration. Include idle, walk side/up/down, face object, pickup/inspect and reach.
- **Ada:** one compact walk cycle family (same directional rig but own silhouettes); visible routes between Hall service/tea station, kitchen and library; default idle near furniture, never blocking main aisle. Props: tea tray and apron.
- **Rowan:** one compact walk cycle family; waiting near entrance/garden fence, then greenhouse bench; visible working clips for fence/plant; no forest or wolf animation before reveal. Garden zone still requires map approval.
- **Lucas:** **no complete map-walker sheet for first production batch**. Spawn at safe fixed indoor anchor in Hall or library on evening visits; subtle idle, turn, folder offer and optional short approach. Do not show him arriving in full daylight.
- **Specialists/courier:** not stage-visible walkers unless later approved. Use tools, sound, result cues and notification.

All actor idle anchors are **proposals** in `map_narrative_routes.json`. Validate with the current navigation graph or new approved graph per room; never silently put a character on a door threshold or use free tap-to-move.

## 6 — Three-language localization preparation

See `docs/production/LOCALIZATION_UPDS_ADAPTATION.md` for the exact UPDS implementation and staged rollout. Production lines are exported into a full **stable-key ledger** in `season1_dialogue_catalog.json`, 280 lines / 28 scenes. Russian source is complete. English and Belarusian *dialogue translations are not yet authored or proofread* and are intentionally `null`, not invented; scene titles in those languages are also pending. The locale adapter uses Russian fallback for missing entries; a **release-quality validator** rejects missing translations.

The 28 object popup entries **do** include first-pass RU/BE/EN copy, pending native editorial review. `RavenProductionLocalization` persists language separately from narrative save (UPDS-style) and provides stable speaker names and lookup APIs. **Not yet connected to live VN UI**. Future port must switch the live dialogue player to ID lookup and refresh the page on language change without stepping the VN cursor.

## Prioritized production slices / acceptance gates

1. **P0:** approve character turnaround/reference and a single layered Evelyn+Ada proof, Hall/Bedroom two-shot UI, procedural blink/talk and one distinctive signature micro per actor.
2. **P0:** calibrate Hall/Bedroom/Corridor room assets in Room Builder and Godot, confirm hotspots and 390×844 readability. Keep the current Onoe placeholder until approved sprites pass.
3. **P1:** implement localization ID adapter in live VN and dialogs, expose RU/BE/EN switch, translate/proofread all 280 line keys and titles, fail release when any required locale is missing.
4. **P1:** implement Chapter II kitchen/Rowan story events and two NPC walk variants, plus approved object-state transitions. Add stable new gameplay IDs only after save-compatibility design.
5. **P1:** expand reuse to Library and Conservatory, keep visual state overlays rather than painting one image per beat; Chapter III–V evidence close-ups.
6. **P2:** finish Chapter VI ending, phone notification, additional prop states, specialist offscreen vignettes, scene continuity tests and a three-language QA playthrough.

### Explicit non-goals

No photorealistic/stop-motion rendering, no new supernatural visible reveals, no magical locks, no auto-navigation to arbitrary tapped floor, no extra ordinary Match-3 tile types beyond eight, no claim that authored production JSON is already playable, no merging of legacy portrait canon (Adrian/Lucian/Silhouette) into this current story without approval.

