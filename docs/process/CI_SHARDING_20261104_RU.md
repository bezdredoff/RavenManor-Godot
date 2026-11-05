# PROC-006 — независимые CI jobs Raven Manor
Дата: 2026-11-04. Статус: proposed до actual exact-head CI и merge.

## Обязательные jobs
- `data-contracts`: PR evidence/governance + полный прежний non-Godot блок `scripts/check.sh` (отдельно `scripts/check_data.sh`); все production/release/backlog валидаторы по-прежнему blocking, визуальные snapshot-тесты dashboard остаются advisory.
- `godot-runtime`: Godot 4.7.2 headless, Hall scene regeneration и неизменённые Godot parse, VN Studio, Save, VN, Match-3, game-loop, map, gameplay tests. Только продублированные `data` проверки пропускаются через `RAVEN_SKIP_DATA_CHECKS=1`.
- `room-builder`: Node/Python importer, wall tools, art-manifest, source mirrors, browser smoke на Chromium. Не требует Godot.
- `art-pipeline`: art handbook генерация, Python + JS/browser checks, workflow pack.
- `web-package`: после data job экспорт Godot Web + сборка Art Handbook, Room Builder, dashboard, preview portal. PR не загружает Pages artifact.
- `build`: сохранено точное старое имя required check; `needs: [data, runtime, room-builder, art, web-package]`. Успех одного job не означает PASS PR.
- `deploy`: выполняется **только из main** после `build` и `web-package`; использует загруженный Pages artifact. На candidate/mobile workflow_dispatch создаётся только non-deployed `raven-candidate-web-<run>`.

## Сохранённая совместимость
- `bash scripts/check.sh` локально по умолчанию делает всё, что делал раньше: non-Godot плюс Godot проверки. `scripts/check_data.sh` можно отдельно запускать без Godot.
- Отдельный `.github/workflows/import-mobile-zip.yml` не меняется: read-only validation архива, безопасная candidate-ветка, `gh workflow run pages.yml --ref ...`, `gh run watch --exit-status`, ручной merge и ZIP cleanup остаются.
- Все игровые проверки остаются обязательными; импорт сцен Godot, Web export, Browser, Room Builder, Art и dashboard выполняются.
- Реальный incoming ZIP и опубликованный Pages после merge следует подтвердить отдельно. Права и защиту веток автоматически не меняем.

Следующий этап: измерить durations на реальном workflow, только потом дробить большой Godot-runtime job на VN/Match-3/map без отмены обязательного интеграционного game-loop smoke.
