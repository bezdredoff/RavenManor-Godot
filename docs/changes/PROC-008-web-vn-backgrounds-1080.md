# PROC-008 — Web-only VN background reduction to UPDS-class 608×1080 (2026-11-06)

Task IDs: PROC-008 (qa-infrastructure; scoped Web packaging follow-up). Baseline main 8c133b3ca415fa4b6c3d90e6a5ab4de50f3d5354, after PR #224's owner-approved 1024px portraits and successful main Pages deployment.

Changes: The GitHub Actions `web-package` job uses Godot `--headless --editor --import` to generate missing untracked background `.webp.import` descriptors, overrides only the 26 catalogued/approved VN backgrounds to `process/size_limit=1080` in an ephemeral checkout, then runs a second Godot import before exporting. Original 1080×1920 WebP images and their catalog SHA256/provenance are preserved; native VN Studio and local Godot import unchanged. Prior 62 × 1024px Web portrait optimization and all 6 module CI gates retained. Python contract/unit tests and Godot runtime tests inspect all approved asset links, dimensions and aspect ratio; PCK size report continues unchanged.

Verification: Source catalog contains 26 approved 1080×1920 backgrounds. A width-only cap of 1080 would have *zero* impact, so use 1080 **longest edge**, approximately 608×1080, identical to UPDS Godot's background budget. Exact-head CI currently pending. Previous baseline PR #224 CI [42293508772](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42293508772): index.pck 78.13 MiB, imported VN backgrounds 49.06 MiB, portraits 14.67 MiB; main Pages artifact 91,279,150 bytes after PR #225 [42298968042](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42298968042). No new savings claimed until next successful Web export.

Owner QA: After owner merge and site publication visually compare Day/Night Hall, Road, Entry, Library, Conservatory, Kitchen, Garden backgrounds in VN with 390×844 mobile and high-DPI phone/desktop; check details, letters/edges, dark scenes and readable overlays, fullscreen cropping, RU/BE/EN and save continuation; native VN Studio should still display full-resolution approved masters. User's earlier approval of *portrait* quality does not imply background visual approval.

Status impact: PROC-008 remains P1/partial/PR_review pending new CI and owner visual QA. qa-infrastructure shard only, no other agent ownership changes; no modification to master arts, registries, story, save schemas or games.

Risk/rollback: Double Godot import extends Web CI runtime but is required because background .import descriptors are *not tracked* (unlike character portraits). Generated imports are not committed. Revert the three added Web-background workflow steps and smoke test step if quality/regression fails; approved originals remain byte-identical.

No automatic merge or asset acceptance.
