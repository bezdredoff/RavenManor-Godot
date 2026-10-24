# RM-VS-01 — gap analysis

## Проверенный текущий статус

Ни один шаг `RM-VS-01` не подтверждён end-to-end в Raven runtime. Отдельные UPDS и spike-компоненты работают, но используют другие данные и не связаны общей Raven session.

| Шаг | Статус | Evidence / первый blocker |
|---|---|---|
| 1. Evelyn arrives | PLACEHOLDER | Stage 1/2 narrative docs; нет Raven scene catalog/runtime. |
| 2. Hall and corridor exploration | MISSING | Approved graph есть, runtime Hall/Corridor отсутствует. Это первый blocker. |
| 3. Meet Ada before reveal | PLACEHOLDER | Narrative contract есть; нет Raven VN data/assets integration. |
| 4. Inspect bedroom entrance | MISSING | `RM-HS-002` описан в CSV, runtime hotspot отсутствует. Product correction: ранняя отдельная задача открывает физический доступ до реставрации ванной. |
| 5. Level 1 and +2 points | PARTIAL | Match-3 работает; Raven reward/catalog/transaction не подключены. |
| 6. Prepare bedroom | PLACEHOLDER | Economy/restoration описаны; state swap существует только в unrelated hub spike. |
| 7. Levels 2–3 | PARTIAL | Engine поддерживает последовательные уровни; Raven IDs/data не реализованы. |
| 8. Bathroom specialist repair | PLACEHOLDER | Contract есть, specialist availability/runtime нет. |
| 9. Bathroom visual change | MISSING | Нет layered bathroom scene/state resources. |
| 10. Childhood clue | PLACEHOLDER | `RM-HS-004` описан; journal integration не реализована. |
| 11. Bedroom door traversable | MISSING | Нет door component/state/link/persistence. Этот шаг переносится до `RM-REST-001`: вход в спальню предшествует её подготовке и не зависит от ванной. |
| 12. Enter bedroom and first-night beat | MISSING | Нет physical scene, crossing event или Raven beat registry. |
| 13. Save/exit/resume | PARTIAL | UPDS save работает, Raven snapshot/schema и интеграция отсутствуют. |

Фактически в полном сценарии подтверждено: **0 из 13 шагов**. Компонентно подтверждены Match-3, VN renderer и generic storage, но это не считается прохождением шага.

## Минимально необходимый implementation slice

1. Raven ID registries: levels, rooms, doors, hotspots, restorations, beats и aliases.
2. Raven snapshot/schema с wallet, first clears, restoration flags, clue, door state, last safe anchor и applied event IDs.
3. Atomic command/reducer layer для `level_won`, `restoration_apply`, `clue_record`, `door_unlock`, `beat_seen`.
4. Greybox Hall + residential Corridor + bedroom threshold; Bathroom допускается focus insert для первого интеграционного теста.
5. Navigation backend с collision geometry и debug overlay.
6. `HubDoorPortal` для `RM-DOOR-CORRIDOR-BEDROOM` с near/far anchors и interruption recovery.
7. Five task hotspots `RM-HS-001..005`, отдельно от navigation affordances.
8. Three Raven Match-3 data entries с наградой first-clear 2/2/2.
9. Two restoration visual states и расходы 2/4.
10. Minimal Ada/Evelyn VN beats до и после restoration.
11. Automated end-to-end smoke, который дважды прогоняет reward callback и reload boundary.

## Product correction RM-HUB-001

Старая зависимость bedroom door от `RM-REST-002` и `RM-HS-004` отменена. Доступ к спальне открывает отдельная ранняя задача, после чего Эвелин входит и только затем выполняет `RM-LVL-001 → RM-REST-001`. Ванная остаётся corridor-side vignette и не блокирует bedroom traversal. Стабильные существующие `RM-*` IDs сохранены; введён и документирован флаг `RM-FLAG-BEDROOM-ACCESS-CLEARED`.

## Не включать в минимальный slice

- все шесть глав;
- production art;
- свободное RPG movement;
- полную Bathroom walk-in scene;
- настоящую систему расписания специалистов;
- восточное крыло/верхние этажи;
- публичный addon API до принятия architecture spike.
