# Raven Manor — three-language VN and narrative localization contract

**Target:** Russian (`ru`), Belarusian (`be`), English (`en`), mirroring the confirmed three languages in `bezdredoff/UPDS-godot`. **Russian is Raven's current approved screenplay/source language**, unlike UPDS where interface fallback is English. Target Godot 4.7.2.

## What we verified in UPDS

1. `scripts/ui/menu_copy.gd` — built-in dictionary with `en/ru/be` for interface strings; `DEFAULT_LOCALE = en`, `FALLBACK_LOCALE = en`; `text(key,locale)` resolves selected copy then fallback.
2. `scripts/ui/player_preferences.gd` — `ConfigFile` persistence of `interface.locale` at `user://player_preferences.cfg`, explicit `locale_changed` signal; preference data is separate from narrative progression.
3. `scripts/ui/settings_screen.gd` — `OptionButton` with native labels **Русский / Беларуская / English**, per-item metadata `ru/be/en`; refreshes all UI strings after switch.
4. `data/prologue.json`, `data/photo_scene.json` — each authored VN line has stable `id` (e.g. `VN0001`), locale-independent `actors` + `pose/layout`, and `localized.ru/be/en` objects with `speaker/emotion/text`; scene titles localized by language. Scene/line progress stored separately.
5. `scripts/vn/vn_screen.gd` — VN chooses `line.localized[preferences.locale].text`, reflows dialogue pages on locale change; `scripts/vn/dialogue_paging.gd` protects grapheme and sentence breaks for RU/BE/EN. **Important:** the VN's direct lookup presumes complete `localized` content; fallback in `menu_copy.gd` does not automatically fix incomplete story translations.
6. `scripts/core/story_session.gd` — stable story line IDs and user choices are locale-independent, so changing language does not renumber or rewind the save.
7. `scripts/match3/match3_reaction_runtime.gd` — a further example of localized narrative barks and speaker lookup by stable ID.

The implementation is not Godot's global `tr()` with CSV import alone; the relevant UPDS patterns are **three-key dictionaries per line**, stable IDs, a persistent locale preference, UI refresh/reflow, independent save progress and complete-translation QA. Raven should reuse these ideas, not copy UPDS characters/story.

## Proposed Raven bundle

- `data/raven/production/season1_dialogue_catalog.json`: **28 scenes and 280 lines**, one stable `RM-BEAT-xx-xx-Lnnn` / `RM-BEAT-06-POST-Lnnn` key per spoken line. Existing beat IDs `RM-BEAT-00-01..03` and `RM-BEAT-01-01..05` are *unchanged*. Their spoken Russian text is taken directly from the playable `rm_vs_01_content.json`, not retranslated from the shorter reading guide.
- `data/raven/production/vn_staging.json`: room art variant, 1–3 visible actors, positions, poses, expressions; **not localized**.
- `data/raven/production/line_performance_cues.json`: line-level poses/gesture suggestions; **not localized**. Stage directions are editorial notes, not spoken text. Convert them into new translation keys only if a specific direction will be seen as narration or UI.
- `data/raven/production/hotspot_popup_copy.json`: 28 short interactable object/NPC popups, currently first-pass fully translated into RU/BE/EN; review in context.
- `scripts/raven/raven_production_localization.gd`: canonical lookup, locale preference persistence, RU fallback, localized scene titles and speaker names. The shared `raven_vn_catalog_adapter.gd` now supplies production catalog lines and IDs to active `RM-VS-01` and `Content Preview` VN beats.

Line data example:

```json
{
  "id": "RM-BEAT-00-01-L001",
  "sceneId": "RM-BEAT-00-01",
  "speakerId": "RM-CHAR-EVELYN",
  "delivery": "speech",
  "localized": {
    "ru": { "text": "Квартира съёмная. Мебель чужая. Даже чашка — не моя, я её просто не вернула. Так проще уезжать." },
    "be": { "text": "Кватэра здымная. Мэбля чужая. Нават кубак — не мой, я яго проста не вярнула. Так прасцей з'язджаць." },
    "en": { "text": "The apartment is rented. The furniture belongs to someone else. Even the mug isn't mine—I just never gave it back. Makes leaving easier." }
  }
}
```

**Translation status (2026-11-02):** RU is the source; all **280 of 280 English dialogue entries** and **28 of 28 English scene titles** are filled in the same canonical ledger, including the existing Chapter II pilot. This is a first editorial draft, not native-speaker proofread/acceptance. **Belarusian is also fully populated for spoken dialogue and scene titles** (280/280, 28/28); both EN and BE remain first-pass editorial drafts pending native-speaker review. Popup BE/EN text is still a first-pass draft. A nonempty cell is not proof of final language quality.

