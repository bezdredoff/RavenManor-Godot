# VNS5-04A — Stage Designer: ориентация, шаблоны и локальный Undo

**База:** `bezdredoff/RavenManor-Godot@ac7bcd0bbbe52db71262ae8a1adf4fbecf9fe9cd` (PR #99 merged, CI #41345448978 passed). Следующий шаг по `Raven_VN_Studio_Godot_Handoff_v5`, PR 04, разделён на A/B, чтобы не ломать stage-v1.

## Доступные функции этой части

В `Godot → VN Studio → Raven Manor → Director → Постановка` добавляется переключатель **Портрет 390×844 / Альбом 844×390**, **Фон: cover/fit**, кнопка **Шаблон 1/2/3**, кнопка **Отменить постановку** и **Safe area**. Сетка и VN HUD повторяют пропорции текущего frame. `stage_layout_tools.gd` отделяет горизонтальные расчёты от уже общего с runtime `raven_vn_portrait_layout.gd` — portrait не изменяется.

**Важные границы:** ориентация, fit/cover и guide overlays — **только параметры preview editor-session**; они не записываются в `vn_staging.json` и не притворяются независимым production landscape asset. Все зарегистрированные BG в основном portrait; cover обрезает их, fit оставляет поля; новая картина не генерируется. Preset применяется по явному нажатию и сохраняет только разрешённые `slot/x/y` для текущих 1–3 персонажей в существующий `stagePatches`; ID, pose, emotion, costume/assetId не меняются. Undo хранит не более 32 предыдущих stage-состояний **только пока редактируется эта сцена в текущей сессии Godot**. Это не проектный UndoRedoManager и не Redo.

При переключении ориентации layout вычисляется на основе нормализованных координат; уже сохранённые `x/y` не переписываются. Отдельные landscape layout-шаблоны заданы как предустановки, а не принудительный пересчёт при каждом переключении. Кнопка шаблона может перезаписать пользовательские координаты **только после нажатия**, предыдущий снимок остаётся в Undo.

## Не входит в VNS5-04A

- Persisted scene orientation, отдельные настройки focal point/crop, foreground masks, z-index и добавление/drag arbitrary props в draft требуют расширения `Store.validate_stage`, версионированной схемы сцен v2 и ревью миграции. **VNS5-04B**.
- Автоматическая материализация staged images из VNS5-03 в `res://` не производится.
- Ни `raven_vn_game_view.gd`, ни игровые saves/rewards/прогрессия, ни UPDS don​​or, ни narrative/locale catalogs не изменяются.

## Проверка

CI: новый `tests/raven/vn_studio_stage_orientation_smoke.gd` проверяет размер canvas, 1/2/3 шаблоны, roundtrip горизонтальных координат, сохранение actor ID, menu cover/fit, editor-only guides, корректный `Store.validate_stage`, Undo и SHA неизменности production staging. Запускаться должен через `scripts/check.sh` и `check.ps1`. До импорта patch в реализационную ветку CI **не запускался**.

Ручной Windows Godot 4.7.2: окна 800×640 / 1024×640 / 1366×768; Raven 1/2/3 персонажа; фон BG-HALL и ещё один вариант; выбрать оба aspect ratio, grid/safe/HUD; переключать fit/cover и проверить отсутствие растяжения; перетащить 2 персонажей, применить шаблон, отменить и сохранить/перезагрузить; затем переключить ориентацию и убедиться, что сохранённые x/y неизменны; проверить старый UPDS UI. Документировать скриншоты. До подтверждения считать PR_review, не accepted.

## Доставка / rollback

`incoming` ZIP содержит **только** документационный handoff patch и сопроводительные instructions, поскольку доверенный importer запрещает `addons/`, `check.ps1` и `scripts/check.sh`. После импортного candidate PR извлечь `implementation.patch.txt` в чистую ветку от зафиксированного `main`, проверить `git apply --check`, применить, получить отдельный **implementation PR**, дождаться полного CI **на последнем SHA**. Нельзя мержить handoff как реализацию. Rollback: revert implementation PR; stage-v1 production files никогда не были затронуты, а редакторные undo stack не являются сохранёнными игровыми данными.
