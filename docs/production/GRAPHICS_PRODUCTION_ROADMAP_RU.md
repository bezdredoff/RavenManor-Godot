# Raven Manor — план и roadmap производства графики

**Версия:** 0.1  
**Дата:** 27 октября 2026  
**Статус:** предлагаемый рабочий production plan; художественные результаты утверждаются владельцем проекта на каждом gate.  
**Цель:** построить воспроизводимый графический pipeline и последовательно произвести согласованный комплект персонажей, локаций, реквизита, Match-3 и интерфейсной графики для первого сезона Raven Manor.

**Парный инженерный план:** [`CODE_PRODUCTION_ROADMAP_RU.md`](CODE_PRODUCTION_ROADMAP_RU.md) — кодовые gates C0–C13, UPDS reuse, Hall end-to-end и общий G11/C11 approval. Этот документ остаётся источником art scope/gates; технический план не заменяет художественных критериев.

## 1. Решение верхнего уровня

Работа идёт в таком порядке:

1. инвентаризация инструментов и безопасный переход на последнюю VNCCS;
2. model bake-off непосредственно в новой VNCCS;
3. style/prompt bake-off средствами новой VNCCS и фиксация Raven Style Contract;
4. базовые identity packs четырёх главных персонажей средствами новой VNCCS;
5. пересборка Raven Character Production workflow на новой VNCCS;
6. VN-позы, выражения и keyframe-микроанимации;
7. отдельные mildly-chibi map-персонажи;
8. один end-to-end эпизодный пилот в Hall;
9. производство пакетами по главам и локациям;
10. интеграционный, мобильный и релизный QA.

Массовая генерация начинается только после прохождения style, identity, pipeline и Hall pilot gates. Старый UPDS Golden Trio v1.4.3 остаётся frozen baseline и источником проверенных решений, но не становится Raven production workflow.

## 2. Зафиксированный художественный scope

### 2.1 Главные персонажи

| ID | Роль | VN | Map | Production-приоритет |
|---|---|---:|---:|---|
| `RM-CHAR-EVELYN` | главная героиня | 3 базовые позы, до 6 выражений, сюжетные keyframes | полный walker | P0 |
| `RM-CHAR-ADA` | домработница | 3 позы, до 6 выражений, сюжетные keyframes | короткие маршруты | P0 |
| `RM-CHAR-LUCAS` | нотариус | 3 позы, до 6 выражений, сюжетные keyframes | stationary/короткий вход | P1 |
| `RM-CHAR-ROWAN` | садовник | 3 позы, до 6 выражений, сюжетные keyframes | ограниченные маршруты | P1 |

До отдельного сюжетного решения не производятся видимые ghost/vampire/wolf-варианты. Специалисты, курьер и неизвестный голос не получают полный VN/map package без утверждённой сцены.

### 2.2 Локации и состояния

Планируются 11 master families: Apartment, Road, Entry, Hall, Corridor, Bedroom, Bath vignette, Kitchen, Library, Garden, Conservatory. Варианты дня, вечера, ночи, шторма, загрязнения и ремонта реализуются преимущественно общими master-композициями, световыми вариантами и state overlays, а не новой картиной для каждого beat.

Map-архитектура и VN-фоны являются разными поверхностями. Нельзя растягивать 65° map-изображение в eye-level VN-фон. Общими остаются landmark IDs, материалы, палитра, архитектурные признаки и состояние объектов.

### 2.3 Реквизит и inserts

Производство опирается на `story_props.json`. Первыми создаются повторно используемые и сюжетно значимые семейства:

- письмо с наследством и герб ворона;
- чайный поднос и чашки;
- папка Лукаса и документы;
- дневник Эвелин;
- детский предмет, фотография, открытки, неподписанное письмо;
- домашний ledger;
- ключи Ады и содержимое кармана фартука;
- садовые инструменты Роуэна;
- repair-cost sheet и estate forms.

Один предмет имеет общий identity/provenance record, но отдельные презентации: map object, VN hand overlay, evidence close-up и state variant.

### 2.4 Match-3

Ровно восемь обычных тайлов: candle, key, rose, book, raven, cup, brooch, quill. Дополнительно максимум три blocker families: cobweb, crate, chain. Specials являются механическими объектами, а не новыми обычными тайлами.

