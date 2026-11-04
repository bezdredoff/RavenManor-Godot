# GAME-BOOST-01 — инвентарь бустеров

Статус: implementation candidate; ручная проверка устройства и принятие владельцем ожидаются. Донорский разбор и реализация без новых графических ресурсов.

## Источники и решение о повторном использовании

- Основной донор `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`: `scripts/match3/match3_game.gd` blob `8c62ec550eb500f0c70d431dd325268e59893de4`, экран `scripts/match3/match3_screen.gd` blob `76b42df35d4857f242d3f6bc06b9f989d43ad0a3`. Движок и board presenter повторно используются; донор автоматически перемешивает поле, когда не остаётся ходов. Отдельной механики инвентаря, ручного молотка или расходуемого shuffle в просмотренных Match-3 источниках нет. Решение: `adapter` к существующим Raven rules и save, UI action targeting добавлен в существующий presenter.
- Исторический Raven PWA `bezdredoff/RavenManor@643a8ec5d39812ec4a00294df6378b12d165280c`: `src/boosters/BoosterTypes.ts` blob `96c40e1b7ac77b185f2c31b59e2bda269a98a370`, `src/boosters/BoosterProgression.ts` blob `1c97a0b266310e7b0be6d6d3bac884dea064bb5e`, `src/engine/Match3Engine.ts` blob `8c62ec550eb500f0c70d431dd325268e59893de4`, `src/engine/ProgressStore.ts` blob `0e4098655dc8efb5b065dbd8d4d6d0c44c6239f3`. PWA использовалась лишь как Raven precedent: hammer очищает одну плитку либо слой блокера без траты хода; shuffle переставляет плитки, сохраняя блокеры и не тратя ход. Не перенесены PWA runtime/state.
- Источник кампаний и покупок остаётся `RavenSnapshot / RavenReducer / RavenCampaignStore`; бустерные действия записываются в Match-3 action history и восстанавливаются детерминированным replay.

## Контракт

- Новый/старый save: `boosterInventory` хранит `hammer` и `shuffle`; старые schema-v1 сохранения получают нулевые остатки. Значения нормализуются к целым `0..99`.
- Покупка `RM-REST-001` единожды выдаёт 2 молотка; `RM-REST-002` единожды выдаёт 2 перемешивания. В магазине, платной валюте и монетизации бустеров нет.
- Reducer принимает идемпотентное событие `booster_spent`; повторный event ID не списывает предмет повторно. Наличие запаса проверяется reducer при фиксации.
- Игрок выбирает доступную клетку для молотка (плитка очищается, блокер теряет один слой) или вызывает shuffle. Обе операции не тратят ход и доступны только после соответствующей починки.
- Списание и новый replay checkpoint записываются одним snapshot. Если сохранение отклонено, live board возвращается к прежней последовательности действий.

## Проверки и границы

`match3_checkpoint_smoke.gd` покрывает нулевую стоимость хода, слой блокера, deterministic replay и невалидные цели. `vertical_slice_smoke.gd` покрывает миграцию старого состояния, лимит, одноразовые награды и идемпотентное списание. Это не заменяет физическое устройство, браузерное сохранение и owner acceptance.
