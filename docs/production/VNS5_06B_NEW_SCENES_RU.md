# VNS5-06B — новые сцены и реплики Raven в VN Studio

**Baseline:** main `eac94deb1be08f7a44c1f6486ab293c3bb3f2dc7` (merged PR #113 VNS5-06A). **Статус:** реализация в review PR, отдельно от игровых переходов. Ни один новый сюжетный узел не вводится в runtime автоматически.

## Пользовательский сценарий

1. Открыть Godot Editor → VN Studio → Raven Manor. Нажать **+ Сцена**, указать русское название, текст первой реплики и существующего персонажа (speaker). Нажать подтверждение.
2. Создаётся сцена вида `RM-DRAFT-BEAT-0001` и реплика `RM-DRAFT-BEAT-0001-L001`. Никакие старые канонические IDs не меняются. Новая сцена появится в списке сцен и в Story Map с gate `draft_unapproved`; Stage Designer честно отображает **ART PENDING** (нет утверждённого фона, постановки или игрового триггера).
3. Нажать **+ Реплика** в новой или существующей сцене. Следующий свободный `sceneId-LNNN` выделяется автоматически, не затрагивая прежние ID. Добавленные реплики редактируются в той же вкладке «Диалог», языки RU/BE/EN доступны через существующее переключение; для отсутствующего перевода сохраняется RU fallback.
4. Для временно добавленной сцены можно рисовать предложенные связи в Story Map, в том числе выбор A/B/C на новых или существующих lineId; всё остаётся локальным черновиком.
5. Использовать обычные Undo/Redo и «Сохранить Raven-черновик». **Экспорт Story Map review** (теперь общий no-loss story review) сохраняет `authoredScenes`, `authoredLines`, `storyGraphPatches`, `textPatches`, `stagePatches`, `stageV2Patches`, `stageFxPatches`, а также `dialogueCatalogReview` — полную просматриваемую копию каталога, но **не** утверждённый production JSON.

## Данные, ограничения, безопасность

- Новые поля в обратносуместимом `raven-vn-studio-draft-v1`: необязательные `authoredScenes: []` и `authoredLines: []`. Старые `user://` черновики без полей открываются без миграции. Новые сцены имеют `status: draft_not_runtime`, первая непустая RU реплика обязательна.
- Максимум 32 новых сцен и 320 новых реплик на один черновик; имена RU — непустые до 120 символов, тексты RU — непустые до 6000, speakers берутся **только** из уже зарегистрированного character catalog.
- ID генерируются детерминированно с проверкой реальных source-IDs и всех локальных новых IDs. У новых сцен зарезервированный префикс `RM-DRAFT-BEAT-`, чтобы не перепутать с утверждёнными `RM-BEAT-`. При Undo/Redo и сохранении ID сохраняются вместе с draft; при будущей настоящей promotion потребуется явное утверждение production-ID и поправка всех ссылок (не часть этого PR).
- Старые JSON-экспорты, способные выбросить новые сцены/реплики, блокируются. Общий review JSON содержит `requiresHumanReview: true` и `runtimeApplied: false`, экспорт `user://`, SHA content-addressed путь, без перезаписи. Existing source/catalog/root и route SHA guards сохраняются.
- Нет прямого изменения `data/raven/production/season1_dialogue_catalog.json`, `map_narrative_routes.json`, `vn_staging.json`, character performance, UPDS donor, `RavenReducer`, `StorySession`, Match-3 или campaign save. Нельзя попасть в отсутствующую сцену в живой игре. Для неё пока не допускаются Stage Designer/FX-авторинг, поскольку отсутствуют approved staging и asset state.

## Тестирование и требуемая приёмка

Новый `tests/raven/vn_studio_new_scenes_lines_smoke.gd` подключён к `scripts/check.sh`. Проверяет канонические 28 сцен/280 реплик, генерацию ID, добавление в существующую сцену, редактирование перевода новых реплик, Story Map ссылки, отсутствие чужих/дублирующих ID, пустого RU, произвольных полей и незарегистрированных speakers, SHA drift, no-loss/no-overwrite экспорт, Godot UI create + Undo/Redo, неизменность источников.

Godot 4.7.2 на Windows — вручную проверить окна **800×640, 1024×640, 1366×768**: диалоги «+ Сцена» и «+ Реплика» должны быть доступны, скролл работает, новая сцена показывает ART PENDING, переход с новой на старую не оставляет устаревшие спрайты. Проверить закрытие/повторное открытие Godot с сохранённым draft и RU/BE/EN, отдельно проверить импорты и экспорт. Пустой RU и speaker вне каталога должны быть отклонены. Без user verification — статус **не accepted**.

## Далее: VNS5-06C и завершение v5

- Отдельный review/promotion workflow: явное преобразование draft scene IDs в согласованные production IDs с проверкой всех inbound/outbound links, route gates, art staging, line/FX references, i18n, совместимости и reversible diff. Никакой auto-promotion.
- Полноценные условия, альтернативные ending paths и игровой choice/Match-3/map transition sink требуют отдельного утверждения контрактов reducer и сохранений.
- VNS5-07: animation clips, runtime production renderer, parity/migration, E2E device QA. Сценарный редактор пока не является полностью завершённой авторской платформой.
