# CODE-08-01 — Chapters II–III executable-readiness manifest

Task IDs: CODE-08-01; related VN-RUNTIME-01, CODE-03-01/02/03.
Changes: Document Chapter II-III readiness dependencies and scene-by-scene handoff without approving production scenes.
Verification: Catalog and gate review recorded in this manifest; pending exact-head Godot CI after test parse fix, not an executed chapter E2E.
Owner QA: NOT_RUN; scene, art and physical hotspot approvals remain pending.
Status impact: CODE-08-01 remains ready / partial in campaign-core; this agent records supporting work on the already owned VN-RUNTIME-01 entry, without a duplicate cross-domain task.

This is an integration contract, not approval of any production scene. Scene IDs, triggers and canonical text are read-only references to the current catalogs.

| Scene / ordered trigger | Gate semantics | Interaction / focus | RU/BE/EN | Background / portraits | Missing art / save / owner dependency |
|---|---|---|---|---|---|
| RM-BEAT-02-01 / 09 | `scene_complete:RM-BEAT-01-05` | entry → Hall tea focus | present / present / present | BG-HALL; Ada/Evelyn staging exists | Ada `offer_tray/dry_amused`; cue-art; save entry RM-BEAT-02-01; Agent B: catalog + route approval, Agent A: portrait/cue approval |
| RM-BEAT-02-02 / 10 | `npc_tap:RM-CHAR-ROWAN` (unsupported until interaction state exists) | entry → Rowan approach anchor | present / present / present | BG-ENTRY; Rowan/Evelyn staging exists | Rowan `point_route/wry`; cue-art; save entry; Agent A: NPC/map interaction evidence, Agent B: save/catalog contract |
| RM-BEAT-02-03 / 11 | `object_tap:PROP-HOUSEHOLD-LEDGER` (unsupported) | kitchen table → ledger hotspot | present / present / present | BG-KITCHEN; Evelyn staging exists | Evelyn `investigate/curious`; cue-art; save entry; Agent A: hotspot evidence, Agent B: save/catalog contract |
| RM-BEAT-02-04 / 12 | `specialist_result:kitchen_power_safe` (unsupported) | kitchen → specialist result focus | present / present / present | BG-KITCHEN; staging exists | no art gap observed; save entry; Agent A: specialist result authority, Agent B: save/catalog contract |
| RM-BEAT-03-01 / 13 | `door_tap:RM-DOOR-HALL-ARCHIVE` (unsupported) | hall archive door → library focus | present / present / present | BG-LIBRARY; Lucas/Evelyn staging exists | Lucas `folder_present/professional`; cue-art; save entry; Agent A: door/map evidence, Agent B: save/catalog contract |
| RM-BEAT-03-02 / 14 | `object_tap:PROP-FAMILY-ALBUM` (unsupported) | library desk → album hotspot | present / present / present | BG-LIBRARY; Lucas/Evelyn staging exists | Lucas `explain/professional`; cue-art; save entry; Agent A: hotspot evidence, Agent B: save/catalog contract |
| RM-BEAT-03-03 / 15 | `npc_tap:RM-CHAR-LUCAS` (unsupported) | library → Lucas approach anchor | present / present / present | BG-LIBRARY; Lucas/Evelyn staging exists | Evelyn `investigate/worried`, Lucas `explain/serious`; cue-art; save entry; Agent A: NPC/map evidence, Agent B: save/catalog contract |
| RM-BEAT-03-04 / 16 | `object_tap:PROP-LIBRARY-DESK` (unsupported) | library → desk hotspot | present / present / present | BG-LIBRARY; Evelyn staging exists | Evelyn `investigate/worried`; cue-art; save entry; Agent A: hotspot evidence, Agent B: save/catalog contract |

Promotion evidence required per scene: approved `runtime_approved` status; canonical route with strict integral unique ordinal and `approvedRuntime=true`, `proposedRuntime=false`; registered save beat; accepted background and every cast/cue pose; all three non-empty locale cells; `manualReview=false`; supported authoritative gate with a deterministic state fixture; dispatcher selection in RU/BE/EN; VN player line-by-line completion and reducer event; read-only Skip/resume regression; clean-save non-mutation; Godot headless test plus Agent E runner registration and exact-head CI.

Remaining batches: (1) Agent B integration batch for statuses/routes/save registrations, (2) Agent A map/hotspot/specialist state contracts, (3) art/animation review batch for missing variants and manual cues, (4) dispatcher follow-up only after those contracts exist, (5) Chapter IV–VI and optional post-credit readiness using the same matrix. No batch may silently promote a scene or invent narrator/offstage portraits.
