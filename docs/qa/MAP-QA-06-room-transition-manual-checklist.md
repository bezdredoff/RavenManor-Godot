# MAP-QA-06 — Room handoff manual QA (all HUMAN_PENDING)

Project: Raven Manor; Godot 4.7.2. Open scenes/raven/tests/room_transition_synthetic.tscn; press F6. Placeholder rectangles are not approved manor geometry.

- [ ] Room A begins with actor feet on QA-A-ENTRY; blue area, authored anchor markers.
- [ ] Select A → B and watch every leg; room must not switch before actor is physically at QA-A-DOOR.
- [ ] Room B is green; actor appears only at its QA-B-ENTRY safe anchor.
- [ ] Walk within Room B; then B → A; actor returns to QA-A-ENTRY, not the previous arbitrary XY.
- [ ] Locked door: rejection, position and room unchanged, no animation/reward.
- [ ] Future door: rejection even if a test unlock is attempted; no imagined area.
- [ ] Virtual portal: a diagnostic only after feet reach QA-A-VIRTUAL; no room switch or fake spawn.
- [ ] Press a transition request twice during motion: no duplicate segments or room switches.
- [ ] Cancel a transition mid-leg: the physical leg completes; no teleport, no room switch.
- [ ] Toggle Gate: approach while Onoe is on the second leg; verify exact on-screen feet are held.
- [ ] Toggle Gate: approach back to open; resume only the already-started leg, no transition.
- [ ] Toggle Gate: A ↔ B after reaching approach: no crossing, no position snap.
- [ ] Pause/resume with button: actual XY unchanged while paused.
- [ ] Close/reopen gate at exact completion race: hard hold needs explicit reset; no invisible rollback.
- [ ] Verify no user:// production save modifications, no change in campaign Continue state.
- [ ] Portrait 390×844, 412×915, 430×932, landscape/tablet: buttons visible, no clipped critical labels or unexpected scale.
- [ ] Mouse/touch click: control presses are discrete; no free tap-to-move.
- [ ] Close and reopen F6: test gates reset, initial room/anchor restored.
- [ ] Existing Hall pilot and Prototype Lab remain playable, without new transition activation.

Record Godot version, OS, viewport, screen recording or screenshot, physical-foot coords at a failure, requested transition ID, confirmed anchor and safe-hold status. A headless smoke passing does NOT grant visual/owner approval; no canonical Corridor or Bedroom door is tested here.

Headless test: godot --headless --path . --script res://tests/raven/map_qa_06_room_transitions_smoke.gd --quit-after 150
