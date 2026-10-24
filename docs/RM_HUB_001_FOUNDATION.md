# RM-HUB-001 — Raven Foundation

Статус: PR 1 implementation milestone.

## Граница системы

Raven Manor хранит кампанию отдельно от UPDS story и Match-3 saves. `RavenReducer` — единственное место изменения Raven snapshot. Match-3, VN и будущий manor hub передают ему типизированные события и не меняют валюту, двери или реставрации напрямую.

- `data/raven/foundation_catalog.json` — единый источник стабильных ID и условий первого среза.
- `scripts/raven/raven_ids.gd` — проверка ID и legacy door alias.
- `scripts/raven/raven_snapshot.gd` — Raven save schema v1 и безопасная нормализация.
- `scripts/raven/raven_reducer.gd` — идемпотентные переходы состояния.
- `scripts/raven/raven_campaign_store.gd` — отдельный save key и recovery slot поверх существующего атомарного storage adapter.
- `tests/raven/raven_foundation_smoke.gd` — acceptance smoke PR 1.

## Snapshot v1

Snapshot содержит баланс `workPoints`, первые прохождения уровней, завершённые реставрации, открытые двери, состояния hotspots, улики, сюжетные флаги и beats, применённые event IDs, последнюю комнату и безопасный anchor. В нём нет числовых индексов сюжета UPDS.

Первое прохождение `RM-LVL-001..003` выдаёт по 2 очка. Повторный callback с тем же `eventId` либо новым event ID для уже пройденного уровня не выдаёт награду. Повторная покупка реставрации также считается безопасным duplicate без расхода валюты.

## Исправленная прогрессия спальни

Решение владельца продукта в `RM-HUB-001` заменяет старый Stage 2 gate:

1. Отдельная ранняя задача устанавливает новый стабильный флаг `RM-FLAG-BEDROOM-ACCESS-CLEARED`.
2. Открывается физическая дверь `RM-DOOR-CORRIDOR-BEDROOM`.
3. Эвелин входит в спальню.
4. После first clear `RM-LVL-001` внутри доступна `RM-REST-001` за 2 очка.
5. `RM-REST-002` ванной остаётся отдельной последующей реставрацией: нужны `RM-LVL-002`, `RM-LVL-003`, 4 очка и `service.plumber_available`.

`RM-DOOR-HALL-BEDROOM` остаётся только legacy alias. Он разрешается в `RM-DOOR-CORRIDOR-BEDROOM` и никогда не создаётся как вторая физическая дверь.

Новая улика `RM-CLUE-01-CHILDHOOD-OBJECT` введена как стабильный ID для записи результата `RM-HS-004`; визуальный и текстовый контент будет подключён в PR 3.

## События

- `level_won`
- `restoration_purchase`
- `door_unlock`
- `hotspot_state`
- `clue_recorded`
- `story_flag_set`
- `story_beat_seen`
- `position_checkpoint`

Каждое событие требует непустой `eventId`. Успешное изменение записывает ID и увеличивает `revision`. Отклонённая команда не меняет snapshot.

## Проверка

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/raven/raven_foundation_smoke.gd --quit-after 120
```

Полный acceptance gate выполняется через `check.ps1`; он запускает foundation smoke вместе с существующими UPDS проверками.
