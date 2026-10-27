# Raven Manor — phone ZIP inbox

**Use this branch (`incoming`), not `main`.** This folder accepts one versioned `raven-delta-v1` archive at a time. The GitHub Actions workflow validates the archive, creates a `candidate/mobile-*` branch and a review PR, and runs independent Godot/Room Builder/Web tests. Never merge a smoke-test PR.

## iPhone / Android test
1. Download the provided `RM-MOB04_PHONE_R1.zip` file into the phone's Files/Downloads.
2. Open this folder on GitHub **with branch `incoming` selected**. Select **Add file → Upload files** (on mobile Safari, Request Desktop Website if Upload files isn't shown).
3. Upload the ZIP to `incoming/` and commit **directly to `incoming`**, never to main. Keep just one ZIP in this folder.
4. Visit GitHub → Actions → `Import Raven mobile ZIP candidate`. It should open a `Mobile ZIP candidate: MOB04-PHONE-R1 (MOB-04)` PR, and dispatch the standard read-only test/export workflow.
5. Do not merge the disposable PR. Close it after validation, and delete the ZIP from `incoming/`.

**Important:** `patch-manifest.json` includes a frozen main SHA. If main has advanced since the ZIP was packaged, it will be rejected intentionally; ask for a regenerated ZIP rather than trying to bypass validation.

Canonical documentation: `docs/process/MOBILE_ZIP_PIPELINE_RU.md` on main.
