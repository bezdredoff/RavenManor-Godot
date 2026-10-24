# Room furnishing and prop layout — proposed production registry v0.1

**Evidence:** object families and room functions originate from Stage 1 v0.5, Stage 2 v0.2 and Stage 3 scene matrix. Specific counts, furniture choices and placements below are **new proposals**, not previously approved floor plans. No pixel coordinates are canon until per-room greybox calibration.

Every object belongs to a contextual cluster and fixed placement anchor. Architectural anchors must be checked against door routes, sight lines, room occluders and water/electrical service routes. No arbitrary random scatter. Visible clutter should be clustered and decodable; primary route remains unobstructed.

Layer families: base architecture, midground furniture, interactable prop, foreground occluder, repair overlay, lighting/atmosphere, VN/close-up insert. Distinguish visually changed furniture from lore clue inserts.

## Порог/крыльцо — `RM-ROOM-ENTRY`

**Planned distinct object families:** 8. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| каменные ступени | `front:stone` | fixed | base |
| створки входной двери | `threshold:center` | locked/open | door |
| настенный фонарь | `wall:left` | dusty/lit | light |
| мокрый коврик | `floor:entry-side` | dusty/clean | dressing |
| дорожный чемодан | `floor:wall-right` | closed/open | story |
| конверт наследства | `hand/insert` | sealed/read | clue |
| кашпо | `side:porch` | overgrown/tended | dressing |
| водосток | `exterior:corner` | aged/fixed | architecture |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.

## Парадный холл — `RM-ROOM-HALL`

**Planned distinct object families:** 16. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| главная лестница и балюстрада | `rear:left` | unsafe/future-access | architecture |
| напольные часы | `rear:focus` | stopped/repaired/chiming | interactive |
| двустворчатая дверь восточного крыла | `rear:right` | locked/future | door |
| арка западного коридора | `rear:central` | open | portal |
| библиотечная дверь | `side:left` | closed/open | door |
| семейный портрет | `wall:hero` | dusty/clean/reveal | story |
| консольный стол | `wall:edge` | dusty/polished | furniture |
| зеркало | `above:console` | clouded/clean | dressing |
| вешалка/стойка зонтов | `near:entry` | dusty/arranged | dressing |
| парадный ковёр | `floor:axis` | rolled/laid | restoration |
| две настенные лампы | `wall:paired` | off/on | light |
| ключница и записки | `wall:service-side` | disordered/ordered | interactive |
| ваза с сухими цветами | `on:console` | dry/refreshed | dressing |
| пыльные защитные чехлы | `floor:perimeter` | covered/removed | restoration |
| коробка запчастей часов | `near:clock` | sealed/open | story |
| запечатанный указатель | `clock:insert` | hidden/discovered | clue |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.

## Жилой коридор — `RM-ROOM-CORRIDOR`

**Planned distinct object families:** 12. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| длинная обшивка стен | `walls:continuous` | dusty/clean | architecture |
| дверь спальни | `side:bedroom` | locked/removed-after-unlock | door |
| дверь санузла | `side:bath` | unsafe/available | door |
| дверь кухни | `end/service` | closed/open | door |
| окно с глубоким откосом | `wall:exterior` | dusty/clean | architecture |
| парные бра | `wall:intervals` | off/on | light |
| узкая скамья | `wall:recess` | covered/clear | furniture |
| узкий коврик-дорожка | `floor:side` | dirty/clean | dressing |
| рамки семейных фотографий | `wall:group` | dusty/reveal | story |
| шкафчик коммуникаций | `wall:service` | unsafe/inspected | interactive |
| корзина белья | `side:bath` | full/cleared | dressing |
| цветочная подставка | `window:alcove` | dry/planted | dressing |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.

## Спальня Эвелин — `RM-ROOM-BEDROOM`

**Planned distinct object families:** 16. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| кровать с изголовьем | `wall:rear` | dusty/made | restoration |
| матрас и бельё | `on:bed` | covered/fresh | restoration |
| прикроватные тумбы | `bed:two-sides` | dusty/clean | furniture |
| прикроватный светильник | `on:nightstand` | off/on | light |
| шкаф | `wall:side` | closed/usable | furniture |
| сундук детских вещей | `bed:foot-side` | closed/open | interactive |
| малый письменный стол | `window:side` | cluttered/clear | furniture |
| стул | `at:desk` | misplaced/aligned | dressing |
| зеркало в раме | `wall:wardrobe` | clouded/clean | dressing |
| шторы | `window` | drawn/open | dressing |
| ковёр | `floor:bedside` | rolled/laid | restoration |
| чехлы и пыль | `furniture:overlays` | covered/removed | restoration |
| детская отметка роста | `wall:concealed` | hidden/visible | clue |
| детская игрушка | `trunk:insert` | hidden/found | clue |
| дорожная сумка | `floor:entry-side` | packed/unpacked | dressing |
| камин или радиатор | `wall:exterior` | off/checked | architecture |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.

## Компактный санузел (vignette) — `RM-ROOM-BATHROOM`

