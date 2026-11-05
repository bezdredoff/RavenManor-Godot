# Hermes / multi-agent harness entrypoint — Raven Manor

**This is a task-runner contract, not a harness installation or configuration.** Repository instructions are LLM/provider-independent. Read root `AGENTS.md`, `docs/process/AGENT_ORCHESTRATION_RU.md` and all nested `AGENTS.md` along the task's intended diff paths.

Dispatch each independent task to a **domain** (one of 15 progress shards), not to a hard-coded model. Give each worker a fresh main SHA, immutable read inputs, exact file allowlist, its own worktree, branch `agent/<domain>/<task-id>-topic`, tests and human acceptance conditions. No concurrent writes to the same file or campaign/reducer/store/scene/workflow; those go through an integration task. Local LM Studio endpoints, external DeepSeek/Codex/ChatGPT models and GPU distribution are optional provider configuration outside this repository; never assume they are connected.

Workers must supply a unique evidence note and update only their domain status shard. Collect PR URL, head SHA, CI logs and open risks; owner approves merge. After merge, domain owner updates truthful `merged` state. Do not auto-merge, infer art/device acceptance, or weaken ZIP security/CI. See the complete handoff card in the operations guide.
