Task IDs: PROC-007
Changes: Stage 2 dashboard and GAP drift consumers use progress_shards.load_shards; sourceFiles points to all 15 shards + index; legacy production_progress frozen. Full shadow-render comparison ignores only sourceFiles; no gameplay/save changes.
Verification: Add blocking test_sharded_dashboard.py, update check_data.sh and mobile dashboard source reader. Existing Godot/Room Builder/art/Web CI remains. Exact-head CI pending.
Owner QA: No device or owner acceptance; no parallel agent writes until Stage 3 shared GAP/workstream migration.
Status impact: PROC-007 remains in_progress until Stage 3; 214 entries and historic evidence unchanged.
