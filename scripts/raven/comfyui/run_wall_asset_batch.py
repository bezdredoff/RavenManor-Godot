#!/usr/bin/env python3
"""Render Raven Manor wall-kit guides and queue the matching ComfyUI jobs.

Every job has a fixed id, seed, prompt and guide silhouette, so a rejected candidate can be
regenerated without touching its siblings. Before queueing anything the runner checks the
whole API graph against the live `/object_info` registry of the running ComfyUI: an unknown
node, an unsupported input, a missing model or a dangling link fails loudly instead of
producing unusable images.

Generated PNGs stay in `ComfyUI/output/RavenManor/walls/{raw,alpha}`. Nothing is copied into
the Godot project and no game data is touched.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

try:  # Pillow is only needed to draw guides, not to validate the graph.
    from PIL import Image, ImageDraw

    PIL_AVAILABLE = True
except ImportError:  # pragma: no cover - exercised only on machines without Pillow
    Image = ImageDraw = None
    PIL_AVAILABLE = False

ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "data/raven/comfyui_wall_asset_manifest.json"
WORKFLOW = Path(__file__).with_name("raven_wall_asset_api.json")
STYLE_REFERENCE = ROOT / "assets/raven/hall/generated_pilot/backgrounds/hall_twin_staircases.png"

# ComfyUI's own default port, then the port ComfyUI Desktop uses on this workstation.
SERVER_CANDIDATES = ("http://127.0.0.1:8188", "http://127.0.0.1:8000")

# LoadImage.image is a live list of files that already exist in ComfyUI/input. The runner
# writes those files itself, so the value is checked on disk instead of against the enum.
DYNAMIC_ENUM_INPUTS = {("LoadImage", "image")}

# Which node/input each manifest model name must appear in.
MODEL_BINDINGS = {
    "unet": ("10", "unet_name"),
    "clip": ("11", "clip_name"),
    "vae": ("12", "vae_name"),
    "rembg": ("27", "model"),
}

GUIDE_KINDS = ("straight_h", "straight_v", "corner_l", "corner_r", "pillar", "door_single",
               "door_double", "window", "arch", "balustrade_left", "balustrade_right")

RAW_PREFIX = "RavenManor/walls/raw/"
ALPHA_PREFIX = "RavenManor/walls/alpha/"
GUIDE_SUBDIR = "RavenManorWallKit"
STYLE_REFERENCE_NAME = "hall_style_reference.png"


def require_pillow():
    if not PIL_AVAILABLE:
        raise RuntimeError("Pillow is required to render geometry guides: "
                           "python -m pip install pillow")


def request_json(url, payload=None, timeout=15):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def enum_options(spec):
    """Allowed values of a COMBO input, or None when the input is not a fixed choice."""
    head = spec[0] if isinstance(spec, list) else spec
    if isinstance(head, list):
        return head
    if head == "COMBO":
        extra = spec[1] if isinstance(spec, list) and len(spec) > 1 else {}
        options = extra.get("options") if isinstance(extra, dict) else None
        return options if isinstance(options, list) else []
    return None


def is_link(value):
    return (isinstance(value, list) and len(value) == 2 and isinstance(value[0], str)
            and isinstance(value[1], int) and not isinstance(value[1], bool))


def validate_graph(workflow, object_info, dynamic_enum_inputs=DYNAMIC_ENUM_INPUTS):
    """Return every way the API graph disagrees with the live ComfyUI registry."""
    problems = []
    if not isinstance(workflow, dict) or not workflow:
        return ["workflow is empty"]
    for node_id, node in workflow.items():
        class_type = node.get("class_type")
        schema = object_info.get(class_type)
        if schema is None:
            problems.append(f"node {node_id}: ComfyUI has no node class {class_type!r}")
            continue
        declared = {}
        declared.update(schema.get("input", {}).get("required", {}))
        declared.update(schema.get("input", {}).get("optional", {}))
        inputs = node.get("inputs", {})
        for key, value in inputs.items():
            if key not in declared:
                problems.append(f"node {node_id} ({class_type}): unsupported input {key!r}")
                continue
            if is_link(value):
                target = workflow.get(value[0])
                if target is None:
                    problems.append(f"node {node_id} ({class_type}): {key} links to missing "
                                    f"node {value[0]!r}")
                    continue
                outputs = object_info.get(target.get("class_type"), {}).get("output")
                if isinstance(outputs, list) and not 0 <= value[1] < len(outputs):
                    problems.append(f"node {node_id} ({class_type}): {key} reads output "
                                    f"{value[1]} of {target.get('class_type')!r}, which has "
                                    f"{len(outputs)}")
                continue
            if (class_type, key) in dynamic_enum_inputs:
                if not isinstance(value, str) or not value.strip():
                    problems.append(f"node {node_id} ({class_type}): {key} must be a file name")
                continue
            options = enum_options(declared[key])
            if options is not None and value not in options:
                problems.append(f"node {node_id} ({class_type}): {key}={value!r} is not "
                                f"installed in ComfyUI")
        for key in schema.get("input", {}).get("required", {}):
            if key not in inputs:
                problems.append(f"node {node_id} ({class_type}): missing required input {key!r}")
    return problems


def bind_model_names(manifest, workflow):
    """Copy the manifest's model names into the graph and fail on any mismatch."""
    problems = []
    for key, (node_id, field) in MODEL_BINDINGS.items():
        node = workflow.get(node_id)
        if node is None:
            problems.append(f"model {key}: workflow has no node {node_id}")
            continue
        if node["inputs"].get(field) != manifest["model"][key]:
            problems.append(f"model {key}: workflow {node['class_type']}.{field}="
                            f"{node['inputs'].get(field)!r} but manifest says "
                            f"{manifest['model'][key]!r}")
    return problems


