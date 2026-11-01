# VNS5-05A — сценный редактор микроанимаций VN Studio

**Baseline:** RavenManor-Godot `main@7652a20676bce76e7aead065bdd025b8cee5154b` после PR #104 и #103. **Status:** implementation candidate; Godot CI и manual Editor QA не выполнены на этой ветке. Scope: P0 editor-only stage micro-FX timeline; runtime playback и line-level cue triggers остаются отдельной задачей VNS5-05B.

## Контракт

- Существующий `raven-vn-studio-draft-v1` расширен необязательным `stageFxPatches[sceneId]`. Старые черновики без этого поля валидны, автоматически не переписываются. Патч: `{format:"raven-vn-stage-fx-v1",schemaVersion:1,sceneId,cues:[...]}`.
- Cue: `{id:"fx-0001",targetType:"background|actor|prop",targetId,effect,startMs,durationMs,repeat,intensity}`. Цели: `background`, текущие `RM-CHAR-*` или текущие `prop-####` из Stage v2; никаких произвольных путей или ресурсов.
- Effects: `breathe`, `blink` (только геометрический proxy, не новый портрет), `shake`, `pulse`, `fade_in`, `fade_out`. `startMs` 0..15000, `durationMs` 120..4000, `repeat` 1..5, `intensity` 0..1; суммарный конец до 20000 ms; максимум 32 cues.
- Семплирование `StageFx.sample(cue,elapsedMs)` **чистое**, независимо от FPS и истории кадров; каждый update возвращает scale/offset/alpha после сброса editor controls к исходной раскладке. 32 шага локального Undo; в глобальном Raven draft — обычный undo/redo snapshot.
- Сохранение via `Store.set_stage_fx` с source SHA locks на staging/cast; old draft remains valid. Невозможно удалить v1 актёра или v2 prop, если на него ссылается FX. Патч v2 и FX не применяется к runtime автоматически.
- `Store.export_fx_candidate` создаёт hash-based no-overwrite `user://raven_story_studio/fx/exports` JSON со stage v1 patches, v2 patches, FX, pinned source SHA, `runtimeApplied:false`. v1 stage и v2 stage exports **отклоняются** при FX, чтобы не терять данные тихо. Это НЕ публикация в production.

## Проверки

1. Full Linux `scripts/check.sh` / Windows `check.ps1`; отдельный `tests/raven/vn_studio_stage_fx_smoke.gd`. До CI честно считать код непроверенным в Godot.
2. В Godot 4.7.2 проверить окна **800×640, 1024×640 и 1366×768**. Открыть сцену с 0/1/2/3 актёрами; выбрать фон, актёра, prop, добавить 1–3 cues; проверить параметры, timeline slider, Play/Pause/Reset, Undo, сохранение и повторное открытие редактора.
3. Задать blink: визуальный proxy **не** меняет выражение лица и не создает кадры; убедиться, что проживание/зажмуривание не в игровой версии. Проверить пропуск сцен и смену sceneId, все истории Undo должны быть scene-scoped.
4. Негативные проверки: duplicate fx ID, unknown actor/prop, NaN/Inf, start 15000 duration 4000 repeat 5, неизвестное поле, попытка удалить animated prop; stale source SHA; повторный export не перезаписывает файл.
5. Проверить SHA `data/raven/production/vn_staging.json`, `season1_dialogue_catalog.json`, 62 approved portraits, runtime/UPDS до и после: **без изменений**. Реальные PNG/WebP assets, VFX keyframes/eye layers и runtime timeline integration не входят.

**Rollback:** revert implementation PR; локальные draft `user://` сохраняются для ручного восстановления. При откате к старому плагину FX sidecar не следует автоматически терять или удалять.