### 2.5 UI и эффекты

В scope входят VN nameplates/slots, inspect popups, evidence inserts, repair/state feedback, Match-3 feedback, loading/placeholder/error art, reduced-motion версии и согласованные простые Godot-эффекты. Полноценная скелетная или покадровая анимационная система не требуется.

## 3. Production-принципы

1. Один утверждённый Style Contract для персонажей, окружения, реквизита и Match-3 с допустимыми подвариантами, но без визуально разных игр внутри проекта.
2. Model, style и character identity — разные контракты. Нельзя менять их одновременно при диагностике.
3. Prompt не заменяет identity reference, pose contract, camera contract и export contract.
4. Все production runs имеют workflow/version, model hashes, seed, prompts, inputs, outputs и checksums.
5. RAW является сохраняемым первичным результатом; matte, crop, resize и runtime conversion воспроизводимы отдельно.
6. Арт принимается внутри игры и на целевом viewport, а не только по отдельному PNG.
7. Генерируются только комбинации, реально требуемые сценами и `line_performance_cues.json`.
8. Новые партии малы до стабилизации pipeline: один персонаж/жест, один фон/state family или 2–3 связанных props.
9. Неутверждённые варианты не заменяют canonical assets и не удаляют предыдущий fallback.
10. Любой accepted asset имеет источник, права/условия использования, статус и связь с runtime ID.

## 4. Этапы, задачи и gates

## GFX-00 — Production control и инвентаризация

**Цель:** создать единый реестр, правила именования и безопасную среду до генерации.

- `GFX-00-01` Сверить сценарий, VN staging, line cues, props, map routes и room register.
- `GFX-00-02` Создать asset ledger со статусами `planned → researching → candidate → review → accepted → integrated → device-approved`.
- `GFX-00-03` Зафиксировать naming/path contract для RAW, alpha, game-ready, previews и manifests.
- `GFX-00-04` Определить каталоги immutable inputs, run outputs, accepted masters и runtime derivatives.
- `GFX-00-05` Зафиксировать target canvases, color space, alpha, pivot и compression для VN, map, props, backgrounds и tiles.
- `GFX-00-06` Создать шаблон run manifest и contact-sheet report.
- `GFX-00-07` Зафиксировать review viewports: 390×844, 412×915, 430×932 и tablet.
- `GFX-00-08` Добавить правила reduced motion, flashing, contrast и safe zones.

**Gate G0:** реестр покрывает весь утверждённый scope; у каждого класса ассетов есть формат, владелец решения, критерии приёмки и runtime destination.

## GFX-01 — Переход на последнюю VNCCS

**Цель:** получить изолированный, воспроизводимый Raven baseline на актуальной VNCCS без повреждения UPDS production.

- `GFX-01-01` Создать отдельную ComfyUI/VNCCS установку и отдельные user/output/cache directories.
- `GFX-01-02` Записать версии ComfyUI, Python, Torch, VNCCS, RMBG и всех custom nodes.
- `GFX-01-03` Зафиксировать SHA-256 моделей и workflow.
- `GFX-01-04` Составить inventory новых VNCCS возможностей: model families, Pose Studio, style library, reference/identity, native alpha, cache и resolutions.
- `GFX-01-05` Проверить загрузку старого workflow без сохранения; затем сохранить копию и изучить JSON diff.
- `GFX-01-06` Исправить API-адаптеры emotion hook и prompt construction под актуальную VNCCS.
- `GFX-01-07` Проверить окончательный positive/negative prompt непосредственно перед sampler.
- `GFX-01-08` Проверить RAW capture, tuple/output contracts, filenames и resume/cache.
- `GFX-01-09` Сгенерировать один контрольный полный рост и сравнить с frozen baseline по framing, scale, alpha и reproducibility.
- `GFX-01-10` Не переносить UPDS artist tag и character registry в Raven defaults.

**Gate G1:** новая установка создаёт повторяемый контрольный RAW и game-ready PNG; UPDS 3.1.2 не изменён; known incompatibilities либо исправлены, либо явно изолированы.

## GFX-02 — Model bake-off

