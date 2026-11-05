# Blender wall kit and map props — `map-props` or `art-pipeline`

Read root `AGENTS.md`, then `docs/process/AGENT_ORCHESTRATION_RU.md` and all relevant local AGENTS. Use the owning `data/raven/production/progress/<domain>.json` and unique `docs/changes/` evidence. Generated dashboard and frozen `production_progress.json` must not be edited. Manual acceptance and merge are not automatic.

Read `docs/BLENDER_WALL_KIT.md`. Use `map-props` shard for map prop/state assets and `art-pipeline` for procedural generation tools. Record Blender version, mesh/material source, pivot, geometry dimensions, tile seams and license/source. Generated mesh/sprite remains a candidate until inspected in Godot; don't replace approved Hall geometry, route anchors, collision or canonical props. Verify actual rendered output separately from code generation tests.
