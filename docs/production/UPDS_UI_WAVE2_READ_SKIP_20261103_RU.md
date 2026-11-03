# GAME-UI-01 · Wave 2 — canonical read history and read-only Skip

Stacked on PR #174 shell (`6be7432`). Donor UPDS-godot `3deed628efd6c22bcd1717f7c545b7d3ca865781`:

| Source | Blob | Decision |
|---|---|---|
| scripts/vn/vn_screen.gd | c44edec0f4a29f05e128cf2d4005009adca0f842 | adapt `_skip_read_lines`, `_is_choice_checkpoint`, `_schedule_auto`, `_auto_delay_for_text`, `_show_history` to Raven adapters |
| scripts/core/story_session.gd | ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02 | adapt `_mark_read` / `advance` persistence boundary; do not import donor StorySession/state |
| scripts/ui/player_preferences.gd | ea81a778c7adf7c0eac2834cd5be577878069153 | existing shared preferences retained; timing currently donor normal speed; speed selector is Wave 3 |

## Save and gate contract

- Add optional `vnReadLines: Array[String]` inside existing Raven schema-v1 campaign. Normalize/deduplicate exclusively against canonical dialogue IDs. Old saves produce `[]`; no migration write on load, no inference from `storyBeatsSeen`, no scene-index or second save key.
- Mark current line only when Next/Auto completes it, atomically with next cursor or final beat event. Failed writes preserve state/cursor/history. Skip never marks more lines read.
- `raven_vn_read_history.gd` adapts donor bounded scan; cannot cross scene end or synthesize choices/events. It stops at canonical adapter-provided `choiceGate.checkpointLineId`, `match3Gate.checkpointLineId` or explicit checkpoint IDs. Missing line mapping disables automatic playback.
- Current approved Raven slice is linear; production dispatch admits only its existing scene/first-clear gates. No VN Studio draft edges, donor hardcoded VN0040 or speculative branch semantics are promoted to runtime. Checkpoint barrier fixtures prove fail-closed behavior, not newly playable choices. Full choice-screen migration remains a separate implementation requirement.
- Auto mode remains transient view state across lines, paused by overlays and checkpoints. Normal delay is donor `2500 + min(1800, max(0, length-28)*18)` ms. No new preferences format.
- History renders persisted read IDs through canonical locale adapter, survives scene/reload and does not mutate progression. Current partially paged text is not recorded as completed/read.

Rollback: revert Wave 2. Older builds ignore the optional field; if an older build re-saves, read history is dropped conservatively. Keep production saves backed up for manual downgrade. No reducer logic, economy, canonical content, art or IDs changed.

## Verification

Godot 4.7.2 `vn_read_skip_smoke.gd` PASS: old/JSON save normalization, unknown/duplicate IDs, first-read disabled, reread stops at unread/checkpoint, final-scene boundary, choice/Match-3 barriers, atomic line advance, injected write failures for Next and Skip, cursor/history restart, New Game reset, unchanged reducer revision/wallet/beats. Errors during failure injection are expected; PASS marker and no SCRIPT ERROR required.

Full `scripts/check.sh`, exact-head PR CI, native screenshots and physical phone/user checks are tracked in PR/STATUS. No whole-UI or owner parity acceptance implied.