**Цель:** выбрать внутри новой VNCCS модельное семейство, пригодное для всего каста и последующей pose/expression работы. GFX-02 использует нативные selectors, previews и model-family controls актуальной VNCCS, а не отдельный legacy flow.

- `GFX-02-01` Инвентаризировать поддерживаемые новой VNCCS model families и выбрать 3–4 реально установленных и лицензируемых кандидата.
- `GFX-02-02` Зафиксировать единые camera, pose, seed policy, resolution и нейтральный style block.
- `GFX-02-03` Подготовить тестовые identity briefs Эвелин и Ады без привязки к конкретному художнику.
- `GFX-02-04` Для каждого кандидата получить нейтральную и активную позу обеих героинь.
- `GFX-02-05` Проверить возраст Ады, лицо, руки, одежду, полный рост, повторяемость и matte.
- `GFX-02-06` Собрать слепой контактный лист без названий моделей.
- `GFX-02-07` Оценить управляемость повторной позы и локального редактирования.
- `GFX-02-08` Оставить максимум две модели для style bake-off.

**Gate G2:** выбран один основной и при необходимости один резервный model family; решение основано на таблице оценок, а не на одном удачном изображении.

## GFX-03 — Style и prompt bake-off

**Цель:** принять единый Raven visual language, используя нативные style library/style selection, prompt controls и previews новой VNCCS. Legacy Style Finder переносится только там, где новая VNCCS не даёт эквивалентного управляемого сравнения.

- `GFX-03-01` Сформировать в новой VNCCS 4–6 стилевых направлений без artist tags и сохранить их как версионируемые style/prompt presets.
- `GFX-03-02` На каждом направлении произвести всех четырёх героев в одной нейтральной композиции.
- `GFX-03-03` Для финалистов добавить по одной характерной позе и один интерьерный/prop sample.
- `GFX-03-04` Проверить женские и мужские лица, возраст, ткани, тёмные материалы, кожу, волосы, руки и читаемость силуэтов.
- `GFX-03-05` Уменьшить персонажей до реального VN-размера и проверить поверх Hall UI.
- `GFX-03-06` Проверить совместимость с map-chibi переводом и Match-3 icon language.
- `GFX-03-07` Зафиксировать Raven Style Contract: palette, line, shading, detail, eyes, skin, material, light, forbidden traits.
- `GFX-03-08` Зафиксировать canonical positive style block, negative/constraint block и допустимые domain modifiers.
- `GFX-03-09` Сохранить четыре style reference masters и контрольный environment/prop board.

**Gate G3 — STYLE LOCK:** принят один визуальный язык и эталоны. Изменение модели или style core после этого требует отдельного regression bake-off.

## GFX-04 — Character identity masters

**Цель:** утвердить персонажей до производства эмоций и анимаций. Character creation/reference/identity возможности новой VNCCS являются основным инструментом; внешнее image editing применяется только для диагностированного дефекта, который VNCCS не удерживает.

Для каждого из четырёх персонажей:

- `GFX-04-A` front / 3⁄4 left / 3⁄4 right / back;
- `GFX-04-B` face close-up с формой глаз, бровей, носа и рта;
- `GFX-04-C` height/proportion reference;
- `GFX-04-D` outfit front/back, palette swatches и material notes;
- `GFX-04-E` hair silhouette и асимметрия для запрета ошибочного flip;
- `GFX-04-F` accessories и detachable props;
- `GFX-04-G` neutral full-body master;
- `GFX-04-H` identity prompt/reference pack и forbidden drift list.

Отдельно проверить, что Ада не омолаживается, Лукас не получает ранних vampire-признаков, Роуэн — wolf-признаков, а Эвелин не становится копией UPDS-персонажа.

**Gate G4 — IDENTITY LOCK:** четыре персонажа узнаваемы между ракурсами, имеют утверждённые силуэты, палитры, одежду и reference packs.

## GFX-05 — Raven Character Production workflow

**Цель:** пересобрать flow вокруг новой VNCCS и Raven contracts.

