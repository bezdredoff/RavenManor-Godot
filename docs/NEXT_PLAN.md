# Raven Manor — next implementation plan

## Gate 0 — product answers: complete

The answers in `PRODUCT_QUESTIONS.md` are recorded as `RM-DEC-013..016`. PR 3 may proceed without another bedroom-hotspot, adapter, Evelyn-placeholder or Onoe-license question.

## Gates 1–3 — implemented in PR 3

1. Define stable records for `RM-LVL-001..003`, `RM-HS-001..005`, `RM-REST-001..002`, the childhood clue and `RM-BEAT-01-01..05`.
2. Encode `RM-HS-005` as the early bedroom-access action: set `RM-FLAG-BEDROOM-ACCESS-CLEARED`, unlock `RM-DOOR-CORRIDOR-BEDROOM`, enter the room, and only then expose `RM-HS-002` / `RM-REST-001`.
3. Add validators for missing IDs, invalid prerequisites and unreachable progression.
4. Add an automated reducer test that executes the corrected 13-step sequence and repeats reward/reload callbacks.

The Raven content contract, minimal adapters and integrated `RM-VS-01` are implemented. Automated coverage executes the complete corrected route, a legal deterministic Match-3 move and save/reload resume. The Prototype Lab exposes the combined slice plus its foundation and navigation components.

Remaining PR 3 acceptance work before merge:

1. Run browser visual QA at 390×844 plus narrow/tall portrait viewports.
2. Exercise real touch separately from mouse input.
3. Confirm CI Web export and Pages deployment after merge to `main`.

## Gate 4 — art feasibility, not production

Only after Gate 3:

1. Create/select the canonical Evelyn identity reference from Raven Manor source materials; until then use Onoe only for technical movement tests.
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
