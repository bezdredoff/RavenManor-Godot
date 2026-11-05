# Raven Manor — контракты модулей и границы для параллельных агентов
Актуализация 2026-11-05. Текущие границы плюс история уже смерженных срезов. Для **полного реестра 15 ролей** см. `docs/process/AGENT_ORCHESTRATION_RU.md` и локальные `AGENTS.md`. Список старых next steps ниже — исторический, не утверждение о невыполненных PR.

## Текущие authoritative границы
- `scripts/raven/raven_snapshot.gd`: Raven-only save, `schemaVersion=1`; `raven_reducer.gd`: единственная мутация campaign с идемпотентным `eventId`; `raven_campaign_store.gd`: save/reload. Другие модули не имеют своего независимого campaign state.
- Поддерживаемые события Reducer: `level_won` с `levelId`, `booster_spent` с `kind`, `restoration_purchase` с `restorationId`, `door_unlock`, `hotspot_state`, `clue_recorded`, `story_flag_set`, `story_beat_seen`, `position_checkpoint`. Новый event/изменение schema требует отдельного contract PR и save migration tests.
- Общая интеграционная зона (один writer): `scripts/raven/vertical_slice.gd`, `raven_reducer.gd`, `raven_snapshot.gd`, `raven_campaign_store.gd`, `raven_ids.gd`, `project.godot`, canonical story registries и общий GitHub workflow.

## Producer → consumer
| Производитель | Потребитель | Текущий контракт | Следующий gate |
| --- | --- | --- | --- |
| VN Studio `addons/vn_studio/` | VN Runtime `raven_vn_runtime_dispatch.gd` | Draft/review/promotion отдельно от canonical runtime, stable scene/line IDs, RU/BE/EN | Versioned reviewed export, SHA источника, routing & save parity, no silent draft promotion |
| Room Builder `tools/room-builder/` | Map / `manor_navigation_graph.gd` | Importer `import_room_builder_game.py` принимает `schemaVersion=1`, `RM-ROOM-*`, размеры/IDs, создаёт **DRAFT_ONLY visual scene** | Calibrated 65° pivots, footprints, anchored routes, collisions требуют отдельного geometry acceptance; draft не меняет save |
| Match-3 | Campaign | `RM-LVL-*`, deterministic checkpoint replay, `level_won`, `booster_spent` | Contract smoke: no double reward/spend, replay/rollback, optional levels do not progress story |
| Manor map/restoration | Campaign | `restoration_purchase`, `door_unlock`, `hotspot_state`, `position_checkpoint` + stable IDs | Hall→Corridor→Bedroom geometry + restoration gate acceptance; core owns state |
| ComfyUI / Blender | VN/map/Match-3 asset consumers | Accepted art registries and `art-handbook/` provenance | Future per-asset manifest: stable ID, type, variant/state, dimension, pivot, SHA, source/license, approval, animation meta; candidate ≠ accepted |

## Разрешённые области независимых задач
- VN Studio agent: `addons/vn_studio/**` + editor tests; canonical story assets read-only.
- Match-3 agent: `scripts/match3/**` and narrow `scripts/raven/raven_match3_*.gd` + related tests. Shared campaign and `vertical_slice.gd` edit only through integrator.
- Map/Builder agent: `tools/room-builder/**`, map-specific importer/test; canonical map/route data read-only before approval.
- Art agent: `scripts/raven/comfyui/**`, pending candidate assets, manifest validation; approved art read-only.
- Integration owner: core state, shared game controller, stable IDs, workflows, inter-module contracts. **Live task status** принадлежит отдельному functional shard/агенту.

Каждая задача задаёт exact file allowlist и требуемые контрактные тесты. Исторический UPDS-first reuse обязателен для UI, Match-3, save, audio и input. Все независимые PR используют отдельный Git worktree и unique `docs/changes/` evidence; reconciliation status выполняет агент своего домена по проверенным PR/CI; интегратор отвечает только за общие контракты.

