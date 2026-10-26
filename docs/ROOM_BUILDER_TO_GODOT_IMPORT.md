# Room Builder → Godot: real game-view scene importer

## Готовая сцена из исходной расстановки

**Не нужно скачивать JSON или запускать конвертер для первого просмотра.** В репозитории уже сохранена настоящая сгенерированная сцена `scenes/raven/generated/RM_ROOM_HALL_GamePreview.tscn`, собранная из `examples/room_builder_hall_original.json`. После `git pull` открой эту `.tscn` напрямую в Godot или запусти **Prototype Lab → 6 · Room Builder → Godot**. В веб-сборке Prototype Lab этот же пример доступен в пункте 6.

Сцена проверена автоматическим импортом движка; GitHub Actions заново генерирует `.tscn` из исходного JSON и сравнивает содержимое байт-в-байт с зафиксированным файлом. Это гарантирует, что готовый пример не оторвался от расположения в редакторе.

Внутри узла сцены `ReferenceGeometry` есть шесть исходных прямоугольников игровых препятствий (включая оба марша лестницы). По умолчанию они скрыты; включи видимость этого узла в инспекторе Godot для сравнения. Это **ориентиры**, не коллизии. Дверные точки импортированы как `Marker2D`.


Status: **working isolated visual importer**, not approved live-game scene. The old importer made flat top-down schematic scenes; the new one correctly preserves the 65° perspective and source artwork as a standalone `.tscn`.

## From tablet to Godot

1. In Room Builder open the finished room and select **Экспорт → Проект JSON**. Save the exported file somewhere your Godot workstation can access.
2. From the `RavenManor-Godot` checkout on your development computer run:

   ```bash
   python3 scripts/raven/tools/import_room_builder_game.py /path/to/downloaded/hall-room.json
   ```

3. Open `scenes/raven/generated/RM_ROOM_HALL_GamePreview.tscn` in the Godot editor, or run that scene with **F6**. When the generated scene is present, the Prototype Lab launcher also offers **6 · Room Builder → Godot** after restarting it.
4. To update after further work in Builder, re-export JSON and run the same importer again. Keep exported JSON as your source and back it up: the generated preview scene is disposable.

The command supports **all eight room IDs**, but dimensions must match their still-provisional rectangles in `data/raven/season1_world_map.json`. For Hall the accepted *test* mapping is 700×690 local coordinates at world origin (500,150). A legacy 1000×800 Hall is **rejected**, not silently reprojected.

## Exact output contract

- `floor` objects are compressed by `sin(65°)` vertically; upright furniture preserves its visual sprite height. Scene objects store stable instance IDs, catalog reference IDs, state, hotspot, world-local top-left/size and image provenance as Godot metadata.
- Seven experimental Hall pilot PNG cutouts and the Hall background are resolved from the same committed sources as Builder and Godot. Personal embedded PNG, JPEG or WebP cutouts are extracted and linked as genuine Godot textures with collision-safe file names.
- Items with missing/unrendered PNGs, unsupported pilot rotations or incompatible variant states become **visible placeholders**. An unapproved image is never relabelled as an approved dirty/broken asset.
- Test **characters are deliberately excluded**, as requested. Only room layout is imported, not Onoe or gameplay-character coordinates. Invisible layers are skipped. Author anchor points are exported only as informational `Marker2D` nodes.
- The preview uses a 0.74× Godot camera zoom; its initial viewport is a reference setting, not certified identical UI framing. Approximate z-index sorting reflects object foot depth; actual collision, doors, foreground-wall masks and character interactions still need separate approval.
- The output is tagged `DRAFT_ONLY`. It does **not** change existing gameplay scenes, the 11-door world graph, authored fixed walking routes, collider bodies, repair states, VN/match-3 flow, or campaign saves.

## Testing and limitations

An original-layout mirror lives at `examples/room_builder_hall_original.json` (and is copied into the test fixture). It is **generated deterministically from the existing `season1_world_map.json` and `hall_visual_contract.json`**, rather than designed a second time. It contains the current seven PNG placements, five actual door anchors, six original physics-guide rectangles (including both stair marches), and one excluded Onoe test character. The sample at `tests/fixtures/hall_room_builder_export_sample.json` therefore contains seven Hall pilot cutouts and one intentionally excluded test character. GitHub CI calls the importer to generate the scene, runs Python tests (coordinates, dimension rejection, real embedded PNGs, state handling), and loads/instantiates it in **Godot** before building the web prototype. Thus the published Prototype Lab's imported Hall is a **fixture demonstration**, not a live copy of the user's tablet layout.

Import works one way: **Builder exported JSON → standalone Godot preview scene**. The next stage, after examining the actual exported tablet Hall, is to agree on the room layout, correct door/occlusion/collision alignment, and then explicitly attach approved render layers to the live Godot map. This importer intentionally does not perform that final gameplay integration.

The original `import_room_builder.py` remains for old 2D schematic previews and `sync_hall_preview.py` for the seven-art visual-only world-map override. Use `import_room_builder_game.py` for the main direct game-view room preview.

## Original layout already reconstructed (not horizontally flipped)

The original provisional composition was recreated from the actual current Godot source, **not guessed or reversed left-right**. Source geometry: Hall (500,150,700,690); clock world (575,460,60,90), seat cluster world (640,560,160,125), two stairs world (640,190,115,195) and (945,190,115,195), console (1110,720,70,65), gallery (525,220,65,165), plus actual Entry/Archive/Corridor/future door markers. The two chairs remain independently rendered PNG instances while the original current gameplay collider remains combined.

Godot renders the original pilot background and all seven existing cutouts in a dedicated review scene. The six physics/architecture rectangles are available as **ReferenceGeometry** in the scene tree, hidden by default; toggle visibility to inspect where the old gameplay map would treat furniture or stairs as obstacles. They are *not* live collision shapes. Opening this example does not alter `Whole Manor Map` or campaign state.

To load the same original arrangement **back into Builder**, use **Импорт JSON** and choose `examples/room_builder_hall_original.json` from the repo. Do not import without saving your current tablet draft first. To regenerate both source JSON outputs after a map change, run `python3 scripts/raven/tools/build_original_hall_layout.py` and then `python3 scripts/raven/tools/import_room_builder_game.py examples/room_builder_hall_original.json`. CI asserts JSON/source parity and successfully loads the scene in Godot.
