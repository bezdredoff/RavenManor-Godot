# VNS5-06D1 — четырёхкаталожный кандидат для ручного review (не применение)

**Baseline:** `main@5372e3c544c43cc71c758a9411e93bf317caea14`, PR #115 merged. **Статус:** implementation PR, не production release.

## Зачем нужен этот этап

Простой перенос новых сцен из VNS5-06B/06C в `season1_dialogue_catalog.json` некорректен: действующий контракт требует синхронные записи в четырёх production-регистрах, а также ограничения сохранений и progression. Автоматически придумывать постановку, фон, gate или micro-FX нельзя. VNS5-06D1 проверяет *предлагаемые* данные и собирает **единый кандидат для ревью**, но никогда не заменяет файлы проекта и не включает новые сцены в runtime.

## В интерфейсе VN Studio

1. Создать сцену и реплики, на вкладке **Promotion Review** указать производственные ID `RM-BEAT-XX-YY` для каждой черновой сцены.
2. Сохранить Raven-черновик. Нажать **1 · Пустой manifest для review**. Появится JSON в `user://raven_story_studio/production_package`. Повторная запись того же файла блокируется.
3. В локальной копии manifest заполнить `reviewRef`, каждый `sceneShots[productionSceneId]` (существующий background master, lighting, roomState, 1–3 зарегистрированных актёра и их pose/emotion/micro), каждый `routeProposals[productionSceneId]` (поддерживаемый `scene_complete` с отличающейся существующей сценой, либо известный `first_clear` level; interactionTarget), `lineCues[promotedLineId]` (pose/emotion/cue зарегистрированного speaker). Не менять `sourceSha256`, `routeSourceSha256`, `stageSourceSha256`, `castSourceSha256`, `cueSourceSha256`.
4. Нажать **2 · Открыть заполненный JSON**. Импорт допускает до 512 КиБ, отклоняет неизвестные поля, несовпадающие SHA, отсутствие реплик/сцен, неверные персонажи/фон/состояния и несогласованные ID. Manifest хранится только в памяти редактора и сбрасывается при смене черновика, поэтому после изменений импортируйте заново.
5. Нажать **3 · Экспорт 4 каталогов (review only)**. Только после сохранения черновика создаётся content-addressed JSON в `user://raven_story_studio/production_package`. Он **не** записывается в `res://`, не применяется при запуске и не активирует персонажей.

## Что в JSON

Формат `raven-vn-production-4registry-review-v1`; пять SHAs; `sceneIdMap`, `lineIdMap`, proposal gates, `diffSummary`, `retainedDraft`; полноразмерные review-копии:

- `files.season1_dialogue_catalog.json` (исходные + новые сцены/реплики, включая изменения текста),
- `files.vn_staging.json` (новые validated sceneShots),
- `files.map_narrative_routes.json` (новые sceneTriggers с **`draft_unapproved`, `approvedRuntime:false`**, оригинальный proposed gate остаётся отдельной записью),
- `files.line_performance_cues.json` (новые line cues с **`manualReview:true`**).

Каждый файл в candidate получает `status: DRAFT_REVIEW_NOT_RUNTIME`. Флаги `runtimeApplied:false`, `readyForRuntime:false`, `requiresFollowUpPromotion:true`. Никакой «approval» из имени поля или `reviewRef` не считается настоящим подтверждением владельца.

## Границы ответственности и fail-closed

- Для новой сцены нужен весь набор shot + route; для каждой новой реплики — cue; IDs должны быть уникальны. Мастер фона должен разрешать конкретные lighting/state; каст ограничен реальными персонажами/позами/эмоциями/micro и разными слотами.
- Прямая циклическая зависимость между предложенными сценами блокируется. Только известные level refs поддерживаются для `first_clear`.
- Предложения Story Map с реальными edges (choice/match3/scene) **пока блокируют** четырёхкаталожный кандидат: их игровой reducer и save/branch contract ещё не реализован. Исходный draft сохраняется для следующей фазы.
- **Публикация остаётся заблокированной**: одобрение art provenance, активация playable gate и переходов, сохранение и миграция старых сейвов, parity test, полноценная локализация BE/EN, проверка rollback и ручная QA обязательны. Это этап D1; реальный opt-in apply требует отдельно утверждённого VNS5-06D2.
- Не трогаем canonical dialogue/stage/routes/cues/cast, UPDS donor, runtime Match-3, save snapshots, GitHub main или assets.

## Проверки

Новый smoke `tests/raven/vn_studio_four_registry_promotion_smoke.gd` в `scripts/check.sh`: синтетическая новая сцена на реальном master/actor, четыре output registry, неизменность пяти исходных SHAs, запрет missing fields/unknown gate/unregistered character/invalid pose/bad cue/branching, no-overwrite template и export, UI manifest import. CI и Windows Godot Editor 800×640 / 1024×640 / 1366×768 обязательны до merge/ручной приёмки.

**Следующая фаза:** VNS5-06D2 — отдельное согласование и внедрение проекции review-кандидата в production с transactional diff, backup/rollback, approved route+art, save migration и end-to-end playable tests. Данный PR сознательно не реализует её.

## Результат CI и параллельная работа
Независимый CI implementation head 59c585b704b1f4522b583a37e46ee4e36d41c51f: [#41466727888](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41466727888) — **SUCCESS**; проверены новые Godot tests, Raven, Room Builder, Web export, dashboard. Этот commit с evidence запускает финальный CI ещё раз. Обнаружен параллельный PR [#116](https://github.com/bezdredoff/RavenManor-Godot/pull/116): это отдельный Python CLI для будущего offline release staging, тогда как #117 — нативная интеграция в Godot VN Studio. У них разные manifest schemas и пересекаются docs/check.sh/dashboard. Нужны осознанное согласование контрактов и rebase после первого мержа; пока нельзя считать два процесса публикации взаимозаменяемыми.
