#!/usr/bin/env python3
"""Build a deterministic Raven Manor wall tileset from one AI-painted material.

The generative batch is good at material and weak at modular structure: it paints rooms
into corners, reads pillars as black plates and cannot guarantee seams or trim height.
This tool keeps one AI render as a *material source* and derives every shape by
construction, so seam continuity and trim height are properties of the code instead of a
seed. The module is a framed square panel whose four edges are identical, which makes any
horizontal, vertical or rotated tiling seamless by construction.

Output is a prototype: shapes are rectangular composites of whole modules, not mitred
geometry, and the inner/outer corner mapping is provisional.
"""
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_COMFY = Path(r"D:\AI\ComfyUI-Desktop")
RAW = Path("output/RavenManor/walls/raw")
ALPHA = Path("output/RavenManor/walls/alpha")

# Authoring scale: 2x the in-game pixel size. A module is therefore 80x80 game pixels.
MODULE = 160
BORDER = 22
GAP = 26
BRASS = (156, 125, 63)
BRASS_LIGHT = (206, 176, 104)
DARK = (26, 16, 12)

SHAPES = ("straight_h", "straight_v", "inner_corner_l", "inner_corner_r",
          "outer_corner_l", "outer_corner_r", "end_pillar")


def newest(comfy_root, subdir, asset_id):
    folder = comfy_root / subdir
    matches = sorted(folder.glob(asset_id + "_*.png")) if folder.is_dir() else []
    return matches[-1] if matches else None


def average_colour(image):
    small = image.convert("RGB").resize((1, 1), Image.LANCZOS)
    return small.getpixel((0, 0))


def derive_materials(source):
    """Cut wood and damask patches out of one AI render and sample the metal accent.

    The raw render is opaque RGB, so the object bounds come from its alpha sibling; colours
    are sampled from the raw pixels, which are identical apart from the matte.
    """
    source = Path(source)
    mask_path = source.parent.parent / "alpha" / source.name if source.parent.name == "raw" else source
    if not mask_path.is_file():
        raise ValueError(f"No alpha sibling to bound the object in {source.name}")
    render = Image.open(source).convert("RGB")
    alpha = Image.open(mask_path).convert("RGBA").getchannel("A")
    box = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if not box or box == (0, 0) + render.size:
        raise ValueError(f"Source render has no usable object bounds: {source}")
    left, top, right, bottom = box
    width, height = right - left, bottom - top

    def crop(fx0, fy0, fx1, fy1):
        return render.crop((int(left + fx0 * width), int(top + fy0 * height),
                            int(left + fx1 * width), int(top + fy1 * height)))

    wood = crop(0.05, 0.00, 0.95, 0.05)        # top rail: plain mahogany
    trim = crop(0.02, 0.20, 0.10, 0.80)        # end pilaster: lighter carved wood
    damask = crop(0.40, 0.45, 0.58, 0.85)      # centre panel: oxblood damask
    if min(wood.size) < 8 or min(damask.size) < 8 or min(trim.size) < 8:
        raise ValueError("Source render is too small to derive materials")
    return {"wood": wood, "trim": trim, "damask": damask,
            "brass": average_colour(trim.resize((1, 1)))}


def tile_fill(size, patch, period):
    """Tile a patch with an exact period that divides the target size, so edges never cut."""
    width, height = size
    period = max(8, int(period))
    tile = patch.resize((period, period), Image.LANCZOS)
    canvas = Image.new("RGB", size)
    for y in range(0, height, period):
        for x in range(0, width, period):
            canvas.paste(tile, (x, y))
    return canvas


