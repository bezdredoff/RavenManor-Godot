# Hermes / multi-agent harness entrypoint — Raven Manor

**Status 2026-11-05:** local Hermes was used for owner-reported, PR-evidenced pilots [#199](https://github.com/bezdredoff/RavenManor-Godot/pull/199) (Codex) and [#200](https://github.com/bezdredoff/RavenManor-Godot/pull/200) (LM Studio Ornith 1.5). This repository documents the harness contract; it **does not** install, configure or automatically start the user's local Hermes, LM Studio or external model endpoints. Local worker logs and provider settings are not part of GitHub CI evidence.

Read root `AGENTS.md`, `docs/process/AGENT_ORCHESTRATION_RU.md`, every applicable nested `AGENTS.md`, and [Ornith's bounded execution contract](docs/process/ORNITH_EXECUTION_CONTRACT_RU.md) before routing work.

## Dispatch: choose domain **and** complexity separately

A domain is one of 15 task-status shards. The **executor** is selected independently:
- **Procedural** (1–3 known writable paths, fully specified steps, known inputs/tests, objective output): local Ornith 1.5 may execute under an immutable allowlist and independent review. Any unknown dependency or unsupported assertion → `UNKNOWN` and STOP.
- **Bounded exploration**: Qwen is a **candidate only**, not yet validated by an equivalent Raven pilot; use a verified stronger executor/reviewer meanwhile.
- **Ambiguous/debugging/cross-module/security/save/schema**: Codex/frontier with wider research and integration review. Do not give Ornith these tasks simply to reduce token cost.
- **Review** of Ornith's semantic claims: confirmed reliable independent reviewer; Qwen only after its review quality is measured. CI PASS does not establish truth of claims about unexecuted tests.

For common repeatable procedures reuse the [fixed Ornith template](docs/process/ORNITH_EXECUTION_CONTRACT_RU.md#5-постоянный-шаблон-выдачи-task-brief). For new tasks with research/uncertainty let a verified strong planner produce the first *bounded* specification, not a novel long guide per step.

## Worker protocol

1. Read fresh origin/main SHA, task ID, workstream/domain, nested instructions, source and donor SHA, open PRs.
2. Set immutable read inputs, **exact** writable-file allowlist, explicit tests, stop conditions, reviewer and isolated worktree / `agent/<domain>/<task>-topic`.
3. Prevent overlapping writers on one file; shared reducer/store/controller/scene/workflow changes require integration owner.
4. For Ornith: at first substantive ambiguity STOP_AND_ESCALATE; at most one **re-scoped**, planner-approved retry (operational policy, not automatically implemented). No expanding its authority.
5. Require report with `FACTS`, `UNKNOWN`, `ASSUMPTIONS`, `COMMANDS EXECUTED` and `NOT RUN`; inspect actual diff/output and verify claims against source.
6. Run required validators, PR-head six-job CI and independent review. Final merge is owner-controlled. Update only own `progress/<domain>.json` after verified merge; never infer whole parent task or device/art acceptance from a slice.
7. Measure end-to-end effort and retry/review cost if available; mark unknown measurements `UNKNOWN` instead of asserting savings.

## Pilot evidence and limitations

- [#199](https://github.com/bezdredoff/RavenManor-Godot/pull/199) — Codex fixed a cancelled touch gesture with a targeted Godot regression (partial CODE-02-01).
- [#200](https://github.com/bezdredoff/RavenManor-Godot/pull/200) — Ornith authored a narrow three-test *static* coverage inventory **with orchestrator corrections and validation** (partial VN-EDITOR-07). It is not evidence of autonomous Ornith delivery.
- Qwen has no equivalent verified pilot yet. See [pilot details and source-limited acceptance](docs/process/ORNITH_EXECUTION_CONTRACT_RU.md#8-наблюдения-из-реального-пилота-5-ноября-2026).

This repository enforces progress-shard ownership on branch-scoped agent PRs, **not general runtime file ACL**. Harness-side restrictions require separate local enforcement. Never auto-merge, infer acceptance, publish private donor data, or weaken ZIP security/CI.
