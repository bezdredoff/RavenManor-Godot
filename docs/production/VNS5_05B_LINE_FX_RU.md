# VNS5-05B (phase 1) — привязка FX к репликам Raven VN Studio

**Источник:** `main@816fe56dc9a5c2a593531af7fbba594100627fae` после merge PR #110.
**Предшественник:** VNS5-05A / [PR #106](https://github.com/bezdredoff/RavenManor-Godot/pull/106), merged in `main`. Исходные FX были **сценными и editor-only**.
**Статус:** implementation PR, **не runtime-ready**. Без ручной проверки Godot Editor — не `accepted`.

## Что добавлено в данном этапе

- Необязательное поле `lineId` в существующей `raven-vn-stage-fx-v1.cues[]`: отсутствие `lineId` означает старую сценную анимацию, без миграции формата и изменения source SHA locks.
- При выборе реплики в Raven VN Studio stage превью получает её `lineId`; новые FX, созданные на выбранной реплике, автоматически привязываются к ней. Опция `Вся сцена` позволяет перенести существующий cue с реплики на сцену или обратно; FX ID остаётся стабильным.
- Список привязок берётся исключительно из существующих `project.linesByScene[sceneId]`. Ссылка на реплику иной сцены, удалённую или неизвестную реплику, пустой ID или тип не String блокируют сохранение, validation, Undo и export; нельзя произвольно вводить новые сюжетные IDs.
- Сценные FX показываются при любой выбранной реплике. FX, привязанные к `lineId`, семплируются только для этой реплики; при переключении реплики Play сбрасывается, чтобы не протекали прежние движения или прозрачность.
- `Store.export_fx_candidate` сохраняет anchor в прежнем no-overwrite `user://` review JSON; V1/V2 экспорт по-прежнему блокируется при наличии FX. Никаких `res://` записей, изменения 28 сцен / 280 реплик, 62 approved cast frames, UPDS donor, reducer, сохранений или playable runtime.

## Проверка

Новый `tests/raven/vn_studio_line_fx_smoke.gd` запускается из обычного `scripts/check.sh`. Проверяет backward compatibility без `lineId`, проверку правильной и чужой реплики, ошибочные типы, draft/save/export no-overwrite и строки JSON, активность эффектов для разных реплик, editor Undo, SHA канонического сценария/постановки/каста до и после. Не выдавать CI за desktop QA.

Ручная приёмка Godot 4.7.2 под Windows при **800×640, 1024×640, 1366×768**:
1. Открыть VN Studio → Raven Manor → первую сцену, выбрать L001 → Постановка → добавить FX. В новом cue должен быть `lineId` L001.
2. На L002 FX от L001 не должен проигрываться, но `Вся сцена` — должен на обеих. Проверить Play/Pause/Scrub, переключение реплик, 0/1/2/3 actor, actor+prop/background FX.
3. Переключить anchor `Вся сцена` ↔ конкретная реплика; проверить FX Undo, общий Undo/Redo, сохранение черновика и перезапуск плагина. Проверить FX review export, отсутствие перезаписи.
4. Проверить error при ручном повреждении черновика (`lineId` другой сцены), fail-closed SHA drift, отсутствие изменения канона или playable VN.
5. Переключить 3 размера окна, убедиться, что controls достижимы скроллом; сверить acceptance screenshot до/после.

## Следующие задачи до закрытия всей VN Studio v5

- **VNS5-05B (phase 2):** утвердить формальный line-event runtime contract; привязать staged timeline к игровому VN presenter через NoOp preview/event sink и тесты смены реплик/skip/auto/reduced-motion. Нельзя включать в runtime текущие editor-only FX без review.
- **VNS5-06:** редактируемая Story Map (scene/choice/condition/Match-3/map/ending), добавление сцен/реплик с уникальными IDs и сохранением канонических gates.
- **VNS5-07–09:** полноценные клипы и production renderer, versioned conversion/parity UPDS, end-to-end desktop/phone QA. Прошедший smoke ≠ принятие stage v2 или runtime.
- Старые VNS5-03/04A/04B/05A остаются merged, но manual QA может быть не записана в дашборд. Не закрывать их автоматически.

**Rollback:** revert PR; существующие draft `user://` не удалять. При откате старый VNS5-05A не знает поле `lineId`, поэтому для сохранённых новых FX применять прошлую версию только после копии черновика и отдельного review — не экспортировать через старый plugin с потерей anchors.