## Исторический план разбиения (актуальный прогресс после PR #188–196)
1. **Частично реализовано в #188:** Match-3 win/reward/retry/repair/VN/optional characterization; полный физический map/device QA остаётся.
2. **Реализовано #189–191:** optional campaign, session transactions и booster UI вынесены за адаптеры; общий controller всё ещё нуждается в интеграционном review.
3. Устранить дублирование settings/onboarding UI между `main_menu.gd` и `raven_settings_dialog.gd` без изменения player preferences.
4. Добавить versioned Room Builder import/manifests contract tests, затем физическую карту и анимации.
5. **Реализовано #192:** независимые data/Godot/Room Builder/art/Web jobs, итоговый blocking `build`, main-only Pages deploy. Дальнейшее Godot sub-sharding — отдельная задача.

## 2026-11-04 — Optional Match-3 campaign presentation boundary (R2a)

- `scripts/raven/raven_optional_campaign_controller.gd` owns the **read-only** optional-level list, ordering by authored `campaignIndex`, unlock indicators, localized return control, and matching optional step descriptors. Tests: `tests/raven/optional_campaign_controller_smoke.gd` + existing main-menu and game-loop smokes.
- `vertical_slice.gd` remains the host for scene transitions, state and match3 game lifecycle; **no** reward/save authority moved. `RavenReducer`/`RavenCampaignStore` are the only progression authority.
- Further separation of board lifecycle and booster persistence is a later task, not included in this controller extraction. Preserve `RM-LVL-101..122` IDs, save schema v1, screen labels, RU/BE/EN return strings and existing mobile incoming flow.

## 2026-11-04 — Match-3 session transaction boundary (R2b)
- `scripts/raven/raven_match3_session.gd` creates/reopens a UPDS-based Raven board from an approved level + `match3Checkpoint`, and prepares reducer-backed snapshot transactions for booster spends, per-move checkpoints and win rewards.
- `vertical_slice.gd` still owns UI, audio, button flow, scene routing, event serial and board repaint after a failed save. The session component never writes a separate save file and has no permissions to mutate VN/Map campaign state directly.
- `RavenReducer` and `RavenCampaignStore` remain the sole campaign authorities; schemaVersion stays 1. Tests: `match3_session_smoke.gd`, `game_loop_characterization_smoke.gd`, `match3_checkpoint_smoke.gd`.
- Further decomposition of Match-3 view/booster presentation is postponed until the current transaction boundary has passed exact-head CI and owner review. No automatic acceptance of gameplay/visual balance.

## 2026-11-04 — Booster UI presentation boundary (R2c)
- `scripts/raven/raven_match3_booster_ui.gd` owns button labels, enabled/disabled presentation, localized copy RU/BE/EN, selected-hammer caption and target hint. Output controls retain their old node names; callbacks are supplied by the host, and no player state is modified here.
- `vertical_slice.gd` continues to own button callbacks, Match-3 effects, UI/audio coordination and state updates returned by `raven_match3_session.gd`. Reducer/Store remain the only authority for rewards, booster spending and checkpoint commits.
- Contract test: `tests/raven/match3_booster_ui_smoke.gd` plus existing session, gameplay and viewport tests. No player-facing UI redesign, schema migration or acceptance status changes in this R2c slice.

## 2026-11-04 — CI sharding, PROC-006

Новая политика в `docs/process/CI_SHARDING_20261104_RU.md`: data/governance, Godot runtime, Room Builder, art pipeline и Web packaging — независимые GitHub Actions jobs. Один required check `build` агрегирует их; main deploy возможен только после всех PASS. Godot smoke не удалены. Следующий срез — отдельная VN/Match-3/map разбивка Godot после подтверждённой интеграции.

## 2026-11-05 — PROC-007 Stage 3b independent status assignments

Agents maintain only `data/raven/production/progress/<domain>.json` for task state/evidence and workstream or P2 ownership. `active_workstreams.json` and `p2_reentry_policy.json` are immutable-by-task metadata, no shared task ID lists. Dashboard membership is computed from shard `assignments` and current priority/status; terminal entries stop appearing active automatically. The legacy monolith and generated dashboard are forbidden edit targets. Domain-agent branches are checked against their matching shard; cross-domain/core PRs require coordinated review. This does not introduce auto-merge or owner/device acceptance. Full CI remains mandatory.