def build_module(materials):
    """One framed wainscot bay. All four edges are identical, so any tiling is seamless."""
    module = tile_fill((MODULE, MODULE), materials["wood"], MODULE // 2)
    draw = ImageDraw.Draw(module)
    inner = MODULE - 2 * BORDER

    # Frame: the same mahogany, lifted a little, with brass keylines instead of a bright fill.
    frame = ImageEnhance.Brightness(tile_fill((MODULE, MODULE), materials["wood"], MODULE // 4)
                                    ).enhance(1.22)
    mask = Image.new("L", (MODULE, MODULE), 0)
    ImageDraw.Draw(mask).rectangle((2, 2, MODULE - 3, MODULE - 3), fill=255)
    ImageDraw.Draw(mask).rectangle((BORDER, BORDER, MODULE - BORDER - 1, MODULE - BORDER - 1),
                                   fill=0)
    module.paste(frame, (0, 0), mask)
    draw.rectangle((BORDER - 5, BORDER - 5, MODULE - BORDER + 4, MODULE - BORDER + 4),
                   outline=BRASS, width=2)
    draw.rectangle((BORDER - 2, BORDER - 2, MODULE - BORDER + 1, MODULE - BORDER + 1),
                   outline=BRASS_LIGHT, width=1)

    # Field: damask with an inner shadow at the top so the panel reads as recessed.
    field = tile_fill((inner, inner), materials["damask"], inner)
    field = ImageEnhance.Brightness(field).enhance(0.92)
    module.paste(field, (BORDER, BORDER))
    shade = Image.new("RGBA", (inner, inner), (0, 0, 0, 0))
    shade_draw = ImageDraw.Draw(shade)
    for step in range(16):
        shade_draw.line((0, step, inner, step), fill=(0, 0, 0, 120 - step * 7))
    module.paste(Image.alpha_composite(module.crop((BORDER, BORDER, BORDER + inner,
                                                    BORDER + inner)).convert("RGBA"),
                                       shade).convert("RGB"), (BORDER, BORDER))

    # Brass corner keys tie the four identical edges together.
    for x, y in ((6, 6), (MODULE - GAP + 1, 6), (6, MODULE - GAP + 1),
                 (MODULE - GAP + 1, MODULE - GAP + 1)):
        draw.rectangle((x, y, x + GAP - 6, y + GAP - 6), outline=BRASS, width=1)

    # Bevel inside the frame: light on the top/left, shadow on the bottom/right.
    draw.line((4, 4, MODULE - 5, 4), fill=BRASS_LIGHT, width=1)
    draw.line((4, 4, 4, MODULE - 5), fill=BRASS_LIGHT, width=1)
    draw.line((4, MODULE - 5, MODULE - 5, MODULE - 5), fill=DARK, width=1)
    draw.line((MODULE - 5, 4, MODULE - 5, MODULE - 5), fill=DARK, width=1)

    # Outer ring drawn last: the join between two modules is this identical dark groove on
    # every side, which is what makes horizontal, vertical and rotated tiling seamless.
    draw.rectangle((0, 0, MODULE - 1, MODULE - 1), outline=DARK, width=2)
    return module


def build_pillar_module(module):
    """Same frame, but the field is fluted so it reads as a structural end pillar."""
    pillar = module.copy()
    draw = ImageDraw.Draw(pillar)
    inner = MODULE - 2 * BORDER
    draw.rectangle((BORDER, BORDER, MODULE - BORDER - 1, MODULE - BORDER - 1),
                   fill=(58, 44, 34))
    for step in range(6):
        x = BORDER + 8 + step * ((inner - 16) // 5)
        draw.line((x, BORDER + 6, x, MODULE - BORDER - 6), fill=(20, 13, 9), width=2)
        draw.line((x + 2, BORDER + 6, x + 2, MODULE - BORDER - 6), fill=(96, 72, 52), width=1)
    return pillar


def rotate_cell(cell, quarters):
    return cell.transpose(Image.ROTATE_90).copy() if quarters % 2 else cell.copy()


def build_shapes(module, pillar, arms=3):
    """Compose every shape out of whole modules; all joints land on identical edges."""
    cell_h, cell_v = module, rotate_cell(module, 1)
    pillar_h, pillar_v = pillar, rotate_cell(pillar, 1)
    shapes = {}

    straight = Image.new("RGBA", (MODULE * arms, MODULE))
    for index in range(arms):
        straight.paste(cell_h, (index * MODULE, 0))
    shapes["straight_h"] = straight

    vertical = Image.new("RGBA", (MODULE, MODULE * arms))
    for index in range(arms):
        vertical.paste(cell_v, (0, index * MODULE))
    shapes["straight_v"] = vertical

    def corner(vertical_side, horizontal_side):
        canvas = Image.new("RGBA", (MODULE * arms, MODULE * arms))
        # Horizontal arm on the requested edge.
        row = 0 if horizontal_side == "top" else arms - 1
        for index in range(arms):
            canvas.paste(cell_h, (index * MODULE, row * MODULE))
        # Vertical arm on the requested edge.
        column = 0 if vertical_side == "left" else arms - 1
        for index in range(arms):
            canvas.paste(cell_v, (column * MODULE, index * MODULE))
        return canvas

    shapes["inner_corner_l"] = corner("left", "bottom")
    shapes["inner_corner_r"] = corner("right", "bottom")
    shapes["outer_corner_l"] = corner("left", "top")
    shapes["outer_corner_r"] = corner("right", "top")

    end = Image.new("RGBA", (MODULE * arms + MODULE, MODULE))
    for index in range(arms):
        end.paste(cell_h, (index * MODULE, 0))
    end.paste(pillar_h, (arms * MODULE, 0))
    shapes["end_pillar"] = end
    return shapes


def seam_delta(image, axis="x"):
    """Mean channel difference across the tiling edge, against the image's own variation."""
    grey = image.convert("L")
    width, height = grey.size
    if axis == "x":
        first = grey.crop((0, 0, 1, height)).tobytes()
        last = grey.crop((width - 1, 0, width, height)).tobytes()
        internal = [abs(a - b) for a, b in
                    zip(grey.crop((width // 2, 0, width // 2 + 1, height)).tobytes(),
                        grey.crop((width // 2 + 1, 0, width // 2 + 2, height)).tobytes())]
    else:
        first = grey.crop((0, 0, width, 1)).tobytes()
        last = grey.crop((0, height - 1, width, height)).tobytes()
        internal = [abs(a - b) for a, b in
                    zip(grey.crop((0, height // 2, width, height // 2 + 1)).tobytes(),
                        grey.crop((0, height // 2 + 1, width, height // 2 + 2)).tobytes())]
    edge = sum(abs(a - b) for a, b in zip(first, last)) / len(first)
    baseline = sum(internal) / len(internal) if internal else 0.0
    return {"edge_delta": round(edge, 2), "internal_delta": round(baseline, 2),
            "verdict": "seamless" if edge <= max(baseline * 1.5, 1.0) else "visible seam"}


def build_preview(shapes, comfy_root, style, target):
    """Side-by-side proof plus the constructed wall at phone framing scale."""
    tile = 220
    rows = len(SHAPES)
    scale_row = 150
    sheet = Image.new("RGB", (tile * 2 + 30, rows * (tile + 26) + scale_row + 20), "#202024")
    draw = ImageDraw.Draw(sheet)
    for row, shape in enumerate(SHAPES):
        top = row * (tile + 26) + 8
        ai_path = newest(comfy_root, ALPHA, f"wall_{style}_{shape}")
        for column, (label, image) in enumerate((("AI", ai_path), ("code", shapes[shape]))):
            left = 10 + column * (tile + 20)
            if isinstance(image, Path):
                if not image.is_file():
                    draw.text((left, top), f"{label}: missing", fill="#d05050")
                    continue
                with Image.open(image) as handle:
                    image = handle.convert("RGBA")
            else:
                image = image.convert("RGBA")
            for y in range(0, tile, 12):
                for x in range(0, tile, 12):
                    shade = "#3a3a40" if (x // 12 + y // 12) % 2 else "#2c2c32"
                    draw.rectangle((left + x, top + y, left + x + 11, top + y + 11), fill=shade)
            thumb = image.copy()
            thumb.thumbnail((tile, tile), Image.LANCZOS)
            sheet.paste(thumb, (left + (tile - thumb.width) // 2,
                                top + (tile - thumb.height) // 2), thumb)
        draw.text((10, top + tile + 4), f"{shape}: AI render  vs  constructed tile",
                  fill="#e8e8e8")

    # Bottom strip: the constructed straight wall at 1x and at 0.74x phone framing.
    top = rows * (tile + 26) + 6
    draw.text((10, top), "constructed straight wall at game scale: 1x (80 px tall) and 0.74x",
              fill="#e8e8e8")
    scale_y = top + 16
    for factor in (1.0, 0.74):
        height = max(1, int(MODULE // 2 * factor))
        width = max(1, int(shapes["straight_h"].width * factor / 2))
        band = shapes["straight_h"].resize((width, height), Image.LANCZOS)
        sheet.paste(band, (10, scale_y), band)
        scale_y += height + 10
    sheet = sheet.crop((0, 0, sheet.width, scale_y))
    target.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(target)
    return target


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--style", default="grand")
    parser.add_argument("--comfy-root", type=Path, default=DEFAULT_COMFY)
    parser.add_argument("--source", type=Path,
                        help="AI render used as the material source (default: newest straight_h)")
    parser.add_argument("--out", type=Path, default=ROOT / "build/wall_tileset")
    parser.add_argument("--preview", type=Path,
                        default=ROOT / "docs/evidence/wall_tileset/tileset_preview.png")
    parser.add_argument("--report", type=Path,
                        default=ROOT / "docs/evidence/wall_tileset/report.json")
    args = parser.parse_args(argv)

    source = args.source or newest(args.comfy_root, RAW, f"wall_{args.style}_straight_h")
    if not source:
        raise SystemExit(f"No AI source render found for style {args.style!r}")
    started = time.monotonic()
    materials = derive_materials(source)
    module = build_module(materials)
    pillar = build_pillar_module(module)
    shapes = build_shapes(module, pillar)
    elapsed = time.monotonic() - started

    target = args.out / args.style
    target.mkdir(parents=True, exist_ok=True)
    for name, image in shapes.items():
        image.save(target / f"wall_{args.style}_{name}.png")
    module.save(target / "module.png")

    report = {
        "style": args.style,
        "source": str(source),
        "build_seconds": round(elapsed, 2),
        "module_px": [MODULE, MODULE],
        "game_px": [MODULE // 2, MODULE // 2],
        "shapes": {name: list(image.size) for name, image in shapes.items()},
        "seams": {"straight_h": seam_delta(shapes["straight_h"], "x"),
                  "straight_v": seam_delta(shapes["straight_v"], "y")},
        "material_sources": {key: list(value.size) if hasattr(value, "size") else value
                             for key, value in materials.items()},
    }
    (target / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    ai_dir = args.comfy_root
    build_preview(shapes, ai_dir, args.style, args.preview)
    print(f"Built {len(shapes)} shapes in {elapsed:.2f}s -> {target}")
    for name, seam in report["seams"].items():
        print(f"  {name}: edge delta {seam['edge_delta']} vs internal "
              f"{seam['internal_delta']} -> {seam['verdict']}")
    print(f"Preview: {args.preview}")
    print(f"Report:  {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
