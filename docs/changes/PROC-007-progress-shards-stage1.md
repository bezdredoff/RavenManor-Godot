Task IDs: PROC-007
Changes: Owner-approved modular progress stage 1; register task in backlog/active workstream, partition all progress entries by 15 stable functional ownership domains, add strict schema and 1:1 legacy parity loader plus tests; keep dashboard's original source unchanged.
Verification: New source/data CI gate validates all shard IDs and complete original evidence/statuses/metadata; regression tests check duplicate IDs, extra shard files, missing tasks and evidence drift. Exact-head Actions pending. Full existing games/Room Builder/Art/Web tests unchanged.
Owner QA: Architectural migration authorized 2026-11-05; production dashboard source switching and per-agent writes NOT yet accepted or enabled. No manual gameplay/device acceptance.
Status impact: PROC-007 in_progress; 213 existing statuses remain exactly unchanged; Stage 2 and Stage 3 require separate merges. Legacy production_progress remains authoritative until switch.
