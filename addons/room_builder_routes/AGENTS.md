# Room Builder Navigation / Routes native Godot editor

Owner domain: `room-builder`. Read root `AGENTS.md`, `CHATGPT.md`, `docs/process/AGENT_ORCHESTRATION_RU.md` and `tools/room-builder/AGENTS.md`.

This add-on edits only separately versioned `DRAFT_ONLY` image-pixel route documents. Hall art, source QA JSON, canonical first-floor manifest/13 RM-NAV anchors, campaign/save/reducer, physical doors and gameplay movement belong to other owners. Never auto-promote a draft into the runtime graph; no writing outside `user://room_builder_routes/` and `res://assets/raven/map/qa/drafts/`. Reuse `ManorNavigationGraph` for in-memory QA compilation. Changes to current Hall Movement Pilot or `project.godot` require an integration owner.

Add tests in `tests/raven/map_edit_01_routes_checks.gd`; invoked by the owning existing Room Builder Godot smoke. Maintain import ID stability and do not rebrand provisional imported edges as authored cell routes.
