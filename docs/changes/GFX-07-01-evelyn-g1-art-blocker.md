Task IDs: GFX-07-01; related GFX-07-05/06/09/10, GFX-11-T06 (not closed).

Changes: Audited #266 main, accepted Evelyn references, camera and Onoe visual/movement contracts. Made one built-in image-generation attempt plus one correction. Neither met production requirements. Added an explicitly rejected correction source, canonical identity/provenance contract, deterministic target atlas specification, per-cell alpha/bounds audit and precise import-ready handoff with owner QA. No usable atlas, validated animation frames or moving Evelyn harness is claimed. No production replacement.

Verification: EXECUTED_PASS — python assets/raven/chibi/evelyn/g1_candidate/audit_source.py --check; python scripts/raven/tools/progress_shards.py (216 overrides / 125 assignments / 15 domains); python scripts/raven/tools/build_production_dashboard.py --check (250 tasks / 28 stages); git diff --check. Godot 4.7.2 version checked; Evelyn runtime/device/occlusion tests NOT_RUN because production art is blocked. Exact-head GitHub CI remains separate from art acceptance.

Owner QA: NOT_RUN. See assets/raven/chibi/evelyn/g1_candidate/HANDOFF.md for eight explicit checks covering identity, both legs, frame/pivot, turns, start/stop, pause/resume/cancel, 390×844 map scale, foreground occlusion, reduced motion and real phone. No auto-approval or merge.

Status impact: GFX-07-01 PR_review / partial in draft https://github.com/bezdredoff/RavenManor-Godot/pull/269; art remains blocked. Related tasks remain open. G1 Definition of Done is NOT MET. Owning shard only; no generated dashboard or frozen monolith edit.

Baseline: 832657cbbed2511a38485ae869b9b021484eb7c8. Fresh GitHub search found no open PR at initial audit. UPDS main tree reconfirmed 3deed628efd6c22bcd1717f7c545b7d3ca865781; Raven existing directional/movement adapter reuse is specified with blob SHAs in the handoff. Historical bible coat/vest proposal is superseded for this asset by owner-accepted VN images; no new canonical outfit inferred.

Scope: assets/raven/chibi/evelyn/g1_candidate/**; this note; data/raven/production/progress/chibi-animation.json. No runtime or shared CI change. Agent E was notified; source-audit PASS means reproducible rejection evidence, never accepted art.
