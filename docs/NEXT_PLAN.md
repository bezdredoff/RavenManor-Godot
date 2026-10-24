# Raven Manor — next implementation plan

## Gate 0 — product answers

Resolve only the questions in `PRODUCT_QUESTIONS.md`. Record answers in `DECISIONS.md` before changing progression data.

## Gate 1 — PR 3 content contract

1. Define stable records for `RM-LVL-001..003`, `RM-HS-001..005`, `RM-REST-001..002`, the childhood clue and `RM-BEAT-01-01..05`.
2. Encode the corrected bedroom-access dependency without changing existing IDs.
3. Add validators for missing IDs, invalid prerequisites and unreachable progression.
4. Add an automated reducer test that executes the corrected 13-step sequence and repeats reward/reload callbacks.

Acceptance: content validation and complete state-only sequence pass without UI.

## Gate 2 — minimal adapters

1. Import or adapt only the proven UPDS Match-3 interfaces needed to launch a level and receive a result.
2. Import or adapt only the proven VN renderer interfaces needed to launch stable beat IDs and apply typed events.
3. Keep Raven content and save state independent from UPDS numeric story indexes.
4. Expose the three levels and beats through Prototype Lab for isolated testing.

Acceptance: each subsystem works alone in the standalone repo; no unrelated UPDS story/content import.

## Gate 3 — integrated `RM-VS-01`

Connect arrival, hall/corridor exploration, Ada meeting, bedroom access, level 1, bedroom restoration, levels 2–3, bathroom specialist vignette, clue, first-night beat and save/reload.

Acceptance:

- corrected 13/13 sequence passes end-to-end;
- rewards remain 2/2/2 and costs 2/4;
- retries, duplicate callbacks and replayed VN beats do not duplicate progression;
- bedroom access never depends on bathroom restoration;
- baseline 390×844 plus one narrow and one tall portrait viewport pass;
- real touch interaction is tested separately from mouse input;
- Prototype Lab exposes subsystem and combined modes;
- Pages deploy passes from `main`.

## Gate 4 — art feasibility, not production

Only after Gate 3:

1. Select the canonical Evelyn identity reference.
2. Capture a fresh ComfyUI/VNCCS/model/workflow/input manifest.
3. Run one clean neutral/front reference-transfer control and stop on identity or clothing drift.
4. If accepted, test two poses and three emotions.
5. Build one small cross-asset board: Evelyn, one second canonical character, one room, five materials/props and an actual Godot UI composite.

Acceptance: reproducible identity and one coherent style board. This still does not authorize mass generation.

## Explicitly deferred

- full-season content;
- canonical production character batch;
- bulk room and prop generation;
- public reusable addon extraction;
- free movement;
- full walkable bathroom;
- engine migration.
