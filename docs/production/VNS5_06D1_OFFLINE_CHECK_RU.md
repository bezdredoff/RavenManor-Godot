# VNS5-06D1-CLI — независимая проверка review-пакета из Godot

**Основа:** `main@3d712b423ce39b8cda6f54b67098a8560c3c30ea`, уже содержит PR #117. **PR #116** — дополнительная внешняя проверка, **не** новая схема одобрения, **не** публикация сюжетных данных.

## Входной формат — ровно один

Инструмент `scripts/raven/tools/prepare_vn_promotion.py` принимает уже экспортированный из Raven VN Studio **«3 · Экспорт 4 каталогов (review only)»** JSON формата `raven-vn-production-4registry-review-v1`. Встроенный в Godot workflow создания и импорта манифеста (`raven-vn-production-package-manifest-v1`) остаётся единственным источником предлагаемых постановок/маршрутов/cues. CLI не просит и не принимает второй approval manifest.

```bash
python3 scripts/raven/tools/prepare_vn_promotion.py --package /path/to/godot-review.json --check-only
python3 scripts/raven/tools/prepare_vn_promotion.py --package /path/to/godot-review.json --output /tmp/new-vn-review-dir
```

`--check-only` ничего не пишет. Второй вариант создаёт **только новую** внешнюю директорию (существующая директория приводит к отказу), содержащую четыре выделенных JSON:
`season1_dialogue_catalog.json`, `vn_staging.json`, `map_narrative_routes.json`, `line_performance_cues.json` и `offline_integrity_manifest.json`. Последний содержит SHA точных байтов входного Godot JSON, SHA пяти исходных production-файлов и каждого файла извлечённого кандидата. Никакие файлы `data/raven/production` автоматически не перезаписываются.

## Fail-closed проверки

- Вход — строго **review-only**: `runtimeApplied=false`, `readyForRuntime=false`, `requiresHumanReview=true`, `requiresFollowUpPromotion=true`. Запрещены реальное включение нового scene gate или line cue без `manualReview=true`, а также любые draft Story Map edges с отсутствующей runtime/сейв-логикой.
- Пять исходных SHA (dialogue, staging, routes, cast, cues) должны **в точности совпадать** с текущим checkout. Объекты четырёх candidate files обязаны иметь статус `DRAFT_REVIEW_NOT_RUNTIME`.
- Количество и ID сцен должно совпадать между catalogue, sceneShots, sceneTriggers; количество и ID реплик — между entries и line cues. Старые canonical сцены, маршруты, постановки и cues должны сохраняться побайтово на уровне JSON-значений; старые тексты меняются **только** согласно точным `retainedDraft.textPatches`.
- Новые scene IDs должны следовать записанному `sceneIdMap` и не пересекаться с canonical; новые реплики — `lineIdMap` и исходному `retainedDraft.authoredLines` с теми же speaker/delivery/text. Проверяются допустимые background master/lighting/roomState, зарегистрированный каст, pose/emotion/micro, уникальные слоты, speaker и cue нового line ID. Старый `RM-CHAR-UNKNOWN-VOICE` остаётся корректным **только** в нетронутом canonical контенте.
- У новых маршрутов допускаются только **`draft_unapproved`**, `approvedRuntime=false`, `proposedRuntime=true`, а не playable gate. Поле `reviewRef` — только ссылка на ревью, не электронная подпись и не доказательство approval.
- Выходной каталог **не является publishable**: `offline_integrity_manifest.json` всегда `runtimeApplied:false`, `readyForRuntime:false`, `cannotAutoApply:true`. Даже успешная проверка не разрешает заменить production JSON этими кандидатами. Для runtime требуется отдельный VNS5-06D2 со сценами, реальными условиями запуска, полноценной локализацией, совместимостью сейвов, rollback и QA.

## Тесты и принятие

`tests/raven/test_vns5_promotion_staging.py` включён в `scripts/check.sh` **в дополнение** к Godot smoke из #117. Он создаёт синтетический пакет на основе реальных исходных каталогов, проверяет корректный выделенный экспорт, отсутствие изменения SHA в checkout, отказ при несовпадающих источниках/регистрах/ID, вмешательстве в старые тексты, активных маршрутах, непроверенных cues и неподдерживаемом branching. Это техническая проверка структуры, **не** утверждение игрового контента.

Требуется независимый CI нового HEAD PR #116 и ручное ревью. Без этих проверок PR не считать принятым. См. `docs/production/VNS5_06D1_FOUR_REGISTRY_RU.md` и `docs/production/VNS5_06C_PROMOTION_REVIEW_RU.md`.
