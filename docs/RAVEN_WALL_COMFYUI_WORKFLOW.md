# Raven Manor first-act wall art · ComfyUI production workflow

Status: **52 reproducible generation candidates; outputs require visual approval** (26 October 2026).

## What the batch makes

The exact prompts, seeds, categories and filenames live in `data/raven/comfyui_wall_asset_manifest.json`:

| Group | Count | Contents |
|---|---:|---|
| Structural tiles | 28 | Seven shapes for each of `grand`, `residential`, `service`, `glass` |
| Door states | 12 | Grand single, grand double, service single and glazed double; closed/open/damaged |
| Windows | 5 | Grand, residential, bathroom, kitchen and conservatory families |
| Grand arch states | 3 | Open, gated and damaged |
| Foreground balustrades | 4 | Left/right, intact/damaged |
| **Total** | **52** | Upper bound of the approved 48–52 image estimate |

Every prompt begins with the same Raven Manor style/camera contract and adds one exact asset description. Structural materials vary only through four controlled style clauses. Every output has a fixed seed and stable ID; rejected candidates can be regenerated without changing unrelated assets.

## Installed local stack

The workflow targets models already present in `D:\AI\ComfyUI-Desktop`:

- `Flux2-Klein-9B-True-V3-fp8mixed.safetensors`
- `qwen_3_8b_fp8mixed.safetensors`
- `flux2-vae.safetensors`
- `BiRefNet_toonout.safetensors`
- custom nodes `VNCCS_Flux_Klein_Encoder` and `VNCCS_RMBG2`

The API template is `scripts/raven/comfyui/raven_wall_asset_api.json`. It uses a generated black geometry guide as the first image condition and the current Hall painting as a style-only second reference. Flux renders a 1024×1024 candidate; BiRefNet saves a separate alpha PNG. Raw and transparent results remain side by side.

## Run all 52

Start ComfyUI and wait until `http://127.0.0.1:8188` is available, then from the repository run:

```powershell
python scripts/raven/comfyui/run_wall_asset_batch.py
```

The runner checks every required node and verifies the three model names against live `/object_info` before queuing anything. It creates geometry guides under `ComfyUI/input/RavenManorWallKit/`, copies the existing Hall style reference there and queues all 52 jobs. Results are written below `ComfyUI/output/RavenManor/walls/raw/` and `alpha/`.

Useful safe modes:

```powershell
# Validate all prompts and guide silhouettes without ComfyUI.
python scripts/raven/comfyui/run_wall_asset_batch.py --dry-run

# Generate one review sample first.
python scripts/raven/comfyui/run_wall_asset_batch.py --only wall_grand_straight_h --wait

# Queue the first four candidates only.
python scripts/raven/comfyui/run_wall_asset_batch.py --max-jobs 4
```

`--wait` keeps only one active generation at a time. Without it, ComfyUI receives the complete queue and processes it normally. Re-running an ID intentionally creates ComfyUI-numbered candidates instead of overwriting earlier files.

## Prompt contract

The shared prompt requires: isolated modular game asset; late-Victorian Gothic Raven Manor; hand-painted stylized realism; crisp readable silhouette; orthographic 65-degree top-down camera; exact guide geometry; common warm directional light; plain white isolation background; complete uncropped object. It explicitly excludes rooms, floor scenes, characters, furniture, text, borders, fisheye distortion and unrequested openings.

The manifest contains the complete resolved English prompt for each file, rather than relying on undocumented UI text. To change the prompt matrix, edit `build_wall_asset_manifest.py`, regenerate the manifest, review the diff and run its tests. Do not hand-edit one generated prompt and silently break family consistency.

## Review and integration gate

Generation does not equal approval. Before any PNG replaces a pilot asset:

1. Reject clipped alpha, opaque canvas edges, floating fragments and incomplete cutouts.
2. Overlay every straight/corner/end tile of a style and verify identical trim height, light direction and seamless endpoints.
3. Put doors, windows and arches into their matching wall style; ensure no baked wall/floor surrounds remain.
4. Compare Hall candidates at 65°/0.74× against the five exact portal guides and two staircase rectangles.
5. Check intact/damaged state silhouettes do not move pivots or thresholds.
6. Check both balustrade cutouts with Onoe behind and in front; alpha gaps must remain genuinely transparent.
7. Record accepted output filename, SHA-256, model, seed and reviewer decision in a separate approval manifest.
8. Only after that review may Godot replace schematic gold rails or promote the three-piece seating collision.

No generated file is copied into production assets automatically, and the workflow never changes routes, saves, collision or story data.
