# Raven Manor — 07a Restoration economy and gate contract — Stage 2 v0.2

**Status [Proposal]:** testable, intentionally **not monetization**. Stage 1 fixes the **sequence and count**, not resource numbers. Story `work_points` represents prepared work, not cash, tradesperson skill or magically produced physical materials.

## Vertical-slice first-clear economy

| ID | Activity | First-win reward | Cost / effect | Repeat behavior |
|---|---|---:|---|---|
| `RM-LVL-001` | bedroom sorting | +2 `work_points` | `RM-REST-001` costs **2** | failed attempts: 0, retriable; replay after clear: 0 new narrative points |
| `RM-REST-001` | bedroom clear + made bed | — | -2 points, self-performed; bedroom becomes `stabilized` | exactly once; instantly restore visual on load |
| `RM-LVL-002` | bathroom service cabinet | +2 | accrues for bathroom | first-clear only |
| `RM-LVL-003` | prepare bathroom | +2 | accrues for bathroom | first-clear only |
| `RM-REST-002` | plumber fixes facilities after prep | — | -4; additionally requires `plumber_available=true` | once; saved before next beat |

Budget check: 2+2+2=6 reward; 2+4=6 compulsory spending; no forced streak. Bedroom first, then bathroom is a **vertical-slice authored sequence**. Failed levels never consume `work_points`; no lives/energy monetization spec. Cosmetic tasks may be selectable in later chapters, but cannot steal compulsory slice resources. Do not award points on opening a level or on failed attempts.

## Explicit gameplay-state keys [conceptual, not code]

| Key | Meaning |
|---|---|
| `first_clear[RM-LVL-001..003]` | persistent per-level award flags |
| `wallet.work_points` | stored earned minus committed spent points, never below 0 |
| `restoration_done[RM-REST-001]`, `restoration_done[RM-REST-002]` | independently confirmed completion flags |
| `service.plumber_available` | local professional appointment completed, **not** resource purchase |
| `clue_seen[RM-HS-004]` | childhood object journalled; triggers pre/post-Ada conversation once |
| `door_unlocked[RM-DOOR-CORRIDOR-BEDROOM]` | true after two saved repairs + clue |
| `first_crossing[RM-DOOR-CORRIDOR-BEDROOM]` | first night beat fires once on room entry |
| `story_beat_seen[RM-BEAT-01-05]` | persistent scene-once guard |

**Atomic save-order contract:** on winning level: apply first-clear reward once, commit save, show reward. On restoration: verify gating and balance, debit once, set restoration flag + state, save, then show completed state/VN. Specialist may be confirmed earlier as appointment, but repair cannot complete until visit is resolved; invoke via a short call/doorstep vignette **without adding to VS five hotspots**. On replay/save reload, never re-run charge/reward, stage reveal, or dialogue. Interrupted save must show either old state with no debit, or new state with debit—not an inconsistent hybrid. UI can show a transient preparing animation only after an accepted command.

## Dependency and optional order

```text
RM-HS-001 → RM-LVL-001 → RM-REST-001 → RM-LVL-002 → RM-LVL-003
  → service.plumber_available → RM-REST-002 → RM-HS-004 → RM-HS-005
  → RM-BEAT-01-05 → RM-CH-02
```

The plumber may be contacted during Level 2; his final repair still waits for Level 3 and preparation. Inspecting future rooms, reading task hints and photographing objects does not consume resources. From CH02 onward multiple available cosmetic preparations can proceed in parallel; safety, evidence and qualified skills remain hard prerequisite gates. **No arbitrary success streak needed**.

## Season-level restoration table (no false economy precision)

| restoration_id | Room | Role | Hard prerequisites | Performer | Outcome |
|---|---|---|---|---|---|
| `RM-REST-001` | `RM-ROOM-BEDROOM` | compulsory | `RM-LVL-001` and 2 points | Evelyn | clear/made bed, toy revealed |
| `RM-REST-002` | `RM-ROOM-BATHROOM` | compulsory | Levels 002–003, 4 points, plumber | plumber after Evelyn prep | functional bathroom |
| `RM-REST-003` | `RM-ROOM-KITCHEN` | compulsory | first night, electrician safety clearance | electrician certifies, Evelyn preps | safe counter/supply |
| `RM-REST-004` | `RM-ROOM-KITCHEN` | compulsory | 003 + follow-up puzzle prep | Evelyn + qualified hook-up as needed | usable kitchen, album |
| `RM-REST-005` | `RM-ROOM-ARCHIVE` | compulsory | album evidence and shelf safety | specialist if shelf structural | ledger accessible |
| `RM-REST-006` | `RM-ROOM-ARCHIVE` | compulsory | 005 | Evelyn | records and niche accessible |
| `RM-REST-007` | `RM-ROOM-CONSERVATORY` | compulsory | map evidence + gardener inspection | Rowan and Evelyn | safe path |
| `RM-REST-008` | `RM-ROOM-CONSERVATORY` | compulsory | 007 + glazing appointment | glazier | secure glass |
| `RM-REST-009` | `RM-ROOM-HALL` | compulsory | clock part + professional | clockmaker | running clock / clue |
| `RM-REST-010` | `RM-ROOM-CONSERVATORY` | compulsory finale | family letter resolved | Evelyn + Rowan | small gathering overlay |

**[Proposed balancing policy]** Outside VS, task costs/rewards are left unspecified until level cadence/design targets are established. The order between exploratory inspections and non-critical cosmetics is flexible; an optional choice can never strand the player without enough resources for the next mainline gate. Opening the east wing or stairs is not purchasable in Season 1.

## Narrative validity of Match-3

Standard reusable matching rules represent clearing and preparation. Visual goal labels switch between sorting belongings, finding fixtures, organizing records and greenhouse tools. Match-3 victory yields *prepared work capacity*; no direct equivalence to sale of valuables. Background and blocker reskins are optional and reuse-driven. Work requiring tradespeople triggers an appointment beat, not a magical instant repair.

## New corridor gating and free-choice safety (v0.2)

1. `RM-DOOR-HALL-CORRIDOR` traversable after the initial hall introduction, regardless of repair currency; player can preview closed bedroom/bath doors.
2. VS consists of five **task hotspots** `RM-HS-001..005`; corridor transit and room portal affordances are navigation controls, not extra task hotspots. `RM-LVL-001 → RM-REST-001 → RM-LVL-002 → RM-LVL-003 → RM-REST-002 → RM-HS-004 → RM-HS-005` is critical order.
3. Before `RM-HS-005` character cannot enter bedroom despite prior cutaway/vignette preparation. Bathroom receives professional access off-camera. This is a deliberate slice presentation constraint, not a realistic inability to walk into physically accessible rooms; post-VS production may relax its door gate if we want more natural navigation.
4. Later chapters allow optional task order only after hard safety prerequisites (electrician/plumber/structural signoff). Work points from cleared levels are fungible, spent once, and cannot bypass tradesperson approval or unlock future wings.
5. Old narrative target `RM-DOOR-HALL-BEDROOM` resolves to physical `RM-DOOR-CORRIDOR-BEDROOM`; `RM-DOOR-HALL-CONSERVATORY` resolves to `RM-DOOR-KITCHEN-CONSERVATORY` after verified passage. Never create two physical doors for one alias.