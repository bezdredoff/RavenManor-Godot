# VNS5-06D · безопасная сборка production-кандидата (phase 1)

**Base:** main `5372e3c544c43cc71c758a9411e93bf317caea14` после merge PR #115. **Режим:** отдельная CLI-операция с явным approval manifest; **не включает** новые сцены в runtime, не пишет `res://` или канонические файлы. Никакие новые сюжетные материалы в этом PR не были одобрены пользователем.

## Почему перенос нельзя делать одним JSON

Production-контракт требует согласованности четырёх каталогов:
- `season1_dialogue_catalog.json` — сцены и реплики;
- `vn_staging.json` — каждому новому sceneId утверждённая композиция с существующим фоном, освещением, состоянием комнаты и 1–3 персонажами;
- `map_narrative_routes.json` — каждому sceneId условие запуска и interaction target;
- `line_performance_cues.json` — каждой новой реплике существующего или нового sceneId свой cue с допустимыми pose/emotion/micro.

У предыдущего **Promotion Review** из VNS5-06C есть только текст и предложенные связи, но нет утверждённого runtime branch sink, новых shots, маршрутов и cues; отдельная проверка сохранений тоже отсутствует. Применение одного `reviewCatalog` повредило бы production registry parity.

## Что реализовано

`scripts/raven/tools/prepare_vn_promotion.py` читает (1) **неизменённый** `raven-vn-promotion-review-v1`, который экспортирует вкладка Promotion Review в Godot; (2) отдельный `raven-vn-release-preflight-v1` approval manifest, подготовленный человеком **после ревью ассетов/сюжета/сейвов**. 

Пример структуры approval manifest (значения — только пример, не факт утверждения):

```json
{
  "format": "raven-vn-release-preflight-v1",
  "schemaVersion": 1,
  "reviewSha256": "<SHA-256 точных байтов review JSON>",
  "cueSourceSha256": "<SHA-256 data/raven/production/line_performance_cues.json>",
  "approvalRef": "ISSUE-REVIEWED-EXAMPLE",
  "artApprovalRef": "ART-REVIEWED-EXAMPLE",
  "storyApprovalRef": "STORY-REVIEWED-EXAMPLE",
  "cueApprovalRef": "CUE-REVIEWED-EXAMPLE",
  "saveReview": {
    "existingSaves": "preserve",
    "newScenesDefault": "locked",
    "reviewRef": "SAVE-REVIEW-EXAMPLE"
  },
  "approvedTextLineIds": [],
  "sceneShots": [],
  "sceneTriggers": [],
  "lineCues": []
}
```

**Пустые три массива не пройдут для новых сцен/реплик.** В манифесте нужно указать полный объект каждой новой записи из исходной схемы registry (поля сопоставлять строго с `vn_staging.json`, `map_narrative_routes.json`, `line_performance_cues.json`), не только ID. Эти записи не генерируются из воздуха: production shot и маршрут должны получить независимую human-acceptance.

Запуск из корня репозитория:

```bash
python3 scripts/raven/tools/prepare_vn_promotion.py --review /path/to/review.json --approval /path/to/approval.json --check-only
python3 scripts/raven/tools/prepare_vn_promotion.py --review /path/to/review.json --approval /path/to/approval.json --output /path/to/new/output-folder
```

`--check-only` не пишет файлы. При успешной подготовке новая папка содержит *четыре JSON-кандидата* с существующими именами production-реестров и `promotion_manifest.json` со списком исходных SHA, SHA каждого output, ID новых сцен/реплик, ссылками на ревью и `runtimeApplied:false` / `readyForRuntime:false` / `cannotAutoApply:true`. Папка должна быть новой, замена/слияние существующей запрещены. Производственные JSON в репозитории не меняются.

## Fail-closed правила

1. Проверяется исходная версия и SHA всех 4 исходных каталогов + SHA cues и **точных байтов review JSON**. Устаревший экспорт отклоняется; автоматического rebase нет.
2. Сравниваются оригинальные scenes и metadata/identity всех старых lines, строки допускаются к изменению только при включении ID в `approvedTextLineIds`. Каждой новой сцене нужен mapping в свободный `RM-BEAT-XX-YY`; каждой новой реплике — корректный `RM-BEAT-XX-YY-LNNN`, без коллизий, с зарегистрированным speaker и RU-текстом.
3. Для каждой новой сцены нужно ровно по одному shot и trigger; для каждой новой реплики — ровно одному cue (включая добавленную в существующую сцену). Shot должен иметь существующий background master и допустимые `lightingVariants`, `stateLayers`, actor/pose/emotion/slot. Cue — зарегистрированную позу/эмоцию и микроанимацию.
4. Gate для новой сцены пока разрешён **только** `scene_complete` с `ref` на уже существующую production-сцену; `approvedRuntime:false`, `proposedRuntime:true`, уникальный ordinal. Не включаются новые `auto_new_game`, `first_clear` и кастомные условия без дополнительного контракта.
5. Если в review или сохранённом черновике существуют Story Map edges (choice, Match-3 или обычный transition), подготовка **блокируется**, даже с текстовой отметкой approval: полноценного runtime sink для них пока нет.
6. Политика сейвов должна быть явно проверена: `existingSaves:preserve`, `newScenesDefault:locked`, собственный `reviewRef`. Это документальный gate, **не** доказательство правильной миграции: прежде чем выпускать, нужна отдельная E2E проверка.
7. Неправильные/дублирующиеся ID, отсутствующие реплики и cues, существующие выходные файлы, неверные hash и несогласованные счетчики должны приводить к `BLOCKED` и коду выхода 2 без изменений источников.

**Важно:** `approvalRef` не проверяется криптографически и не заменяет GitHub review/подпись/решение пользователя. Скрипт создаёт **пакет для отдельного PR**, не выполняет публикацию и не активирует флаги playable runtime. Нельзя просто копировать выходные JSON в `data/raven/production` без проверки scene routing, save migration, localization, полной CI parity и ручного ревью. Данные в тестах синтетические, не одобрение нового сюжета.

## Тесты / дальнейшая приёмка

`tests/raven/test_vns5_promotion_staging.py` включён в `scripts/check.sh`: положительный сценарий синтетического approved пакета, проверка неизменности канонических файлов, отказ при устаревших SHA, неточных ID, текстовых правках вне review, отсутствии shot/route/cue, неизвестном BG/pose, неразрешённых edges, неподтверждённой политике сейвов и no-overwrite.

**Следующая работа:** интеграция утверждённых кандидатных файлов через отдельный PR с обзором точного diff и rollback; E2E старых сейвов, path/condition consistency, localizations RU/BE/EN, runtime scene gating и micro-FX. Это отдельная задача **VNS5-06D phase 2**, не выполненная этим PR. Поскольку нет фактически утверждённого пользователем нового сценного контента, никаких реальных игровых сцен этот PR не переносит.
