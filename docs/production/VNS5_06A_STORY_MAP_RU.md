# VNS5-06A — редактируемая Story Map Raven в Godot (фаза 1)

**Baseline:** `main@be793b37be0ad8f279182ab461230cbe311e029b`, PR #112 merged. **Scope:** reviewed-only graph editing of existing canon scene IDs. **Status:** PR review candidate; не production topology.

## Что работает в VN Studio

- Вкладка **Story Map** вместо текстовой заглушки отображает нативный **GraphEdit** с настоящими 28 Raven-сценами, уже существующими `map_narrative_routes.json` trigger gates и графическими связями. `scene_complete` связывает фактический source scene с target; прочие условия (`first_clear`, `restoration_done`, `npc_tap`, `door_tap` и т. п.) представлены отдельными gate-узлами. **Порядок сцен не выдумывается как игровая цепочка переходов.**
- Переключатель **Все сцены** / окружение текущей сцены; текущая сцена разделяется с остальными вкладками VN Studio.
- В панели редактирования: тип `scene` (единственный безусловный переход), `choice` (выбор A/B/C, обязательная контрольная существующая `lineId`, произвольный короткий текст подписи) и `match3` (только levelId, уже встречающийся в канонических first_clear gate refs: на текущем исходнике `RM-LVL-002`). Кнопки **+ Связь** и **− Связь** изменяют только локальный draft.
- Сценные связи и выборы в graph draft — **только proposal/review**, а не работающие переходы в игре. В существующем runtime нет утверждённой generic choice/condition/match3 projection. Никакие выборы не активируются от нарисованной связи.
- Черновой `storyGraphPatches[sceneId]` добавляется опционально в **старый** `raven-vn-studio-draft-v1`. Старые drafts валидны. Патч формата `raven-vn-story-edges-v1`, поля `format/schemaVersion/sceneId/edges`; каждый edge: `edge-0001`, `kind`, `targetId`, `label`, для choice также `lineId` и `choiceKey`. Выбор target берётся из реально открытого проекта, без ручного ввода произвольного пути.

## Безопасность и экспорт

- source route SHA `routeSourceSha256` привязан к `map_narrative_routes.json`. При внешнем изменении файла validation/export **fail closed**, автоматического rebase нет; не перезаписывать другой агентский проект.
- Запрещены неизвестные поля, повторяющиеся IDs/choice key, отсутствующие scene/line/match3 targets, choice lineId другой сцены, пустые подписи, более 20 edges и более одного безусловного transition на сцену. Возможные циклы/конфликтные канонические gate conditions остаются на **human review**; это не production engine.
- Поддерживается Undo/Redo главного Raven Draft и `Store.save_local`. **Экспорт Story Map review** в `user://raven_story_studio/story_graph/exports` — SHA/хэш-контент, **no-overwrite**, `runtimeApplied:false` и `requiresHumanReview:true`, с ВСЕМИ существующими draft категориями (текст, stage v1/v2, FX), чтобы не потерять данные.
- Старые экспорты текста, v1/v2 и FX **отклоняются**, пока присутствуют изменения Story Map: нельзя тихо выбросить graph patch. Канонические `map_narrative_routes.json`, `season1_dialogue_catalog.json`, все фоны/арт/UPDS donor, reducer, Match-3 и сейвы НЕ меняются.

## Проверки

`tests/raven/vn_studio_raven_graph_smoke.gd` в `scripts/check.sh`: проверка реальных source graph/route gates; две условные ветки A/B и их контрольная реплика; проверка target; duplicate IDs; больше одного unconditional edge; match3 ref; нет потерь при экспорте; no-overwrite; SHA drift; headless GraphEdit instantiate, add/remove; неизменность четырёх канонических файлов.

Ручная проверка Godot 4.7.2 под Windows в **800×640, 1024×640, 1366×768**:
1. VN Studio → Raven → Story Map → переключить все сцены / текущая. Увидеть `RM-BEAT-00-01`, его gate, исходные dependencies, без фиктивного перехода из каждого ordinal.
2. На `RM-BEAT-00-01` создать `choice A` для L001 → `RM-BEAT-00-02`, choice B → `RM-BEAT-00-03`; проверить кнопки удаления и общий Undo/Redo.
3. Проверить `match3` с реально существующим `RM-LVL-002`, некорректные target ID и повтор выбора; не должно быть возможности сохранить их в canonical.
4. Сохранить draft, закрыть/открыть Godot Editor, убедиться, что граф восстановлен. Экспортировать Story Map review; второй экспорт должен быть заблокирован до изменения содержимого.
5. Проверить, что игра, донор UPDS, сцена чая и экран Match-3 ведут себя как прежде.

## Что ещё требуется для полного VNS5-06

**VNS5-06B:** безопасное добавление новых Raven сцен и реплик с неизменяемыми IDs и дефолтными staging/route placeholders, draft-only migration/promotion в новый каталог, параллельная RU/BE/EN локализация, добавление полноценного choice/condition/Match-3/return-map/ending runtime schema после отдельного владельческого решения и parity/reducer tests. VNS5-06A не выдавать за готовый авторский сюжетный движок.

**Важное QA ограничение:** green CI ≠ визуальная приёмка редактора. После merge VNS5-06A оставить status `merged` (не `accepted`) до ручной проверки окон и функциональности.

## Проверенная CI-сборка PR #113 (02.11.2026)
Первый CI [#41440902075](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41440902075) остановился на старом тесте разметки, который ожидал удалённую текстовую заглушку Story Map. После обновления этого теста независимый [CI #41441192327](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41441192327) **прошёл**, включая новый Story Map smoke и все предыдущие Raven, Godot, Room Builder, Web и dashboard проверки. Эта фиксация результата изменяет только docs/status, dashboard и данный файл, поэтому финальный head CI нужно проверить отдельно перед мержем. Human desktop UX и owner acceptance не проводились.
