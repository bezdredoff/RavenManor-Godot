# VNS5-05A — incoming handoff R1

**Это handoff, не исполняемый Godot PR. Закройте автоматически созданный incoming PR БЕЗ MERGE.**

Фиксированная база: `bezdredoff/RavenManor-Godot@main` `7652a20676bce76e7aead065bdd025b8cee5154b`, после merge VNS5-04B #104 и GFX-05 #103. ZIP допустим для текущего защищённого raven-delta-v1 importer, так как содержит только `docs/handoffs/VNS5-05A/*`. Импорт не устанавливает код в addons/ — это **преднамеренная защита**.

## Следующему агенту

1. Убедиться, что `main` SHA в GitHub совпадает с `FILE_MANIFEST.baseSha`; если нет, вручную ребейзить, не перезаписывать изменения других PR.
2. Создать ветку от актуального `main` и применить `implementation.patch.txt`, сначала `git apply --check`. Проверить SHA-256 и bytes всех 10 файлов по `FILE_MANIFEST.json`. Только эти файлы разрешены в реализации.
3. Открыть отдельный Draft implementation PR с кодом и тестами. Изменить **актуальные** `data/raven/production/production_progress.json` и `docs/STATUS.md`: отразить merge PR #104 и #103, новую VNS5-05A `PR_review`, ссылки на реальный PR и CI. Эти два файла не включены в patch во избежание отката GFX-05-данных из недавнего параллельного PR.
4. Прогнать CI Godot/Raven/Web на последнем code head. Ошибки исправлять в этой implementation-ветке, без bypass importer и без auto merge. Отдельно тестировать headless `vn_studio_stage_fx_smoke.gd` и оба runners.
5. Manual QA Editor 800×640 / 1024×640 / 1366×768: target background/actor/prop, 0/1/2/3 characters, add/remove FX, `startMs/durationMs/repeat/intensity`, Play/Pause/scrub/Reset, Undo/Redo, save/reopen, invalid target/duplicate/NaN, no-overwrite FX export, no-loss v1/v2 export.
6. Убедиться в неизменности canonical story/staging, approved art, runtime/save, UPDS. Stage FX не исполняется в релизной игре; real blink keyframe assets/runtime events потребуют VNS5-05B.
7. Закрыть handoff PR без мержа и удалить ZIP из `incoming` после переноса, иначе следующий incoming import встретит два ZIP.

См. `docs/production/VNS5_05A_MICRO_FX_RU.md` в implementation patch и `addons/vn_studio/README.md`. Границы приёмки не расширять молча.
