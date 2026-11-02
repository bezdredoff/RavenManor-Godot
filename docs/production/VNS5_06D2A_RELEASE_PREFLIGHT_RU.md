# VNS5-06D2A — проверка готовности релиза, сохранений и плана отката

**Baseline:** `main@8830e018f5332872c16e9a1867cb63792ee188f1` (PR #116 merged). **Этап:** preflight/rollback rehearsal, **НЕ** выпуск и **НЕ** автоматический apply.

## Почему эту проверку нельзя пропускать

VNS5-06D1 позволил собрать полный review-only пакет (диалоги, постановка, маршруты и cues), а D1-CLI #116 — проверить и выгрузить его в отдельную папку. Однако этого **недостаточно для игрового runtime**: `raven_snapshot.gd` нормализует `storyBeatsSeen` по `data/raven/foundation_catalog.json → storyBeats`. Новый `RM-BEAT-XX-YY`, не зарегистрированный там, будет выкинут из старого или нового сейва при загрузке. `raven_reducer.gd` отвергает `story_beat_seen` для неизвестного ID. Кроме этого, `raven_slice_director.gd` пока явно проводит только утверждённую последовательность старых сцен. Кандидатный route `draft_unapproved` не запускает VN.

**Цель D2A:** дать однозначный список всех блокеров до реального релиза, проверить точные исходные SHA, зафиксировать source backups для отката и доказать поведение старых сейвов настоящим Godot smoke. Он не пытается обходить эти блокеры и не присваивает контенту несуществующие одобрения.

## Как использовать

Сначала выгрузить из Godot **3 · Экспорт 4 каталогов (review only)**, затем выполнить независимый D1 offline check:

```bash
python3 scripts/raven/tools/prepare_vn_promotion.py \
  --package /path/to/godot-review.json \
  --output /tmp/first-empty-review-dir
```

После этого D2A:

```bash
# Только диагностика; не пишет никаких файлов
python3 scripts/raven/tools/plan_vn_release.py \
  --package /path/to/godot-review.json \
  --staging /tmp/first-empty-review-dir --check-only

# Отчёт и оригинальные файлы для ручного rollback; обязательна новая внешняя папка
python3 scripts/raven/tools/plan_vn_release.py \
  --package /path/to/godot-review.json \
  --staging /tmp/first-empty-review-dir \
  --output /tmp/new-release-audit

# Строгая проверка именно готовности к запуску; пока все новые сцены заблокированы
python3 scripts/raven/tools/plan_vn_release.py \
  --package /path/to/godot-review.json \
  --staging /tmp/first-empty-review-dir --require-ready --check-only
```

Последняя команда завершится ненулевым кодом, пока не решены игровые блокеры (в этом PR **нет** пути автоматического разблокирования). Первый/второй варианты могут завершиться с кодом 0, если *целостность данных проверена*; это означает только успешную **диагностику**, а не готовность релиза.

## Что именно проверяется

- Точный SHA **байтов** Godot JSON должен совпадать с `offline_integrity_manifest.json`. Пять исходных registry SHA (dialogue, routes, staging, cues, cast) должны соответствовать текущему checkout, все четыре extracted files должны совпадать с заново независимо рассчитанными байтами. Подмены, лишние файлы и symlink-файлы отклоняются.
- New scene IDs ищутся в `foundation_catalog.storyBeats`. Отсутствие ID — серьёзный блокер: при нормализации save этот сюжетный бит будет потерян. Проверяются ссылки `scene_complete` и `first_clear`, неизвестные level refs и циклы зависимостей.
- Для каждой новой сцены перечисляется отсутствие runtime-presenter/interaction, утверждённого активного gate, art provenance, BE/EN title; для каждой новой реплики — BE/EN text и ручная приёмка cue. Нужны проверки Match-3/branch reducer, VN paging, сейвов и обратной совместимости.
- Существующие долги локализации BE/EN фиксируются отдельно как предупреждение; это не оправдывает выпуск непереведённых **новых** реплик.
- Проверяется `save_contract.json` (raven save schema 1, отдельный ключ) и неизменность реальных файлов. В выводе `saveCompatibility` видны ожидаемые потери при rollback.

## Артефакт

В *новой внешней папке*, никогда внутри репозитория, появляются:

- `release_readiness_report.json`: `status: NOT_RELEASE_READY`, перечень `blockers`, `warnings`, `diffSummary`, `saveCompatibility`, пять source SHA + дополнительные SHA для foundation/save contract, SHA исходного пакета/манифеста/кандидатов.
- `rollback/` с **точными исходными байтами** пяти production registry JSON, `foundation_catalog.json` и `save_contract.json`. Файлы никогда не применяются автоматически, это immutable backup только для ручного review/rollback PR.

Успешное создание отчёта **не включает** новые сцены, не заменяет файлы проекта, не изменяет игровые сейвы и не запускает автоматический откат.

## Тесты

`tests/raven/test_vns5_release_readiness.py` проверяет полный synthetic happy-path диагностики, реальный откатный архив, повторный экспорт, отказ при изменённом extracted JSON/манифесте/поддельном SHA/symlink/лишнем файле, ошибки graph/level dependency. `tests/raven/vn_release_save_rehearsal_smoke.gd` запускается в Godot и проверяет нормализацию и сохранение legacy snapshot schema 1, rejected unknown beat, разрешённый event и идемпотентность на **временной копии расширенного каталога**, а также регрессию отката к старому каталогу. Никаких новых ID он не дописывает в канон.

Оба теста добавлены в `scripts/check.sh`, рядом с D1-CLI тестами. Нужна зелёная CI финального PR-head, затем ручное ревью/приёмка владельцем. **Следующий VNS5-06D2B**: реальный opt-in атомарный production import только после утверждённого контента, gate и source diff, согласованного snapshot/reducer и отката с сохранением user data.

## CI и состояние PR

Implementation head `e772c8b6c6fe99e4fed2a8a9c6311e5b1d79c676` прошёл полный CI [#41477532318](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41477532318), включая новую Godot-проверку old-save и Python-проверки целостности/backup. После добавления этого свидетельства нужен повторный финальный CI. PR #118 остаётся Draft/PR_review; реальная публикация сцен и ручная owner QA не выполнены.