### Proposed runtime resolver contract

- `current_line_id` is stored alongside (not replacing) the stable beat/cursor position at a later approved migration. Never serialize localized text or an array offset derived from the selected language.
- Resolve `speakerId` → localized display name, and `lineId` → localized `text`; retrieve `pose/emotion/micro` from `line_performance_cues` by the same ID.
- Changing language in VN: keep `sceneId/lineId` untouched, reset *only* page wrap layout and redraw text/nameplate/buttons; preserve read-line history and skip eligibility. A change should not replay a voice/micro cue.
- If missing `be/en` translation in a development build, show the approved RU line while emitting a debug warning + translation coverage metric. Do not hide the line or skip it.
- Before release, `--release` validation must pass **without fallback used** for every required dialogue line, scene title, popup, choice, item state label, quest/objective, diary entry and UI action. The current ledger handles dialogue + scene titles + popups; the last groups must be added to the same stable-ID design when authored.
- Screen widths: test RU/BE/EN with portrait 390×844, narrow phones and tablets; manual line breaks are **not** carried between locales. Follow UPDS dialogue reflow strategy; avoid ellipsis truncating meaning and orphan one-word tails.
- Typography: choose fonts licensed for Latin **and** Cyrillic + Belarusian `ў/і`; test uppercase labels, quotes `«»`, long names and combining marks.
- Localization keys are immutable after shipping. A line can be rewritten while keeping its ID *only while it refers to the same logical utterance*; adding or reordering content in a published scene requires explicit migration/versioning.

## Extract/edit/QA pipeline

1. **Script owner (Russian):** verify `docs/NARRATIVE_SCRIPT_READABLE.md` against the scene ledger. First-act Russian runtime data wins for already shipped beats. Text editorial changes enter the script, then the ledger in one PR.
2. **Translation work:** export `id + speakerId + context + Russian text` in a translator-friendly CSV/PO or side-by-side sheet, with no scene index dependence. Provide scene context, speaker emotion/prop and do-not-reveal notes to translators.
3. **Backfill:** populate `localized.be.text` and `localized.en.text`, keeping unchanged IDs and literal placeholders such as `{count}` intact.
4. **Static gate:** `python3 scripts/raven/tools/validate_production_narrative.py` accepts missing future translations but checks contracts. `--release` rejects every missing BE/EN line and scene title. This catalog-level check now passes with the populated RU/BE/EN dialogue and titles; it is not a substitute for full game UI localization or editorial QA.
5. **Godot contract smoke:** `tests/raven/production_narrative_smoke.gd` verifies key lookup, fallback, 3-language popup completeness, catalog/scene/shot references and standalone preference persistence. It does **not** claim a full UI switch.
6. **Preview:** implement two-language-switch controls on an isolated Raven VN preview before touching the playable vertical-slice player. Check save/reload across language changes, line pagination, actor gestures and accessibility/reduced motion.
7. **Release:** require in-context proofreading by RU/BE/EN reviewers, screenshot/overflow QA, and strict translation coverage for every player-facing string. Add translations for future user-visible narration, Match-3 goal labels, map-state messages and all journal entries.

## Scope and privacy

No change to `RM-VS-01` save schema, 2/2/2 reward and 2/4 costs. No release-grade claim for Chapter II–VI playable implementation. Source material from the private narrative repository should only enter public Godot Web artifacts once intended for players; all bundled future plot data is extractable from a public Web build. Keep untranslated or non-release spoiler data out of the published export when making the real production exporter.

## Acceptance criteria for implementation PR (separate from this preparation PR)

- Language switch visible and accessible: RU / BE / EN.
- Resume at identical beat/line after switching languages, closing and restarting.
- No `RM-*` IDs changed by locale.
- Character name, narrator, choice, popup, objective, diary and navigation label update with the locale.
- Error/fallback is deterministic and logged; no missing string silently hidden.
- All three languages pass first-run tutorial, chapter transitions, Match-3, old-save loading and complete season playback.
- `--release` zero missing translations, native editorial pass, mobile readability and fonts approved.

## English dialogue integration — CODE-04-03 / RM-GAP-013 (2026-11-02)

