# Raven Manor — audit of every merged work item (2026-11-03)

## Verified baseline and interpretation

- Source: `bezdredoff/RavenManor-Godot`, `main@443d8bead9243db8765b6ec9f06b77e075d39403` (PR #140 was merged). GitHub API verified PR #9 and all referenced #46–#140 records as `merged_at != null`. At the snapshot: **no open PRs** and 53 progress entries with `status=merged`.
- **`merged` is already a terminal/closed delivery state in dashboard**, not part of the default «Оставшаяся работа». A task's original PR cannot be merged again; it need not be reimplemented just because a higher-level feature remains unfinished.
- **Not synonymous with `accepted`:** many editor tasks have automated GitHub CI but no owner Windows Godot interaction, actual authoring workflow acceptance, or 3-language/device release check. Those remain in existing named follow-up tasks. No human approvals inferred or fabricated.
- **50 of 53** keep `merged` (scoped technical delivery closed), with explicit implementation, QA and approval axes and follow-up ID links where residual work is already planned.
- **3 of 53** were marked `merged` beyond demonstrated contract coverage for broader-than-delivered art workflow states; reset to `ready`, retaining the original PR evidence and already approved exact art.
- Existing `integrated` and `accepted` statuses are untouched, including `DASH-RENDER-01` owner-confirmed functioning. Full game/runtime/mobile acceptance remains unclaimed.

## Three misleading merged states re-opened

1. **`GFX-05-04`** — deterministic paths, partial resume and per-frame regeneration. PR #103 delivered a read-only handbook builder and catalog. The handbook also includes archived local-path reference runners with some resume logic plus an opt-in single-recipe replay helper; neither demonstrates an adopted, reproducible production batch with deterministic partial resume and per-frame regeneration. Follow-up: `ART-BATCH-AUTOMATION` and `ART-PROVENANCE-QA`. Implementation partial; no native batch proof.
2. **`GFX-05-05`** — each generated frame should preserve RAW, matte mask, RGBA master, preview and manifest. Art Handbook preserves output recipes and archived reference scripts (some of which process masks and raw PNGs), but no production-grade, independently verified per-frame export contract across RAW, matte, RGBA master, preview and manifest has been shown. Follow-up: `ART-BATCH-AUTOMATION` and `ART-PROVENANCE-QA`.
3. **`GFX-06-06`** — actual stateful physical props (letter, tray, folder, tools). Merged #97 contains accepted hand-held **composite character images** (e.g., Ada holding tray, Lucas with folder, Evelyn envelope). The 62 imported images are all artistically approved, but this does **not** produce standalone state variants to bind in map/VN. Follow-up: `VNS5-08`, `CODE-07-01`. Set the **GFX-06-06 task** `approvalState=pending` for missing independent prop states. This does **not** revoke the 62 exact accepted character frames, whose owner-art approval remains in `vn_character_catalog.json`.

## Complete 53-item audit

The table distinguishes original **technical delivery closure** from work still requiring QA or a follow-up. For existing `merged` items, «автотесты/код» means CI evidence only, **not user acceptance**. For editor-only items, `qaState=manual_pending` explicitly records the unperformed manual check.

| Task | Actual PR | Before → after | QA evidence / outstanding | Remaining work IDs |
|---|---|---|---|---|
| `VNS5-05A` | [#106](https://github.com/bezdredoff/RavenManor-Godot/pull/106) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-05B` | [#112](https://github.com/bezdredoff/RavenManor-Godot/pull/112) | `merged` → `merged` | ручной QA | `VNS5-09`, `VN-RUNTIME-01` |
| `VNS5-06A` | [#113](https://github.com/bezdredoff/RavenManor-Godot/pull/113) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-06B` | [#114](https://github.com/bezdredoff/RavenManor-Godot/pull/114) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-06C` | [#115](https://github.com/bezdredoff/RavenManor-Godot/pull/115) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-06D1` | [#117](https://github.com/bezdredoff/RavenManor-Godot/pull/117) | `merged` → `merged` | ручной QA | `VNS5-09`, `VN-RUNTIME-01` |
| `VNS5-06D1-CLI` | [#116](https://github.com/bezdredoff/RavenManor-Godot/pull/116) | `merged` → `merged` | автотесты/код | `VN-RUNTIME-01` |
| `VNS5-06D2A` | [#118](https://github.com/bezdredoff/RavenManor-Godot/pull/118) | `merged` → `merged` | автотесты/код | `VN-RUNTIME-01` |
| `VNS5-06D2B` | [#119](https://github.com/bezdredoff/RavenManor-Godot/pull/119) | `merged` → `merged` | автотесты/код | `VN-RUNTIME-01` |
| `VNS5-06D2C` | [#120](https://github.com/bezdredoff/RavenManor-Godot/pull/120) | `merged` → `merged` | ручной QA | `VN-RUNTIME-01` |
| `GFX-05-05` | [#103](https://github.com/bezdredoff/RavenManor-Godot/pull/103) | `merged` → `ready` | workflow не подтверждён | `ART-BATCH-AUTOMATION`, `ART-PROVENANCE-QA` |
| `GFX-05-04` | [#103](https://github.com/bezdredoff/RavenManor-Godot/pull/103) | `merged` → `ready` | workflow не подтверждён | `ART-BATCH-AUTOMATION`, `ART-PROVENANCE-QA` |
| `VNS5-04B` | [#104](https://github.com/bezdredoff/RavenManor-Godot/pull/104) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-04A` | [#101](https://github.com/bezdredoff/RavenManor-Godot/pull/101) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-03` | [#99](https://github.com/bezdredoff/RavenManor-Godot/pull/99) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-02` | [#96](https://github.com/bezdredoff/RavenManor-Godot/pull/96) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-01` | [#93](https://github.com/bezdredoff/RavenManor-Godot/pull/93) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `VNS5-00` | [#92](https://github.com/bezdredoff/RavenManor-Godot/pull/92) | `merged` → `merged` | автотесты/код | `VN-EDITOR-07` |
| `CODE-01-01` | [#46](https://github.com/bezdredoff/RavenManor-Godot/pull/46) | `merged` → `merged` | автотесты/код | `CODE-01-02` |
| `PROC-001` | [#48](https://github.com/bezdredoff/RavenManor-Godot/pull/48) | `merged` → `merged` | автотесты/код | — |
| `PROC-002` | [#48](https://github.com/bezdredoff/RavenManor-Godot/pull/48) | `merged` → `merged` | автотесты/код | — |
| `PROC-004` | [#48](https://github.com/bezdredoff/RavenManor-Godot/pull/48) | `merged` → `merged` | автотесты/код | — |
| `MOB-00` | [#48](https://github.com/bezdredoff/RavenManor-Godot/pull/48) | `merged` → `merged` | автотесты/код | `MOB-04` |
| `RM-GAP-009` | [#138](https://github.com/bezdredoff/RavenManor-Godot/pull/138) | `merged` → `merged` | автотесты/код | — |
| `CODE-02-02` | [#60](https://github.com/bezdredoff/RavenManor-Godot/pull/60) | `merged` → `merged` | ручной QA | `CODE-02-06`, `RM-GAP-010` |
| `CODE-02-00` | [#54](https://github.com/bezdredoff/RavenManor-Godot/pull/54) | `merged` → `merged` | автотесты/код | `CODE-02-06`, `RM-GAP-010` |
| `CODE-02-04` | [#61](https://github.com/bezdredoff/RavenManor-Godot/pull/61) | `merged` → `merged` | ручной QA | `CODE-02-06`, `RM-GAP-010` |
| `PROC-005` | [#61](https://github.com/bezdredoff/RavenManor-Godot/pull/61) | `merged` → `merged` | автотесты/код | — |
| `VN-EDITOR-00` | [#68](https://github.com/bezdredoff/RavenManor-Godot/pull/68) | `merged` → `merged` | автотесты/код | — |
| `VN-EDITOR-01` | [#69](https://github.com/bezdredoff/RavenManor-Godot/pull/69) | `merged` → `merged` | автотесты/код | `VN-EDITOR-07` |
| `VN-EDITOR-02` | [#70](https://github.com/bezdredoff/RavenManor-Godot/pull/70) | `merged` → `merged` | ручной QA | `VN-EDITOR-07` |
| `VN-EDITOR-03` | [#71](https://github.com/bezdredoff/RavenManor-Godot/pull/71) | `merged` → `merged` | ручной QA | `VN-EDITOR-07` |
| `VN-EDITOR-04` | [#72](https://github.com/bezdredoff/RavenManor-Godot/pull/72) | `merged` → `merged` | ручной QA | `VN-EDITOR-07` |
| `VN-EDITOR-05` | [#73](https://github.com/bezdredoff/RavenManor-Godot/pull/73) | `merged` → `merged` | ручной QA | `VN-EDITOR-07`, `VNS5-09` |
| `VN-EDITOR-06` | [#76](https://github.com/bezdredoff/RavenManor-Godot/pull/76) | `merged` → `merged` | ручной QA | `VN-EDITOR-07`, `VNS5-09` |
| `RAVEN-VN-EDITOR-01` | [#77](https://github.com/bezdredoff/RavenManor-Godot/pull/77) | `merged` → `merged` | ручной QA | `VNS5-09` |
| `GFX-06-06` | [#97](https://github.com/bezdredoff/RavenManor-Godot/pull/97) | `merged` → `ready` | ручной QA | `VNS5-08`, `CODE-07-01` |
| `VNS5-07A` | [#122](https://github.com/bezdredoff/RavenManor-Godot/pull/122) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07B` | [#123](https://github.com/bezdredoff/RavenManor-Godot/pull/123) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07C1` | [#124](https://github.com/bezdredoff/RavenManor-Godot/pull/124) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07C2` | [#125](https://github.com/bezdredoff/RavenManor-Godot/pull/125) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07C3` | [#126](https://github.com/bezdredoff/RavenManor-Godot/pull/126) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07E` | [#127](https://github.com/bezdredoff/RavenManor-Godot/pull/127) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07F1` | [#128](https://github.com/bezdredoff/RavenManor-Godot/pull/128) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07F3` | [#130](https://github.com/bezdredoff/RavenManor-Godot/pull/130) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07F4` | [#131](https://github.com/bezdredoff/RavenManor-Godot/pull/131) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `VNS5-07F5` | [#132](https://github.com/bezdredoff/RavenManor-Godot/pull/132) | `merged` → `merged` | ручной QA | `VNS5-07F2`, `VNS5-09` |
| `CODE-04-03` | [#136](https://github.com/bezdredoff/RavenManor-Godot/pull/136) | `merged` → `merged` | ручной QA | `RM-GAP-013`, `LOC-EN-QA`, `LOC-BE-QA` |
| `CODE-00-01` | [#46](https://github.com/bezdredoff/RavenManor-Godot/pull/46) | `merged` → `merged` | автотесты/код | — |
| `CODE-00-02` | [#46](https://github.com/bezdredoff/RavenManor-Godot/pull/46) | `merged` → `merged` | автотесты/код | `CODE-08-01` |
| `CODE-00-03` | [#9](https://github.com/bezdredoff/RavenManor-Godot/pull/9) | `merged` → `merged` | автотесты/код | `RM-GAP-010` |
| `CODE-01-03` | [#9](https://github.com/bezdredoff/RavenManor-Godot/pull/9) | `merged` → `merged` | автотесты/код | `CODE-13-01` |
| `CODE-08-02` | [#9](https://github.com/bezdredoff/RavenManor-Godot/pull/9) | `merged` → `merged` | автотесты/код | `CODE-13-01` |

## Rules for subsequent updates

- Keep the technical PR task `merged` once its **exact agreed deliverable** is on main. Follow-up acceptance is in a separate ID; do not re-open code-delivery only because the whole game remains incomplete.
- Re-open to `ready` when a task's **own exact deliverable** is not evidenced (three GFX examples), despite some nearby PR being merged.
- For closed tasks, record `followUpTaskIds` pointing to existing canonical work packages. The dashboard validates IDs and displays them as separate remaining work. The dashboard's «Требует ручной / device QA» filter now matches explicitly `qaState=manual_pending` only; `automated` alone no longer labels a scoped code deliverable as awaiting real-device checking.
- Set `implementationState=delivered` for code delivered to main, `qaState=manual_pending` for unperformed native/device acceptance, and `approvalState=pending` unless specific owner acceptance is recorded. Preserve the 26/26 approved VN backgrounds and 62/62 accepted character image records; the incomplete GFX-06-06 task has separate pending acceptance. No new art variants invented.
- There is no blanket auto-acceptance from a merge or green CI. If a future PR genuinely finishes a follow-up task, update that ID's own status and QA evidence in the same PR.

Rollback: revert this metadata/report/dashboard PR. No game save, story, runtime, ComfyUI local state, image assets, localization content or story IDs changed.