- `GFX-05-01` Разделить inputs: character identity, style, pose, expression, prop, camera, export.
- `GFX-05-02` Поддержать произвольный character registry вместо жёсткого Golden Trio.
- `GFX-05-03` Поддержать named poses и named keyframes вместо только Pose A/Pose B.
- `GFX-05-04` Добавить deterministic paths, partial resume и per-frame regeneration.
- `GFX-05-05` Сохранять RAW, matte mask, RGBA master, preview и manifest.
- `GFX-05-06` Сохранить original RGB + selected mask как проверяемый export path.
- `GFX-05-07` Сравнить native alpha актуальной VNCCS с `BiRefNet_toonout`; выбрать по визуальному тесту волос, пальцев и полупрозрачных краёв.
- `GFX-05-08` Реализовать contain/no-crop, bottom-center anchor и safe margin.
- `GFX-05-09` Добавить preflight полноты заказанной партии до дорогого matte/export.
- `GFX-05-10` Автоматически строить contact sheet с guide lines и frame metadata.
- `GFX-05-11` Создать Godot import manifest: asset ID, pivot, frame duration, transition hints, prop/state links.

**Gate G5:** один персонаж проходит полный путь от registry до Godot без ручного переименования и с воспроизводимым повторным экспортом.

## GFX-06 — VN poses, expressions и keyframe microanimations

**Цель:** выпустить только нужный сценам performance set через новую VNCCS: создавать или редактировать позы в Pose Studio, сохранять их как именованные production inputs и на их основе делать keyframes.

- `GFX-06-01` Сопоставить 280 line cues с pose/expression/gesture и удалить неиспользуемые комбинации из заказа.
- `GFX-06-02` Произвести три базовые позы каждого главного героя.
- `GFX-06-03` Произвести до шести утверждённых выражений, начиная с реально используемых P0-сцен.
- `GFX-06-04` Для каждого signature micro создать storyboard из 3–6 keyframes, затем создать или отредактировать соответствующие промежуточные позы в VNCCS.
- `GFX-06-05` Проверить identity drift между keyframes; сначала корректировать reference/pose в VNCCS, затем при необходимости использовать controlled edit/inpaint вместо полной генерации с нуля.
- `GFX-06-06` Отдельно производить физически значимые prop states: письмо, поднос, папка, инструменты.
- `GFX-06-07` В manifest хранить durations, hold, easing, return frame и разрешённые Godot effects.
- `GFX-06-08` Реализовать image swap плюс scale/squash/shake/offset/opacity; без полноценного animation rig.
- `GFX-06-09` Подготовить reduced-motion профиль с меньшей амплитудой либо статичным hold.
- `GFX-06-10` Проверить, что противоречивые состояния не комбинируются: две занятые руки, повторный prop, жест во время несовместимой позы.

**Gate G6:** Evelyn и Ada имеют принятый P0 performance set, а минимум две микроанимации проигрываются в Godot без заметного identity/scale jitter.

## GFX-07 — Map character production

**Цель:** создать отдельную mildly-chibi систему с сохранением идентичности. Инструмент заранее не фиксируется: короткий сравнительный spike проверяет новую VNCCS, ChatGPT image generation/editing и Nano Banana на одних reference packs и целевых позах.

- `GFX-07-01` Провести tool spike VNCCS vs ChatGPT vs Nano Banana на одной Эвелин: front idle, side walk key pose и back pose в диапазоне 3.5–4.5 heads.
- `GFX-07-02` Оценить identity, направление, повторяемость, прозрачность, скорость правок и пригодность для согласованной walk family; выбрать основной и резервный инструмент.
- `GFX-07-03` Провести chibi proportion mini-bake-off: 3.5 / 4.0 / 4.5 головы в выбранном инструменте.
- `GFX-07-04` Утвердить cross-scale identity markers каждого героя.
- `GFX-07-05` Эвелин: idle, walk down/up/side, turn, inspect, pickup, interact.
- `GFX-07-06` Ада: idle, короткий walk set, tray offer, apron reach.
- `GFX-07-07` Роуэн: idle, ограниченный walk set, tool/plant interaction.
- `GFX-07-08` Лукас: idle, turn, folder offer, optional short approach.
- `GFX-07-09` Проверить foot pivot, frame bounds, speed, foot slide и side-flip ограничения.
- `GFX-07-10` Проверить реальный размер на 65°/0.74× карте и перекрытия архитектурой.

