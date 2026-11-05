# Module tests and gameplay integration — shared test area

Read root `AGENTS.md`, then `docs/process/AGENT_ORCHESTRATION_RU.md` and all relevant local AGENTS. Use the owning `data/raven/production/progress/<domain>.json` and unique `docs/changes/` evidence. Generated dashboard and frozen `production_progress.json` must not be edited. Manual acceptance and merge are not automatic.

Feature owner may update narrowly scoped tests for its module, not unrelated golden assertions or fixtures. Match-3: checkpoint, booster/session, game loop, viewport. VN: VNS5, read history/choice/locale and promotion. Map/Room Builder: navigation, importer/route tests. Campaign core: save/reducer/idempotency/error recovery. Keep functional gates blocking; non-functional dashboard snapshot advisories are separate. Run `bash scripts/check.sh` where possible, then exact-head GitHub Actions; manually tested device/UI/geometry is separate QA evidence.
