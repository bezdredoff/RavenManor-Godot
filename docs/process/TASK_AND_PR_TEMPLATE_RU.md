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
**Progress update:** fields in production_progress.json.
```

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
## Production status and documentation updated in this PR
## Open risks, follow-up task ID(s)
```

**Нельзя:** generic `fixed bugs`, утверждать `tests pass` без фактического лога, считать план выполненным от merged документа, мерджить автоматически.

## Мобильный ZIP handoff

В архиве `patch-manifest.json` должен называть реальные task IDs; PR после импорта сохраняет их и текущий baseline. Данные прогресса/документации входят в сам архив, чтобы не было «код в одной ветке, status в другой». Большие файлы идут только с источником/rights и `accepted` art approvals. Если ZIP превышает безопасные лимиты, делить на независимые reviewable пакеты по 3–4 related images или use Git LFS/proper artifact store **после отдельного технического решения**, без обхода валидатора.
