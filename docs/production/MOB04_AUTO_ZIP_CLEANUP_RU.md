# MOB-04 · Автоматическая очистка incoming ZIP

## Назначение

В `.github/workflows/import-mobile-zip.yml` добавлен завершающий `cleanup_incoming_zip` job. Он зависит от `validate`, `candidate` и `test_candidate`, но выполняется с `always()` даже при провале ZIP preflight, создании candidate PR или независимого CI. ZIP удаляется из `incoming` отдельным коммитом, при этом **candidate PR и его код не мержатся**. Архив остаётся доступен через Git history, а в успешном пути ещё и как Actions artifact (retention: 3 дня).

### Безопасность

- `validate` продолжает работать только с `contents: read`. Только отдельный `cleanup_incoming_zip` получает `contents: write`.
- Cleanup не checkout'ит и не исполняет untrusted `incoming` или ZIP; используется фиксированный `actions/github-script@v7`.
- Разрешено удалять лишь файлы `incoming/[A-Za-z0-9._-]+.zip`, которые присутствовали в **trigger commit SHA**. Для ручного `workflow_dispatch` на ветке `incoming` удаляется только указанная в `archive_path` ZIP.
- Перед очисткой проверяется, что `incoming` всё ещё указывает на SHA запуска. Если пользователь загрузил другой ZIP во время CI, старый job **не удаляет ничего** и оставляет очистку более новому запуску.
- Перед каждым удалением ещё раз сверяются HEAD ветки и SHA blob. Для нескольких ZIP учитываются только коммиты, созданные собственными предыдущими удалениями. При гонке прекращается работа без затрагивания более новых загрузок.
- При `workflow_dispatch` на `main` cleanup не запускается. Обработка архивов и поведение importer не меняются; `main`/production game не редактируются.
- Очистка по push обрабатывает все `*.zip`, присутствовавшие в снимке загрузки, чтобы при ошибке «больше одного ZIP» мусор тоже удалялся. Удаление/пустая папка безопасно пропускаются.
- Отмена workflow вручную или outage GitHub/API не гарантирует выполнение cleanup. При таких исключениях проверить `incoming` и удалить ZIP вручную.

## Активация

1. Смёржить implementation PR в `main`.
2. Синхронизировать **только** `.github/workflows/import-mobile-zip.yml` с `main` в ветку `incoming`, поскольку push на incoming использует YAML именно этой ветки.
3. Удалить предыдущий `RM-VNS5-05A_HANDOFF_R1.zip` из `incoming` — сам по себе новый workflow уже совершённый импорт не переигрывает.
4. Загрузить в `incoming` новое ZIP, убедиться, что `cleanup_incoming_zip` запустился после успеха/ошибки и ZIP исчез из дерева incoming.
5. Негативный тест: невалидный `incoming/MOB04-cleanup-invalid.zip` должен провалить `validate`, но всё равно запустить cleanup и автоматически удалить файл. **Не нужно мержить получившийся candidate PR.**

## Проверки

`node --test tests/raven/incoming_zip_cleanup.test.mjs` запускается внутри `pages.yml` и проверяет правила `always()`, допустимые пути, успешную и ошибочную очистку, выбор при manual dispatch и отсутствие удаления новой загрузки при смене HEAD или SHA blob.

**Границы приёмки:** синтетический CI тест не равен live проверке на GitHub. Статус MOB-04 по остальным device/phone acceptance вопросам не закрывается.

## 2026-11-02 — Исправление после merge PR #107

После merge PR #107 GitHub Actions не смог прочитать workflow: ключ `cleanup_incoming_zip:` оказался на верхнем уровне YAML вместо дочернего элемента `jobs:`. Запуски [main #41405224801](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41405224801) и [incoming #41357836990](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41357836990) завершились сразу, без jobs. Успешный Pages CI не подтверждал синтаксис importer.

Исправление: вложить `cleanup_incoming_zip:` под `jobs:` (два пробела) и добавить независимый тест структуры YAML в `tests/raven/incoming_zip_cleanup.test.mjs`. Исправленный workflow нужно применить в обеих ветках: `main` и `incoming`. Старые failed runs не следует rerun как проверку фикса: они привязаны к старым коммитам. ZIP-папка incoming при аудите была пуста.

**Проверка после применения в обе ветки:**

1. В GitHub Actions убедиться, что importer больше не выдаёт мгновенную ошибку парсинга workflow. Изменение только YAML не обязано запускать importer: его push-триггер фильтрует `incoming/*.zip`.
2. С телефона загрузить тестовый невалидный ZIP `incoming/MOB04-cleanup-negative.zip` в ветку `incoming` (один ZIP за раз), затем открыть последний `Import Raven mobile ZIP candidate` run.
3. Ожидается: `validate` = failed по отсутствующему `patch-manifest.json`, `candidate` и `test_candidate` пропущены, `cleanup_incoming_zip` = success, ZIP исчез из `incoming`. Общий run может иметь статус failure — это нормально для negative test.
4. Positive test провести при следующем **настоящем валидном** delta ZIP с актуальным `baseSha`: `validate` / `candidate` / `test_candidate` и `cleanup_incoming_zip` должны пройти; ZIP исчезнет, а candidate PR появится и останется на ручном review. Не мержить smoke-test PR.
5. При failure `cleanup_incoming_zip` проверить log и разрешения Settings → Actions → General → Workflow permissions; при race warning проверить новую загрузку отдельно. Отмена run и outage API остаются исключениями.

До live positive + negative проверки нельзя отмечать MOB-04 как accepted.
