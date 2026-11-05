# Room Builder owner: `room-builder`

Read repository-root `AGENTS.md` and `docs/process/AGENT_ORCHESTRATION_RU.md` first. These local rules supplement root policy. Update only the owning `data/raven/production/progress/<domain>.json` plus unique `docs/changes/` evidence; never manually edit generated `dashboard/status.json` or frozen `production_progress.json`. Never auto-merge or claim unverified owner/device/art acceptance.

Own draft PWA `tools/room-builder/**` and narrow importer tests. Read its README and `docs/ROOM_BUILDER_VOLUMETRIC_ROOMS.md`. Preserve schemaVersion, `RM-ROOM-*` and hotspot IDs, scale/camera 65°/45° assumptions, versioned export and undo/touch behavior. Import produces **draft** geometry, not accepted Godot navigation/collisions. Changes to approved Hall, routes, canonical scenes or reducer require integrator. Run Room Builder Node/browser/importer and impacted Godot map tests; report real device QA separately.
