# Godot scenes — shared integration boundary

Read root `AGENTS.md`, then `docs/process/AGENT_ORCHESTRATION_RU.md` and all relevant local AGENTS. Use the owning `data/raven/production/progress/<domain>.json` and unique `docs/changes/` evidence. Generated dashboard and frozen `production_progress.json` must not be edited. Manual acceptance and merge are not automatic.

`scenes/raven/**` contains launcher, VN/Match-3 hosts, map/greybox and generated scenes with cross-domain references. Explicitly request integration scope before editing `vertical_slice.tscn`, `main_menu.tscn`, `manor_greybox.tscn`, `project.godot` or generated imports. Preserve Godot UIDs, scene/node paths, screen size, save resumption, occlusion and authored route geometry. Rebuild generated scenes from authoritative source instead of hand-patching their output; test impacted gameplay and device view.
