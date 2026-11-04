# Raven Manor — контракты модулей и границы для параллельных агентов
2026-11-04 · Проектная политика (предложение) + проверенные текущие API. Не является заявлением о готовности новых форматов.

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
- Integration owner: core state, shared game controller, changes to stable IDs, CI, production status.

Каждая задача задаёт exact file allowlist и требуемые контрактные тесты. Исторический UPDS-first reuse обязателен для UI, Match-3, save, audio и input. Все независимые PR используют отдельный Git worktree и unique `docs/changes/` evidence; reconciliation status выполняет один координатор.

## Следующие небольшие технические PR (ещё не выполнено)
1. GAME-LOOP-01/GAME-QA-01 characterization: menu→VN→M3→reward→repair→map→save/reload + optional campaign no mutation.
2. Вынести optional campaign/boost UI из 687-строчного `vertical_slice.gd` за адаптер с сохранением поведения/схемы save.
3. Устранить дублирование settings/onboarding UI между `main_menu.gd` и `raven_settings_dialog.gd` без изменения player preferences.
4. Добавить versioned Room Builder import/manifests contract tests, затем физическую карту и анимации.
5. Разделить монолитный CI на independent data/lint, targeted Godot, browser/Room Builder, export/deploy jobs, сохранив blocking integrated test перед merge и main-only Pages deploy.
