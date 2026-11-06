# PROC-008 — UPDS-size portrait optimization for Raven Manor Web (2026-11-06)

Task IDs: PROC-008 (qa-infrastructure scoped Web export follow-up). Godot 4.7.2. Source project, catalog, approved art and native VN Studio are unchanged.

Changes: Only the GitHub Actions \`web-package\` job calls \`scripts/raven/tools/prepare_web_portrait_imports.py\` before the first Godot import. The script walks all approved entries in the runtime VN character catalog and modifies their \`.webp.import\` working copies to \`process/size_limit=1024\`. The original master WebP content, filenames, SHA256, catalog data, source project/editor imports and asset approval state are preserved. Godot retains existing lossless mode and alpha/mipmap settings. Added Python unit tests and Godot headless Web import smoke: all 62 assets load, dimensions are <= 1024 on the longest edge, original proportions are retained, and four neutral-sprite alpha samples are preserved.

Verification: UPDS-godot main \`3deed628efd6c22bcd1717f7c545b7d3ca865781\` portraits are 576x864, sized by \`scripts/optimize-game-images.py\` from 1024x1536. Raven has 62 accepted portraits: **50 at 1088×1920 and 12 at 2048×3614**. A Web-only max dimension of 1024 gives approximately 580×1024 in both source groups while preserving aspect ratio. Web PCK baseline before this PR was 121.27 MiB (PR #220 CI https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42284013618). Imported character texture total 57.82 MiB. Actual new Web export/PCK and page artifact savings require exact-head CI and main deploy measurement. No QA or saving claimed before measurements.

Owner QA: After optional merge, review the game on a phone and on a high-DPI screen: Evelyn, Ada, Lucas, Rowan solo and multi-character, faces and hand props, transparency/edges, portraits during microanimation, VN Studio source-quality images in native editor, EN/RU/BE and save resume. The import script must not run in native editor CI; current approved masters remain available for later high-res variants.

Status impact: PROC-008 remains P1 / partial / PR_review; only qa-infrastructure shard is updated. This is Web distribution optimization, not asset reapproval, character-art acceptance or gameplay-task closure.

Rollback: Remove the two Web-only CI preparation/test steps. The original source files and \`.import\` metadata remain untouched in main, so rollback does not require regenerating images or migrating saves.
