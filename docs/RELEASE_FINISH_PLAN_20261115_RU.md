# Raven Manor — finish-line plan для завершения Season 1
**Статус:** план-предложение для owner review; НЕ изменяет approved canon, статусы или runtime.  
**Аудит:** 2026-11-15, main 8f931c37b049a6a6c13eb35edf81a690ece9ede4, PR #265 merged; открытых PR 0; latest main Actions run 43762839236 SUCCESS.  
**Источники:** docs/DECISIONS.md, docs/NEXT_PLAN.md, docs/changes/CODE-08-01-season1-audit.md, docs/process/AGENT_ORCHESTRATION_RU.md, 15 live progress shards, main/GitHub PR #255–265.

## 0. Что именно считаем готовой игрой
**Предлагаемый релизный контракт S1:** законченный первый сезон по уже зафиксированным шести главам, без сочинения нового сюжета. 27 обязательных сцен из существующего каталога + одна сцена 06-POST как необязательный бонус (всего 28), три уже существующих сюжетных уровня RM-LVL-001..003, существующая экономика work_points/две реставрации как совместимый фундамент, существующие 22 optional Match-3 уровня как необязательный режим без сюжетных наград. Все три локали RU/BE/EN. У сезона есть явный финал и понятное поведение Continue после титров. Никаких новых глав, полноценных map-этажей или дополнительных обязательных игровых уровней.

**Минимальная исследуемая карта:** Hall, Corridor, Bedroom, Archive/Library, Kitchen на уже утверждённой карте первого этажа, плюс Bathroom только как vignette. Для первого gameplay gate обязательны Hall↔Corridor (HC), Corridor↔Bedroom (CB); HA (Hall↔Archive) и CK (Corridor↔Kitchen) добавляются **только тогда**, когда их реально требует достижимая сцена. Garden/Conservatory/Entry/Road/Apartment допускают существующие VN backgrounds, сюжетные переходы и явные hotspot/focus interactions без притворства, что неутверждённые зоны карты доступны для физической ходьбы. Любое такое упрощение требует owner подтверждения соответствия сценарию. Остальные 11 физических door candidates НЕ становятся проходимыми автоматически.

**Визуальный бюджет:** существующие утверждённые 62 VN frames и 26 backgrounds — основной материал; не перегенерировать их. Разрешены только (a) согласованные door/floor/foreground маски для реально используемых HC/CB/HA/CK, (b) один канонический Evelyn mildly-chibi walker с idle/walk и ногами в каждом кадре, (c) точечные критические runtime-ассеты или одобренные fallback для пропущенных pose×emotion. Не требуется полноценный NPC walker-пакет, 3D-перестройка дома, массовая генерация props или новая анимационная система.

**Do not start:** второй этаж, свободный tap-to-move, новый Room Builder/VN Studio редактор, VN prop catalogue, перенос на другой движок, 3D-навигация, дополнительные сюжетные M3 уровни, отдельная валюта звёзд, новые monster reveals, шоп/монетизация, новый asset pipeline, большие UI refactors без блокирующего дефекта, фанатичное HTML-v5 pixel parity, публикация handbook/builder. Шлифовка только после прохождения функциональных gates.