def resolve_server(server=None, candidates=SERVER_CANDIDATES, timeout=5):
    """Find a running ComfyUI: an explicit URL, otherwise the first candidate that answers."""
    urls = [server.rstrip("/")] if server else list(candidates)
    failures = []
    for url in urls:
        try:
            return url, request_json(url + "/system_stats", timeout=timeout)
        except (urllib.error.URLError, OSError, ValueError) as error:
            failures.append(f"{url} ({error})")
    raise RuntimeError("No ComfyUI server answered. Tried: " + ", ".join(failures) +
                       ". Start ComfyUI Desktop or `python main.py --port 8188` and retry.")


def render_guide(kind, size=1024):
    """Draw the black-on-white silhouette that conditions one candidate.

    Every guide is a solid object silhouette. An outline or ring reads as a black backdrop
    panel behind the object and survives alpha extraction as an unusable black plaque, which
    happened to an early door pass.
    """
    require_pillow()
    if kind not in GUIDE_KINDS:
        raise ValueError("Unknown guide: " + str(kind))
    image = Image.new("RGB", (size, size), "white")
    draw = ImageDraw.Draw(image)
    black = "#080808"
    if kind == "straight_h":
        draw.rounded_rectangle((90, 390, 934, 635), 12, fill=black)
    elif kind == "straight_v":
        draw.rounded_rectangle((390, 90, 635, 934), 12, fill=black)
    elif kind == "corner_l":
        draw.polygon([(180, 180), (500, 180), (500, 510), (844, 510), (844, 780), (230, 780),
                      (230, 500), (180, 500)], fill=black)
    elif kind == "corner_r":
        draw.polygon([(844, 180), (524, 180), (524, 510), (180, 510), (180, 780), (794, 780),
                      (794, 500), (844, 500)], fill=black)
    elif kind == "pillar":
        draw.rounded_rectangle((360, 135, 664, 889), 24, fill=black)
    elif kind == "door_single":
        draw.rounded_rectangle((330, 135, 694, 905), 10, fill=black)
    elif kind == "door_double":
        draw.rounded_rectangle((250, 135, 774, 905), 10, fill=black)
    elif kind == "window":
        draw.rectangle((205, 165, 819, 850), fill=black)
        draw.rectangle((300, 255, 724, 745), fill="white")
    elif kind == "arch":
        draw.rectangle((230, 400, 800, 905), fill=black)
        draw.ellipse((230, 150, 800, 650), fill=black)
    else:  # balustrade_left / balustrade_right
        points = [(205, 855), (300, 855), (820, 220), (765, 175), (245, 720)]
        if kind.endswith("right"):
            points = [(size - x, y) for x, y in points]
        draw.line(points, fill=black, width=58, joint="curve")
        for step in range(7):
            x = 290 + step * 76
            y = 720 - step * 78
            if kind.endswith("right"):
                x = size - x
            draw.line((x, y, x, y + 185), fill=black, width=20)
    return image


