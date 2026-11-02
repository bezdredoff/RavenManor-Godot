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
