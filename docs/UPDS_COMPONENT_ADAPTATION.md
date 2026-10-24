# UPDS component adaptation for RM-VS-01

PR 3 adapts only the minimum proven runtime boundaries from the owner-controlled `UPDS-godot` project.

- `raven_match3_game.gd` retains the useful `configured_level → board → attempt_swap/get_hint_move → won/lost` contract. It is a Raven-only deterministic implementation with adjacent swaps, real match validation, cascades, move limits and collect objectives.
- `raven_vn_player.gd` retains the simple scene/line/advance contract. Stable `RM-BEAT-*` IDs and Raven lines come from `rm_vs_01_content.json`.
- The UPDS `StorySession`, numeric story indexes, campaign JSON, sprites, backgrounds, UI shaders and other story content are intentionally not imported.
- All progression mutations still pass through `RavenReducer`; both adapters are presentation/gameplay inputs to the canonical Raven snapshot.

This boundary keeps the executable proof real while preventing UPDS narrative and art assumptions from becoming Raven dependencies. It is an internal owner-authorized adaptation, not a claim that Onoe or other temporary art is production Raven content.
