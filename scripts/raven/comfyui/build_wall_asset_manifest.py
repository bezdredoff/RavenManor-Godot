#!/usr/bin/env python3
"""Build the exact 52-job first-act Raven Manor wall-art manifest."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "data/raven/comfyui_wall_asset_manifest.json"
STYLES = {
    "grand": "grand entrance-hall finish, dark carved mahogany panels, oxblood damask inset, restrained antique brass trim",
    "residential": "private-room finish, warm walnut wainscot, faded burgundy wallpaper, smaller restrained moulding",
    "service": "service-room finish, aged painted plaster, dark practical timber trim, subtle moisture-safe stone base",
    "glass": "conservatory finish, dark oxidized bronze frame, pale stone plinth, Victorian greenhouse detailing"
}
SHAPES = [
    ("straight_h", "long horizontal seamless wall section", "straight_h"),
    ("straight_v", "long vertical seamless wall section", "straight_v"),
    ("inner_corner_l", "left-facing concave inside corner wall piece", "corner_l"),
    ("inner_corner_r", "right-facing concave inside corner wall piece", "corner_r"),
    ("outer_corner_l", "left-facing convex outside corner wall piece", "corner_l"),
    ("outer_corner_r", "right-facing convex outside corner wall piece", "corner_r"),
    ("end_pillar", "wall termination with a narrow structural end pillar", "pillar")
]
BASE = (
    "Isolated modular environment asset for Raven Manor, a late-Victorian Gothic mystery adventure game. "
    "Hand-painted stylized realism, crisp game-readable silhouette, orthographic 65-degree top-down camera, "
    "same scale and warm directional lighting as the supplied hall reference. Match the black geometry guide exactly. "
    "Centered complete object on plain white background for clean alpha extraction; no floor plane, no room scene, "
    "no characters, no furniture, no text, no watermark, no border, no crop, no fisheye, no extra openings. "
)

def job(asset_id, category, description, guide, seed, style="shared", state="default"):
    material = STYLES.get(style, "the same Raven Manor carved dark wood, aged stone and antique brass visual language")
    return {"id": asset_id, "category": category, "style": style, "state": state,
            "guide": guide, "seed": seed, "width": 1024, "height": 1024,
            "prompt": BASE + description + ". Material direction: " + material +
            ". Preserve straight tileable joins and consistent trim height; cast only a tight contact shadow inside the silhouette."}

jobs=[]; seed=26010001
for style, _ in STYLES.items():
    for suffix, desc, guide in SHAPES:
        jobs.append(job(f"wall_{style}_{suffix}", "structure", desc, guide, seed, style)); seed += 1

doors = {
    "grand_single": "single grand interior Victorian door in a carved frame",
    "grand_double": "symmetrical double grand Victorian doors in a carved frame",
    "service_single": "plain sturdy service door in a practical timber frame",
    "glazed_double": "symmetrical bronze-framed glazed conservatory double doors"
}
for family, desc in doors.items():
    style = "service" if family.startswith("service") else ("glass" if family.startswith("glazed") else "grand")
    for state in ("closed", "open", "damaged"):
        state_desc = {"closed":"fully closed and readable", "open":"open inward with a completely clear walkable threshold",
                      "damaged":"story-safe damaged version, cracked trim and loose panel but still recognizable"}[state]
        jobs.append(job(f"door_{family}_{state}", "door", f"{desc}, {state_desc}", "door_double" if "double" in family else "door_single", seed, style, state)); seed += 1

windows = [
    ("grand_tall", "grand tall mullioned window with burgundy drape returns", "grand"),
    ("residential_sash", "modest two-part Victorian sash window", "residential"),
    ("bathroom_frosted", "small frosted privacy window with moisture-safe sill", "service"),
    ("kitchen_casement", "practical inward casement window above a stone sill", "service"),
    ("conservatory_section", "full-height repeating greenhouse glass wall bay", "glass")
]
for suffix, desc, style in windows:
    jobs.append(job(f"window_{suffix}", "window", desc, "window", seed, style)); seed += 1

for state, desc in [("open","open ceremonial pointed arch with a clear threshold"),
                    ("gated","ceremonial pointed arch closed by an ornate iron story gate"),
                    ("damaged","damaged ceremonial pointed arch with cracked trim but a readable threshold")]:
    jobs.append(job(f"arch_grand_{state}", "arch", desc, "arch", seed, "grand", state)); seed += 1

for side in ("left", "right"):
    for state in ("intact", "damaged"):
        mirror = "left-hand" if side == "left" else "right-hand mirrored"
        condition = "complete and intact" if state == "intact" else "repair-state damaged with two missing spindles"
        jobs.append(job(f"balustrade_{side}_{state}", "foreground", f"{mirror} staircase balustrade cutout, {condition}, open alpha spaces between rails", "balustrade_"+side, seed, "grand", state)); seed += 1

assert len(jobs) == 52 and len({x["id"] for x in jobs}) == 52
manifest = {"schemaVersion":1,"status":"GENERATION_CANDIDATES_NOT_ART_APPROVED",
            "model":{"unet":"Flux2-Klein-9B-True-V3-fp8mixed.safetensors","clip":"qwen_3_8b_fp8mixed.safetensors",
                     "vae":"flux2-vae.safetensors","rembg":"BiRefNet_toonout.safetensors"},
            "count":len(jobs),"jobs":jobs,
            "acceptance":["transparent PNG has non-empty alpha and no clipped opaque pixels",
                          "straight joins align across same-style pieces", "door/window opening preserves guide silhouette",
                          "65-degree scale matches Hall capture", "human review required before repository integration"]}
OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(f"Wrote {len(jobs)} jobs to {OUT}")