**Gate G7:** Эвелин проходит Hall → Corridor → Bedroom с читаемой походкой и неизменной идентичностью; остальные персонажи проходят свои минимальные staging cases.

## GFX-08 — Environment и room-state production

**Цель:** превратить утверждённую геометрию в согласованные map и VN surfaces.

- `GFX-08-01` Закрыть Hall wall/door/stair calibration до декоративного scale-out.
- `GFX-08-02` Выбрать constructed modular structure против AI structural pieces; AI использовать преимущественно для материалов и уникального декора, если это даёт более стабильные seams.
- `GFX-08-03` Утвердить material library: wood, plaster, wallpaper, stone, glass, metal, fabric.
- `GFX-08-04` Для каждой комнаты зафиксировать landmarks, camera, light directions, actor safe zones и occlusion masks.
- `GFX-08-05` Произвести 11 VN background masters преимущественно через ChatGPT image generation/editing: этот путь уже оказался проще для точного portrait aspect ratio, композиции и стилевого выравнивания в UPDS.
- `GFX-08-06` Для каждого ChatGPT-фона сохранять исходный бриф, reference board, целевой размер, Style Contract, landmarks и последующие edits; принятый master image становится источником производных.
- `GFX-08-07` Производить state overlays и light grades отдельно от base master; ChatGPT использовать для крупных семантических вариантов, ComfyUI или локальную обработку — для воспроизводимых масок, grades и пакетных производных.
- `GFX-08-08` Произвести map-ready room elements по Room Builder/Godot geometry.
- `GFX-08-09` Проверить дверные seams, лестницы, collision footprints, foreground masks и character contact.
- `GFX-08-10` Не менять story/navigation/collision из-за косметического изображения без отдельного физического контракта.

**Gate G8:** Hall, Corridor и Bedroom имеют принятые map/VN варианты, согласованные landmarks и корректные character occlusion/contact.

## GFX-09 — Props, evidence и state assets

- `GFX-09-01` Разбить 37 story prop families на P0/P1/P2 и reuse groups.
- `GFX-09-02` Произвести P0: letter, tea set, notary folder, bedroom door, bed, childhood object, bath pipes.
- `GFX-09-03` Произвести P1: ledger, clock, library desk/shelves, photo, cards, unsigned letter, garden tools, childhood box/map.
- `GFX-09-04` Произвести P2: storm/archive handling, repair costs, estate forms, final diary states.
- `GFX-09-05` Для каждого prop family связать map/VN/insert variants одним logical ID.
- `GFX-09-06` Проверить hands/contact, readable text policy, scale, state causality и spoiler safety.

**Gate G9:** все props текущей производственной главы существуют в нужных presentation forms и переключаются только утверждёнными story events.

## GFX-10 — Match-3 и UI art

**Сверка с кодом (27.10.2026):** PR #54 смержил UPDS-origin `CODE-02-00` — форму поля, motion layer, easing и tutorial event predicates с Godot smoke. Это **только подготовка рендерера**. Тайлы, blockers, specials, UI skin и эффектные state frames по `GFX-10-01…08` **не утверждены**; требования этого раздела и GFX-11 сохраняются. Следующий совместный gate — настоящий Match-3 экран с mobile readability и временным/затем утверждённым артом. Текущие evidence и статус CODE/GFX хранятся в `production_progress.json`, не выводятся из факта мержа PR.

Основной путь для концептов и финальных восьми обычных тайлов — ChatGPT image generation/editing, как в UPDS. ComfyUI используется как сравнительный или пакетный инструмент только при доказанном выигрыше в консистентности, вариантах состояний либо воспроизводимой обработке.

- `GFX-10-01` Через ChatGPT создать silhouette/value bake-off восьми тайлов на одном style board и общей сетке размеров.
- `GFX-10-02` Проверить различимость без цвета, на маленьком экране и при визуальных эффектах.
- `GFX-10-03` Утвердить единый набор из восьми тайлов без тематических замен по главам.
- `GFX-10-04` Произвести cobweb, crate 1/2 hit и chain.
- `GFX-10-05` Произвести specials и состояния selected/hint/matched/fall.
- `GFX-10-06` Настроить мягкие glow/dissolve/bounce эффекты в Godot.
- `GFX-10-07` Проверить reduced motion, contrast и отсутствие визуальной перегрузки.
- `GFX-10-08` Привести VN frame, popups, inserts и repair feedback к Style Contract.

