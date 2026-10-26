#!/usr/bin/env python3
"""Generate guides and queue all Raven Manor wall-kit candidates in ComfyUI."""
import argparse
import json
import shutil
import tempfile
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "data/raven/comfyui_wall_asset_manifest.json"
WORKFLOW = Path(__file__).with_name("raven_wall_asset_api.json")
STYLE_REFERENCE = ROOT / "assets/raven/hall/generated_pilot/backgrounds/hall_twin_staircases.png"
REQUIRED_NODES = {"LoadImage", "ImageScaleToTotalPixels", "UNETLoader", "CLIPLoader", "VAELoader",
                  "KSamplerSelect", "VNCCS_Flux_Klein_Encoder", "Flux2Scheduler", "BasicGuider",
                  "RandomNoise", "SamplerCustomAdvanced", "VAEDecode", "VNCCS_RMBG2", "SaveImage"}

def request_json(url, payload=None, timeout=15):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(url, data=data, headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))

def draw_guide(kind, target):
    image = Image.new("RGB", (1024, 1024), "white")
    d = ImageDraw.Draw(image)
    black = "#080808"
    if kind == "straight_h": d.rounded_rectangle((90, 390, 934, 635), 12, fill=black)
    elif kind == "straight_v": d.rounded_rectangle((390, 90, 635, 934), 12, fill=black)
    elif kind == "corner_l": d.polygon([(180,180),(500,180),(500,510),(844,510),(844,780),(230,780),(230,500),(180,500)], fill=black)
    elif kind == "corner_r": d.polygon([(844,180),(524,180),(524,510),(180,510),(180,780),(794,780),(794,500),(844,500)], fill=black)
    elif kind == "pillar": d.rounded_rectangle((360,135,664,889), 24, fill=black)
    elif kind == "door_single":
        d.rectangle((270,120,754,900),fill=black); d.rectangle((365,245,659,900),fill="white")
    elif kind == "door_double":
        d.rectangle((180,120,844,900),fill=black); d.rectangle((290,245,734,900),fill="white")
    elif kind == "window":
        d.rectangle((205,165,819,850),fill=black); d.rectangle((300,255,724,745),fill="white")
    elif kind == "arch":
        d.rectangle((175,300,849,900),fill=black); d.ellipse((270,130,754,615),fill="white"); d.rectangle((270,370,754,900),fill="white")
    elif kind.startswith("balustrade"):
        points=[(205,855),(300,855),(820,220),(765,175),(245,720)]
        if kind.endswith("right"): points=[(1024-x,y) for x,y in points]
        d.line(points,fill=black,width=58,joint="curve")
        for step in range(7):
            x=290+step*76; y=720-step*78
            if kind.endswith("right"): x=1024-x
            d.line((x,y,x,y+185),fill=black,width=20)
    else: raise ValueError("Unknown guide: "+kind)
    image.save(target)

def validate_manifest(manifest):
    jobs=manifest.get("jobs", [])
    if manifest.get("count") != 52 or len(jobs) != 52 or len({job["id"] for job in jobs}) != 52:
        raise ValueError("Manifest must contain exactly 52 unique jobs")
    for job in jobs:
        if not job["prompt"].startswith("Isolated modular environment asset for Raven Manor"):
            raise ValueError("Unexpected prompt contract for "+job["id"])
        if not 0 <= int(job["seed"]) < 2**64: raise ValueError("Invalid seed")

def preflight(server, manifest):
    info=request_json(server+"/object_info", timeout=30)
    missing=sorted(REQUIRED_NODES-set(info))
    if missing: raise RuntimeError("Missing ComfyUI nodes: "+", ".join(missing))
    model=manifest["model"]
    checks={"UNETLoader":("unet_name",model["unet"]),"CLIPLoader":("clip_name",model["clip"]),
            "VAELoader":("vae_name",model["vae"]),"VNCCS_RMBG2":("model",model["rembg"])}
    for node,(field,value) in checks.items():
        choices=info[node]["input"]["required"][field][0]
        if value not in choices: raise RuntimeError(f"{value} is not available in {node}")
    return info

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server",default="http://127.0.0.1:8188")
    parser.add_argument("--comfy-root",type=Path,default=Path(r"D:\AI\ComfyUI-Desktop"))
    parser.add_argument("--only",help="comma-separated asset IDs")
    parser.add_argument("--max-jobs",type=int,default=52)
    parser.add_argument("--wait",action="store_true",help="wait for every job before queuing the next")
    parser.add_argument("--dry-run",action="store_true",help="validate and render temporary guides without contacting ComfyUI")
    args=parser.parse_args()
    manifest=json.loads(MANIFEST.read_text(encoding="utf-8")); validate_manifest(manifest)
    template=json.loads(WORKFLOW.read_text(encoding="utf-8"))
    selected=set(args.only.split(",")) if args.only else None
    jobs=[job for job in manifest["jobs"] if selected is None or job["id"] in selected][:args.max_jobs]
    if selected is not None and len(jobs) != len(selected):
        missing=selected-{job["id"] for job in jobs}; raise ValueError("Unknown or excluded IDs: "+", ".join(sorted(missing)))
    if args.dry_run:
        with tempfile.TemporaryDirectory() as temp:
            for job in jobs: draw_guide(job["guide"],Path(temp)/(job["id"]+".png"))
        print(f"Dry run passed: {len(jobs)} prompts and geometry guides")
        return
    preflight(args.server.rstrip("/"),manifest)
    input_dir=args.comfy_root/"input"/"RavenManorWallKit"; input_dir.mkdir(parents=True,exist_ok=True)
    shutil.copy2(STYLE_REFERENCE,input_dir/"hall_style_reference.png")
    client_id=str(uuid.uuid4())
    for index,job in enumerate(jobs,1):
        guide_name=job["id"]+"_guide.png"; draw_guide(job["guide"],input_dir/guide_name)
        workflow=json.loads(json.dumps(template))
        workflow["1"]["inputs"]["image"]="RavenManorWallKit/"+guide_name
        workflow["20"]["inputs"]["prompt"]=job["prompt"]
        workflow["24"]["inputs"]["noise_seed"]=job["seed"]
        workflow["80"]["inputs"]["filename_prefix"]="RavenManor/walls/raw/"+job["id"]
        workflow["81"]["inputs"]["filename_prefix"]="RavenManor/walls/alpha/"+job["id"]
        result=request_json(args.server.rstrip("/")+"/prompt",{"prompt":workflow,"client_id":client_id},timeout=30)
        prompt_id=result.get("prompt_id"); print(f"[{index:02d}/{len(jobs)}] queued {job['id']} ({prompt_id})")
        if args.wait:
            while prompt_id not in request_json(args.server.rstrip("/")+"/history",timeout=30): time.sleep(2)
    print("Queued",len(jobs),"jobs. Outputs: ComfyUI/output/RavenManor/walls/{raw,alpha}")

if __name__ == "__main__": main()