- **Single source of spoken truth:** `data/raven/production/season1_dialogue_catalog.json` is both the Raven VN Studio source and the translated data consumed by the playable VN. Do not maintain a second hand-written English list in `rm_vs_01_content.json` or UI scripts.
- **Legacy stage compatibility:** `scripts/raven/raven_vn_catalog_adapter.gd` checks that every legacy Russian line and order matches the canonical catalog, then projects the same `beatId`, immutable `lineIds`, speaker IDs and localized text to `RavenVNPlayer`. On source drift, it logs an error and keeps the legacy scene instead of silently assigning the wrong translation.
- **Visible runtime:** The vertical slice and Content Preview expose RU/BE/EN, persist the choice through the shared `user://raven_language.cfg` preference, and replace the line text without changing the beat or line cursor. Existing Raven campaign save and reducer semantics are untouched. `raven_vn_game_view.gd` shows localized titles/speakers/buttons, paginates long translated dialogue using the existing UPDS text measurement/paging utility, and passes the canonical line ID to character staging.
- **Standalone Hall Tea pilot:** already read `Copy.line_text(line.id, lang)` from this exact catalog; English entries for that pilot were preserved. Editing English content in Raven VN Studio changes its source in the same place; reviewed source promotion is still required before gameplay reflects local `user://` draft edits.
- **VN Studio local drafts:** Source SHA locking is intentional. A draft made against the previous Russian-only catalog may show a source-drift warning after this PR; **do not discard it**. Back up and compare the draft; resolve against the new catalog explicitly. Do not auto-rebase a local draft or silently overwrite a canonical locale cell.
- **QA:** `tests/raven/vn_english_localization_smoke.gd` covers English completeness, stable scene/line IDs, legacy beat/source parity, active preview language switching, saved locale and translated UI elements. Existing runtime background tests now account for paginated lines. The regular contract smoke expects RU/BE/EN=0 missing; the separate BE smoke checks Studio source, immutable line IDs, gameplay language switch, persistence and pagination.
- **Remaining release gates:** full English native-editorial proofreading; manual 390×844, 412×915, 430×932 and tablet checks; all user-visible menu, Match-3, map, choice, objective and journal copy must be localized separately. `validate_production_narrative.py --release` now validates completeness for spoken dialogue, scene titles and hotspot popups in all three languages. **This is not the full game release gate:** the map, Match-3, interface, choice, objective and journal copy still need separate coverage and manual QA.

## Belarusian spoken VN integration — 2026-11-02 follow-up

- **Content:** all 280/280 existing Season 1 spoken `localized.be.text` lines and 28/28 `scene.title.be` records now populated with idiomatic first-pass Belarusian while retaining 12 pre-existing translations from the Chapter II Hall Tea pilot. All 280 Russian and 280 English lines, scene IDs, line IDs and VN stage / art / cue metadata remain unchanged. Names remain consistent with `raven_production_localization.gd`: Эвелін, Ада, Лукас, Роўэн.
- **Integration:** no second BE script or game-specific text copy. The merged English-language runtime already supports `be` and resolves `RavenVNPlayer` from canonical Studio `sceneId`/`lineId`. The same mechanism now displays Belarusian in RM-VS-01, Content Preview and Hall Tea pilot, with session and persisted preference selection, correct speaker and title, measured paging and no scene/line cursor reset. VN Studio's side-by-side BE field is populated directly from this catalog; pending local draft modifications are deliberately NOT loaded at runtime.
- **Automated verification:** `tests/raven/vn_belarusian_localization_smoke.gd` checks 28 translated titles, 280 non-fallback lines, Studio's original source reader, 8 legacy playable scene/line mappings, actual 390x844 preview display, line-aware pagination, RU→BE→EN→BE mid-scene switch, persistent BE language and unchanged IDs. `scripts/check.sh` calls it and the strict registry `validate_production_narrative.py --release` in CI. `tests/raven/production_narrative_smoke.gd` now requires 0 missing dialogue entries for all three locales.
- **Known limits:** this is a first Belarusian editorial draft, **not** a Belarusian native-editor approved proofread. Mobile font glyphs (particularly `ў`, `і` and uppercase labels), line wrapping, character voice, literary tone and all 28 scenes require native on-device QA. UI strings outside the VN (launcher, map, Match-3 objectives, quests, journal, future choices and item descriptions) are independent work and **must not** be claimed release-ready. `--release` only covers the enumerated registries, not these other UI systems.
- **Studio safety:** this PR changes the SHA of the canonical dialogue JSON. Existing `user://raven_story_studio/v1` local drafts can be intentionally blocked by the SHA guard. Back up and reconcile them through explicit source diff/review; do not delete or silently rebase them.