def validate_manifest(manifest):
    jobs = manifest.get("jobs", [])
    if manifest.get("count") != 52 or len(jobs) != 52:
        raise ValueError("Manifest must contain exactly 52 jobs")
    ids = {job["id"] for job in jobs}
    if len(ids) != 52:
        raise ValueError("Manifest job ids must be unique")
    for job in jobs:
        if not job["prompt"].startswith("Isolated modular environment asset for Raven Manor"):
            raise ValueError("Unexpected prompt contract for " + job["id"])
        if not 0 <= int(job["seed"]) < 2**64:
            raise ValueError("Invalid seed for " + job["id"])
        if job["guide"] not in GUIDE_KINDS:
            raise ValueError(f"Unknown guide {job['guide']!r} for {job['id']}")
        if (job["width"], job["height"]) != (1024, 1024):
            raise ValueError("Unexpected canvas for " + job["id"])


def preflight(server, manifest, workflow):
    """Verify the live registry and the installed models before queueing anything."""
    info = request_json(server + "/object_info", timeout=120)
    problems = bind_model_names(manifest, workflow) + validate_graph(workflow, info)
    if problems:
        raise RuntimeError("Workflow does not match live ComfyUI:\n - " + "\n - ".join(problems))
    return info


def history_entry(server, prompt_id, timeout=30):
    history = request_json(f"{server}/history/{prompt_id}", timeout=timeout)
    return history.get(prompt_id)


