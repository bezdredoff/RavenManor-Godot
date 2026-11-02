# VNS5-05B, фаза 2 — безопасное воспроизведение FX в игровом VN

**Baseline**: `main@f9817672e066c1823e43c15c05fe75332c5531d9` (PR #111 merged). **Scope**: explicit opt-in gameplay presentation runtime and regression checks. **Status**: review candidate, not art/owner/device acceptance.

## Runtime, общий с редактором

- `scripts/shared/vn/micro_fx_math.gd` — единый чистый sampler для эффектов `breathe`, `blink` (сжатие спрайта, не кадр моргания), `shake`, `pulse`, `fade_in`, `fade_out`. `addons/vn_studio/model/stage_fx_store.gd` использует эту же формулу; никаких двух параллельных реализаций.
- `scripts/raven/raven_vn_fx_runtime.gd` — ограниченный RefCounted-контроллер (никаких `EditorInterface`, `user://`, `StorySession`, `RavenReducer` и IO). Только валидация и visual samples; не генерирует события, не меняет story index, save или награды.
- `scripts/raven/raven_vn_game_view.gd`: `configure_reviewed_fx(scene_id,line_ids,bundle)`, `show_beat(...,explicit_line_id="")`, `set_fx_accessibility(reduced_motion,skipping)`, `clear_reviewed_fx()`. При повторном показе той же реплики (например, новая страница или перевод) не сбрасывает `lineMs`; при новой реплике сбрасывает только `lineMs`. При смене сцены обнуляет обе шкалы.
- `scripts/raven/hall_tea_vn.gd`: `configure_reviewed_fx(bundle)`, тот же line-ID event hook на уже существующие двенадцать реплик. Сценные FX используют непрерывные `sceneMs`, привязанные к реплике — `lineMs`. Фокус говорящего хранится отдельно от alpha FX, чтобы fade не накапливал прозрачность.
- На каждом кадре сбрасываются базовые `position/scale/modulate`, после чего применяется детерминированная композиция FX. При `skipping` либо `reduced_motion` визуальные FX немедленно становятся нейтральными; сюжет не изменяется. `_next` и `_switch_locale` остаются единственными привычными UI путями перехода/локализации.

## Строгий gate публикации FX

`raven-stage-fx-review-candidate` из локального Editor export содержит `runtimeApplied:false`; его нельзя загружать в runtime. Ни один новый FX не включён в текущих canonical VN сценах. Для будущего включения нужен **отдельный human-approved promotion PR** с отдельным явно указанным путём и проверенной provenance/licensing.

Runtime принимает ТОЛЬКО переданный напрямую валидный `raven-vn-runtime-fx-v1`, `schemaVersion:1` и поля:

```json
{
  "format": "raven-vn-runtime-fx-v1",
  "schemaVersion": 1,
  "sceneId": "RM-BEAT-02-01",
  "approvalStatus": "approved",
  "approvalRef": "reviewed-change-reference",
  "cues": [
    {
      "id": "fx-0001",
      "targetType": "background",
      "targetId": "background",
      "effect": "pulse",
      "startMs": 0,
      "durationMs": 1400,
      "repeat": 1,
      "intensity": 0.35,
      "lineId": "RM-BEAT-02-01-L001"
    }
  ]
}
```

Этот пример — **не утверждённый эффект** и не следует коммитить как автоматически подключённый игровой контент. Факт наличия строк `approvalStatus`/`approvalRef` в JSON сам по себе не заменяет ревью; технический gate также требует explicit `configure_reviewed_fx` в контексте просмотренного PR.

Ошибки блокируют **весь** конфиг (no partial apply): несовпадающий sceneId, неизвестная реплика, чужой actorId, неизвестные поля, duplicate cue ID, NaN/Inf, неверное время / типы, попытка `prop` без проверенного renderer, `runtimeApplied:false`, пустое согласование. Локальные `user://` файлы не открываются.

## CI и ручная QA

Новый `tests/raven/vn_fx_runtime_smoke.gd` запускается из `scripts/check.sh`: валидирует вход, scene/line часы, неподтверждённый/невалидный payload, skip/reduced-motion, общий Raven VN view, Hall Tea, отсутствие записи canonical `season1_dialogue_catalog.json`, `vn_staging.json`, `character_performance.json`. Старые editor FX smoke остаются в той же матрице.

**Desktop Godot QA** — требуется отдельно на 800×640, 1024×640, 1366×768: проверка L001→L002, repeat/locale/page/skip/reduced motion и наложения на focus tween; проверить, что отсутствие одобренного FX не меняет текущую игру и Web export. Отдельная ручная проверка approved promotion, включая честную provenance, нужна **перед включением живых анимаций**. Test/synthetic approval ref не даёт права публиковать сцену с ним.

**VNS5-05B:** phase 1 merged PR #111; phase 2 runtime hook предлагается в текущем PR. Не считать VNS5-05B `accepted` без ручной desktop QA и реального утверждённого эффекта. Затем переходить к **VNS5-06** (создание/редактирование сцен, реплик, Story Map с безопасными ID/гейтами) и VNS5-07+.
