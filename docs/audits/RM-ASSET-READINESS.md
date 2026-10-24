# Raven Manor — asset readiness

## Найдено

- UPDS: каталог 142 assets, 127 оптимизированных изображений, VN backgrounds/portraits, Match-3 art и проверенные пути.
- Raven hub prototype: один общий plate двух неутверждённых комнат; 6 props × broken/fixed; Onoe v1 directional sheet и v2 side walk; screenshots.
- Existing character art: UPDS portraits, включая Оноэ; это reference/prototype material, не Raven cast.

## Не найдено как Raven production assets

- Hall, Corridor, Bedroom, Bathroom, Kitchen, Archive и Conservatory master plates;
- layered restoration variants по утверждённым room specs;
- doors в состояниях locked/closed/opening/open/closing;
- foreground occlusion masks;
- Evelyn/Ada/Lucas/Rowan VN production sets;
- map-scale Evelyn animation с проверенным baseline/margins;
- Raven props/clue inserts;
- lighting/atmosphere layers;
- Raven hotspot markers/effects;
- единый Raven asset manifest/source of truth.

## Готовность относительно оценки

Оценка `5 principal rooms + compact bathroom + corridor/entry + 4 characters + 12–20 props` пока покрыта только спецификациями Stage 2. Визуальные prototypes доказывают сборку сцены, но не production coverage или единый стиль.

## Минимальный model/style test set без новых изображений

Для технического composite test уже доступны:

1. current two-room environment plate;
2. broken/fixed furniture sheet;
3. Оноэ neutral portrait;
4. Оноэ map sprite sheets;
5. реальный portrait UI.

Этого достаточно для проверки масштаба, импорта, alpha, animation playback и layering. Этого недостаточно для принятия Raven style lock, потому что отсутствуют утверждённые Evelyn и Stage-2 room anchors.

## До дополнительного production artwork

- принять scene/asset matrix Stage 3;
- построить greybox с точными layer slots;
- определить pixel density, camera grid, safe margins и occluder format;
- принять один room/Evelyn/prop anchor composite;
- ввести Raven asset manifest и provenance;
- автоматизировать проверки dimensions, alpha, frame count и missing IDs.