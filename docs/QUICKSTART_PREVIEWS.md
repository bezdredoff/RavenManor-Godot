# Quickstart: Raven Manor previews

Updated 2026-10-25 for merged RM-VS-01, Content Preview, Room Builder PWA and Hall AI pilot. Specific Godot/Web build status is maintained in `docs/STATUS.md`.

## One universal launcher

Open `project.godot` in Godot 4.7.2 and press **F6/F5**, or run:

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path "C:\git\RavenManor-Godot" --editor
```

The project main scene is `res://scenes/raven/prototype_launcher.tscn`.

The published build is <https://bezdredoff.github.io/RavenManor-Godot/>. The published page updates from `main` after its Pages build; both the custom Actions and legacy branch/Jekyll workflows are still active.

## Test one continuous Season 1 map (new feasibility greybox)

Choose **5 · Whole Manor Map · S1 GREYBOX** in Prototype Lab.
The shared-coordinate schematic contains all six season-one story spaces, Entry and Corridor, 11 canonical doorway relations and major furniture footprints. Drag/touch to pan, mouse wheel or −/+ buttons to zoom, recenter on animated Onoe (authorized noncanonical placeholder), and select room props to walk to safe interaction points. Shared shallow pseudo-orthographic floor projection and AStarGrid2D orthogonal routes now avoid major furniture and walls. **ВСЕ ПРОХОДЫ: ТЕСТ** permits non-future rooms solely for spatial testing; **ПО СЮЖЕТНЫМ GATE** respects currently stored door flags. Select a repair-related prop to open its linked level with **MATCH-3**; preview is isolated and does not award real repairs. **До / После** changes only the block's local visualization.

**AI Hall art comparison (merged PR #17, still experimental):** In the same Whole Manor Map, open **Настр.** and tap **Вид** to cycle **AI1** (default twin staircase Hall + separate generated props) → **AI2** (alternate crimson painting; runner baked in) → **ПЛАН** (plain greybox) → **SVG** (previous vector mockups) → AI1. The original 8 generated PNGs, SHA-256 manifest and explicitly **reconstructed** image prompts are in `assets/raven/hall/generated_pilot/`; see `docs/assets/RM_HALL_GENERATED_ART_INTEGRATION.md` for placement, known visual mismatches, and acceptance steps. This is a **visual composition test** only; generated walls/door openings are not yet metrically calibrated to the continuous map.

**Camera / art calibration (pilot):** the map now starts with **65° camera elevation, zoom 0.74×**, hall-focused framing, a compact full-screen mobile HUD and a separate Hall shell plus painted-vector placeholder props. Tap **Настр.** then **Камера: 65°** to cycle 45° → 55° → 65°. The main HUD offers zoom −, zoom-preset cycling (0.68× / 0.74× / 0.80×), zoom + and recenter; diagnostics (gate, art, bounds, safe viewport, overview) are hidden under **Настр.**. **Вид** cycles **AI1 → AI2 → ПЛАН → SVG**; **Габариты: СКР** shows clickable collision outlines. Onoe stays upright at every angle. Compare portal widths, floor legibility, clock and chair sizes, and screen-space tap targets before locking any angle. Prompts and art provenance: `docs/assets/RM_CAMERA_ART_PILOT.md`.

This new mode does **not** replace the existing Hall→Corridor→Bedroom vertical-slice graph. Full 2D layer art, collision certification, pinch zoom and real mobile touch QA remain pending. Implementation notes: `docs/RM_MAP_S1_GREYBOX.md`.

## Test one Match-3 level

In Prototype Lab choose **4 · Content Preview**, then choose:

- `RM-LVL-001` — «Пыльные коробки»;
- `RM-LVL-002` — «Следы под обоями»;
- `RM-LVL-003` — «Запертый водопровод».

The preview uses real adjacent swaps, match validation, cascades, objectives and move limits. **Сделать подсказанный ход** executes a legal deterministic move. Restarting a level recreates its seeded initial board. Isolated preview does not award work points or modify Raven-save.

## Test one VN scene

In **4 · Content Preview** choose any stable beat:

- `RM-BEAT-01-01` / `arrival`;
- `RM-BEAT-01-02` / `bedroom`;
- `RM-BEAT-01-03` / `trace`;
- `RM-BEAT-01-04` / `night`;
- `RM-BEAT-01-05` / `complete`.

**Далее** advances the line and loops to the beginning at the end. Isolated VN preview does not mark a beat as seen.

## Test all systems together

Choose **3 · RM-VS-01 vertical slice** or **Начать общий flow**. This route uses the canonical Raven snapshot and runs:

1. `RM-HS-005` and bedroom door unlock;
2. arrival VN;
3. `RM-LVL-001`;
4. bedroom restoration `RM-HS-002` / `RM-REST-001`;
5. bedroom VN;
6. `RM-LVL-002`;
7. clue setup VN;
8. `RM-LVL-003`;
9. `RM-REST-002`;
10. childhood clue;
11. night VN;
12. completion VN and persisted completed state.

The footer controls are:

- **Save** — persist the current canonical snapshot;
- **Reload** — discard the in-memory copy and reload the saved snapshot;
- **Reset** — delete only the Raven campaign save and return to a fresh snapshot.

Foundation Sandbox has equivalent **Сохранить**, **Перезагрузить из save** and **Сбросить Raven save** controls. The navigation greybox reads the same save, so bedroom-door state is visible there after reload.

## Run a scene directly

These commands bypass the launcher:

```powershell
$godot = "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe"
& $godot --path "C:\git\RavenManor-Godot" "res://scenes/raven/content_preview.tscn"
& $godot --path "C:\git\RavenManor-Godot" "res://scenes/raven/vertical_slice.tscn"
& $godot --path "C:\git\RavenManor-Godot" "res://scenes/raven/manor_greybox.tscn"
```

Run the complete automated verification:

```powershell
& "C:\git\RavenManor-Godot\check.ps1" -GodotPath "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe"
```

Content definitions live in `data/raven/rm_vs_01_content.json`. The preview is intentionally an engineering/debug surface: current letters/colors are placeholders, not approved production art.

## Tablet Room Builder (independent editor)

Open [Room Builder](https://bezdredoff.github.io/RavenManor-Godot/builder/index.html) in Android Chrome. It is a standalone touch/stylus flat-plan PWA, **not the Godot runtime**. Tap assets to stamp, drag to rearrange, use two fingers to pan/zoom, import owned images and export JSON/PNG. Browser IndexedDB can be evicted; back up as JSON. Standalone Godot scene export is draft-only, unaligned to World Map camera/doors. See `tools/room-builder/README.md` and `docs/ROOM_PIPELINE_NEXT_GATE.md`.

The owner has verified the published editor and game load, but full real-device input, zoom, offline persistence and in-game art/collider QA are still separate acceptance items.
