# GAME-UI-01 — главное меню: UPDS-first сверка и ограниченный фикс failure-режимов

Task IDs: GAME-UI-01 (домен ui-shell), срез GAME-UI-01-shell-parity; связанные CODE-04-01, GAME-QA-01. База — origin/main 368a070 и авторский draft PR #156 (initial main menu, Raven save-backed New/Continue, RU/BE/EN settings, one-tap Prototype Lab).
Changes: Сверка главного меню Raven с донором UPDS (`bezdredoff/UPDS-godot`) по принципу UPDS-first и фикс ограниченного набора расхождений в одном файле оболочки `scripts/raven/main_menu.gd`: (1) постоянная строка статуса сохранения `SaveStatus` для отказа чтения и восстановления повреждённого сейва (семантика `_update_continue()`/`status` в донорском `scripts/ui/main_menu.gd`); (2) блокировка Continue при нечитаемом/повреждённом сейве и донорская подача disabled-состояния (alpha 0.38 поверх normal-surface); (3) New Game запрашивает подтверждение и при нечитаемом сейве, а не только при наличии прогресса; (4) возврат фокуса на действие «Настройки» после закрытия панели настроек; (5) локализация оставшегося английского литерала об ошибке сброса прогресса (RU/BE/EN). Добавлен новый blocking smoke `tests/raven/main_menu_upds_parity_smoke.gd` и по одной строке регистрации в `check.ps1` / `scripts/check.sh`. Полный gap-список по остальным расхождениям зафиксирован ниже; геометрия/визуальный слой, settings-screen и версии требуют отдельного среза или интеграционной зоны.
Verification: EXECUTED_PASS на этой машине (Godot 4.7.2 stable, Windows): новый `main_menu_upds_parity_smoke.gd`; существующие `main_menu_smoke.gd`, `main_menu_match3_campaign_smoke.gd`, `runtime_settings_smoke.gd`; полный `check.ps1` — см. раздел «Verification (фактический вывод)» ниже. NOT_RUN: GitHub Actions на точном head SHA, web/mobile Chromium, физические устройства, визуальный pixel-review.
Owner QA: См. нумерованный список в разделе «OWNER MANUAL QA» ниже; закрытие GAME-UI-01 остаётся за владельцем.
Status impact: GAME-UI-01 остаётся status=in_progress, priority=P0, implementationState=partial, qaState=not_started, approvalState=pending. Добавлено только evidence о выполненной сверке и о проверенном ограниченном срезе; merge, accepted и device-QA не заявляются.

## Donor provenance (UPDS-first gate)

Локальная копия донора `C:/Users/bezdr/Downloads/godot-upds` **не является git-репозиторием** (каталог без `.git`), поэтому git commit/path blob SHA для неё недоступны. Вместо выдуманного SHA зафиксированы SHA-256 просмотренных файлов; происхождение — локальная копия UPDS-порта, датированная 2026-10-21. Историческая сверка в shard для Match-3-маршрута ссылается на `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`; совпадение этой локальной копии с данным коммитом не проверено (UNKNOWN) и не утверждается.

| Файл донора | SHA-256 |
| --- | --- |
| `scripts/ui/main_menu.gd` | `0d6a932b0c26c42770394068c270f76a92f6a737659c31e58f653b80e9dc9225` |
| `scripts/ui/menu_copy.gd` | `749edd91836836b17575cd88c1bbde791803b9e61673b466771a9f3ffbc46f33` |
| `scripts/ui/main_menu_layout.gd` | `605a619dca5daedd1eec27d79c7ee6aa8990d015c7f88c11ca4e5d5f8c1aaf79` |
| `scripts/ui/menu_theme.gd` | `c1a347ac97ea9cb0ff3cc7d607a618184ae3a143f25a9a4d13164212d2ae5518` |
| `scripts/ui/phone_frame.gd` | `c643d48345bdcace3dde13e3a862c0ae05dcb810e055991230aef1fc4267b526` |
| `scripts/ui/settings_screen.gd` | `fa6dfd4d5ec3538db042f06469a72e2e29d01e8c71c1d52b15f0aff6fc4bb764` |
| `scenes/main_menu.tscn` | `eec35b0bcf002963a9872a324c7d30f54610c27425d3644de149d3798c10dca5` |