def wait_for(server, prompt_id, timeout=1800, poll=2.0):
    """Block until ComfyUI finishes the prompt and return its outputs."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            entry = history_entry(server, prompt_id)
        except (urllib.error.URLError, OSError, ValueError):
            entry = None
        if entry:
            status = entry.get("status") or {}
            if status.get("status_str") == "error":
                raise RuntimeError(f"{prompt_id} failed inside ComfyUI: "
                                   f"{describe_error(status)}")
            if status.get("completed") or entry.get("outputs"):
                return entry.get("outputs", {})
        time.sleep(poll)
    raise RuntimeError(f"Timed out after {timeout}s waiting for {prompt_id}")


def describe_error(status):
    for message in status.get("messages", []):
        if isinstance(message, list) and len(message) == 2 and message[0] == "execution_error":
            detail = message[1] or {}
            return f"{detail.get('node_type')}: {detail.get('exception_message')}".strip()
    return "unknown error"


def saved_images(outputs, node_id):
    return [image.get("filename", "") for image in (outputs.get(node_id) or {}).get("images", [])
            if image.get("filename")]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server", help="ComfyUI base URL; auto-detected when omitted")
    parser.add_argument("--comfy-root", type=Path, default=Path(r"D:\AI\ComfyUI-Desktop"))
    parser.add_argument("--only", help="comma-separated asset IDs")
    parser.add_argument("--max-jobs", type=int, default=52)
    parser.add_argument("--wait", action="store_true",
                        help="wait for every job before queueing the next")
    parser.add_argument("--timeout", type=int, default=1800, help="per-job wait timeout")
    parser.add_argument("--dry-run", action="store_true",
                        help="validate prompts and guides without contacting ComfyUI")
    args = parser.parse_args(argv)

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    validate_manifest(manifest)
    template = json.loads(WORKFLOW.read_text(encoding="utf-8"))
    models = bind_model_names(manifest, template)
    if models:
        raise ValueError("Manifest and workflow disagree:\n - " + "\n - ".join(models))

    selected = set(args.only.split(",")) if args.only else None
    known = {job["id"] for job in manifest["jobs"]}
    if selected is not None and selected - known:
        raise ValueError("Unknown IDs: " + ", ".join(sorted(selected - known)))
    jobs = [job for job in manifest["jobs"] if selected is None or job["id"] in selected]
    jobs = jobs[:args.max_jobs]

    if args.dry_run:
        require_pillow()
        with tempfile.TemporaryDirectory() as temp:
            for job in jobs:
                render_guide(job["guide"]).save(Path(temp) / (job["id"] + ".png"))
        print(f"Dry run passed: {len(jobs)} prompts, guides and graph bindings are consistent")
        return 0

    server, stats = resolve_server(args.server)
    version = (stats.get("system") or {}).get("comfyui_version", "unknown")
    print(f"ComfyUI {version} at {server}")
    preflight(server, manifest, template)

    input_dir = args.comfy_root / "input" / GUIDE_SUBDIR
    input_dir.mkdir(parents=True, exist_ok=True)
    if not STYLE_REFERENCE.is_file():
        raise FileNotFoundError(f"Missing Hall style reference: {STYLE_REFERENCE}")
    shutil.copy2(STYLE_REFERENCE, input_dir / STYLE_REFERENCE_NAME)

    client_id = str(uuid.uuid4())
    failures, started = [], time.monotonic()
    for index, job in enumerate(jobs, 1):
        guide_name = job["id"] + "_guide.png"
        render_guide(job["guide"]).save(input_dir / guide_name)
        workflow = json.loads(json.dumps(template))
        workflow["1"]["inputs"]["image"] = f"{GUIDE_SUBDIR}/{guide_name}"
        workflow["2"]["inputs"]["image"] = f"{GUIDE_SUBDIR}/{STYLE_REFERENCE_NAME}"
        workflow["20"]["inputs"]["prompt"] = job["prompt"]
        workflow["24"]["inputs"]["noise_seed"] = job["seed"]
        workflow["80"]["inputs"]["filename_prefix"] = RAW_PREFIX + job["id"]
        workflow["81"]["inputs"]["filename_prefix"] = ALPHA_PREFIX + job["id"]
        try:
            result = request_json(server + "/prompt", {"prompt": workflow,
                                                       "client_id": client_id}, timeout=60)
        except urllib.error.HTTPError as error:
            body = error.read().decode("utf-8", "replace")
            raise RuntimeError(f"ComfyUI rejected {job['id']}: {body}") from error
        prompt_id = result.get("prompt_id")
        if not prompt_id:
            raise RuntimeError(f"ComfyUI returned no prompt id for {job['id']}: {result}")
        if not args.wait:
            print(f"[{index:02d}/{len(jobs)}] queued {job['id']} ({prompt_id})")
            continue
        try:
            outputs = wait_for(server, prompt_id, timeout=args.timeout)
        except RuntimeError as error:
            failures.append(f"{job['id']}: {error}")
            print(f"[{index:02d}/{len(jobs)}] FAILED {job['id']}: {error}")
            continue
        raw, alpha = saved_images(outputs, "80"), saved_images(outputs, "81")
        if not raw or not alpha:
            failures.append(f"{job['id']}: ComfyUI saved raw={raw} alpha={alpha}")
            print(f"[{index:02d}/{len(jobs)}] FAILED {job['id']}: missing raw or alpha output")
            continue
        print(f"[{index:02d}/{len(jobs)}] {job['id']}: raw {raw[0]} + alpha {alpha[0]}")

    minutes = (time.monotonic() - started) / 60
    print(f"Queued {len(jobs)} jobs in {minutes:.1f} min. Outputs: "
          "ComfyUI/output/RavenManor/walls/raw and .../alpha")
    if failures:
        print("Failures:\n - " + "\n - ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
