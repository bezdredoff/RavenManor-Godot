# VNS5-04B — локальная схема постановки v2

**Baseline:** `main@6bdd5fa6fc494a7c37d7b5c4aaf0e1d05ecf5346`, PR #101 merged. **Status:** implementation candidate, not merged/accepted. The incoming ZIP transports the implementation patch for a separate reviewed GitHub PR; incoming PR is not the deliverable.

## Контракт

Существующий `raven-vn-studio-draft-v1` и `stagePatches` сохраняются без миграции и без изменения `vn_staging.json`. Необязательный `stageV2Patches[sceneId]` содержит собственные `format=raven-vn-stage-overlay-v2`, `schemaVersion=2`, `sceneId`, `orientation=portrait|landscape`, `fitMode=cover|contain`, `focal={x,y}`, `actorZ` (ID только текущего cast), массив `props` (не более 24). У props стабильный `instanceId=prop-0001`, `assetId=""` для явного **ART PENDING** либо `asset-<sha256>` из локального import staging, `state`, `label`, `x/y∈[0,1]`, `z=-10..100`, `scale=0.1..3`, `pivot=center`.

Это **editor-only sidecar**: gameplay VN, Hall Tea, Room Builder, saved progress, season1 narrative, 28 scene IDs и 280 реплик не меняются. Принятые изображения персонажей и production background plates остаются исходными. Редактор отображает staged prop только после проверки при открытии локального `StagedImageStore`; он не становится approved asset или частью бинарников игры. Для ещё не созданных prop states явно используется placeholder.

## UX

В `Raven Manor → Director → Постановка` ориентация и `fit/cover` теперь записываются в V2 draft и восстанавливаются после перезапуска. `Focal X/Y` показывает визуальный крестик без смещения runtime-камеры. Можно задать z выбранного актёра, добавить до 24 экземпляров prop, сменить состояние (`clean`, `dirty`, `broken`, `restored`, `new`), asset, x/y, z, scale, удалить prop, перетянуть на сцене и отменить V2 изменение. Существующая stage-v1 расстановка персонажей остаётся отдельной, а 04A шаблоны сохранены.

Верхняя кнопка `Экспорт V2 review` пишет hash-named JSON **только в** `user://raven_story_studio/v2/exports` с pinning SHA исходного сюжета, staging и cast, V1 patches, V2 sidecar, staged prop hashes/provenance/license и списком ART PENDING. Повторный экспорт того же содержимого блокируется (no overwrite). Старый v1 stage export блокируется при наличии V2 patches, чтобы не отбрасывать ориентацию/props молча. Никакой автоматической записи в `res://`, promotion или runtime adapter нет.

## Проверки и ограничения

- Старые локальные черновики без `stageV2Patches` должны открываться без миграции; для новых полей действует strict schema; запрет неизвестных полей, duplicate instanceId, path-like assetId, NaN/Inf, неправильного focal/z/state, stale source SHA, unknown actor ID.
- Staged prop при review export должен существовать с корректной категорией `prop` и source locks; отсутствие binary или drift блокирует экспорт.
- Проверить Godot 4.7.2 Editor при 800×640, 1024×640, 1366×768. Добавить 1–3 cast, prop placeholder, staged prop, изменить ориентацию/fit/focal/state/z/scale, drag, undo, save/reopen, экспорт и повторный no-overwrite.
- Прогнать `vn_studio_stage_v2_smoke.gd`, старые smoke/regression `check.sh`/`check.ps1`, PR Godot CI/Web export. Сравнить SHA `vn_staging.json` и `season1_dialogue_catalog.json` до/после.
- Границы: focal — пока только **визуальный ориентир**, не pan/crop трансформация; перенос V2 в runtime, time clips/animation, полноценный production prop registry и approved state variants требуют отдельных PR, review и owner approval.

**Отмена:** revert implementation PR; локальные user:// черновики остаются доступны для ручного восстановления, canonical source unaffected.
