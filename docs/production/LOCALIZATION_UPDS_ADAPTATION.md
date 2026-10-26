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
- `scripts/raven/raven_production_localization.gd`: standalone lookup & `ConfigFile` preference adapter, `ru` fallback when translation missing, speaker-name localized labels. Explicitly **not yet hooked into the playable VN**.

Line data example:

```json
{
  "id": "RM-BEAT-00-01-L001",
  "sceneId": "RM-BEAT-00-01",
  "speakerId": "RM-CHAR-EVELYN",
  "delivery": "speech",
  "localized": {
    "ru": { "text": "Квартира съёмная. Мебель чужая. Даже чашка — не моя, я её просто не вернула. Так проще уезжать." },
    "be": null,
    "en": null
  }
}
```

**Do not confuse fallback with finished translation.** The current `ru` line ledger is complete; **all Belarusian and English dialogue and scene-title translation remains to be written and proofread**. The `null` values are transparent TODOs so a reviewer sees real coverage. Do not invent a translation only to force a green metric. Popup BE/EN text exists as a first-pass draft only.

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
4. **Static gate:** `python3 scripts/raven/tools/validate_production_narrative.py` accepts missing future translations but checks contracts. `--release` rejects every missing BE/EN line and scene title. It is **expected to fail at present**.
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
