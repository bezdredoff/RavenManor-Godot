# Raven Manor — фиксация положительной ручной QA от владельца

**Дата сообщения:** 2026-11-03. **Основание:** после мержа #153 владелец сообщил в текущем проектном чате: «Проверки выполнены и всё хорошо». До этого были предложены проверяемые сценарии VN Studio, RU/EN/BE, безопасного phone ZIP и проверки интерфейсов/устройств. Это **owner attestation**, а не автоматически созданные логи, вложенные скриншоты или данные телеметрии.

**Что сделал этот PR:** учёл положительный результат по завершённым, узко определённым QA-пакетам. Оставил открытыми широкие блокеры, для которых успех указанного сценария сам по себе не доказывает все критерии — особенно chibi, Hall/map, Match-3 и полноценный вертикальный срез.

## Принято как законченная scoped QA

| Задача | Новый статус | Что подтверждено / не переписано |
|---|---|---|
| **VNS5-09** | **accepted**, manual_verified, feature_approved | Ручная приёмка текущего workflow VN Studio: BG-HALL, 1–3 composite heroes, narrator, RU/EN/BE, reorder, save→restart→reopen, A/B/C QA branch + FX и Undo/Redo. Технический smoke в merged #147. **Не** принимаются этим шагом standalone VN prop catalog, точная HTML-v5 pixel parity или runnable branching в игре |
| **LOC-EN-QA** | **accepted**, manual_verified, feature_approved | Редакторская/UX приёмка английской локали, разметки и переключения; существующий перевод #135 остаётся без изменений |
| **LOC-BE-QA** | **accepted**, manual_verified, feature_approved | Редакторская/UX приёмка белорусской локали, включая ў/і; существующий перевод #136 остаётся без изменений |
| **RM-GAP-013** | **accepted**, manual_verified, feature_approved | Сквозной owner PASS RU/EN/BE в текущем игровом и редакторском UI; текст, переключение языков и ожидаемое сохранение курсора. Отдельный финальный Hall QA по `GFX-11-T08` не поглощается |
| **PROC-003** | **accepted**, manual_verified, feature_approved | Безопасный контракт и workflow загрузки ZIP с телефона, positive/negative incoming→candidate PR; имеющиеся Actions #40554280539 и #41417364700 / cleanup PR #110 сохранены как технические подтверждения. **Не** принимается полный security matrix/device/preview/stable-release `MOB-04` |

**Ограничение evidence:** в новом сообщении **не** были приложены конкретные screenshots, viewport/build/OS таблицы, полный список визуально сравнённых экранов, устройства, хэши новых архивов или URL свежих запусков. Их нельзя выдумывать. Положительную *субъективную* оценку UX фиксируем как прямое решение владельца; требующие артефактов другие QA-gates не закрываем молча.

## Результат для незавершённых пакетов

| Задачи / поток | Что принято на словах | Почему они ещё открыты |
|---|---|---|
| `VNS5-07F/07F2`, issue **#129** | Owner сообщает, что просмотренный интерфейс выглядит хорошо | Для исторически заявленного **exact HTML-v5 screenshot parity** нужны оригинальный HTML reference, идентичные viewport screenshots и control-by-control comparison; не утверждать pixel parity без артефактов |
| `GFX-11-T08`, `GFX-03-05`, `GFX-05-08` | Owner прошёл предложенные визуальные проверки | Финальный Hall device/VN geometry, все сценовые cast safe zones и per-scene variants требуют точных screenshot/acceptance evidence |
| `MOB-04` | Обычный валидный/невалидный phone ZIP handoff работал | Нужно подтверждение всех adversarial cases, stale-base/forbidden paths/symlink/casefold и безопасного post-merge результата; playable preview origin отдельно |
| `RM-GAP-002`, `RM-GAP-010`, `CODE-10-01/02`, `GFX-06-09` | Owner не сообщил о проблемах при недавних ручных проверках | Чтобы закрыть **полную** device матрицу, нужны фактические device/OS/resolution/motion/offline/stylus/recovery results; пользовательское сообщение не перечисляет их |
| `CODE-02-06`, `CODE-05-01/02`, `RM-GAP-001/006`, `GFX-07-*`, `CODE-11-01`, `GFX-11-T09` | Положительная оценка проверок редактора/языков/ZIP | Это другие задачи: реальные input/hints/help, физический Hall, chibi, карты, full vertical slice и phone integration. **Не** заявлять завершение несуществующего арта/кода |

## Снимок и следующие шаги

- До owner QA: 238 задач, **13 активных P0, 65 активных P1, 44 открытых P2**, всего 122 открытых.
- После принятия **четырёх открытых P1** (`LOC-EN-QA`, `LOC-BE-QA`, `RM-GAP-013`, `PROC-003`) и ранее `merged` VNS5-09: 238 задач, **13 P0, 61 P1, 44 P2**, всего **118 открытых**. VNS5-09 меняется `merged → accepted` и не влияет на число открытых.
- Два stream-контейнера теперь имеют по одной задачe: `WS-LOCALES` → `GFX-11-T08`, `WS-MOBILE-HANDOFF` → `MOB-04`. Все **74 актуальные P0/P1** по-прежнему назначены одному из 10 потоков.
- Исторические планы CODE/GAP/GFX, `p2_reentry_policy.json` и artifact acceptance 26 approved VN backgrounds / 62 approved composites неизменны.

Для дальнейшего закрытия screenshot/device-sensitive задач достаточно добавить ссылки на уже сделанные скриншоты и фактические названия устройств — **повторять пройденные тесты не требуется**. В следующем PR с этим evidence можно целенаправленно закрыть оставшиеся acceptance gates.
