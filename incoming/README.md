# Raven Manor — phone ZIP inbox

**Use this branch (`incoming`), not `main`.** This folder accepts one versioned `raven-delta-v1` archive at a time. The GitHub Actions workflow validates the archive, creates a `candidate/mobile-*` branch and a review PR, and runs independent Godot/Room Builder/Web tests. Never merge a smoke-test PR.

## iPhone / Android test
1. Download the provided `RM-MOB04_PHONE_R1.zip` file into the phone's Files/Downloads.
2. Open this folder on GitHub **with branch `incoming` selected**. Select **Add file → Upload files** (on mobile Safari, Request Desktop Website if Upload files isn't shown).
3. Upload the ZIP to `incoming/` and commit **directly to `incoming`**, never to main. Keep just one ZIP in this folder.
4. Visit GitHub → Actions → `Import Raven mobile ZIP candidate`. It should open a `Mobile ZIP candidate: MOB04-PHONE-R1 (MOB-04)` PR, and dispatch the standard read-only test/export workflow.
5. Review the candidate PR manually. When `cleanup_incoming_zip` completes, the uploaded ZIP should disappear automatically from `incoming/`, whether the import succeeded or failed. Do not merge a disposable smoke-test PR. If cleanup itself fails or the run is cancelled, inspect the logs and remove the archive manually.

**Important (2026-11-02):** ZIP cleanup is installed in `main` and `incoming` (PR #108/#109), and the invalid-ZIP negative path was confirmed in [run #41417364700](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/41417364700). A positive-path acceptance run remains required. Download handoff ZIPs from `mobile-handoff/` if provided, but upload the actual ZIP file directly into `incoming/` — not the `mobile-handoff/` directory.

**Important:** `patch-manifest.json` includes a frozen main SHA. If main has advanced since the ZIP was packaged, it will be rejected intentionally; ask for a regenerated ZIP rather than trying to bypass validation.

Canonical documentation: `docs/process/MOBILE_ZIP_PIPELINE_RU.md` on main.