**Gate G10:** board читается на телефоне, все восемь тайлов различимы, а эффекты не маскируют цели и блокеры.

## GFX-11 — Hall end-to-end pilot

Пилот должен включать:

- принятый Hall background/state;
- Эвелин и Аду в двухместной VN-композиции;
- не менее двух поз и трёх выражений каждой;
- письмо либо чайный prop interaction;
- две keyframe-микроанимации;
- map-Эвелин и staging Ады;
- один inspect popup и один evidence/prop insert;
- RU/BE/EN geometry check, даже если переводной текст ещё использует fallback;
- mobile screenshots, reduced-motion и resume/save regression.

**Gate G11 — SCALE-OUT APPROVAL:** пилот выглядит как одна игра, проходит runtime/mobile QA и подтверждает реальную стоимость одного pose/expression/gesture/background/prop package.

## GFX-12 — Пакетное производство по главам

После G11 работа идёт вертикальными пакетами:

| Волна | Содержание | Основные ассеты |
|---|---|---|
| W0 | Пролог + глава I | Apartment, Road, Entry, Hall, Corridor, Bedroom, Bath; Evelyn/Ada/Lucas P0 |
| W1 | Глава II | Kitchen, Rowan intro, kitchen states, ledger, electricity props |
| W2 | Глава III | Library, Lucas/Ada scenes, photo/cards/letters, archive props |
| W3 | Глава IV | Garden, Conservatory, Rowan performance, childhood box/map |
| W4 | Глава V | storm grades/overlays, wet archive states, Ada apron supplies |
| W5 | Глава VI | decision/ending states, forms, diary, final Hall/Bedroom views |

Каждая волна проходит: `planned → generated → art-reviewed → integrated → scene-reviewed → phone-reviewed → accepted`.

## GFX-13 — Финальный art QA и release packaging

- asset crawl без missing/duplicate/decode ошибок;
- проверка всех 28 VN-сцен и обязательных revisit states;
- проверка scale, pivots, alpha halos, crop и compression;
- проверка времени суток и отсутствия ранних supernatural reveals;
- проверка props и персонажей на continuity;
- проверка RU/BE/EN text geometry;
- проверка portrait devices и tablet;
- reduced-motion и accessibility pass;
- memory/load-time baseline и оптимизация atlas/compression;
- licenses, provenance, credits, model/workflow hashes;
- финальный accepted asset manifest и rollback package.

**Gate G13 — ART RC:** в shipped-сценах нет заглушек, непринятых candidates, неправильных состояний или визуально несовместимых пакетов.

## 5. Матрица приоритетов

### P0 — начать сейчас

- GFX-00 production control;
- GFX-01 latest VNCCS isolated migration;
- GFX-02 model bake-off;
- GFX-03 style lock;
- GFX-04 identity masters всех четырёх героев;
- GFX-05 новый Raven workflow;
- Evelyn/Ada VN proof;
- Hall/Bedroom/Corridor calibration;
- Hall end-to-end pilot.

### P1 — после Hall pilot

- полный P0 performance set всех четырёх героев;
- map Эвелин/Ада/Роуэн и minimal Lucas;
- главы II–IV;
- основные story props;
- восемь Match-3 tiles и blockers;
- Library/Garden/Conservatory production.

### P2 — после подтверждения первых волн

- главы V–VI и ending states;
- storm/archive overlays;
- редкие prop close-ups;
- дополнительные keyframe-жесты;
- optimisation, credits и полный Art RC.

## 6. Зависимости и критический путь

```text
Inventory
  → latest VNCCS baseline
  → model bake-off in VNCCS
  → style/prompt bake-off in VNCCS
  → four identity masters in VNCCS
  → Raven workflow
  → Evelyn/Ada performance proof
  → Hall end-to-end pilot
  → chapter waves
  → Art RC
```

