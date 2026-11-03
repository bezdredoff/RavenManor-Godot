# Raven Manor — consistency reconciliation (2026-11-03)

**Authority:** owner-approved `docs/DECISIONS.md` > approved later product amendments > current runtime/production state for *what is implemented* > historical Stage 1/2 proposals. Historical documents remain intact. Runtime is evidence, not automatic product approval.

| Conflict | Sources | Resolution | Gate |
|---|---|---|---|
| Bedroom door after bathroom/clue vs independent | Stage 1 flow, Stage 2 07a vs RM-DEC-006/013 | Bedroom access via RM-HS-005 independent of bathroom; bedroom restoration only after entry. Preserve RM IDs. | Navigation and save QA |
| Free tap-to-move vs authored anchors | older design vs RM-DEC-004 | Only hotspots/door/target authored A* graph | Map device QA |
| Door close/reopen vs persistent open | old Stage 1 vs RM-DEC-005 | Persist portal unlocked; no repeated door animation required | Reload/occlusion |
| Hall direct bedroom vs corridor | Stage 1 vs RM-DEC-002 | Hall→Corridor→Bedroom, legacy names are aliases only | Graph QA |
| Star economy vs work_points | historical Raven design vs Stage 2 Godot | work_points is sole restoration currency; stars may be non-currency performance only. First-clear reward once. | GAME-LOOP-01 |
| 22 UPDS levels vs 3 RM slice IDs | UPDS-godot campaign vs rm_vs_01_content | Retain RM-LVL-001..003 and 2/2/2 rewards; adapt UPDS 22 mechanical layouts as candidates for additional Raven levels, not literal school campaign or automatic replacement | GAME-M3-01 |
| UPDS save vs Raven reducer | shared architecture vs UI imports | RavenCampaignStore/Reducer sole authority; UPDS session used through adapters | GAME-LOOP-01 |
| VN draft vs canonical runtime | VN Studio vs production narrative | Draft/FX/branch tests are editor-only until reviewed publication; approved art != runnable chapter | VN-RUNTIME-01 |
| 24 beats vs 28 scenes | Stage 1 vs production narrative | Beat IDs and scene IDs are distinct types; map explicitly before claiming coverage | CODE-08-01 |
| VN prop catalogue vs map props | older VN Studio plan vs owner 2026-11-03 | Defer standalone VN prop catalogue; map props remain in scope | Existing GFX |
| Approved VN art vs playable map | GFX approvals vs physical Hall gate | Separate accepted art and map geometry/collision/device acceptance | CODE-05-01/02 |
| Merged vs accepted | production_progress rules | Keep independent implementation, QA and owner approval fields; never auto-accept | Dashboard QA |

**Known runtime limitation:** `scripts/raven/upds_match3_campaign_adapter.gd` reads three levels from `data/raven/rm_vs_01_content.json`. The 22 UPDS levels are a *mechanics/layout reuse pool*, not a proven balanced Raven season. No source/runtime migrations are performed in this planning PR.

**Outstanding evidence:** Real device walkthrough, full story mapping, actual 22-level balance, save recovery and Hall geometry must be verified in implementation PRs. No historical approved ID is renamed.

## Reconciliation discipline
1. Read DECISIONS before archived Stage 1/2.
2. Keep historical source wording; attach supersession notices and links.
3. Before a gameplay PR, identify affected stable IDs and saved-state migration.
4. Close task only with its own evidence; merged != accepted.
