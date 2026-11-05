# Shared UPDS-derived runtime — integrator review required

Read root `AGENTS.md`, then `docs/process/AGENT_ORCHESTRATION_RU.md` and all relevant local AGENTS. Use the owning `data/raven/production/progress/<domain>.json` and unique `docs/changes/` evidence. Generated dashboard and frozen `production_progress.json` must not be edited. Manual acceptance and merge are not automatic.

`scripts/shared/upds/**` and `scripts/shared/vn/**` are **shared libraries**, not owned solely by Match-3 or VN Runtime. Before a change inspect exact `bezdredoff/UPDS-godot` donor commit/path/blob SHA and all Raven consumers. Preserve deterministic Match-3/paging/Skip semantics, save compatibility, locale and input behavior. Changes require explicit cross-domain integration/reuse decision and appropriate consumer regression tests. Do not bring private UPDS narrative/assets into public Raven.