## 1. Доказанная отправная точка и риск
- Main после PR #265, CI+Pages SUCCESS (run 43762839236). #262, #263, #264, #265 слиты. Открытых PR — 0, GitHub Issues — 5 (широкие исторические acceptance issues; не равны пяти оставшимся задачам).
- Есть native Route Editor/freehand/editable NO-GO (#251–255), 08B route draft (#257), 09B 34-waypoint/29-route TEST_ONLY opening blueprint (#261), физическая экспертиза 11 реальных дверей (#258); **нет утверждённой production-геометрии/порогов**.
- Есть изолированная hotspot→Match-3→VN QA петля (#259), fail-closed navigation source (#260), но bridge ещё использует отдельный greybox graph/session и живой Continue не маршрутизирует сохранённую комнату/anchor.
- Аудит CODE-08-01: **8/28** сцен исполняется legacy RM-VS-01, **20/28** не исполняется, **0/28** выбирается production VN dispatch; 19 сцен отсутствуют в storyBeats save-каталоге. Механические блокеры включают JSON ordinal float/int, unsupported gate kinds, draft statuses, портретные комбинации, 2 manual cue reviews и 1 offstage speaker case. Это главный объём Season 1, который нельзя назвать завершённым из-за готового Studio.
- Настройки, UPDS shell, RU/BE/EN, 3 story + 22 optional M3, audio/boosters существуют как технические поставки, но конечные устройства, save failure/resume и арт остаются acceptance gates.

## 2. Release-blocking backlog — не дублировать 216 live записей
| Доставка | Existing IDs / ownership | Зависимость / результат |
| --- | --- | --- |
| R0. Зафиксировать релизный контракт, объявить stop-list | integration coordinator; GAME-LOOP-01, CODE-08-01 | Owner отвечает только на scope/геометрию/критические art fallback; без изменения live statuses из-за этого плана |
| R1. Один navigation source для hotspot bridge | GAME-LOOP-01 / CODE-05-02; integration single writer | #259 + #260 → единые graph/session/transition, QA opt-in, production fail closed, arrival recheck, cancel/gates |
| R2. Физически обоснованные HC/CB, затем HA/CK по факту сцены | CODE-05-01/02, RM-GAP-001/006; GFX-11-T04/T07 | Owner-approved image, near/far feet, 65° elevation, collision, foreground, locks, reverse, no XY jump |
| R3. Production Hall→Corridor→Bedroom loop + save/Continue | GAME-LOOP-01, CODE-07-02, CODE-11-01, GAME-UI-01 | Ровно один reducer/store, отыгрывание VN/M3, idempotent rewards, safe room anchor after restart; backup/corrupt recovery |
| R4. Все обязательные главы через production VN dispatch | CODE-08-01, VN-RUNTIME-01, CODE-03-01/02/03 | Decimal ordinal parse, finite supported gates, scene approvals **после** review, 19 beat IDs/catalog/save migration, branch/FX/offstage/fallback QA; wave II–III → IV → V–VI |
| R5. Evelyn walking art вместо Onoe | GFX-07-01/05/06/09/10, GFX-11-T06 | VN-identity consistent hair/outfit; legs visible each frame; same feet pivot; idle/walk 4 facing directions where actually needed; reduced-motion fallback, owner approval |
| R6. Минимально необходимый UI/feedback, props и доступность | GAME-UI-01, CODE-02-06, CODE-07-01/02, GFX-11-T04/T07 | New/Continue/Settings, objective affordance, clear gates/repair feedback, readable 3 story M3 and touch help, only critical scene props |
| R7. Release QA, build and evidence | GAME-QA-01, GFX-11-T08/T09, CODE-10-01, PROC-008, CODE-11-01 | Windows desktop, Web desktop, real portrait touch, RU/BE/EN, offline/refresh/save, full 27-scene completion, no stuck gate or duplicate reward |

**Overlap rule:** 17 current P0 live entries are not 17 independent feature PRs. Geometry IDs CODE-05-01/02 + RM-GAP-001/006 describe a shared deliverable; GFX-07 and GFX-11-T06 converge on one Evelyn asset; GAME-QA-01/CODE-11-01/GFX-11-T09 converge on one E2E acceptance run. Closed/merged historical entries must NOT be reopened solely to fill a release list.

## 3. Пять параллельных AI потоков (один integration owner)
| Поток | Роль, write boundary | Первый независимый PR / строгий результат |
| --- | --- | --- |
| A — **Navigation & environment** | manor-map + room-builder + environment/map props. Edit QA/geometry/art data only; no reducer, shared bridge, live save, project.godot | HC/CB physical evidence and minimal approved art/footpoint/collision proposal; HA/CK deferred until mapped to scene |
| B — **Game integration & persistence** | campaign-core / restoration **единственный интегратор**. Owns shared nav bridge, production scenes, save/reducer/catalog, user action IDs | unify bridge/source WITHOUT production enable; then source opt-in and atomic save/Continue with approved map |
| C — **Narrative & VN content** | vn-runtime + localization; content-only files, per-scene contracts and tests first. Do NOT modify B's save/catalog or vertical_slice concurrently | Chapter II–III executable scene package, existing RM-* IDs, tri-locale & gate/asset matrix, then chapters IV and V–VI |
| D — **Evelyn & targeted art** | chibi-animation + character-art; separate candidate spritesheets, pivots, provenance, animation harness | one VN-faithful Evelyn walker and owner screenshot acceptance; no Onoe replacement until approved |
| E — **QA, UX & release** | qa-infrastructure + ui-shell + match3; initially QA-only tests/harness and docs; main menu/vertical_slice changes go via B | acceptance automation, 3 locale × viewport, M3/input, save failure, offline/browser; later bounded UI fixes |

No more than **five active agent worktrees**, no two writers on one file. Across each stream, **max one reviewable PR in flight**, rebase onto main after upstream merge; shared files (foundation_catalog, map_narrative_routes, vertical_slice, snapshot/store/reducer, project.godot, workflows, index status) belong to B/integration window. Agent may inspect other streams read-only. Same task ID → continue existing PR instead of duplication. All instructions in AGENTS.md and docs/process/AGENT_ORCHESTRATION_RU.md apply.

## 4. Очерёдность по gates: не переходить дальше без DoD
### G0 — scope lock (doc-only, без runtime изменений)
- Утверждены обязательный сезон и жанровые non-goals, назначены A–E, выбран один integration owner.
- Отмечены HC/CB как минимум и условия HA/CK; непроверенная геометрия НЕ объявляется APPROVED.
- Backlog помечается operational must/conditional/defer в этом документе; live task shard statuses меняют только владельцы доменов на основании фактов.

### G1 — безопасные контракты (параллельно A/C/D/E + B)
- B: один nav source, безопасная остановка при unavailable_geometry, проход тестов in-memory без изменения production switch.
- A: обзор HC/CB openings, feet/elevation/art masks; **owner geometry approval** до production activation.
- C: сценные листы, статусы/gates/IDs/asset fallback plan; все 280 реплик сохранены; никакой массовой автопубликации draft сцен.
- D: chibi кандидат и кадры на реальном map viewport.
- E: smoke coverage + чеклист реального устройства; не заменять физическую QA симуляцией.

### G2 — первый канонический gameplay loop (только после G1)
- B принимает утверждённые HC/CB и чётко авторизованный production source. Игра стартует из обычного меню, а не F6.
- Hall↔Corridor↔Bedroom, hotspot→route→arrival→VN/M3→reducer, lock/unlock, cancellation, paused/restart, Continue/New Game and recovery pass.
- QA: реальный Web/Windows+portrait экран, RU/BE/EN, повторное прохождение не дублирует reward. **MVP slice accepted**; не считать это финалом шести глав.

### G3 — сюжетные волны, без новых систем
- C готовит главы II–III; B последовательно подключает и проверяет runtime dispatch, save catalog/gates. Далее главы IV, V–VI.
- A добавляет HA/CK **только** если одобренный эпизод без них нельзя честно проиграть. У неотображённых локаций — VN/focus transition с user-approved staging, не выдуманный маршрут.
- Для каждой главы: reachable, complete once, save/reload mid-scene, RU/BE/EN, spoiler-safe flag, no dead end. Финал сезона и optional 06-POST обрабатываются без новой системы ending.
- Не стартовать следующую волну, пока предыдущая не end-to-end PASS на exact main.

### G4 — release candidate и feature freeze
- 27/27 обязательных сцен достижимы и заканчиваются, 06-POST безопасно optional; 3 обязательных M3 win/retry, 22 optional доступно только если подтверждено, что они без сюжетных наград и не блокируют сценарий.
- Один полноценный игроковый проход через меню, карту, сюжет, мини-игру, восстановление, финал и повторный Continue/New Game. Web/desktop/portrait touch + RU/BE/EN; offline/refresh/corrupt-save and failure/recovery. Портретные атласы и двери owner approved.
- GitHub Actions exact main + Pages green, no outstanding blocker severity bugs, reversible changelog/release tag. After G4: только release blockers, никакого расширения функционала.

## 5. Обязательные правила каждого agent prompt и PR
Запрашивать **один bounded PR** с: baseline main SHA; one existing task ID + owner domain; explicit read-only context and exact writable paths; upstream contract; UPDS donor audit if game/UI; mandatory regression tests; statuses/owner QA distinguished; rollback; unique docs/changes evidence and own shard only. В конце PR указать exact head SHA, CI link, changed files, remaining blocker, owner manual QA. Agent никогда не мерджит автоматически и не ставит device_verified/accepted без фактического owner proof.

**WIP:** 5 agents may research/prepare independently; integration owner maintains exactly one shared runtime migration PR. No speculative parallel edits to common game state. All QA-only/editor-only work must not change default production source by side effect. A failed gate leads to one narrowly scoped bugfix, not replacing editor/architecture.

## 6. Отложить без сожаления (не удалить из истории)
- VN Studio HTML-v5 screenshot parity (#121/#129), advanced draft editor props/FX and authoring polish: return only if it blocks publishing existing 28 scenes. No new editor feature for its own sake.
- Tablet Room Builder S-Pen/multitouch full certification (#21): defer if release geometry can be author-approved in native Godot Route Editor; keep actual production opening QA mandatory.
- Full compositing pipeline/turnarounds, animated NPC walkers, large map props/room library, secondary floors, full 11 door resolution, photo-real redraw, broad match-3 icon rework, new levels/currency.
- Journal/collection system (GAME-JOURNAL-01): minimal current objective feedback is enough unless playtest proves lost player progression. No new meta-loop.
- Large refactors, optional accessibility polish, extra export formats/build targets beyond Web+desktop: only if a failing release criterion shows why.

## 7. Single source of truth и следующий управляющий шаг
Statuses: data/raven/production/progress/*.json (15); dashboard generated automatically. Code/gap/GFX historical plan JSONs are NOT live status. This document is an **operational proposed release subset** over those statuses, not a new status ledger and not an approval record.
**Next actions:** review/merge this planning PR; owner accepts/edits release boundary and HC/CB architecture; issue five narrow agent task cards from sections 2–4; merge R1 source boundary before enabling R2/R3 production; use G1–G4 checkboxes to govern every subsequent task.

## G2-03 integration checkpoint — 2026-11-17

Status reconciliation #281–284 and QA baseline #286 merged with exact-head CI; details, exact SHAs, visual findings, verification and rollback are in [GAME-LOOP-01 G2-03 evidence](changes/GAME-LOOP-01-g2-03-production-unification.md). Existing draft #287–289 implementations are consolidated on `integration/G2-03-production-unification` for shared production-contract review. No new parallel runtime implementation or production approval was created.

The real player-map view, registered menu/map/E2E tests, inactive world-plan calibration and actual GPU captures are available. Full Windows runner PASS; Linux/full integration CI is recorded in the integration PR. Candidate source selection and separate acceptance receipt remain disabled. G2 is **not owner accepted**: final painted HC/CB finish, structural headroom/occlusion approval, real phone QA and the distinct portrait-art blockers remain. The broader Season 1 plan and parent tasks stay open.
