# UPDS → Raven Manor: утверждённый план переиспользования UI

Дата решения: 2026-11-03. Статус: **утверждённая архитектурная политика и план**, не доказательство реализации или визуального паритета.

Источники: `bezdredoff/UPDS-godot` (донор), `bezdredoff/RavenManor-Godot` (цель). Перед каждым PR фиксировать SHA донора и сверять конкретные функции. См. `UPDS_FIRST_REUSE_AUDIT_20261103_RU.md`.

## Утверждённые решения

1. **Skip строго как UPDS:** пропускать только ранее прочитанные реплики, останавливаться на непрочитанной реплике или контрольной точке выбора. Никогда не выбирать за игрока. Текущий Raven Skip, открывающий последнюю страницу текущей реплики, **не является эквивалентом**. Для полноценного переноса необходимы сохранённые ID прочитанных реплик и адаптер к Raven reducer/store.
2. **Максимальный перенос VN shell UPDS:** хедер, сцена, фон, имя, диалог, нижняя панель, адаптивность, overlays, ввод и поведение. Менять тему на Raven; не копировать историю, персонажей, сохранённые состояния или уникальные игровые механики UPDS.
3. **Все игровые UI в области переиспользования:** VN, меню, настройки, Match-3, HUD, ввод, переходы, help/tutorial, результаты, сохранения, уведомления и доступность.
4. **Draft PR #171** с самостоятельно написанной адаптивной нижней панелью **замещается планом**: не мержить как канонический UPDS shell, закрыть или заменить после переноса донорской компоновки.

## Матрица исходников и действий

| Система | UPDS-godot | Raven | Действие / приоритет |
|---|---|---|---|
| Полный VN shell, хедер, сцена, имя, диалог, нижние кнопки | `scripts/vn/vn_screen.gd`: `_ready`, `_layout_vn`, `_build_controls` | `scripts/raven/raven_vn_game_view.gd`, вложен в технический `vertical_slice.gd` | Выделить/перенести UI, убрать debug wrapper из игрового режима — P0 |
| Мобильная адаптация, клавиатура, касания | `vn_screen.gd`: `_layout_vn`, `_on_dialogue_gui_input`, `_unhandled_key_input`; `scripts/ui/phone_frame.gd` | Собственный layout и Next | Перенести правила, проверить safe area и отсутствие двойного ввода — P0 |
| Пагинация, точки, индикатор | `scripts/vn/dialogue_paging.gd`, `vn_screen.gd` | Уже используется `scripts/shared/upds/dialogue_paging.gd` | Сохранить общее ядро, перенести отображение — P0 |
| Auto / Skip | `vn_screen.gd`: `_schedule_auto`, `_skip_read_lines`, `_is_choice_checkpoint` | Простой таймер, Skip текущей страницы | Перенести логику прочитанного текста, блокировки на выборе и overlay — P0 |
| Выборы и переходы | `vn_screen.gd`: `_build_choice_screen`, `_choose` | Raven director/reducer | Перенести представление, сохранить Raven authority — P0 |
| История | `vn_screen.gd`: `_show_history`, `scripts/core/story_session.gd` | Только история текущей сцены в AcceptDialog | Постоянная история + overlay — P1 |
| Настройки и предпочтения | `vn_screen.gd`: `_show_config`; `scripts/ui/settings_screen.gd`, `player_preferences.gd` | VN Settings открывает выбор языка | Перенести скорость Auto, размер текста, аудио, доступность; адаптер RU/EN/BE — P1 |
| Сохранение и загрузка | `vn_screen.gd`: `_save_manual`, `_load_manual`; `scripts/core/{campaign_store,save_format,save_storage}.gd` | Raven snapshot/store; `scripts/core/save_storage.gd` | Переиспользовать UI/валидацию, не заменять Raven schema — P1 |
| Модальные окна, стили, шрифты, scroll | `vn_screen.gd` overlays; `scripts/ui/{touch_scroll_container,ui_fonts,menu_theme,css_motion}.gd` | В основном отдельные виджеты; `scripts/ui/css_motion.gd` | Выделить общие UI-компоненты, Raven theme — P1 |
| Главное меню и навигация | `scripts/ui/{main_menu,main_menu_layout,phone_frame}.gd` | Raven prototype/hub | Функциональное сопоставление и перенос подходящих частей — P0 |
| Match-3 правила, экран, анимации | `scripts/match3/{match3_game,match3_screen,match3_tile_motion_layer}.gd` | Shared UPDS rules + Raven presenter/motion | Сохранить shared rules, сверить UI, жесты, HUD — P0 |
| Match-3 help, tutorial, intro, campaign, reactions | `scripts/match3/{match3_help_overlay,match3_tutorials,match3_level_intro_screen,match3_campaign_screen,match3_reaction_runtime}.gd` | Raven UI и shared tutorials | Функциональный аудит, затем extraction/adaptation — P1 |
| Фоны, портреты, анимации, reduced motion | `scripts/vn/vn_background_fill.gd`, portrait rig, `scripts/core/reduced_motion.gd` | Raven approved art и FX | Выборочно переносить, сохранить утверждённые ассеты и постановку — P1 |
| Концовки и досье | `scripts/ui/ending_view.gd`, `vn_screen.gd`: `_show_dossier` | Аналог не подтверждён | Адаптировать под концовки и журнал Manor при появлении контента — P2 |

