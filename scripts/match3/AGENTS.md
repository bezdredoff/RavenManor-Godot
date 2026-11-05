# Match-3 owner: `match3`

Read repository-root `AGENTS.md` and `docs/process/AGENT_ORCHESTRATION_RU.md` first. These local rules supplement root policy. Update only the owning `data/raven/production/progress/<domain>.json` plus unique `docs/changes/` evidence; never manually edit generated `dashboard/status.json` or frozen `production_progress.json`. Never auto-merge or claim unverified owner/device/art acceptance.

Primary: `scripts/match3/**`, narrow `scripts/raven/raven_match3_*.gd`, `scripts/raven/raven_optional_campaign_controller.gd` and corresponding tests by explicit allowlist. Inspect `bezdredoff/UPDS-godot` donor first; pin source SHA and reuse decision. Preserve deterministic replay, checkpoint/first-clear/booster atomicity and no work-point/story reward from optional stages. `vertical_slice.gd`, `raven_reducer.gd`, `raven_campaign_store.gd` and shared UPDS code are integration-owned. Run Match-3 checkpoint/session/game-loop/viewport smokes and full blocking CI.