Raven-базис: `scripts/raven/main_menu.gd` (251 строка до правки), `scenes/raven/main_menu.tscn` (голый `Control` без узлов), `scripts/raven/raven_settings_dialog.gd`, `scripts/raven/raven_menu_copy.gd`, `tests/raven/main_menu_smoke.gd`, `tests/raven/main_menu_match3_campaign_smoke.gd`, `tests/raven/runtime_settings_smoke.gd`.

## Gap matrix: donor ↔ Raven PR #156

Класс: `fixed` — исправлено в этом PR; `adapt` — переносимо адаптером, отдельный срез; `blocked` — требует интеграционной зоны или прав/арта; `n/a` — расхождение осознанное.

| # | Область | UPDS donor | Raven (базис #156) | Класс | Где дорабатывать |
| --- | --- | --- | --- | --- | --- |
| 1 | Строка статуса сейва (отказ чтения, восстановление после порчи, недоступная позиция) | `main_menu.gd::_update_continue()` → `MenuCopy.text("story_save_error"/"story_load_error"/"story_recovered"/"story_position_unavailable")`, узел `SaveStatus` | нет; `_has_progress()` молча возвращал «нет прогресса» | `fixed` (кроме «позиция недоступна») | `scripts/raven/main_menu.gd` |
| 2 | Подача disabled Continue | alpha 0.38 на всём контроле + `disabled` stylebox = `normal` (`menu_theme.gd`) | только `disabled = true` на дефолтной теме | `fixed` | `scripts/raven/main_menu.gd` |
| 3 | New Game при нечитаемом/повреждённом сейве | подтверждение и при `load_report.detail == "storage-read-failed"` / `status == "recovered-corrupt"` | подтверждение только при наличии прогресса → сейв перекрывался без вопроса | `fixed` | `scripts/raven/main_menu.gd` |
| 4 | Фокус после закрытия экрана/панели | `grab_focus()` на Continue/NewGame/Settings (`_close_story`, `_close_campaign`, `_close_settings`) | фокус терялся | `fixed` (только путь настроек главного меню) | `scripts/raven/main_menu.gd` |
| 5 | Локализация ошибки сброса прогресса | копии в `menu_copy.gd` | жёсткий английский литерал `"Could not reset game progress"` | `fixed` | `scripts/raven/main_menu.gd` |
| 6 | Композиция: eyebrow / двухцветный заголовок / tagline / hero-медальоны / backdrop-шейдер + gradient wash / phone-frame 430×932 / phone shadow >430px | `scenes/main_menu.tscn`, `main_menu_layout.gd`, `phone_frame.gd` | плоский `Column` + webp-фон `road/dusk_mist.webp` + `ColorRect` затемнение, без шейдеров и адаптивных брейкпоинтов | `adapt` + `blocked` (арт/права) | новый Raven-адаптер компоновки (`scripts/raven/…layout.gd`) + `scenes/raven/main_menu.tscn`; UPDS-арт персонажей переносить нельзя без rights review |
| 7 | Адаптивная геометрия (narrow ≤340 / compact ≤760, title 34/38/44, hero 56/66/78, кнопки 44/49, separation 6/9) | `main_menu_layout.gd::apply()` | фиксированные 52 px, `custom_minimum_size.x = 270`, margin 24 | `adapt` | тот же layout-адаптер; проверить на 320/340/360/390/430 |
| 8 | Экран настроек | отдельный `settings_screen.gd` (816 строк): секции, capability-строка haptics, блок NAVIGATION с «Главное меню» и разным предупреждением (безопасно / «текущая попытка будет потеряна»), `z_index = 256` поверх Match-3, `navigation_copy` | две копии UI: inline-панель в `main_menu.gd` и `raven_settings_dialog.gd` (Window) в слайсе; нет блока навигации и предупреждений | `adapt` | `scripts/raven/raven_settings_dialog.gd` + `main_menu.gd` + call-sites слайса (≥2 файла, дублирование уже помечено в `docs/architecture/MULTI_AGENT_DATA_CONTRACTS_RU.md`, п.3) |
| 9 | Подтверждение новой игры как карточка | overlay `NewGameConfirmation` (eyebrow, title, copy, две кнопки: «Begin case» / «Keep reading») | нативный `ConfirmationDialog` (text/ok/cancel), без eyebrow/title | `adapt` | новый overlay-контрол в оболочке меню; визуальное принятие — владелец |
| 10 | Версия сборки в футере | `Content/Footer` = `"v" + CONTRACT.data.appVersion` | нет источника версии: `data/save_contract.json` содержит только ключи сейва, `project.godot` не задаёт `application/config/version` | `blocked` | `project.godot` или `data/save_contract.json` — интеграционная зона, отдельный PR интегратора |
| 11 | Уведомление «сохранённая позиция недоступна в этой сборке» | `story_position_unavailable` | `raven_snapshot.gd` молча отбрасывает невалидный `vnCursor`/`match3Checkpoint` | `blocked` | `raven_snapshot.gd`/store — single-writer интеграционная зона |
| 12 | Маршрут Match-3 | `campaign_requested` → встроенный `Match3CampaignScreen` + `Match3LevelIntroScreen` + цепочка next-level + dossier | действие `Match3Levels` → one-shot meta + `vertical_slice.tscn` optional campaign (адаптер, PR по GAME-M3-01) | `n/a` (осознанный адаптер) | проверять в слайсе, не в меню |
| 13 | Хост-сигналы меню | `new_game_requested` / `continue_requested` / `settings_requested` и общие сцены | меню — самостоятельная сцена, прямой `change_scene_to_file` | `n/a` (архитектура Raven-сцены) | — |
| 14 | Дополнительные действия | нет | `PrototypeLab`, `HowToPlay` (onboarding), `Match3Levels` | `n/a` (Raven-скоуп; Lab — one-tap по требованию владельца) | — |
| 15 | Дефолтная локаль меню | `en` | `ru` (`raven_menu_copy.gd`) | `n/a` (продуктовое решение) | — |

