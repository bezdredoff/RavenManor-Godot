# VNS5-06D2C · Канонический runtime-диспетчер утверждённых VN-сцен

**Основа:** `main@4fc37d8603d277a8aa4a3a49a2cd009d0c55209d`, PR #119 смёржен. **Область:** fail-closed runtime dispatch после существующего RM-VS-01. Этот PR **не публикует новых сцен** и не меняет ни один каталог сюжетного контента.

## Что сделано

Новый `scripts/raven/raven_vn_runtime_dispatch.gd` читает только канонические `res://data/raven/production/` каталоги и `foundation_catalog.json`, НЕ читает JSON из `user://`, D1/D2A/D2B review-кандидаты или внешние staging-папки. Он выбирает следующую доступную сцену (по `ordinal`) после завершения существующего вертикального среза. Доступ определяется всеми требованиями **одновременно**:

- `season1_dialogue_catalog.json.scenes[].status == "runtime_approved"` (**новое отдельное явное значение**; `review_only_not_runtime` и старое `already_runtime` не проходят).
- `map_narrative_routes.json`: `gate.approvedRuntime == true`, `gate.proposedRuntime == false`, известная цель взаимодействия и точное поведение `postSceneAction`/once. Для этой фазы поддерживаются только безопасные `scene_complete` (уже пройденный beat) и `first_clear` (известный пройденный Match-3 level). Выборы, time-gates, script, произвольный branching **не поддерживаются и не стартуют**.
- Scene ID зарегистрирован в `foundation_catalog.storyBeats` (иначе `RavenSnapshot.normalize` потерял бы его); в текущем сейве `storyBeatsSeen` его ещё нет.
- У сцены ровно один sceneShot; фон и lighting/state находятся в каталоге и файл существует; фон имеет `status: accepted` и заполненный `approved`, путь ограничен `res://assets/raven/vn_backgrounds/`. Текущие кандидатные/неутверждённые фоны **не проходят**.
- Каждый актёр в уникальном слоте и имеет реальный **accepted + approved** portrait asset с точной pose/emotion; fallback до neutral не является допуском к релизу. Для всех реплик speaker присутствует в shot cast.
- Каждая новая реплика непустая на **RU/BE/EN**, имеет ровно один согласованный cue `manualReview == false`, `portraitVisible == true` с принятым artwork pose/emotion; несовпадения и отсутствующие cues блокируют сцену.

`find_approved`/ `build_config` — чистые функции на переданных **копиях** каталогов для unit/smoke. `next_scene` для реальной игры всегда получает **только** preloaded canonical `res://` JSON. Из него формируется конфигурация существующего `RavenVNPlayer` с явными `lineIds`, локализованными именами и текстом. `RavenVNGameView` переиспользуется для VN UI, background, portraits/cues.

## Реальная точка интеграции

`scripts/raven/vertical_slice.gd` оставляет прежнюю последовательность `Director.STEPS` и Match-3 полностью прежними. **Только после `Director.next_step(state).kind == "done"`** проверяется `RuntimeDispatch.next_scene(state, locale)`; если допущенных сцен нет, показывается старый экран `done`.

При завершении **последней реплики**, а не при открытии сцены, `completion_event` формирует idempotent `story_beat_seen`. Сначала `RavenReducer.apply`, затем `RavenCampaignStore.save_campaign`, и только при успешной записи меняется UI state. При ошибке event/сохранения UI оставляет последнюю реплику для повторного действия. Повторный event не удваивает прогресс. Reload и старые schema v1 сейвы используют тот же `Snapshot.normalize` и не получают новые несовместимые поля.

**Важно:** данный переход после завершения RM-VS-01 — минимальный инкрементальный способ проверки; он НЕ заменяет общий world-map/Story Map runtime director. Чтобы встроить сцены в другие места истории, нужны следующие этапы D2D: route scheduler, trigger/interaction, choices, return-to-map и Match-3 branches с отдельным save contract.

## Фактический статус и тесты

В текущем `main` нет новых `runtime_approved` сцен с принятыми фонами, поэтому `next_scene` возвращает пустой результат и **поведение игры не меняется**. Никакой owner approval не генерируется автоматически.

`tests/raven/vn_production_runtime_dispatch_smoke.gd` в `scripts/check.sh` создаёт **исключительно синтетические глубокие копии** canonical-пакета. Положительный сценарий временно принимает реальный существующий фон в памяти, создаёт scene+shot+cue+route+foundation beat для `RM-BEAT-07-01` и проверяет RU/BE/EN, настоящие `RavenVNPlayer` / `Reducer`, идемпотентность, нормализацию нового/старого сейва. Отрицательные: отсутствие approval, любой candidate art, нет staging/cue, неподтверждённый cue, несуществующие level/scene deps, нестандартные gate, пропавший перевод, неизвестный speaker, нет принятого portrait, replay уже пройденного beat. Исходники и пользовательские сохранения не меняются.

**Ручная проверка:** открыть текущий вертикальный срез, пройти до конца; старый экран завершения должен остаться. На EN/BE при текущем каноне новая ветка не должна появиться. Для настоящего release требуются ручные approvals art+dialogue+route+localization/cues, полный diff в отдельном PR, replay/rollback QA и save migration acceptance. **Нельзя** активировать новую сцену просто изменением флага в D1/D2B review-пакете.

## PR #120: проверенный код и оставшиеся блокеры

Кодовый HEAD `9f6cd96b2dc750e8a06ec50c91d6f46e8137d8de` прошёл полный независимый GitHub Actions [#41494291648](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41494291648): реальная компиляция нового runtime-dispatch и synthetic happy/negative Godot smoke, прежний RM-VS-01/Match-3, Room Builder, Web, dashboard. Два ранних CI показали синтаксические проблемы Godot, они исправлены в ветке до зелёного запуска. После обновления документации требуется отдельный финальный CI. Owner QA на настоящих новых сценах и приемка арта, перевода, маршрутов и сейвов всё ещё открыты.
