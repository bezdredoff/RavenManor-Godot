# RM Architecture Decision — keep, refactor or migrate

## Решение

**Оставить Godot 4.7.2 и инкрементально выделить общие UPDS-системы за стабильными интерфейсами. Raven Manor реализовать новым content namespace и manor runtime.**

## Почему

- Текущий проект уже Godot, portrait-first и имеет успешный полный smoke suite.
- Match-3 существенно реализован и протестирован.
- VN renderer, choices, portraits, dossier/history и save primitives уже существуют.
- Нативных Godot `AStar2D`, `NavigationRegion2D`, `NavigationAgent2D` и `NavigationLink2D` достаточно для greybox; addon не обязателен.
- Перенос в Unity или web stack повторно создаст работающие VN, Match-3, save, mobile UI и CI без доказанной выгоды.

## Что расширять

- `LevelCatalog`, `StoryRegistry`, `AssetResolver`, `SaveAdapter` interfaces.
- Campaign store/recovery patterns с отдельным Raven key/schema.
- Match-3 data presentation для Raven context.
- VN presentation как renderer Raven story-beat data.

## Что строить отдельно

- Raven session/reducer и catalogs.
- Hub scene/runtime.
- Navigation controller и door portal.
- Hotspot/restoration components.
- Room layers/foreground masks.
- Raven end-to-end tests.

## Что не переносить в production

- hardcoded waypoint arrays из `manor_hub_prototype.gd`;
- прямые tweens как pathfinding;
- sprite sheets как production baseline;
- UPDS numeric story indices в Raven save;
- prototype object dictionary как content catalog.

## Addon decisions

- Navigation: сначала native Godot A/B spike; внешнее решение не требуется по умолчанию.
- Camera: `Camera2D` достаточно для первого greybox; Phantom Camera оценивать только если priorities/blends начинают дублировать сложный код.
- Dialogue: текущий VN renderer оставить; Dialogue Manager не вводить без отдельного доказанного gap.
- Inventory: не нужен для vertical slice.

## Reusable publication path

После принятия `RM-HUB-001` общие компоненты выделяются в `addons/restoration_hub/`. Публичный API нельзя замораживать на основе текущего spike. Нужны второй независимый sample hub, tests, license audit, Raven-free demo assets и semantic versioning.