## Что именно изменено (bounded scope)

- `scripts/raven/main_menu.gd` (единственный файл оболочки):
  - `SaveStatus` — новый `Label`, видимый только при `storage-read-failed` или `recovered-corrupt`; текст берётся из копий RU/BE/EN и перерисовывается на смене локали.
  - `_has_progress()` теперь сохраняет `store.last_load_report` в `save_report`; добавлены `_snapshot_has_progress()` и `_save_is_unknown()`. Состояние кампании по-прежнему читается только через `RavenCampaignStore`; права записи не менялись.
  - `_new_game()`: `confirm.popup_centered()` при прогрессе **или** неизвестном сейве.
  - `_refresh()`: донорская подача disabled (alpha 0.38) + `disabled` stylebox = `normal` на действиях.
  - `_close_settings()`: `grab_focus()` на действии «Настройки».
  - `_reset_and_start()`: локализованный текст ошибки (индекс 23) вместо английского литерала.
- `tests/raven/main_menu_upds_parity_smoke.gd`: свежий сейв (строка скрыта, Continue заблокирован, alpha 0.38, stylebox-parity, ничего не записано), возврат фокуса, повреждённый сейв (recovery-строка RU/EN/BE, Continue заблокирован, резервная копия читается, New Game требует подтверждения), отказ чтения (`ReadFailStorage`, строка RU, подтверждение, локализованная ошибка сброса), валидный сейв (status `loaded`, Continue активен, alpha 1.0, лишних ключей не появляется).
- `check.ps1`, `scripts/check.sh`: по одной строке регистрации нового smoke.

Интеграционная зона (`raven_reducer.gd`, `raven_campaign_store.gd`, `raven_snapshot.gd`, `raven_ids.gd`, `project.godot`) — только чтение, правок нет.

## Verification (фактический вывод)

Машина: Windows 11, git-bash; Godot `4.7.2.stable.official.ed1daf0bf`, консольный бинарник `C:/Users/bezdr/Downloads/VRExperiments/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`. Каталог: `C:/Users/bezdr/RavenManor-Godot/.worktrees/w3-shell` (worktree, base `368a070`).