**Planned distinct object families:** 12. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| раковина | `wall:plumbing` | dry/working | restoration |
| смеситель | `on:basin` | dry/dripping/working | interactive |
| унитаз | `wall:wet` | unsafe/usable | furniture |
| душ/ванна | `rear:wet` | unsafe/usable | furniture |
| экран/шторка | `front:shower` | closed/open | occluder |
| зеркало | `above:basin` | clouded/clean | dressing |
| полка для полотенец | `wall:dry` | empty/stocked | dressing |
| настенное освещение | `above:mirror` | off/on | light |
| сервисный люк | `wall:plumbing` | closed/open/repaired | interactive |
| трещина/течь соединения | `under:basin` | leaking/repaired | restoration |
| инструменты сантехника | `floor:service-corner` | arrived/removed | story |
| мыльница и флакон | `on:shelf` | dusty/usable | dressing |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.

## Кухня — `RM-ROOM-KITCHEN`

**Planned distinct object families:** 18. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| кухонный гарнитур | `wall:service` | covered/usable | restoration |
| мойка и смеситель | `wet:wall` | dry/working | restoration |
| плита | `wall:service` | unsafe/working | restoration |
| разделочный стол | `center:off-axis` | cluttered/clear | furniture |
| буфет | `wall:back` | locked/organized | furniture |
| холодильник/кладовой шкаф | `wall:service` | off/usable | furniture |
| сушилка для посуды | `by:sink` | empty/stocked | dressing |
| тарелки/чашки (набор) | `inside:cupboard` | dusty/clean | dressing |
| чайник | `on:counter` | cold/in-use | dressing |
| банки для сухих продуктов | `on:shelf` | disordered/arranged | dressing |
| полотенца и прихватки | `on:rail` | stored/hung | dressing |
| коробки доставки | `near:entry` | present/cleared | story |
| коробка с фотоальбомом | `near:buffet` | sealed/open | clue |
| распределительная панель | `wall:service` | unsafe/approved | interactive |
| дверь к оранжерее | `rear:garden-side` | locked/open | door |
| служебная дверь | `rear:service-wing` | locked/future | door |
| корзина овощей | `on:table` | empty/filled | dressing |
| оконные занавески | `window` | dusty/clean | dressing |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.

## Библиотека/архив — `RM-ROOM-ARCHIVE`

**Planned distinct object families:** 16. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| высокие стеллажи | `walls:perimeter` | unstable/braced/restored | restoration |
| письменный стол | `center:off-axis` | buried/organized | restoration |
| два читальных кресла | `near:table` | covered/usable | furniture |
| настольная лампа | `on:desk` | off/on | light |
| каталожные ящики | `shelf:lower` | jammed/sorted | interactive |
| лестница для книг | `shelf:edge` | unsafe/secured | dressing |
| шкаф семейных документов | `rear:wall` | locked/accessible | interactive |
| гостевая книга | `on:reading-desk` | hidden/read | clue |
| семейный альбом/фотография | `on:table` | closed/read | clue |
| карта растений | `drawer:insert` | hidden/discovered | clue |
| архивный конверт | `niche:rear` | sealed/open | clue |
| чернильный прибор | `on:desk` | dry/arranged | dressing |
| книжные стопки | `shelf:secondary` | scattered/sorted | dressing |
| шторы и занавес | `window` | drawn/open | dressing |
| бумажные коробки | `shelf:lower` | cluttered/stored | dressing |
| закладка и ключ | `inside:book` | hidden/found | story |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.

## Оранжерея — `RM-ROOM-CONSERVATORY`

**Planned distinct object families:** 19. Place visually dense groups along walls/perimeters; do not blanket the navigation axis. At least one focal object per camera view; support clusters should fill the environment without introducing fake hotspots.

| Object | Placement | States | Category |
|---|---|---|---|
| стеклянные секции | `walls:rear` | cracked/replaced | restoration |
| дверь из кухни | `front:service` | locked/open | door |
| дверь в сад | `rear:exterior` | locked/future | door |
| центральная дорожка | `floor:center` | overgrown/clear | restoration |
| верстак садовника | `wall:side` | dirty/organized | furniture |
| скамья для собраний | `perimeter:window` | bare/inviting | restoration |
| стеллаж для горшков | `wall:back` | tilted/secured | restoration |
| большая кадка с деревцем | `perimeter:bright` | dry/healthy | dressing |
| три семейства горшечных растений | `shelves:grouped` | wilted/revived | dressing |
| подвесные кашпо | `ceiling:perimeter` | overgrown/tended | occluder |
| садовые ножницы и совок | `on:workbench` | rusty/clean | interactive |
| лейка | `by:water-point` | empty/filled | dressing |
| ящик с семенами | `under:bench` | closed/open | interactive |
| растение с детской биркой | `display:focus` | concealed/identified | clue |
| капсула/деталь часов | `pot:insert` | hidden/obtained | clue |
| шланг и водоразбор | `wall:service` | dry/working | interactive |
| осколки стекла | `floor:hazard` | present/cleared | restoration |
| столик для встречи | `side:cleared` | absent/arranged | restoration |
| садовые фонари | `along:path` | off/on | light |

**Composition gate:** verify traversable graph edges, visible doors, actor scale, nearest foreground mask, camera focus and furniture shadows; mark clusters as background-only unless explicit hotspot ID exists.