Параллельно после style lock могут идти material library, ChatGPT Match-3 silhouette work и prop identity sheets. ChatGPT VN-background pilot можно готовить сразу после style lock, но массовые фоны начинаются после Hall camera/geometry acceptance. Map-персонажи начинаются после identity lock и отдельного VNCCS/ChatGPT/Nano Banana spike. Массовые character states начинаются после G5/G6.

## 7. Оценка объёма и планирование

Оценки задаются после Hall pilot, когда измерена фактическая стоимость accepted asset. До этого использовать относительные размеры:

- **S:** один prop state, expression либо простой keyframe;
- **M:** базовая поза, evidence insert, blocker family либо light/state overlay;
- **L:** identity pack, map walk family, VN background master;
- **XL:** новый workflow, room family с geometry/occlusion или chapter art package.

Для каждой задачи учитывать четыре разных времени: generation, art review, correction и integration/device QA. Скорость получения PNG не равна скорости получения production asset.

## 8. Правила ревью

Каждый кандидат поставляется с:

- ID и сценами использования;
- contact sheet;
- reference/brief;
- model/workflow/seed/prompt manifest;
- alpha на светлом и тёмном фоне;
- изображением в реальном UI;
- списком известных дефектов;
- рекомендацией `accept / revise / reject`.

Пользователь принимает style, identity и финальную художественную пригодность. Технический gate проверяет формат, runtime ID, размер, alpha, pivot, state linkage и воспроизводимость. Candidate не становится production только потому, что успешно сгенерирован.

## 9. Stop rules

- Не запускать следующий широкий batch при систематическом identity drift.
- Не исправлять geometry prompt-тюнингом, если проблема требует control guide или constructed asset.
- Не обновлять model/node/workflow во время принятой партии без нового baseline.
- Не производить полный Cartesian product поз, эмоций, props и gestures.
- Не создавать полного специалиста ради одной offscreen функции.
- Не принимать арт только по desktop contact sheet.
- После прохождения согласованных gates и Art RC прекращать добавление новых вариантов и выпускать.

## 10. Первые 12 конкретных задач

1. Создать Raven graphics asset ledger из production JSON и room/prop registers.
2. Создать изолированную latest-VNCCS установку.
3. Зафиксировать node/model inventory и hashes.
4. Выполнить API/runtime compatibility spike.
5. Подготовить два нейтральных identity briefs: Evelyn и Ada.
6. Провести model bake-off внутри новой VNCCS.
7. Подготовить в новой VNCCS 4–6 неавторских style/prompt presets.
8. Провести style bake-off на четырёх героях внутри новой VNCCS.
9. Утвердить Raven Style Contract.
10. Выпустить средствами новой VNCCS identity master packs четырёх героев.
11. Пересобрать Raven Character Production v0.1.
12. Сделать Evelyn/Ada Hall pilot с двумя keyframe-микроанимациями и мобильным ревью.

После задачи 12 пересчитать объём, утвердить batch size и расписать W0–W5 в календарный производственный график.


## Cross-gate GFX-10 × CODE-02C (27.10.2026)

Программные highlight/fade для `flash-row/flash-column/evidence/lead/insight` и clip по сегментам колонок из UPDS подготовлены в ветке `code/code-02c-special-impact-segment-motion`. Это **временный programmer art**: цветная вспышка / символ типа / числовые слои blocker, без утверждения tile sprites, silhouettes, FX, particles, animations, background или accessibility цвета. Все acceptance критерии `GFX-10` и совместный `CODE-11 × GFX-11` Hall Pilot остаются отдельными gates. Финальные ассеты должны подставляться в Raven theme/manifest без переписывания UPDS match rules.


## Cross-gate GFX-10 × CODE-02D — responsive placeholder UI (2026-10-27)

CODE-02D адаптирует размеры поля и кнопок, строки целей/ходов и safe area, но **не утверждает никакого финального GFX-10 арта**. Все восемь тайлов, blocker/special sprites, FX и HUD-хром пока programmer art. После GFX-10 подставить графические пакеты через Raven theme; проверить legibility целей и значков на 320/390/412/430px, 44px touch targets и физический iPhone без поперечной прокрутки. GFX-11 × CODE-11 Hall Pilot остаётся совместным gate.
