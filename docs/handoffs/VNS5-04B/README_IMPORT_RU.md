# VNS5-04B — Incoming handoff R1

**Это транспортный PR, а не implementation. НЕ МЕРЖИТЬ входящий PR в main.**

Основа: `bezdredoff/RavenManor-Godot@main` SHA `6bdd5fa6fc494a7c37d7b5c4aaf0e1d05ecf5346` после merged PR #101. В архиве только разрешённые `docs/handoffs/VNS5-04B/*`. Реальный код *ещё не установлен*. Защита incoming запрещает прямой импорт `addons/` и `check.ps1` — её нельзя обходить.

## Агенту / следующему чату

1. Проверить, что `main` всё ещё совпадает с baseSha. При расхождении *остановиться и rebase вручную*, не применять patch вслепую.
2. В новой ветке от `main` применить `implementation.patch.txt` через `git apply --check` и `git apply`. Проверить `FILE_MANIFEST.json` (SHA256 всех 13 файлов); никаких сторонних изменений.
3. Открыть **отдельный Draft implementation PR** по VNS5-04B (не мержить handoff). Проверить независимый PR-head CI Godot/Raven/Web, ошибки скриптов и контроль локального staging.
4. Обновить `docs/STATUS.md` и `production_progress.json` в implementation PR фактическими ссылками и статусами CI. Пометить VNS5-04B `PR_review`; не `accepted` без ручного QA.
5. В Godot 4.7.2 проверить 800x640, 1024x640, 1366x768: старый v1 draft, сохранение новой ориентации/fit/focal, prop add/remove/drag/scale/state/z, staged prop images, undo, reload, no-overwrite review export и запрет потери v2 при v1 export. Проверить, что production JSON, runtime и UPDS не затронуты.
6. Закрыть входящий handoff PR без мержа, после интеграции удалить ZIP из incoming; передать на human review только implementation PR. Ни merge, ни deployment не выполнять автоматически.

Документация и ограничения — в patch: `docs/production/VNS5_04B_STAGE_V2_RU.md`. Focal — пока визуальный ориентир, не runtime crop. Props — только staged/ART PENDING, не accepted art.
