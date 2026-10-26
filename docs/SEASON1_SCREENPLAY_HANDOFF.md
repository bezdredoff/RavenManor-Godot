# Season 1 — screenplay handoff and approval checklist

**Status: merged story direction approved by owner (2026-10-26); production-trigger details remain proposed.** The appended chapters II–VI in [NARRATIVE_SCRIPT_READABLE.md](./NARRATIVE_SCRIPT_READABLE.md) are a full season proposal, **not** fully shipped VN data. Existing prologue and chapter I, their stable `RM-*` IDs, gameplay balances, and save structures are untouched.

## Story flow and player comprehension

| Chapter | Player's immediate goal | Story revelation | Planned playable setting |
|---|---|---|---|
| I — The return | First habitable night | Evelyn remembers the house, not its people | Hall, corridor, bedroom, bathroom |
| II — The house wants breakfast | Restore basic kitchen function; meet Rowan | The estate was closed room by room | Kitchen, safe garden approaches |
| III — Books cannot keep quiet | Organize library and verify family records | Unsent postcards, disputed departure | Library |
| IV — The garden remembers differently | Make conservatory safe with specialists | Childhood keepsake box and annotated map | Garden, conservatory |
| V — When the house won't sleep | Protect safe spaces during a storm | Ada kept letters, departure story remains uncertain | Hall, library |
| VI — Stay | Decide about estate management | Evelyn accepts the personal and financial cost | Library, hall, bedroom |

**Night rule:** Lucas's in-person visits should take place after sunset. The storm's morning-after scene must not include him. The reasons are **not** disclosed to Evelyn in Season 1.

**Revelation rules:** No explicit player-facing statement about Ada's, Lucas's or Rowan's supernatural identity or about whether the manor is sentient. Ada's apron producing useful unexpected items is a recurring visible character quirk without an explanation. The supernatural memory-fading rule is canonical internally, but its cause is deliberately not resolved here.

**Narrative uncertainty / approval:** Identity of the second hand/voice in childhood memory; author of unaddressed letter; particulars of Evelyn's departure; the exact factual nature and timeline of Ada's remote contact with Evelyn; whether the post-credits scene belongs in final release. Do not convert these from proposed mysteries into resolved facts.

## Match-3 scope lock

- **Exactly eight ordinary thematic tiles** in one reusable pool: `candle`, `key`, `rose`, `book`, `raven`, `cup`, `brooch`, `quill`. Their names, render styles and feedback remain the same throughout the season.
- Each level draws a **subset** (usually five or six) from that pool. Do **not** add kitchen, garden, rain, archive or repair-specific ordinary tile classes.
- Variety comes from board masks/shapes, move budgets, objective mixes, and an initial **maximum of three blocker families**: cobweb (clear by adjacent matches), crate (1–2 hits), chain (immobilized tile until released). These are *design proposals* to assess for compatibility with Godot gameplay; not implemented code.
- Specials made by four/five matches are separate *mechanical* objects, not additions to the eight ordinary-tile pool.
- Reuse UPDS-Godot's proven concepts for authored board layouts, blockers, specials, objective validation and cascades where technically suitable. Do not assume direct script compatibility without review.
- The narrative framing is **work preparation**. Matching a book tile does not literally sort a book; matching a rose does not physically fix greenhouse glazing. Actual plumbing, electric, structural, glass and clock repair needs an appropriate professional.
- ASMR target: clear tactile silhouettes; satisfying soft swipe, warm glow, mild dissolution, gentle landing bounce; quiet tile-identity sound accents; cascades that become more musical but do not produce harsh noise, shaking or visual overload. Existing `tile_pool.json` has non-binding visual/audio direction, not finished production effects.

## Playable transitions (proposal, not level IDs)

| Story beat | Match-3 role | Gameplay complexity guidance |
|---|---|---|
| Kitchen preparation (II) | Earn work points; clear safe access | 5 tiles, simple shape, introductory cobweb |
| Library setup (III) | Earn points for preparation | 5 tiles, cut corners and crates |
| Sorting records (III) | Earn work points; then unlock inspectable document state | 5–6 tiles, familiar blockers, collect target |
| Garden path (IV) | Earn work points; subsequent manual repair by Rowan | 5 tiles, asymmetric board |
| Conservatory (IV) | Prepare access for glazier | 5–6 tiles, shape variations and layered existing blockers |
| Storm (V) | Collect resources for safe preparation, no new emergency minigame | 5 tiles, known board elements and limited moves |
| Wet archive (V) | Prepare document preservation, then narrative prop state change | 5–6 tiles, known blockers |
| Season closing tasks (VI) | Reuse previously introduced mechanics and assets | No new tile family or blocker family |

The proposed scenes do **not** define runtime level IDs, their rewards or restoration costs; these require approved balancing and a separate runtime implementation PR. The first slice reward **2/2/2**, costs **2/4**, existing level and beat IDs must remain unchanged.

## Functional handoff / post-approval tasks

1. Confirm the screenplay and open narrative questions. Copy approved beats to planned narrative data with new IDs; keep Chapter I playable data unchanged.
2. Define small authored restoration/room-state contracts and professional repair triggers, never magical locks.
3. Extend campaign progression only after checking save backwards compatibility and replay rules.
4. Add dialogue scenes in staged content packs; test story flags, gate causality and time-of-day consistency.
5. Design and implement board masks + vetted blocker subsets separately; test on mobile and with the existing hint system.
6. Generate a single polished eight-tile art set, matching animations and audio; run visual/readability testing before adding content variants.

**Non-goal:** This screenplay PR must not silently turn provisional chapters II–VI into approved runtime content.
