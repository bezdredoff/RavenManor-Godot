Task IDs: PROC-006, GAME-QA-01
Changes: Split pages.yml into independent data, Godot runtime, Room Builder, art and Web packaging jobs. Preserve blocking aggregate build and main-only deploy. Extract non-Godot source checks to scripts/check_data.sh, preserving local scripts/check.sh behavior. No gameplay code, save schema or incoming ZIP workflow changes.
Verification: All original checks mapped to individual jobs, no removals; exact-head GitHub Actions pending. Requires five successful independent jobs and aggregate build. Visual-only dashboard snapshot tests remain advisory, source validators blocking.
Owner QA: Manual phone/device and real incoming ZIP smoke after main merge remain pending.
Status impact: PROC-006 CI candidate, GAME-QA-01 remains open; central status reconciled post-merge.
