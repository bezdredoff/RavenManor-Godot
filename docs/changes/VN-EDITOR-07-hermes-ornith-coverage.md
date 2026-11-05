Task IDs: VN-EDITOR-07 (vn-studio documentation sub-slice)

Changes:
- Added `addons/vn_studio/PARITY_COVERAGE.md` — an evidence-backed table with exactly three requirement rows, each anchored to a real test file and line range:
    * full authored scene round-trip parity -> vn_studio_full_authoring_e2e_smoke.gd L9/L35/L41/L65
    * background texture/plate parity vs gameplay Resolver (real apartment plate) -> vn_studio_backgrounds_smoke.gd L13/L30/L32
    * responsive layout at window widths [800, 1024, 1366] -> vn_studio_layout_smoke.gd L41-54
  A ground-truth donor block records `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`
  and the manifest-reported corpus target (scenes=45 / lineOccurrences=1026) without copying imported content.
- No code, tests or assets added; no donor story text or art published to public Raven.

Verification: static review only — test source was read and its assertions inspected; no Godot tests were executed, so no pass/fail or acceptance is claimed. Confirmed by reading file contents (not inferred across the repo): full_authoring_e2e copies real Raven registries into an isolated user:// fixture and asserts 28 scenes / 280 lines plus approved BG-HALL and portrait assetIds; backgrounds_smoke opens the real res:// project and asserts the apartment texture at exactly 1080x1920 matching gameplay Resolver.texture_for_scene; layout_smoke creates real Studio/Raven Control nodes and iterates window widths [800, 1024, 1366]. This is a selected static inventory, not an exhaustive scan.

Owner QA: not performed — this is a documentation slice, no manual acceptance or device/visual run. Remaining gates (full-donor import parity, visual/portrait-motion acceptance, real old-save round-trip) are unverified and left as missing in the coverage note; they must not be inferred from these three rows.

Status impact: VN-EDITOR-07 is `PR_review` for open PR https://github.com/bezdredoff/RavenManor-Godot/pull/200; broad task kept
incomplete pending full-donor / visual / old-save gates. No code or tests added.

Pilot provenance: authored through Hermes with LM Studio ornith-1.5-9b. The initial broad inventory contained unsupported all-synthetic claims and missed completion checks; review requested corrections. A narrowed three-test retry produced this selected inventory but hit its iteration limit before validators. The orchestrator corrected remaining wording, restored final JSON newline, verified the three source references and runs the validators before publication. This is assisted delivery, not an autonomous Ornith success. README includes the inventory link. No Godot execution or donor/visual/device acceptance is inferred. Reuse: documentation-only inventory of existing implementation.

Orchestrator verification: python scripts/raven/tools/progress_shards.py PASS (214 overrides, 124 assignments); python scripts/raven/tools/build_production_dashboard.py --check PASS (249 tasks); git diff --check PASS; compared against origin/main, all assignments and every entry except VN-EDITOR-07 are unchanged. Rollback: revert this documentation slice.
