# VNS5-07E — полный размер Raven VN Studio в Godot

**Основание:** скриншот владельца от 2026-11-02, issue #121. Status: PR_review candidate; CI и native UI QA на момент написания не проведены.

## Факт по скриншоту

В окне Godot (приблизительно 1650×930) Director/Story Map занимает лишь верхнюю часть отведённой рабочей области, а оставшаяся нижняя часть пустая. Stage слишком узкий; портретный frame может быть промотан до пола, создавая впечатление маленькой картинки. Отдельно видно множество `Unexpected NUL character` в Godot Output — **не установлено**, относятся ли они к layout; это отдельная диагностическая задача, не критерий, по которому можно заявлять отсутствие ошибки.

## Причина по коду

- `raven_story_view.gd` содержит `ScrollContainer → VBoxContainer` с `body.custom_minimum_size.y = 440`. ScrollContainer не растягивает VBox автоматически на всю высоту viewport, а вложенный HSplitContainer получает только минимум по вертикали. Избыток высоты окна остаётся пустым.
- `Stage` был по умолчанию узким (splitter offset ~390px) при расширяющемся инспекторе; старый EditorSettings мог закрепить такое значение.
- `StageDesigner` держит фиксированный логический 390×844 portrait (или landscape ref) даже в низкой панели. Это правильно для игрового референса, но неудобно как экранный размер редактора: приходится вручную прокручивать одну картинку.
- `Story Map` тоже находится внутри ScrollContainer, у которого GraphEdit разрастается только до естественного min-height, даже когда справа есть свободное место.

## Изменения

1. Отслеживать высоту viewport `_workspace_scroll`, на каждом resize задавать `_workspace_body.custom_minimum_size.y >= _workspace_scroll.size.y`. При коротких окнах остаётся внутренний scroll (min 440px), без скрытия toolbar/status/path.
2. Сдвинуть default Stage/Inspector split в пользу **центрального Stage**, сохранить пользовательский draggable splitter через новое имя EditorSettings `vn_studio/raven_stage_pane_width_v2`. Предыдущее значение v1 (~390px) больше не блокирует новый default. Варианты ширины 800/1024/1366 сохраняют горизонтальный scroll при нехватке места.
3. В докованном Raven Director подгонять Canvas Stage к видимой области по масштабу min(width/referenceWidth, height/referenceHeight), не увеличивать больше 1×. Для portrait/landscape использовать точное соотношение сторон. **Сохранять прежние normalized (0–1) координаты actor/prop и референсный размер runtime**: уменьшается только отображение в Editor; standalone StageDesigner остаётся полноразмерным.
4. Для `Story Map` задавать min-height его графового workspace не меньше высоты доступного Tab/Scroll viewport: GraphEdit растёт на высоком окне, но при коротком остаётся прокрутка до кнопок и списка связей.
5. Новые CI smoke проверки `tests/raven/vn_studio_layout_smoke.gd` проверяют, что рабочий HSplit занимает доступную высоту при 800×640/1024×640/1366×640, портретный Stage сохраняет aspect ratio без 844px обязательного scroll, Story Map увеличивает GraphEdit при 1366×900.

## Критерии ручной QA

- Запустить Godot 4.7.2 (native Windows) → VN Studio → Raven Manor на исходном размере со скриншота. **Рабочие колонки должны тянуться почти до нижней строки пути черновика**, без пустой полосы ~180–200px между графом и нижним статусом.
- Сверить Stage Inspector, Translations, Asset Library, Story Map, Animation, Promotion Review. При переключении вкладок центральный Stage остаётся виден, списки сцен/реплик занимают высоту.
- На Stage выбрать `BG-HALL / evening / dusty`: **вся композиция** портретного фона помещается по высоте, а не только ковёр в нижней части; при смене orientation landscape сохраняется соотношение сторон, актёры/props остаются в тех же нормализованных координатах. Проверить drag с 1 и 2 персонажами, Undo/Redo, сохранение и повторное открытие.
- В Story Map проверить высокий viewport, панорамирование/zoom и видимые зелёные канонические/оранжевые draft провода; controls `+ Связь` доступны без визуального конфликта, при более узком окне есть scroll.
- Проверить 800×640, 1024×640, 1366×768 и размер со скриншота, а также свёрнутый Output. Рабочая область должна адаптироваться при изменении высоты встроенного Output/Debugger.
- Source SHA для канонических каталогов неизменен, сохранения/runtime/RavenReducer и UPDS донор не затронуты.

## Чего этот PR НЕ обещает

Семантическое и **pixel-perfect** совпадение с утверждённым HTML не доказано. Локальный оригинал найден Codex ранее: `C:/git/Raven_VN_Studio_Godot_Handoff_v5_2026-11-01/prototype/raven_vn_studio_v5.html` и `docs/02_PRODUCT_UX_AND_WORKFLOWS.md` из того же handoff. Для дальнейшей QA требуется side-by-side скриншоты HTML vs Godot при одинаковых viewport с явным перечнем отличающихся колонок, кнопок, инспекторов и asset workflows. Не объявлять «как HTML» только по green CI. Следующий VNS5-07F parity pass отдельный scope после native acceptance базовой высоты.

Не auto-merge; исходный `user://` draft и canonical assets менять нельзя.
