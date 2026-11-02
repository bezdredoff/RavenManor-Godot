# VNS5-06D2B · Locked release staging (пакет для отдельного PR, НЕ запуск)

**Baseline:** `main@7f4b079046197ec8bac700e5db3d924342d68b2a`, PR #118 смёржен. **Статус:** отдельный кодовый PR без утверждённых новых игровых сцен, без реального runtime apply.

## Зачем нужен D2B

До этого:
- Godot VN Studio экспортирует `raven-vn-production-4registry-review-v1` (D1);
- `prepare_vn_promotion.py` делает **независимую** проверку и извлекает четыре review-регистра (D1-CLI);
- `plan_vn_release.py` проверяет целостность, сюжетные ID, save/reducer и создаёт `release_readiness_report.json` и исходные файлы `rollback/` (D2A).

Но реальные изменения ещё нельзя направить в PR без явного согласования ID, proposed gates, блокеров и списка затронутых исходников. Особенно важно: `RavenSnapshot.normalize` и `RavenReducer.apply` сверяют `storyBeatsSeen` с `data/raven/foundation_catalog.json`, тогда как VN Studio раньше формировал лишь четыре сюжетных реестра. D2B создаёт **пятую кандидатную копию** `foundation_catalog.json`, куда исключительно **в конец `storyBeats`** добавлены новые scene IDs.

Сборка происходит только после внесения независимых записей о ревью — и всё равно остаётся **locked**: `runtimeApplied:false`, `readyForRuntime:false`, `canMergeToProduction:false`. Настоящих утверждений, настоящих картинок или пользовательских сохранений в этой задаче нет.

## Единая цепочка

```bash
# 1. Из Godot VN Studio: 3 · Экспорт 4 каталогов (review only)
# 2. D1-CLI:
python3 scripts/raven/tools/prepare_vn_promotion.py \
  --package /tmp/godot-review.json --output /tmp/d1-extracted

# 3. D2A — backup и отчёт о фактически нерешённых условиях релиза:
python3 scripts/raven/tools/plan_vn_release.py \
  --package /tmp/godot-review.json --staging /tmp/d1-extracted \
  --output /tmp/d2a-audit

# 4. D2B — проверка точной привязки решения ревьюера (no writes):
python3 scripts/raven/tools/stage_vn_release_patch.py \
  --package /tmp/godot-review.json --staging /tmp/d1-extracted \
  --audit /tmp/d2a-audit --decision /tmp/review-decision.json --check-only

# 5. D2B — новый внешний каталог, не в res:// / Git:
python3 scripts/raven/tools/stage_vn_release_patch.py \
  --package /tmp/godot-review.json --staging /tmp/d1-extracted \
  --audit /tmp/d2a-audit --decision /tmp/review-decision.json \
  --output /tmp/new-locked-patch
```

В обеих командах D2B заново выполняются верификации D1 и D2A; D2A `release_readiness_report.json` сравнивается **полностью**, после чего проверяется точный SHA его байтов, а также SHA байтов самого Godot-пакета и каждой исходной копии `rollback/`. D2B не умеет `--apply`, не вызывает GitHub и не восстанавливает сейвы.

## Контракт review-decision.json

Это **не второй манифест для Godot**: он не описывает картинки, позы, реплики или реальные активные маршруты. Это только независимое, привязанное к уже собранному bundle, **подтверждение того, какие предложения и блокеры видели ревьюеры**. Пример ключей (значения `SHA...` и ID должны быть заполнены строго по исходным D1/D2A файлам):

```json
{
  "format": "raven-vn-release-stage-decision-v1",
  "schemaVersion": 1,
  "releaseMode": "REVIEW_ONLY_NO_RUNTIME",
  "packageSha256": "SHA256_ТОЧНЫХ_БАЙТОВ_GODOT_JSON",
  "auditReportSha256": "SHA256_ТОЧНЫХ_БАЙТОВ_D2A_ОТЧЁТА",
  "reviewRef": "RM-OWNER-REVIEW-ISSUE",
  "storyReviewRef": "STORY-REVIEW-ISSUE",
  "artReviewRef": "ART-REVIEW-ISSUE",
  "localizationReviewRef": "LOC-REVIEW-ISSUE",
  "saveReviewRef": "SAVE-REVIEW-ISSUE",
  "acceptedSceneIds": ["RM-BEAT-07-01"],
  "acceptedLineIds": ["RM-BEAT-07-01-L001"],
  "acceptedRouteProposals": {
    "RM-BEAT-07-01": {
      "kind": "scene_complete",
      "ref": "RM-BEAT-00-01",
      "interactionTarget": "REVIEW-ONLY-EXAMPLE"
    }
  },
  "unresolvedBlockers": ["ВСЕ СТРОКИ ИЗ D2A blockers, БЕЗ ИЗМЕНЕНИЙ"],
  "enableRuntime": false,
  "applyToRepo": false
}
```

Значения выше **не утверждены** и приведены только как объяснение. Ссылки `storyReviewRef` и аналогичные — traceability, **не криптографическая подпись** и не подтверждение разрешения игрокам видеть сцену. `acceptedSceneIds`, `acceptedLineIds`, `acceptedRouteProposals` должны **в точности** совпадать с D1. `unresolvedBlockers` должна быть точной копией массива из D2A: удаление одного блокера запрещает сборку. Любое `enableRuntime:true`, `applyToRepo:true` или новая схема документа запрещены.

## Структура внешнего результата

```text
new-locked-patch/
  locked_release_patch_manifest.json     # SHAs источников, кандидатов и решения, unresolved blockers
  candidate/
    season1_dialogue_catalog.json
    vn_staging.json
    map_narrative_routes.json
    line_performance_cues.json
    foundation_catalog.json              # добавлены только новые storyBeats
  rollback/
    season1_dialogue_catalog.json
    vn_staging.json
    map_narrative_routes.json
    line_performance_cues.json
    character_performance.json
    foundation_catalog.json
    save_contract.json
```

Все файлы находятся **вне репозитория**. Выходной каталог должен отсутствовать; повторная запись, вложение в исходный каталог D1/D2A, симлинки исходных данных и вывод в checkout запрещены. Резервные файлы содержат **точные байты** исходного канона (без нормализации/переформатирования). Схема Raven save `1` и оба save key остаются прежними. Никакие активные маршруты не генерируются: `draft_unapproved`/ `approvedRuntime:false` сохраняются, никаких новых ветвлений/Match-3 в runtime не происходит.

## Проверки и следующий этап

`tests/raven/test_vns5_locked_release_patch.py` в `scripts/check.sh` проводит синтетический (не утверждённый) положительный no-apply экспорт и отрицательные проверки: испорченные SHA пакета/отчёта/backup, отсутствие файлов rollback, незнакомые ID или изменённые proposed gate, отсутствие подтверждения всех блокеров, попытки активации/overwrite, запись внутри checkout, целостность всех семи исходных файлов. Работают также старые тесты Godot save schema/Reducer, D1 и D2A.

**Остаётся для D2C:** отдельная реализация real, opt-in, owner-approved runtime patch с VN presenter, match-3/story transitions, актуальной `foundation_catalog`, проверкой реальных локализаций/арта, старых и новых сейвов, внешними rollback-тестами и контрольным PR. Пока нет реально утверждённых сцен, этот PR сознательно не активирует их.
