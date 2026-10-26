# Raven Manor first-act wall art · ComfyUI production workflow

Status: **52 generated candidates, zero art approvals** (26 October 2026). The batch is
reproducible and every candidate is recorded as `pending` in
`data/raven/comfyui_wall_asset_review.json`; only a human review may change that.

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

Every prompt begins with the same Raven Manor style/camera contract and adds one exact asset
description. Structural materials vary only through four controlled style clauses. Every
output has a fixed seed and stable ID, so a rejected candidate can be regenerated without
touching unrelated assets.

## Installed local stack

The workflow targets models and nodes already present in `D:\AI\ComfyUI-Desktop`
(junction `C:\StableDiffusion\ComfyUI-Desktop`):

- `Flux2-Klein-9B-True-V3-fp8mixed.safetensors` — `models/unet` and `models/diffusion_models`
- `qwen_3_8b_fp8mixed.safetensors` — `models/text_encoders`, listed by `CLIPLoader`
- `flux2-vae.safetensors` — `models/vae`
- `BiRefNet_toonout.safetensors` — `models/RMBG/BiRefNet`, exposed by the `ComfyUI-RMBG` node
  `BiRefNetRMBG` as the model option `BiRefNet_toonout`
- `VNCCS_Flux_Klein_Encoder` — the `vnccs` custom-node pack

The API template is `scripts/raven/comfyui/raven_wall_asset_api.json`. A generated black
geometry guide is the first image condition, the current Hall painting is a style-only second
reference. Flux renders a 1024×1024 candidate; BiRefNet saves a separate alpha PNG. Raw and
transparent results remain side by side.

Three workstation facts are easy to get wrong and are now enforced by the runner:

| Pitfall | Reality | Guard |
|---|---|---|
| Server port | ComfyUI Desktop serves `127.0.0.1:8000`; a plain `python main.py` serves `8188` | The runner probes both, or accepts `--server` |
| Alpha node | `BiRefNetRMBG` exists; the earlier draft node `VNCCS_RMBG2` is installed in no pack | Preflight rejects unknown node classes |
| Model name | The node option is `BiRefNet_toonout`, not the `.safetensors` file name | Manifest and graph are cross-checked |

## Run all 52

Pillow is required to draw guides and to run the review checks:

```powershell
python -m pip install pillow
```

Start ComfyUI Desktop (or `python main.py`), wait until its port answers, then from the
repository run:

```powershell
python scripts/raven/comfyui/run_wall_asset_batch.py
```

The runner resolves the live server, renders every geometry guide under
`ComfyUI/input/RavenManorWallKit/`, copies the Hall style reference there and queues the
chosen jobs. Before the first job it validates the whole API graph against live
`/object_info`: node classes, every input name, every enum value (models included), every link
target and output index, and every required input. A stale workflow fails before any GPU time
is spent.

Useful safe modes:

```powershell
# Validate prompts, guide kinds and graph bindings without contacting ComfyUI.
python scripts/raven/comfyui/run_wall_asset_batch.py --dry-run

# Generate one review sample first.
python scripts/raven/comfyui/run_wall_asset_batch.py --only wall_grand_straight_h --wait

# Queue the first four candidates only.
python scripts/raven/comfyui/run_wall_asset_batch.py --max-jobs 4
```

`--wait` keeps only one active generation at a time and reports the raw and alpha filename of
each job. Without it, ComfyUI receives the complete queue. The runner exits non-zero if any
job fails or saves no output.

Results are written below `ComfyUI/output/RavenManor/walls/raw/` and `alpha/`. Re-running an
unchanged prompt and seed is a ComfyUI execution-cache hit: it returns the previous filename
and writes nothing new. Change the seed (or delete the previous output) when a genuinely new
candidate is required.

## Prompt contract

The shared prompt requires: isolated modular game asset; late-Victorian Gothic Raven Manor;
hand-painted stylized realism; crisp readable silhouette; orthographic 65-degree top-down game
view; the exact black guide silhouette; the same scale and warm light as the Hall reference;
one detached component centred on a pure-white backdrop and fully inside the frame.

Two rules came out of the first real run and must not be regressed:

1. **No negated nouns.** The sampler path is `BasicGuider`, so there is no CFG negative
   prompt. Flux reads "no characters" as content — the first pass rendered a woman's
   silhouette into `wall_residential_straight_v`. Exclusions are therefore expressed
   positively ("one detached architectural component", "empty interior architecture").
