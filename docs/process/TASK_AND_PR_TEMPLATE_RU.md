# Raven Manor — формат задания / PR / handoff

Рекомендованное имя ветки: `code/<task-id>-short-topic`, `gfx/<task-id>-short-topic`, `process/<task-id>-short-topic`. Если ветка уже открыта — продолжать её, не создавая дубликат.

## Task proposal

```markdown
### Task CODE-XX-YY — <кратко>
**Источник / baseline:** repo main SHA, open PR refs, документ/сцены.
**Goal:** измеримое поведение пользователя.
**Why UPDS:** paths + blob SHA; vendor/extract/adapter/new; причина.
**Scope:** paths, RM-IDs, locales, gameplay, art.
**Dependencies:** Cx/GFX-y and existing task IDs.
**Implementation steps:** минимальные этапы без расширения scope.
**Acceptance:** функционально, регрессии, визуальные/mobile, save, replay.
**Tests:** exact commands and expected evidence.
**Risks & rollback:** обратная совместимость/приватность/preview.
**Progress update:** unique docs/changes evidence + current task status in the owning progress/<domain>.json; verified merged status updated by that agent after merge.
```

**PROC-006:** каждый authored PR включает уникальный `docs/changes/<TASK-ID>-<topic>.md` с полями `Task IDs:`, `Changes:`, `Verification:`, `Owner QA:`, `Status impact:`. Альтернатива — оба старых canonical status файла. Owning domain agent updates only the corresponding shard after verified merge, не заставляя параллельных агентов конкурировать. Numeric incoming candidates по-прежнему проходят отдельный security review.

## PR description (заполняется автоматически/вручную)

```markdown
## Task IDs / reason
## Baseline, source authority & UPDS reuse (path + SHA)
## Changes: files, stable RM-* IDs, gameplay/visual behavior
## What deliberately remains unchanged
## Data/save schema, migrations and rollback
## Code/GFX gates; candidate vs accepted assets and permits
## Verification run (commands, actual outcome, CI run/head SHA)
## Human/device QA required (viewport, platform, screenshots)
## Per-PR evidence, post-merge canonical status owner
## Open risks, follow-up task ID(s)
```

**Нельзя:** generic `fixed bugs`, утверждать `tests pass` без фактического лога, считать план выполненным от merged документа, мерджить автоматически.

## Мобильный ZIP handoff

В архиве `patch-manifest.json` должен называть реальные task IDs; PR после импорта сохраняет их и текущий baseline. Evidence note включается в архив; canonical status после review/merge обновляет integration owner. Большие файлы идут только с источником/rights и `accepted` art approvals. Если ZIP превышает безопасные лимиты, делить на независимые reviewable пакеты по 3–4 related images или use Git LFS/proper artifact store **после отдельного технического решения**, без обхода валидатора.

## PROC-007 Stage 3b — независимый статус в PR

Для веток `agent/<domain>/<task-id>-...` агент обновляет `data/raven/production/progress/<domain>.json` и свой уникальный `docs/changes` evidence. Ни `production_progress.json`, ни `active_workstreams.json`, ни `p2_reentry_policy.json`, ни `dashboard/status.json` не являются источником для ручной синхронизации. После настоящего merge агент дополнительно фиксирует `merged` в **том же shard**, не заранее. Для P0/P1 задача получает `assignments.workstreamId`, для P2 — `assignments.p2ReentryGroup`. Готовность устройства/owner accepted остаётся отдельным актом.
