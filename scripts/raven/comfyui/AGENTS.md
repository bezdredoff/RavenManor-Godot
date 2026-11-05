# ComfyUI manifests and batch review — `art-pipeline`

Read root `AGENTS.md`, then `docs/process/AGENT_ORCHESTRATION_RU.md` and all relevant local AGENTS. Use the owning `data/raven/production/progress/<domain>.json` and unique `docs/changes/` evidence. Generated dashboard and frozen `production_progress.json` must not be edited. Manual acceptance and merge are not automatic.

Local scope: `scripts/raven/comfyui/**`. Read `docs/RAVEN_WALL_COMFYUI_WORKFLOW.md` and `art-handbook/files/AGENT_GUIDE.md`. Record model/workflow/seed/settings, dimensions, variant and source SHA, rights and candidate/accepted distinction. Don't publish candidate art as approved or assume a successful CI validates an actual GPU/LM Studio/ComfyUI run. Keep generated binary batches separate from published art; use reviewed ZIP/manifest flow. Test manifest builders and handbook `--check`, report unrun local model tests explicitly.
