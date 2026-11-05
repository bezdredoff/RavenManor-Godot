# VN Studio parity coverage — Raven Manor

Selected static inventory of semantic-parity / data-integrity checks that exist
in `tests/raven`, plus acceptance gates these checks do not establish. This is a **selected**
review, not an exhaustive scan: it does not claim absence across the whole repo.
No Godot tests were executed here; every row below is read source only.

## Ground-truth donor (not copied)

- Canonical private donor: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`
- Public Raven manifest corpus target reported by the project manifest: scenes=45, lineOccurrences=1026, hiddenOccurrences=213.
- No donor story text or assets were copied into public Raven; reuse is documentation-only.

## Requirement rows (selected static inventory)

| # | Requirement | Test path + assertion/function | What static source shows | What remains unverified |
|---|-------------|--------------------------------|--------------------------|-------------------------|
| 1 | Full authored scene round-trip parity (28 scenes / 280 lines, approved plate + actor art) | `tests/raven/vn_studio_full_authoring_e2e_smoke.gd` — copies real registries (`SOURCE_FILES`, L9), asserts `sceneCount==28 and lineCount==280` (L35), plate `backgroundId=="BG-HALL"` (L41), cast portrait `assetId` present (L65) | Source copies public Raven registries into an isolated `user://` fixture, without touching the owner's draft; asserts the Raven registry counts and that approved art IDs are retained. | Execution of this test was not performed for this inventory. Full private-donor parity and real old-save compatibility are separate gates. |
| 2 | Background texture/plate parity with gameplay `Resolver.texture_for_scene` (real apartment plate) | `tests/raven/vn_studio_backgrounds_smoke.gd` — opens real `res://` project (L13), asserts prologue apartment texture at exactly 1080x1920 matching `Resolver.texture_for_scene` (L30/L32) | Source loads the real apartment texture and compares VN Studio `_bg_image` to the gameplay Resolver output by pixel size. This does not establish exhaustive background-state coverage. | Visual/portrait-motion acceptance on device; exact donor asset SHA parity across every lighting/state combination not run here. |
| 3 | Responsive layout keeps stage controls reachable at short window heights (800/1024/1366) | `tests/raven/vn_studio_layout_smoke.gd` — builds real Studio/Raven Control nodes, iterates widths `[800, 1024, 1366]` (L41-54), asserts scroll not disabled and body fills viewport; Story Map graph canvas grows tall pane (L57-65) | Source creates live editor UI and checks vertical scroll mode + minimum-size fit at each width without requiring deep scrolling. | Native Windows Editor visual QA on real hardware; taller-window / high-DPI geometry acceptance remains separate manual evidence. |

## Separate acceptance gates (unverified by this inventory)

- Full private-donor import parity (all 45 scenes / full corpus).
- Visual/portrait-motion and native-device acceptance.
- Real old-save round-trip against the private donor save schema.
