# VNS5-06C — Promotion Review новых VN-сцен и реплик (не публикация)

**Baseline:** `main@4ba8d4eab7db22fbccc632421eed06423778d7c1`, PR #114 merged. **Статус:** PR candidate, не runtime-approved и не owner/device-accepted.

## Проблема

В текущем Raven production-контракте каждая каноническая сцена должна присутствовать одновременно в `season1_dialogue_catalog.json`, `vn_staging.json`, `map_narrative_routes.json`, а её ID/реплики/звуки/выборы должны соответствовать сохранениям и игровому progression. Новый черновик из VNS5-06B имеет зарезервированный ID `RM-DRAFT-BEAT-XXXX`, не имеет одобренных shot/gate и **не может** безопасно автоматически стать runtime-сценой. Story Map VNS5-06A — предложения, не реализованная логика выбора/Match-3.

## Что добавлено

В Raven VN Studio появилась отдельная вкладка **Promotion Review**. Для каждой новой сцены можно явно сопоставить черновой ID новому production-style ID `RM-BEAT-XX-YY` (например, `RM-DRAFT-BEAT-0001 → RM-BEAT-07-01`). Target не может совпадать с существующей сценой, другим target или чужим ID. Изменения mapping принадлежат обычному `raven-vn-studio-draft-v1` и используют общий Undo/Redo/локальное сохранение.

**Проверить миграцию ID** строит детерминированный предпросмотр; **Экспорт Promotion Review** создаёт неизменяемый JSON в `user://raven_story_studio/promotion_review/raven-promotion-<hash>.json`. Сначала сохраните локальный draft; второй экспорт идентичного содержимого блокируется. Нет кнопки `Apply`, записи в `res://`, commit/PR автопубликации и разрешения загрузить такой JSON как runtime-ресурс.

Выходной формат `raven-vn-promotion-review-v1` содержит:

- SHA-256 исходных четырёх каталогов (dialogue, routes, staging, cast) для проверки устаревших/конкурирующих изменений.
- `idMap` и `lineIdMap`, которые заменяют draft scene ID и все line ID новой сцены на предложенные production IDs, при сохранении существующих line IDs других сцен.
- `reviewCatalog` — **предлагаемый** каталог с оригинальными + новыми сценами/репликами и текстовыми правками; `status: DRAFT_PROMOTION_REVIEW_NOT_RUNTIME`. Исходный каталог не затронут.
- `reviewGraphPatches` — ссылки Story Map после преобразования source scene ID, целевого scene ID и choice checkpoint `lineId`; ссылки Match-3 на существующие уровни остаются прежними.
- `retainedDraft` — все source graph/text/stage v1/stage v2/FX изменения без потерь.
- `diffSummary` (before/after scenes/lines, число правок локализации, графов), `promotionBlockers` (shot, route gate, runtime/Match-3/choice sink, save migration), `localizationWarnings` (RU/BE/EN completeness), `runtimeApplied:false`, `readyForRuntime:false`, `requiresHumanReview:true`, `requiresFollowUpPromotion:true`.

Поле `promotionSceneIdMap` в draft опционально. Старые черновики без него работают как раньше. Старый Story Map review экспорт запрещён при непустом ID mapping, чтобы не потерять существенные сведения. Смена SHAs/чужая ветка/коллизии должны **закрывать** экспорт.

## Ключевое ограничение

Наличие полного `reviewCatalog` в JSON **не означает**, что можно заменить им `season1_dialogue_catalog.json`: для новой сцены ещё нет утверждённого `vn_staging.sceneShots` с проверенным фоном, asset provenance и персонажами, а также `map_narrative_routes.sceneTriggers` с поддерживаемым runtime gate. Не создана миграция старых сохранений и нет утверждённого универсального runtime-исполнителя Story Map. Прямое применение приведёт к несогласованности производственного контракта; экспорт предназначен только для review.

**Следующая отдельная работа / VNS5-06D:** подготовить ручной review и атомарную promotion-операцию после решения владельца по staging, trigger, flow, сцепке save-contract, checksum и сохранению backward compatibility. Тогда нужна проверка экспортируемых JSON, source diff, rollback, CI parity и подтверждение локализаций. PR этой фазы этого не обещает и не делает.

## Тесты и ручная QA

`tests/raven/vn_studio_promotion_review_smoke.gd` запускается из `scripts/check.sh`. Проверяет на настоящем производственном каталоге: исходные 28 сцен/280 реплик, новый scene/line + новую реплику в старой сцене, mapping, прямые ссылки/choice checkpoints, RU/EN текстовые правки, ID/line collisions, отсутствие допустимости старого экспорта, SHA-drift, неизменность canonical files, no-overwrite review, отдельную вкладку, Undo/Redo и disabled export без mappings.

**Ручная Windows Godot Editor проверка** на 800×640, 1024×640 и 1366×768: создать одну сцену и реплику, открыть Promotion Review, ввести `RM-BEAT-07-01`, проверить список блокирующих задач, Undo/Redo, сохранить draft, закрыть/открыть редактор, убедиться в сохранении ID mapping, экспортировать один раз. Проверить неверный target / collision, переключение UI языков, неизменность игрового VN/Match-3 и дашборда. **Green CI не равен owner acceptance.**

Подробнее: `docs/production/VNS5_06A_STORY_MAP_RU.md`, `docs/production/VNS5_06B_NEW_SCENES_RU.md`, `scripts/raven/tools/validate_production_narrative.py`.

## PR #115 CI evidence, 02.11.2026
Первый полный CI для исходного implementation head c692459162f5e802d6259f7047ee16fb80351e9e: [#41456371177](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41456371177) — **SUCCESS**. Проверены новый VNS5-06C Godot smoke, все прежние Raven checks, Room Builder, сборка Web и dashboard. Эта правка документации и статуса вызывает новый CI для финального head; его результат ещё требуется проверить. Нативный Windows Editor, живой пользовательский save/reopen, art, route, branch runtime и сейвы не были приняты владельцем.
