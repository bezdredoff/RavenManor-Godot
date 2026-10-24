# Raven Manor — reconciliation and contradiction matrix

| Topic | Older evidence | Current evidence / authority | Resolution |
|---|---|---|---|
| Repository implementation | Imported audit and old plan say the new repo is documentation-only | PR #4–#6 are merged into `main`; tests and Pages build pass | Old wording is historical. `STATUS.md` is current. |
| 70-requirement score | 12 implemented / 30 partial / 6 placeholder / 21 missing / 1 unknown; 0/13 slice steps | Foundation and navigation were implemented after that audit | Preserve baseline counts; rerun after PR 3 instead of guessing revised counts. |
| Bedroom access | Stage 2 files require bathroom repair + clue before bedroom traversal | `RM-DEC-006`: bedroom access is independent; bedroom work follows entry | Current decision wins. Old files remain preserved historical sources. |
| Door behavior | Older FSM expects repeated locked/closed/opening/open/closing presentation | `RM-DEC-005`: unlocked door may remain open or disappear while portal/state persist | Only locked/available is required for the slice; animation states are optional. |
| Navigation | Earlier spike includes free click movement and hardcoded waypoint arrays | `RM-DEC-004` and current authored AStar graph | No free movement. Interactions select graph targets. Do not extend the old spike. |
| Bathroom | Older room plan can imply a walkable bathroom | `RM-DEC-007`: corridor-side vignette is sufficient | PR 3 uses a vignette, specialist flag and persistent visual state. |
| Save/CI status | UPDS status JSON marks `RM-SAVE-001`, `RM-HUB-001`, and Pages as todo/blocked | Standalone Raven save, hub greybox and Pages deployment now pass | UPDS tracker is historical/reference-only; canonical status belongs here. |
| Onoe rights | Earlier audit treated provenance as unresolved | Repository owner explicitly confirmed ownership and authorized repository use | Onoe may be used as a technical placeholder; `ASSET_PROVENANCE.md` records scope. |
| Evelyn identity | ComfyUI prototype uses “Evelyn Blackwood”; a later clone visibly differs | Canon is Evelyn Raven / `RM-CHAR-EVELYN`; no accepted identity reference | Blackwood output is diagnostic and cannot define canon. Select a canonical reference before another clone test. |
| Cast identity | R&D generated Adrian, Lucian and Mara | Canon is Ada, Lucas and Rowan alongside Evelyn | Generated non-canonical characters do not replace cast IDs or descriptions. |
| VNCCS version | Installed folders documented as 3.1.2; upstream has 3.2.x/3.3.0; wrappers target older calls | Static 3.3 compatibility review found API risks; no accepted runtime migration | Do not call any version “production baseline” without a fresh manifest and clean reference-transfer run. |
| VNCCS evidence | Wrapper/full-flow attempts created broken, cached or regenerated results | Clean-reference plan requires original reference input and stop-on-drift criteria | Previous outputs remain diagnostic only. No batch generation. |
| Visual style | Multiple generators produced visibly different characters | Draft style contract requires one character/room/prop anchor board and Godot composite | Style remains unlocked. Prototype Lab can host the later composite test. |
| “Raven Miner” naming | Requested review mentioned possible stale references | No `Raven Miner` reference was found in either repository's owned text documents | No replacement was made; do not invent a rename target. |
