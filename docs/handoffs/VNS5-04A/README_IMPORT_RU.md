# Raven Manor — VNS5-04A incoming handoff R1

## Что это

Patch для следующей узкой задачи VNS5-04A (preview orientation, actor templates, undo). GitHub importer **не может** применять `addons/` или `check.ps1/scripts/check.sh` из ZIP из-за security policy. Incoming PR создаётся только с `docs/handoffs/VNS5-04A/*` и не устанавливает код. **Не мержить handoff как реализацию.**

## После автоматического incoming PR

Агент/Codex с GitHub integration берёт `docs/handoffs/VNS5-04A/implementation.patch.txt` (либо этот ZIP локально), создаёт отдельную чистую ветку от `main@ac7bcd0bbbe52db71262ae8a1adf4fbecf9fe9cd`, вызывает `git apply --check` и `git apply`, либо переносит перечисленные в patch 10 файлов точно, обновляет statuses c реальным PR и CI, открывает implementation PR. Запуск Godot 4.7.2 required. **Never merge incoming handoff PR.**

В отличие от старого R2, этот пакет основан на смерженном PR #99, а не PR #97. Штатный importer требует только один ZIP в `incoming/`. При смене main запрашивать новую ревизию ZIP, нельзя переиспользовать baseSha.

## Область/обязательные проверки

- Portrait 390x844 unchanged shared portrait game layout; landscape 844x390 editor preview separate
- Templates 1/2/3 actors only on click; x/y normalized; current scene stage-v1 validates; Undo up to 32 steps
- Fit/cover, safe/grid/HUD preview only (not scene metadata); props/z-order/focal persistence still VNS5-04B
- Source art/catalogs/runtime/game saves untouched
- CI `scripts/check.sh`, `check.ps1` + manual 800/1024/1366, screenshot evidence and owner QA

See docs/production/VNS5_04A_STAGE_EDITOR_HANDOFF_RU.md in the patch for full acceptance.
