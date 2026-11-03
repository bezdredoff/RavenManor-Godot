# Raven Manor — canonical progression and save contract

**Owner-approved planning direction (2026-11-03), not implemented by this document.**

- `work_points` is the **only restoration currency**. Star ratings, if exposed, are cosmetic/performance and cannot pay for repairs.
- Existing `RM-LVL-001..003` remain stable with first-win awards **2+2+2**. `RM-REST-001` costs **2**, `RM-REST-002` costs **4**. No replay farm; no payment on failure.
- `RM-HS-005` opens `RM-DOOR-CORRIDOR-BEDROOM` independently of bathroom repair/clue. `RM-HS-002` is bedroom restoration **after** entering. Bathroom preparation and plumber sign-off are independent bedroom-entry gates. First-night transition waits for required domestic readiness; do not conflate door access and end-of-chapter gates.
- A level win applies reward at most once via Raven reducer, saves atomically, then renders feedback. Restoration verifies safety/specialist and wallet, commits once, saves, then displays state. Resume cannot double-award or double-charge.
- `RavenCampaignStore`/`RavenReducer` is the single state authority. Do not persist parallel UPDS campaign progress.
- Reuse UPDS `22` level definitions as *candidate mechanics/layouts*, with new stable Raven IDs, local fiction and difficulty review; never overwrite `RM-LVL-001..003` or copy UPDS story/session identifiers.
- Locked wings/floors require physical/safety clearance, not arbitrary magic or purchasable currency shortcuts.
- 24 canonical beat IDs and 28 production VN scenes are different inventories; a coverage mapping is required before claiming complete season.
- Draft VN Studio branches/FX require review/publish before game runtime; approved backgrounds and character images alone do not imply scene integration.

**Validation required before runtime changes:** source-level contract test for first-clear/replay/reload, bedroom independence, legacy save migration, IDs, and all available restoration gates. Scope expansion for season balance is a separate owner gate.