**Границы доказательств:** VN проверен на уровне конкретных функций. Меню, Match-3, сохранения и платформенные компоненты пока инвентаризированы по исходникам, но не прошли полное функциональное сравнение. Нельзя автоматически маркировать их как отсутствующие или готовые.

## Очередность

- **Wave 0 / P0:** закрепить SHA донора, матрицу зависимостей, golden screenshots и контрольные точки выбора; определить формат read-line history. Разделить игровую VN и технический прототип.
- **Wave 1 / P0:** полный VN shell UPDS с Raven адаптерами; не создавать параллельную систему layout.
- **Wave 2 / P0:** read-only Skip, choice-aware Auto, выборы, защита от двойного ввода; тесты сохранений и сюжетных событий.
- **Wave 3 / P1:** история, настройки, ручные Save/Load, overlays, локализация и доступность.
- **Wave 4 / P0–P1:** главное меню, Match-3 экран, intro/help/tutorial, HUD, переходы, общие UI.
- **Wave 5 / P2:** концовки и Manor journal на основе соответствующих UPDS-компонентов.

## Обязательные критерии для каждого implementation PR

1. Donor path, **точный commit/blob SHA**, перечень функций, зависимостей и решение `reuse-as-is / extract / adapt / not-applicable`. Переписывание вместо переноса требует обоснования.
2. Тесты 320/340/360/390/430 px, landscape/desktop, RU/EN/BE и длинных реплик, если затрагивается экран.
3. Проверка Auto/Skip, first-read vs reread, choice checkpoints, overlay, save/load, фокуса и касаний для соответствующих компонентов.
4. Не менять без согласования Raven reducer, утверждённые фоны/персонажей, FX и VN Studio data.
5. В том же PR обновить `docs/STATUS.md` и `data/raven/production/production_progress.json` с правдивым статусом и evidence. Не считать административные счётчики функциональными блокерами.

## Открытые решения до реализации

Точный формат сохранённой истории read-line IDs и миграция старых save; источник контрольных точек; число ручных слотов; платформенная поддержка аудио/haptics; developer-only debug shell; смысл Manor journal. Это вопросы проектирования, не разрешение произвольно менять поведение.

**Не копировать целиком большой `vn_screen.gd` вместе с сюжетом и состояниями UPDS.** Требуется максимально полный перенос *проверенных UI-компонентов* и минимальные Raven-адаптеры.