2. **Guides are solid silhouettes.** An outline or ring (the old door/arch guides) reads as a
   black backdrop panel and survives alpha extraction as an unusable black plaque. Openings
   also need the prompt to name the backdrop ("the doorway behind the leaf showing the plain
   white studio backdrop"), otherwise the model paints a room inside the opening.

The manifest contains the complete resolved English prompt for each file, rather than relying
on undocumented UI text. To change the prompt matrix, edit `build_wall_asset_manifest.py`,
regenerate the manifest, review the diff and run its tests. Do not hand-edit one generated
prompt and silently break family consistency.

## Verified local run (26 October 2026)

- ComfyUI Desktop 0.42.5 at `127.0.0.1:8000`, RTX 5080 (16 GB), `euler`, 12 Flux2 steps,
  `flux2-vae`, `BiRefNet_toonout`.
- All 52 candidates rendered: the full pass took 23.7 minutes (~27 s per job once the models
  were resident) and finished with exit code 0, no failed job and no missing raw or alpha
  output.
- A follow-up pass re-rendered the 16 corner pieces and four end pillars after a prompt
  revision (9.5 minutes). That revision did not fix them — see the review finding below.
- Every candidate is 1024×1024; raw is RGB on white, alpha is RGBA with genuine transparency.
- The earlier claim that the batch had only been dry-run is superseded: the whole matrix has
  been rendered on this workstation and mechanically checked.

Mechanical results and per-candidate checksums are in
`data/raven/comfyui_wall_asset_review.json` (52 entries, 0 missing, 0 mechanically flagged,
all `pending`); a labelled contact sheet of every alpha cutout is in
`docs/evidence/comfyui_wall_kit/`.

### What the first complete review shows

The mechanical checks pass, but the contact sheet makes the art-direction split obvious:

| Family | State | Review finding |
|---|---|---|
| Straight horizontal/vertical walls (8) | usable candidates | Isolated bands, consistent trim height, white margins intact |
| Doors (12) | mostly usable | Single/double/service doors read correctly; open leaves show a transparent threshold. `door_glazed_double_*` renders as a whole glasshouse instead of double doors |
| Windows (5) | mostly usable | Grand, residential, bathroom and kitchen windows work with transparent glass. `window_conservatory_section` renders as a lantern/dome, not a repeating wall bay |
| Arches (3) | usable candidates | Open, gated and damaged arches read correctly; the gated version keeps a transparent opening |
| Balustrades (4) | usable candidates | Diagonal rails with open alpha between balusters |
| Corners (16) | **needs redesign** | The model completes a room: floor tiles, white plaster and enclosed white alpha inside the concave notch |
| End pillars (4) | **needs redesign** | The guide is read as a black column or plate; most renders are unusable |

The corner/pillar failure is a guide-interpretation problem, not a stale prompt: rewording
them to name the white backdrop explicitly did not change the result. They need a different
construction (for example composed from straight segments, or a tighter guide strategy)
before that part of the budget can be approved. Nothing above is an approval.


## Review and integration gate

Generation does not equal approval. Run the collector after a batch:

```powershell
python scripts/raven/comfyui/review_wall_asset_batch.py --sheet docs/evidence/comfyui_wall_kit/wall_kit_contact_sheet.png
```

It records filename, size, SHA-256, seed, guide silhouette box and alpha metrics for every ID
and writes `data/raven/comfyui_wall_asset_review.json` with `decision: pending`. It never
approves anything itself; edit `decision` to `approved` or `rejected`, add `reviewer` and
`notes`. Re-running the collector preserves a decision as long as the file hash is unchanged,
and resets it to `pending` when the candidate is regenerated.

Automatic flags (information for the reviewer, not an approval):

| Flag | Meaning |
|---|---|
| `alpha_empty` | No visible alpha, or almost none |
| `alpha_opaque` | The cutout is fully opaque — extraction did not run |
| `alpha_touches_border` | Visible pixels touch the frame: likely cropped |
| `raw_background_not_white` | Raw render is not isolated on white |
| `raw_unexpected_size` / `alpha_unexpected_size` | Not 1024×1024 |
| `raw_missing` / `alpha_missing` | One of the two outputs is absent |

Human review before any PNG replaces a pilot asset:

1. Reject clipped alpha, opaque canvas edges, floating fragments and incomplete cutouts.
2. Overlay every straight/corner/end tile of a style and verify identical trim height, light
   direction and seamless endpoints. The guide box in the review manifest is the reference.
3. Put doors, windows and arches into their matching wall style; ensure no baked wall/floor
   surrounds remain and that open thresholds are genuinely transparent.
4. Compare Hall candidates at 65°/0.74× against the five exact portal guides and two staircase
   rectangles.
5. Check intact/damaged state silhouettes do not move pivots or thresholds.
6. Check both balustrade cutouts with Onoe behind and in front; alpha gaps must remain
   genuinely transparent.
7. Record accepted output filename, SHA-256, model, seed and reviewer decision in the review
   manifest (this is the separate approval record).
8. Only after that review may Godot replace schematic gold rails or promote the three-piece
   seating collision.

No generated file is copied into production assets automatically, and the workflow never
changes routes, saves, collision or story data.

## Known limits

- **Geometry is guidance, not a constraint.** There is no ControlNet for this model, so the
  guide conditions proportions and silhouette softly. The review manifest records the intended
  guide box next to the actual alpha box so the overlay review can measure the deviation.
- **Corner and end-pillar guides do not work yet.** Concave corners are completed into room
  scenes (floor tiles, white plaster) and pillars into black plates. This needs a new
  construction for those two families; the current 20 candidates are deliberately left
  `pending` rather than presented as usable.
- **Two families inherit the wrong object type.** `glazed_double` produces a glasshouse and
  `window_conservatory_section` a lantern because the style reference is a full hall; both
  need narrower prompts or references before re-rendering.
- **State changes are prompt-driven.** Closed/open/damaged share one silhouette per family;
  the prompt and seed carry the state. A regenerated state may shift the silhouette slightly.
- **Small alpha artifacts are possible.** A faint grey wisp appeared inside one open doorway.
  This is exactly what the flag-and-review step is for.
- **Nothing here is art-approved.** The palette, trim heights and seam continuity are
  candidates for review, not an accepted Raven Manor style.
