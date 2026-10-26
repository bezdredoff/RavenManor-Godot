#!/usr/bin/env python3
"""Collect generated Raven Manor wall candidates into a reviewable approval manifest.

Generation is not approval. This tool never changes a decision by itself: it records the
filename, SHA-256, seed, model and mechanical alpha checks for every candidate and leaves
`decision` at `pending` until a human edits the manifest. Existing human decisions are
preserved as long as the underlying file hash is unchanged.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import date
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont

    PIL_AVAILABLE = True
except ImportError:  # pragma: no cover - exercised only on machines without Pillow
    Image = ImageDraw = ImageFont = None
    PIL_AVAILABLE = False

ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "data/raven/comfyui_wall_asset_manifest.json"
REVIEW = ROOT / "data/raven/comfyui_wall_asset_review.json"

RAW_SUBDIR = Path("output/RavenManor/walls/raw")
ALPHA_SUBDIR = Path("output/RavenManor/walls/alpha")

ALPHA_VISIBLE = 8          # alpha above this counts as visible
OPAQUE = 250               # alpha above this counts as fully opaque
MIN_COVERAGE = 0.01        # below this the cutout is considered empty
WHITE_BORDER = 235         # mean border luminance expected on the isolation background


def require_pillow():
    if not PIL_AVAILABLE:
        raise RuntimeError("Pillow is required: python -m pip install pillow")


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _alpha_channel(image):
    return image.convert("RGBA").getchannel("A")


_GUIDE_MODULE = None


def _guide_module():
    """Import the batch runner so guide silhouettes are drawn by exactly one implementation."""
    global _GUIDE_MODULE
    if _GUIDE_MODULE is None:
        import importlib.util

        path = Path(__file__).with_name("run_wall_asset_batch.py")
        spec = importlib.util.spec_from_file_location("run_wall_asset_batch", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        _GUIDE_MODULE = module
    return _GUIDE_MODULE


def guide_bbox(kind):
    """Intended silhouette box of a geometry guide, for side-by-side review with the alpha bbox."""
    require_pillow()
    guide = _guide_module().render_guide(kind).convert("L")
    box = guide.point(lambda value: 255 if value < 128 else 0).getbbox()
    return list(box) if box else []


def analyze_alpha(path):
    """Mechanical cutout checks: coverage, bounding box, transparency and clipping."""
    require_pillow()
    with Image.open(path) as image:
        alpha = _alpha_channel(image)
        width, height = alpha.size
        histogram = alpha.histogram()
        total = float(width * height)
        coverage = sum(histogram[ALPHA_VISIBLE + 1:]) / total
        opaque = sum(histogram[OPAQUE + 1:]) / total
        bbox = alpha.point(lambda value: 255 if value > ALPHA_VISIBLE else 0).getbbox()
        ring = max(1, min(width, height) // 64)
        border_max = max(
            alpha.crop((0, 0, width, ring)).getextrema()[1],
            alpha.crop((0, height - ring, width, height)).getextrema()[1],
            alpha.crop((0, 0, ring, height)).getextrema()[1],
            alpha.crop((width - ring, 0, width, height)).getextrema()[1],
        )
        mode = image.mode
        size = list(image.size)
    flags = []
    if not bbox:
        flags.append("alpha_empty")
    elif coverage < MIN_COVERAGE:
        flags.append("alpha_empty")
    if opaque > 0.999:
        flags.append("alpha_opaque")
    if border_max > ALPHA_VISIBLE:
        flags.append("alpha_touches_border")
    return {
        "mode": mode,
        "size": size,
        "coverage": round(coverage, 4),
        "opaque_fraction": round(opaque, 4),
        "bbox": list(bbox) if bbox else None,
        "border_max_alpha": border_max,
        "flags": flags,
    }


def analyze_raw(path):
    """The raw render must stay isolated on a plain white background."""
    require_pillow()
    with Image.open(path) as image:
        grey = image.convert("L")
        width, height = grey.size
        ring = max(1, min(width, height) // 64)
        samples = [
            grey.crop((0, 0, width, ring)), grey.crop((0, height - ring, width, height)),
            grey.crop((0, 0, ring, height)), grey.crop((width - ring, 0, width, height)),
        ]
        values = []
        for strip in samples:
            histogram = strip.histogram()
            count = sum(histogram)
            values.append(sum(index * value for index, value in enumerate(histogram)) / count)
        border_mean = sum(values) / len(values)
        mode = image.mode
        size = list(image.size)
    flags = []
    if border_mean < WHITE_BORDER:
        flags.append("raw_background_not_white")
    return {"mode": mode, "size": size, "border_mean_luminance": round(border_mean, 1),
            "flags": flags}


def newest_candidate(directory, asset_id):
    if not directory.is_dir():
        return None
    matches = sorted(directory.glob(asset_id + "_*.png"))
    return matches[-1] if matches else None


def previous_decisions(review_path):
    if not review_path.is_file():
        return {}
    try:
        stored = json.loads(review_path.read_text(encoding="utf-8"))
    except ValueError:
        return {}
    decisions = {}
    for job in stored.get("jobs", []):
        if job.get("decision") and job["decision"] != "pending":
            decisions[job["id"]] = job
    return decisions


def build_review(manifest, comfy_root, review_path):
    require_pillow()
    previous = previous_decisions(review_path)
    raw_dir = comfy_root / RAW_SUBDIR
    alpha_dir = comfy_root / ALPHA_SUBDIR
    jobs, counts = [], {"pending": 0, "approved": 0, "rejected": 0, "missing": 0, "flagged": 0}
    for job in manifest["jobs"]:
        raw = newest_candidate(raw_dir, job["id"])
        alpha = newest_candidate(alpha_dir, job["id"])
        record = {"id": job["id"], "category": job["category"], "style": job["style"],
                  "state": job["state"], "guide": job["guide"], "seed": job["seed"],
                  "guide_bbox": guide_bbox(job["guide"]),
                  "raw": None, "alpha": None, "flags": [], "decision": "pending",
                  "reviewer": None, "notes": None}
        if raw is None or alpha is None:
            if raw is None:
                record["flags"].append("raw_missing")
            if alpha is None:
                record["flags"].append("alpha_missing")
            counts["missing"] += 1
        else:
            record["raw"] = {"filename": raw.name, "bytes": raw.stat().st_size,
                             "sha256": sha256(raw), **analyze_raw(raw)}
            record["alpha"] = {"filename": alpha.name, "bytes": alpha.stat().st_size,
                               "sha256": sha256(alpha), **analyze_alpha(alpha)}
            record["flags"].extend(record["raw"]["flags"])
            record["flags"].extend(record["alpha"]["flags"])
            expected = [job["width"], job["height"]]
            for key in ("raw", "alpha"):
                if record[key]["size"] != expected:
                    record["flags"].append(f"{key}_unexpected_size")
        if record["flags"]:
            counts["flagged"] += 1
        kept = previous.get(job["id"])
        if kept and record["alpha"] and kept.get("alpha", {}).get("sha256") == record["alpha"]["sha256"]:
            record["decision"] = kept.get("decision", "pending")
            record["reviewer"] = kept.get("reviewer")
            record["notes"] = kept.get("notes")
        counts[record["decision"]] += 1
        jobs.append(record)
    flagged = [job["id"] for job in jobs if job["flags"]]
    return {
        "schemaVersion": 1,
        "status": "AWAITING_HUMAN_REVIEW",
        "generated": date.today().isoformat(),
        "model": manifest["model"],
        "candidate_count": len(jobs),
        "summary": counts,
        "flagged": flagged,
        "declared_checks": [
            "alpha has non-empty transparency and no clipped opaque pixels",
            "raw render stays isolated on a plain white background",
            "straight joins align across same-style pieces",
            "door/window/arch states preserve the guide silhouette",
            "65-degree scale matches the Hall capture",
            "human review required before repository integration",
        ],
        "jobs": jobs,
    }


def draw_contact_sheet(review, alpha_dir, target, tile=160, columns=8):
    require_pillow()
    rows = max(1, (len(review["jobs"]) + columns - 1) // columns)
    label_height = 18
    sheet = Image.new("RGB", (columns * tile, rows * (tile + label_height)), "#202024")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, job in enumerate(review["jobs"]):
        column, row = index % columns, index // columns
        left, top = column * tile, row * (tile + label_height)
        for y in range(0, tile, 16):
            for x in range(0, tile, 16):
                shade = "#3a3a40" if (x // 16 + y // 16) % 2 else "#2c2c32"
                draw.rectangle((left + x, top + y, left + x + 15, top + y + 15), fill=shade)
        if job["alpha"]:
            with Image.open(alpha_dir / job["alpha"]["filename"]) as image:
                thumb = image.convert("RGBA")
                thumb.thumbnail((tile, tile), Image.LANCZOS)
                sheet.paste(thumb, (left + (tile - thumb.width) // 2,
                                    top + (tile - thumb.height) // 2), thumb)
        colour = "#d05050" if job["flags"] else "#e8e8e8"
        label = job["id"].replace("wall_", "").replace("door_", "d_").replace("window_", "w_")
        draw.text((left + 2, top + tile + 3), label[:26], fill=colour, font=font)
    target.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(target)
    return target


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--comfy-root", type=Path, default=Path(r"D:\AI\ComfyUI-Desktop"))
    parser.add_argument("--out", type=Path, default=REVIEW)
    parser.add_argument("--sheet", type=Path,
                        help="write a labelled contact sheet of every alpha cutout")
    args = parser.parse_args(argv)

    require_pillow()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    review = build_review(manifest, args.comfy_root, args.out)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(review, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    summary = review["summary"]
    print(f"Wrote {args.out} for {review['candidate_count']} candidates: "
          f"{summary['missing']} missing, {summary['flagged']} flagged, "
          f"{summary['approved']} approved, {summary['rejected']} rejected")
    if review["flagged"]:
        print("Flagged: " + ", ".join(review["flagged"]))
    if args.sheet:
        draw_contact_sheet(review, args.comfy_root / ALPHA_SUBDIR, args.sheet)
        print("Wrote " + str(args.sheet))
    return 0


if __name__ == "__main__":
    sys.exit(main())
