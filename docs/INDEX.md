# Documentation map and authority

- `audits/MERGED_CLOSURE_AUDIT_20261103.md`: all 53 merged work items individually checked against merged PRs; 50 closed-scope deliveries, 3 GFX tasks reopened with exact follow-up IDs and QA evidence.

- `audits/ACTIVE_WORK_AND_REVIEW_20261103.md`: 35-item live GitHub workflow state re-audit after PR #139; separates currently active/review from previously partial, merged and waiting for QA.

- `audits/RM-REQUIREMENT-RECONCILIATION_20261102.md`: all 70 historical requirement IDs re-evaluated with current component evidence and honest unresolved QA; original CSV remains a frozen baseline.

- `../art-handbook/index.html`: interactive art-production handbook; image-to-recipe links, exact saved ComfyUI settings/prompts, downloads, system/model snapshot and experiment history.
- `../art-handbook/files/AGENT_GUIDE.md`: human/AI reproduction and evidence rules; companion machine catalog is `../art-handbook/catalog.json`.

- `../AGENTS.md`: root mandatory agent rules; [agent roles/orchestration](process/AGENT_ORCHESTRATION_RU.md) + path-specific `AGENTS.md` under modules. `../HERMES.md`, `../CHATGPT.md`, `../CODEX.md`, `../DEEPSEEK.md` are provider entrypoints.
- `DECISIONS.md`: *current product-owner overrides* of historical stage documents.
- `PROJECT_CONTEXT.md`: current project snapshot.
- `IMPLEMENTATION_PLAN.md`: `RM-HUB-001` and gated PR roadmap.
- `STATUS.md`: canonical current implementation, verification, blockers and art state.
- `RECONCILIATION_MATRIX.md`: conflicts between historical audits, current runtime and R&D evidence.
- `NEXT_PLAN.md`: gated path from current Prototype Lab to integrated `RM-VS-01`.
- `RAVEN_WALL_COMFYUI_WORKFLOW.md`: first-act wall-art ComfyUI batch, prompt contract and art review gate.
- `WALL_TILESET_PIPELINE.md`: constructed wall tileset prototype compared with the generated batch.
- `BLENDER_WALL_KIT.md`: procedural Blender wall kit with a verified corner joint and leak check.
- `../dashboard/`: public Pages production overview, generated from machine-readable backlog and status; not an editable authority.
- `../preview/`: trusted GitHub Actions candidate review portal (CI links / downloadable Web artifacts only). **Not playable preview until separate origin.**
- `process/AI_COLLABORATION_RU.md`: shared ChatGPT/Codex/DeepSeek read/propose/implement/PR/status workflow.
- `process/TASK_AND_PR_TEMPLATE_RU.md`: task proposal and PR format.
- `process/MOBILE_ZIP_PIPELINE_RU.md`: scoped mobile ZIP delta delivery design, security gates and pending importer activation.
- `../data/raven/production/progress/`: **15 canonical owner shards** for current task status, evidence and workstream/P2 assignment. Former `production_progress.json` is a frozen migration snapshot.
- `../data/raven/production/gap_work_packages.json`: missed UX/production/QA work from recent project discussions.
- `production/GRAPHICS_PRODUCTION_ROADMAP_RU.md`: gated roadmap производства персонажей, VN/map-графики, фонов, реквизита, Match-3 и art QA.
- `UPDS_VN_CORPUS_AUDIT.md`: pinned UPDS-godot VN 45-scene inventory, reader oracle, migration risks, privacy and next-gate evidence.
- `../addons/vn_studio/README.md`: native Godot VN Studio Legacy Viewer setup, read-only privacy contract, known limits and manual QA.
- `VN_STUDIO_EDITOR_SPEC.md`: proposed native Godot VN Studio EditorPlugin, UPDS-godot legacy inspection/controlled conversion, parity gates and CODE-03 work packages.
- `production/VN_STUDIO_V5_CONTRACT_PROPOSAL.md`: VNS5-00 source baseline, read-only v2 adapter decision and pending format gates.
- `process/VN_STUDIO_AGENT_GUIDE_RU.md`: human/AI editing and import runbook for the **existing** native plugin (individual features still require verification).
- `production/CODE_PRODUCTION_ROADMAP_RU.md`: парный gated engineering roadmap по переносу/переиспользованию UPDS и Raven-only карте, NPC, восстановлению, season flow и QA.
- `../data/raven/production/code_work_packages.json`: машинный бэклог с P0/P1/P2, оценками S–XL, зависимостями и связями с GFX-этапами.
- `PRODUCT_QUESTIONS.md`: resolved answers that unblock PR 3; future unresolved decisions should be added explicitly.
- Source materials and narrative authority: [bezdredoff/RavenManor](https://github.com/bezdredoff/RavenManor); executable Godot runtime remains in this repository.
- `preproduction/stage1/`: approved Stage 1 v0.5 story baseline.
- `preproduction/stage2/`: approved Stage 2 v0.2 layout and progression baseline.
- `preproduction/stage3/`: Stage 3 v0.2 research, candidates, scene/asset matrix and target budget (practical validation remains).
- `audits/`: external-repository UPDS Godot prototype audit, not proof that code exists here.

Where old contracts conflict (especially bedroom gate, door cycling, free movement) follow `DECISIONS.md`. Preserve old files to maintain provenance; update active implementation contracts and record migrations explicitly.

- [GAME-UI-01 Wave 1 donor-derived VN shell](production/UPDS_UI_WAVE1_VN_SHELL_20261103_RU.md)

- [GAME-UI-01 Wave 2 persisted read-only Skip](production/UPDS_UI_WAVE2_READ_SKIP_20261103_RU.md)

- [CODE-02-06 viewport pointer and modal recovery](production/CODE_02_06_VIEWPORT_POINTER_QA_20261103_RU.md)

## Мультиагентная подготовка (2026-11-04)
- [Аудит и очередность](audits/MULTI_AGENT_READINESS_20261104_RU.md)
- [Контракты и file ownership](architecture/MULTI_AGENT_DATA_CONTRACTS_RU.md)
- [PR evidence](changes/PROC-006-multi-agent-governance.md)

- [PROC-007 — independent modular task progress](process/PROC_007_PROGRESS_SHARD_MIGRATION_RU.md) (#193–196 merged; current status shards and dynamic workstreams).

- [Multi-agent operations and 15 domain ownership profiles](process/AGENT_ORCHESTRATION_RU.md) — task dispatch, worktrees, local AGENTS, dependencies, CI, merge and real acceptance gates.
- [Ornith 1.5: bounded procedural execution contract and Hermes routing pilot](process/ORNITH_EXECUTION_CONTRACT_RU.md) — 1–3 file tasks, evidence protocol, UNKNOWN/STOP, independent review and #199/#200 learnings.
