# Codex entrypoint — Raven Manor

Use the canonical workflow in [AGENTS.md](AGENTS.md) and [docs/process/AI_COLLABORATION_RU.md](docs/process/AI_COLLABORATION_RU.md). The same source/branch/PR/test/status obligations apply to ChatGPT and DeepSeek.

1. Inspect actual Git remote, latest main, dirty worktree, existing PR and task ID.
2. Read docs/DECISIONS.md, STATUS.md, INDEX.md, paired code/art roadmaps and the narrow contract.
3. Before creating VN/Match-3/settings/audio/UI rules, inspect UPDS-godot for existing code and pin blob SHA.
4. Produce Task proposal using docs/process/TASK_AND_PR_TEMPLATE_RU.md; implement one scoped branch/PR; test and update production_progress.json + docs/STATUS.md in same PR. Do not auto-merge.
5. For phone ZIP fallback consult docs/process/MOBILE_ZIP_PIPELINE_RU.md. Never claim that pipeline is live without end-to-end proof.
