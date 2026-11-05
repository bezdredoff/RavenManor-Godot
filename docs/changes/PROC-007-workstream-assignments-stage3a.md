Task IDs: PROC-007
Changes: Add 124 domain-owned assignments in progress shards (80 active workstreams, 44 P2 reentry). For 35 plan-only IDs assign a domain/group without inventing a status or QA record. Extend progress loader with duplicate/shape validation. Dashboard behavior and canonical status/evidence unchanged.
Verification: New blocking test_workstream_assignment_migration.py checks exact parity with old registries and per-domain ownership; existing Stage 2 shadow dashboard and full CI retained. Exact-head CI pending.
Owner QA: No runtime/device QA, and no independent shard assignment writes until Stage 3b source switch.
Status impact: PROC-007 remains in_progress; no current task status or priority changed.
