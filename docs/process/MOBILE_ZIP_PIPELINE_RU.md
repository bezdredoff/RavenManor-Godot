# Raven Manor — загрузка больших патчей в GitHub с телефона

**Status (27.10.2026):** MOB-00 и код MOB-01/02 смержены (#48, #49); ветка `incoming` создана и реальный безвредный ZIP успешно проверен. GitHub Actions создал `candidate/mobile-40538610191`, но **автоматическое открытие PR блокируется настройкой GitHub**. Ручной тестовый PR #50 с полностью успешным Godot/Room Builder/Web CI закрыт без мержа. `/preview/` в следующем PR — безопасный портал ревью с Web artifacts, **не playable candidate на общем origin**. Физическую загрузку с телефона ещё не проверяли. В UPDS похожий workflow уже реализован, но его npm-проверки и зависимости нельзя применять к Godot как есть.

## Когда использовать

- ChatGPT/DeepSeek не может отправить десятки файлов или большой binary patch через connector; авторизация GitHub недоступна; сгенерированы 3–4 связанных арт-ассета/ZIP для Room Builder/Godot.
- Для небольшой текстовой правки сохраняется прямой PR без загрузки ZIP.
- На телефоне: архив сохраняется в «Файлы» → GitHub web → ветка `incoming` → `incoming/<RM-task>_R<revision>.zip` → commit **только в incoming**, не в main. Использовать GitHub Pages `/preview/` только после настоящего ввода в эксплуатацию pipeline.

## Формат предпочтительного изменения (дельта)

```text
RM-CODE-02_R1.zip
├── patch-manifest.json
└── files/
    ├── scripts/...
    ├── docs/STATUS.md
    └── data/raven/production/production_progress.json
```

`patch-manifest.json`:
```json
{
  "format": "raven-delta-v1",
  "baseSha": "<40-hex SHA of RavenManor-Godot main at packaging>",
  "feature": "RM-CODE-02_R1",
  "taskIds": ["CODE-02-01"],
  "files": ["scripts/raven/...", "data/raven/production/production_progress.json"],
  "delete": []
}
```

Archive paths are relative POSIX paths with **no** absolute / ../ / symlinks. Runtime applies only if `baseSha` equals current main. For stale main, **fail closed** (a later `raven-delta-v2` may safely rebase after implementing path-conflict tests from UPDS); never overwrite newer paths. `files[]` plus `delete[]` declare exact content; undeclared payloads fail. All changes to task/status/docs should accompany code in the same ZIP.

## Security contract (mandatory before automation)

1. Max **25 MiB compressed** per ZIP (GitHub browser-friendly); max **250 MiB uncompressed**, max 1500 entries, reject duplicate normalized/case-fold paths, traversal, absolute/backslashes, symlinks, encrypted files, ZIP bombs, nested .git and code outputs.
2. Reject the protected paths: `.github/`, `AGENTS.md`, `CODEX.md`, `DEEPSEEK.md`, `CHATGPT.md`, `scripts/raven/tools/validate_mobile_patch.py`, ZIP-import automation itself, `docs/DECISIONS.md`, credentials, generated binaries, Never allow archive to change workflows/tests that validate it.
3. `production_progress.json` may be included in a candidate, but its claims of `accepted`, device QA or a merged PR are **not trusted automatically**. Every progress change requires normal human review and CI; import does not grant approval. Validate and apply on an isolated checkout with only `contents: read`; **no secrets, write-token or release credentials** present when inspecting or executing candidate code.
4. After validation of ZIP paths, **a distinct write-capable job** may create `candidate/*` branch + PR from exact validated main SHA. No untrusted process executed in write job. Actual Godot/tests run as separate low-privilege PR CI.
5. Candidate is **not** deployed directly to stable root; once isolated preview deployment is implemented, stable `/` is main, `/preview/` is one temporary candidate, separately cached and never intercepted by stable Service Worker.
6. Required: manual code review, GitHub Actions quality gate, relevant portrait device QA, provenance/license check, manual merge and rollback path. No auto-approve/auto-merge.
7. Public repo `incoming` archives are **public and remain recoverable in git history** without intentional cleanup. Never upload private bible/spoilers not approved for publication, personal data, keys, licensed models, purchased assets. On failure, invalidate/delete inbox tree, and rotate any leaked secret outside this pipeline (commits do not magically erase history).
8. Proposed `incoming` branch must be created from `main` only during pipeline bootstrap; no direct branch overwrite from phone. Subsequent changed ZIPs must be distinguishable; do not assume GitHub can upload >25 MiB.


## Как упаковать патч уже сейчас (рабочий ручной fallback)

Агент, имеющий доступ к файлам проекта, может собрать только нужные файлы из одной task branch. **Требуется точный 40-символьный SHA `main`**, а не текущий head старой feature branch.

```bash
python3 scripts/raven/tools/package_mobile_patch.py \
  --base <40-hex-raven-main-SHA> \
  --feature CODE-02_R1 --task CODE-02-01 \
  --file scripts/raven/example.gd \
  --file docs/STATUS.md \
  --file data/raven/production/production_progress.json \
  --output /tmp/RM-CODE-02_R1.zip

python3 scripts/raven/tools/validate_mobile_patch.py \
  /tmp/RM-CODE-02_R1.zip <40-hex-raven-main-SHA>
```

Этот упаковщик сохранит точный список файлов и перепроверит итоговый ZIP. Отдельные большие артефакты лучше делить на небольшие партии по независимым задачам.

**Пока MOB-01 ещё не активирован:** передать ZIP с телефона в `incoming/` отдельной upload branch и дать ссылку Codex/ассистенту с доступом к Git. Агент скачивает этот конкретный ZIP, проверяет его **валидатором из доверенного `main`**, в чистой копии main применяет файлы/удаления, запускает полные тесты Godot, создаёт отдельный PR вручную. В текущем состоянии `/preview/` **не гарантирован**: URL будет доступен лишь после MOB-03. Нельзя исполнять скрипты из ZIP с write-token; нельзя переносить ZIP напрямую в `main`.


## Checklist для первого настоящего мобильного ZIP (после мержа workflow)

1. Убедиться, что в `main` есть `.github/workflows/import-mobile-zip.yml` и новый защищённый `pages.yml`; тогда создать ветку `incoming` **от актуального `main`**. Не создавать её заранее на ветке без импортирующего workflow: push-триггер зависит от наличия YAML на ветке.
2. Проверить в GitHub Settings → Actions → General, что настройка **Allow GitHub Actions to create and approve pull requests** допускает создание PR через `GITHUB_TOKEN`. При блокировке — не обходить права PAT с расширенными разрешениями; изменить политику явно или оставить ручное создание candidate PR.
3. Создать harmless ZIP с `patch-manifest.json`, `taskIds: ["MOB-04"]`, `baseSha` точного текущего `main`, одним неисполняемым файлом `docs/evidence/mobile_zip_smoke.txt`; не включать секретов или ещё не одобренных assets.
4. Загрузить ZIP в `incoming/<feature>_R1.zip` с телефона на ветку `incoming`. Оставить на ветке **ровно один** ZIP. Проверить, что import workflow создал candidate PR, и что содержимое PR соответствует manifest и исходному архиву.
5. Проверить **две независимые CI стадии**: импортирование безопасных данных без запуска candidate-кода с write-token и отдельный Godot/Room Builder/Web workflow с правами только `contents: read`. Проверить текущее значение SHA в PR и успешный workflow run.
6. Атакующие кейсы: stale base, запрещённый `.github/`, symlink, ZIP-slip, duplicate casefold, >25 MiB, неправильный manifest; каждый должен завершиться без candidate PR. Провести тесты с телефона и записать evidence в progress JSON.
7. Пока нет MOB-03, `/preview/` не используется: `workflow_dispatch` на candidate **проверяет**, но не публикует. Merge в `main` только после человеческого review и device QA.

**Ограничение автоматизации:** PR с этим кодом доказывает успешную сборку/модульные тесты, но **не может удостоверить фактическое создание candidate PR через Actions до установки этого workflow в default branch и настройки разрешений**. Этот acceptance gate остаётся явно открытым.

## Current implementation stages

- **MOB-00**: смержен в PR #48 — упаковщик, security validator и тесты `raven-delta-v1`.
- **MOB-01**: в отдельной feature-ветке реализованы два доверительных домена: read-only проверка ZIP на `incoming` и отдельное создание `candidate/*` PR по точному `main SHA` (проверяется повторно перед записью). **Ещё необходимо смержить workflow, создать `incoming` от нового `main`, подтвердить право GitHub Actions создавать PR и выполнить живой тест**.
- **MOB-02**: feature-ветка запускает штатный `pages.yml` на candidate через `workflow_dispatch`, ожидает реальный результат Godot/Builder/Web проверок и завершает импорт с ошибкой при failed CI. Build job имеет только `contents: read`; `pages: write` и OIDC доступны исключительно deploy job для `main`. **Подтверждение на реальном candidate PR остаётся после мержа и bootstrap**.
- **MOB-03**: safe GitHub Pages `/preview/` packaging with stable main root and separate SW/cache scope; preview auto-expiry/rollback.
- **MOB-04**: end-to-end phone upload, invalid ZIP attacks, stale SHA, PR creation, iPhone/Android viewport test, manual merge → stable deploy proof.

Отсутствие MOB-01–04 не означает, что ChatGPT не может подготовить готовый ZIP для ручной загрузки в будущий pipeline. Отдельный PR потребуется для security-reviewed GitHub Actions. Можно воспользоваться direct connector PR небольших файлов до активации importer. **Статус MOB-01–04 должен быть явно отображён в production dashboard, без ложных «готово».**


## Фактический тест и необходимые действия владельца (2026-10-27)

- Реальная загрузка ZIP с валидным manifest: [Actions run 40538610191](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/40538610191). Read-only ZIP validation: **success**. Отдельная candidate branch `candidate/mobile-40538610191`: **создана**.
- `gh pr create` в write-job вернул GitHub GraphQL: **GitHub Actions is not permitted to create or approve pull requests**. Невозможно активировать это из PR; потребуется действие владельца: GitHub → RavenManor-Godot → **Settings → Actions → General → Workflow permissions** → **Allow GitHub Actions to create and approve pull requests**. Включать автоматическое одобрение PR не требуется; только разрешение создавать PR. Если политика запрещает — оставить создание PR вручную с ограниченным connector access.
- Тестовый [PR #50](https://github.com/bezdredoff/RavenManor-Godot/pull/50) создан отдельно из той же candidate branch, полный Godot/Room Builder/Web CI прошёл. PR **закрыт без мержа**; тестовый файл не попал в `main`.
- Следующий импорт по `incoming` после PR с исправлением будет создавать candidate branch и **продолжать независимые проверки, даже если настройка PR creation выключена**. Workflow выдаст ссылку на ручной PR и завершится с явным warning/error, если PR не создан. Не помечать полный pipeline принятым до успешного прогона с включённой настройкой.
- MOB-04 остаётся незакрытым: синтетический реальный Git push ZIP не является физической загрузкой с iPhone/Android.

## Почему не публикуем candidate игру прямо в /preview/

GitHub Pages `https://bezdredoff.github.io/RavenManor-Godot/` и `/preview/` имеют **одинаковый origin**. JavaScript, который находится в `/preview/`, потенциально может воздействовать на storage, cache, service worker и данные стабильной игры; путь URL не создаёт origin isolation. Запуск непроверенного кандидата в одной области безопасности с `main` не удовлетворяет требованиям production handoff.

Поэтому безопасная стадия MOB-03 публикует в `/preview/` **только доверенную страницу списка CI-сборок**, а candidate Web export загружает в GitHub Actions как отдельный артефакт `raven-candidate-web-<run_id>` на **7 дней**, с `contents:read` и без Pages deploy. Пользователь видит состояние проверок и получает архив со сборкой, который может разместить на изолированном домене.

Для **играбельного preview по ссылке** надо заранее создать **отдельный Pages-репозиторий или иной хостинг с отдельным origin**, отдельной политикой доступа и cache/SW. Пока такого репозитория нет, публичный `/preview/` **не является играбельной candidate версией**. Не отправлять туда произвольные файлы ZIP через workflow с правами Pages deployment.

### Чеклист приёмки следующей партии

1. Owner проверяет Settings → Actions → General для PR creation, без расширенных PAT.
2. Мержит отдельный PR для trusted portal и fallback CI; проверяет доступность `/preview/`.
3. Повторяет загрузку безопасного ZIP и проверяет **автоматически** открытый candidate PR и отдельные CI Web-артефакты.
4. Проверяет upload с телефона, защищённые пути/старая база, артефакт, отказ ошибочного ZIP и отсутствие влияния на стабильный root.
5. Для playable preview принимает отдельный origin/хостинг — отдельная задача, не смешивать с безопасным CI.
