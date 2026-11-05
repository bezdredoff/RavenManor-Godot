# Shared production definitions — not a live status ledger

Read root `AGENTS.md`, then `docs/process/AGENT_ORCHESTRATION_RU.md` and all relevant local AGENTS. Use the owning `data/raven/production/progress/<domain>.json` and unique `docs/changes/` evidence. Generated dashboard and frozen `production_progress.json` must not be edited. Manual acceptance and merge are not automatic.

This directory contains common CODE/GAP/art/story definitions. `code_work_packages.json`, `gap_work_packages.json`, `active_workstreams.json` and `p2_reentry_policy.json` are planning/QA metadata, **not live status sources**. For task statuses and assignments read stricter `progress/AGENTS.md`; only there can one domain update status. Schema, canonical narrative, translation IDs, art approval and other producer→consumer contracts may require coordinated integration PR; no silent changes to shared registries. Never update frozen `production_progress.json`.
