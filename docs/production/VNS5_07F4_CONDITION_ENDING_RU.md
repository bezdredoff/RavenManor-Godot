# VNS5-07F4 — Condition и Ending в черновой Story Map

**Основание:** восстановленный HTML v5 (ChatGPT, 1 ноября 2026), issue #129. **Статус:** PR_review, CI и Windows нативная QA на момент записи открыты.

## Новые связи

- `condition`: существующая source scene → существующая target scene. Дополнительное поле `conditionRef` — **строго текстовая безопасная метка** длиной 1–64 (латиница, цифры, точка, подчёркивание, дефис). Например `has_clue` или `gate.read_letter`. Это **не** GDScript, не скриптовый путь, не executable expression и не новая переменная `RavenReducer`. Валидатор запрещает повторные `conditionRef+targetId`, запрещает `lineId/choiceKey` для этого типа и проверяет существование target scene.
- `ending`: source scene → редакторский терминальный `DRAFT_END` (визуальная нода `end:<sceneId>`). Это **НЕ** утверждённая игровая концовка и не произвольный `RM-END-*`. Валидатор требует строго этот marker и запрещает дополнительные поля; количество безусловных переходов защищено прежним правилом: не более одного `scene/match3/ending` на исходную сцену.
- Оба типа сохраняются только в `user://` `storyGraphPatches` (существующий `raven-vn-story-edges-v1`, расширение разрешённых ключей и типов с полной backwards compatibility), доступны через `+ Связь`, inspector, списки и цветной оранжевый draft-провод. Если адресат не выбран, действие не создаётся.
- `condition` и `ending` отражаются только в `Graph.build` для просмотра и в существующем `export_story_graph_candidate`; ни один gameplay route gate, Match-3, сохранение, концовка или reducer не меняются.

## Почему это не является runtime-контрактом

В истории HTML были controls `condition` и `ending`, но не было согласованной семантики переменных, условий истинности, ending IDs, checkpoint и миграции сохранений. Заполнить их выдуманной игровой логикой было бы опасно. Поэтому это явный **proposal/annotation**, а утверждение исполняемой семантики потребует отдельного контракта, согласования и PR.

## QA

Автотест `tests/raven/vn_studio_raven_graph_smoke.gd` расширен: condition+ending положительный валидный draft, отвергаемые script/path conditions, дубли, неверные ending IDs, двойные unconditional, читаемый terminal node, inspector edit/roundtrip, отрисовка orange wire, неизменность SHA canonical sources.

Windows Godot 4.7.2:
1. Выбрать сцену → Story Map → тип `condition`, target другую сцену, `conditionRef=has_clue`, подпись, `+ Связь`. Проверить видимый оранжевый провод, выделение и редактирование `conditionRef`.
2. Попробовать `conditionRef=res://x.gd` и дубликат — ошибка, draft не меняется.
3. Выбрать `ending` → target `DRAFT_END` → `+ Связь`. На карте появится **ФИНАЛ-ЧЕРНОВИК**, не связанный с реальной концовкой. Попробовать добавить второй безусловный `scene`: валидатор отклоняет.
4. Проверить, что клик по зелёной канонической линии не открывает редактирование, а orange draft открывает. Сохранить `user://` черновик / перезапустить Godot / экспорт Story Map review и убедиться в сохранности `conditionRef/ENDING`, неактивности runtime.
5. Проверить маленькое окно 800×640 и широкий Editor, прокрутку inspector и графа; визуальный HTML-v5 screenshot parity не утверждать без локального оригинала.

## Зависимость и актуальный статус

PR #130 **смержен** в main как `84ca9484296694fc9039dfb8b5be2833f8d3e979`. PR #131 **перебазирован** на этот main без коммитов-предков #130 (чистый один коммит с семью F4-файлами). Повторная независимая CI и нативная Godot QA требуются до принятия PR #131. Не автосливать и не менять source scene status на `accepted`.