- `EXECUTED_PASS` новый smoke: `--headless --path . --script res://tests/raven/main_menu_upds_parity_smoke.gd --quit-after 180` → `Raven main menu UPDS failure-mode parity smoke passed`.
- `EXECUTED_PASS` существующие: `main_menu_smoke.gd` → `Raven Manor main menu and Prototype Lab navigation smoke passed`; `main_menu_match3_campaign_smoke.gd` → `Raven main menu Match-3 campaign entry smoke passed`; `runtime_settings_smoke.gd` → `Raven runtime settings persistence, modal and locale smoke passed`.
- `EXECUTED_PASS` полный прогон: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File check.ps1 -GodotPath "<бинарник>"` → `exit=0`, 85 строк `... passed.`, включая `Project import passed.`, `Main menu settings smoke passed.`, `Main menu UPDS failure-mode parity passed.`
- Наблюдение окружения (не дефект этого PR): локальный `check.ps1` не идемпотентен по `user://vn_studio_conversions/v1` — `VN Studio conversion dry-run and export` намеренно отказывает, если экспорт уже существует. Первые два прогона упали именно на этом шаге (stale synthetic export от 2026-11-07); каталог `v1` переименован в `v1.pre-20261108` / `v1.pre-150734` (не удалён), после чего полный прогон прошёл.
- `NOT_RUN`: GitHub Actions на точном head SHA; браузерная (Chromium) и мобильная проверка; физические устройства; визуальный/pixel-review; скриншоты.

Локальные тесты выполнялись на сцене `scenes/raven/main_menu.tscn` с in-memory storage (`tests/support/memory_storage.gd`) и отдельным файлом настроек `user://raven_main_menu_upds_parity_smoke.cfg` (удаляется тестом); реальный `user://`-сейв кампании тестами не затрагивался.

## OWNER MANUAL QA (для закрытия GAME-UI-01 после merge)

Ни один пункт не выполнен и не заявляется как выполненный. Ожидаемые пути: сейв кампании — `%APPDATA%/Godot/app_userdata/Raven Manor/campaign_saves/raven-manor-campaign-v1.json`, recovery — `...-v1:recovery-v1.json`.

1. Windows, 390×844, чистый профиль: меню открывается, «Продолжить» приглушена (alpha ≈ 0.38), но подпись остаётся читаемой; строка статуса сейва отсутствует.
2. Сыграть несколько строк, выйти в главное меню: строка статуса отсутствует, «Продолжить» активна и не приглушена.
3. Испортить сейв (вписать в файл невалидный JSON), запустить игру: под кнопками видна строка «Сохранение повреждено. При возможности сохранена резервная копия.» на выбранном языке; «Продолжить» заблокирована; recovery-файл существует.
4. В том же состоянии нажать «Новая игра»: появляется подтверждение (игра не стартует сразу); «Отмена» возвращает меню; «Начать» сбрасывает прогресс и открывает гайд.
5. Проверить строку статуса на 320×568, 360×640, 390×844, 430×932 в RU/BE/EN: переносится, не обрезается, не перекрывает кнопки.
6. Настройки → переключить язык RU→BE→EN → «Назад»: после закрытия фокус стоит на кнопке «Настройки» (проверить клавиатурой и геймпадом).
7. Отказ чтения сейва (сделать файл нечитаемым, например каталогом с тем же именем): при запуске строка «Не удалось прочитать сохранение. Сохранённые данные не изменены.», Continue заблокирована, New Game требует подтверждения; после подтверждения ошибка сброса показана на выбранном языке, а не по-английски.
8. Визуально зафиксировать, что композиция меню (eyebrow/двухцветный заголовок/tagline/hero-медальоны/phone-frame/шейдер-фон/карточка подтверждения/версия сборки) всё ещё отличается от UPDS — это открытые пункты 6–10 gap-матрицы, не регресс этого PR.

## Ограничения и риски

- Сверка сделана по локальной копии донора без git-истории: привязка к `UPDS-godot@main` не подтверждена коммитом.
- `SaveStatus` проверен headless-smoke, но реальная читаемость на 320 px (перенос строки на BE-копии) — только владельческая визуальная проверка.
- Пункты 6–11 остаются открытыми: два из них требуют интеграционной зоны, остальные — отдельного среза оболочки; сведение `main_menu.gd` и `raven_settings_dialog.gd` к одному экрану настроек — следующий логичный шаг.
