# Quickstart: Raven Manor previews

Verified against `main` commit `91b656637f3a08ec0761c4170384706b25fa69f1` plus the pending Content Preview change documented here.

## One universal launcher

Open `project.godot` in Godot 4.7.2 and press **F6/F5**, or run:

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path "C:\git\RavenManor-Godot" --editor
```

The project main scene is `res://scenes/raven/prototype_launcher.tscn`.

The published build is <https://bezdredoff.github.io/RavenManor-Godot/>. The page updates only after the Content Preview commit is merged to `main` and the Pages workflow succeeds.

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
