# VNS5-07F1 — живое редактирование FX во вкладке Animation

Основание: замечания владельца о несоответствии HTML-прототипу, issue #121; PR #127 VNS5-07E merged 2026-11-02. **Статус PR_review**, до независимого CI и нативной приёмки.

## Что было неверно

Native Raven VN Studio содержал вкладку **Animation**, но она состояла из `RichTextLabel` с сообщением о том, что timeline/clips появятся позже. При этом рабочий редактор микро-FX уже присутствовал глубоко в `Stage Inspector` (код `raven_stage_designer.gd`). Поэтому пользователь видел пустую Animation и не находил уже реализованные функции.

## Что изменено

- Реальные FX-виджеты `raven_stage_designer.gd` сгруппированы в `_fx_controls: VBoxContainer` и помещены в **Animation** в проектном Raven Director. В режиме standalone `StageDesigner` они остаются внутри StageDesigner — старые тесты и инструменты не должны терять функциональность.
- В Animation видны: **цель** (background / cast actor / staged prop), **+ FX**, **− FX**, **Undo FX**, список cues, scene/line anchor, effect `breathe/blink/shake/pulse/fade_in/fade_out`, start/duration/repeat/intensity, **Play/Pause/Reset и scrub**. Все контролы редактируют уже существующий `stageFxPatches`, без новой схемы.
- Центральный Stage остаётся одновременно видимым; Play/Pause и scrub меняют только предпросмотр и не запускают RavenReducer / игровую кампанию. Диалоги и локализации остаются прежними.
- Подсказка показывает выбранный lineId / исходный cue и явно говорит: `blink` сейчас геометрический proxy, а не анимированный набор глаз. Параметры кадровой анимации, animation clips с keyframes и production ассеты — будущие задачи, не фейковые функции этого PR.

## Приёмка

Автотест `tests/raven/vn_studio_layout_smoke.gd` проверяет, что Animation (index 4) содержит **действующие виджеты** `_fx_controls`/список/Play и что они не остаются в Stage Inspector; синтетический `+FX` добавляет cue, `Undo FX` возвращает прежний список без изменения canonical sources. Прежние Godot FX smoke и no-loss/validation/sha checks должны пройти в CI.

**Windows Godot 4.7.2 ручная проверка:**
1. После pull и полного перезапуска Godot: VN Studio → Raven Manor → Inspector → **Animation**. Должен быть **не только текст**, но список/кнопки/слайдер. Stage остаётся центральным и видимым.
2. Выбрать сцену (с нейтральным исходным фоном), в Animation цель `background`, нажать `+ FX`; выбрать `pulse`, start=0, duration=1400, repeat=1, intensity=0.3. Нажать Play/Pause и подвигать scrub: фон должен визуально менять scale. Reset возвращает base.
3. Нажать реплику L002 → изменить anchor cue с «Вся сцена» на L002. При выборе L001 эффект не должен проигрываться; после возврата на L002 должен появиться на scrub.
4. Поменять effect на breathe/shake/fade. На сцене с персонажем выбрать его target и проверить FX. Если ассет отсутствует, такой результат фиксируется как ART PENDING, не утверждается новая анимация.
5. Сохранить Raven-черновик, перезапустить редактор, проверить cue; Undo/Redo, Export FX review, статус draft. Старые сцены / story map / production JSON не меняются.
6. Повторить при ширинах 800, 1024, 1366; убедиться, что Animation ScrollContainer даёт доступ к кнопкам, не перекрывая Stage.

## Отдельный HTML parity gate

Фактический утверждённый прототип был найден локальным Codex по адресу `C:/git/Raven_VN_Studio_Godot_Handoff_v5_2026-11-01/prototype/raven_vn_studio_v5.html`; исходника в `RavenManor-Godot@main` и в доступных файлах текущего ChatGPT-сеанса нет. Поэтому **VNS5-07F1 подтверждает конкретный пробел функциональности, но не pixel-perfect / workflow parity с HTML**.

Следующий независимый этап VNS5-07F2 должен *локально* открыть HTML и Godot в одинаковых viewport (1366×768 и ширина скриншота пользователя), записать screenshot side-by-side, таблицу отличий по placement/content и отдельно проверить scene navigator, dialogues, props gallery, actual timeline/cues, Stage, Story Map. Изменения в рамках такого сравнения — отдельные небольшие PR. Не выдавать отсутствие скриншотов за подтверждённую паритетность.

Нет production FX asset approval, auto runtime apply, GameSave/Reducer changes, auto-merge. Документы и статусы обновляются в каждом PR.
