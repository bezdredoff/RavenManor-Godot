# Art handbook / provenance — `art-pipeline`

Read root `AGENTS.md`, then `docs/process/AGENT_ORCHESTRATION_RU.md` and all relevant local AGENTS. Use the owning `data/raven/production/progress/<domain>.json` and unique `docs/changes/` evidence. Generated dashboard and frozen `production_progress.json` must not be edited. Manual acceptance and merge are not automatic.

Read `art-handbook/README.md` and `art-handbook/files/AGENT_GUIDE.md`. Canonical recipes/provenance include `data/raven/production/art_workflow_handbook.json` and recorded source files; `catalog.json`/`data.js` are generated outputs. Run `python3 scripts/raven/tools/build_art_handbook.py --check`, don't hand-edit generated output as source, don't claim ComfyUI execution without proof, never turn candidate into accepted just because documented. Validate new assets' source, model, SHA, rights and full environment/recipe metadata.
