# Next agent instruction — PR97-safe VNS5-03

Task: implement the 9-file patch stored as inert text in `docs/handoffs/VNS5-03-R2/implementation.patch.txt`, not just merge documentation.

Baseline blobs and each target file checksum are in `source-integrity.json`. Confirm current `origin/main` before applying (reference merged PR97 main `8313a109b708e0ae244f5516d9a80d952bcd508f`); check existing PRs. A new `main` commit requires a fresh rebase. This patch specifically preserves PR97's 62 accepted portraits in the asset library, no isolated four-metadata-only assumptions. `staged_image_store.gd` locks `Registry.CHARACTER_ART` and test fixture copies 4 catalogs; import is local-only `user://`.

Apply on clean branch: `git apply --check implementation.patch.txt` followed by `git apply implementation.patch.txt` (save file outside repo or use the docs/handoffs location after candidate checkout). Run:
- Godot 4.7.2 headless editor parse; `tests/raven/vn_studio_staged_image_smoke.gd`; existing asset_registry/layout/drafts/raven_story/character_art smokes; complete `check.ps1` or `scripts/check.sh`.
- `python3 scripts/raven/tools/validate_code_plan.py`, `python3 scripts/raven/tools/build_production_dashboard.py --check`, and PR governance.
- Windows interactive import/export, multi-file PNG/JPG/WebP, alpha, duplicate, collision, fake/SVG/script, traversal/absolute, symlink/junction, metadata validation, export rights gate, catalog drift, reopen and persist, manual QA on several viewport sizes.
- Source files only in implementation PR; no code from private UPDS; no changes to RavenReducer/CampaignStore, story topology, Match3 gates, canonical dialogue, or content JSON. No VNS5-04.

Do NOT mark accepted based on PR CI alone; no merge without user approval. The incoming PR imports docs only and is not a functional plugin delivery.
