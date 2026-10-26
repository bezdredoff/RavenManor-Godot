import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]


def load_module():
    path = ROOT / "scripts/raven/tools/build_wall_tileset.py"
    spec = importlib.util.spec_from_file_location("build_wall_tileset", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def materials(module):
    wood = Image.new("RGB", (64, 64), (74, 49, 40))
    trim = Image.new("RGB", (64, 64), (96, 68, 52))
    damask = Image.new("RGB", (64, 64), (83, 40, 37))
    return {"wood": wood, "trim": trim, "damask": damask, "brass": (156, 125, 63)}


class WallTilesetTests(unittest.TestCase):
    def setUp(self):
        self.tiles = load_module()
        self.material = materials(self.tiles)

    def test_module_edges_are_identical_on_all_four_sides(self):
        module = self.tiles.build_module(self.material).convert("RGB")
        size = module.width
        left = module.crop((0, 0, 1, size)).tobytes()
        right = module.crop((size - 1, 0, size, size)).tobytes()
        top = module.crop((0, 0, size, 1)).tobytes()
        bottom = module.crop((0, size - 1, size, size)).tobytes()
        self.assertEqual(left, right, "left and right edges differ -> horizontal tiling seam")
        self.assertEqual(top, bottom, "top and bottom edges differ -> vertical tiling seam")

    def test_shapes_have_expected_geometry_and_transparent_outside(self):
        module = self.tiles.build_module(self.material)
        pillar = self.tiles.build_pillar_module(module)
        shapes = self.tiles.build_shapes(module, pillar)
        self.assertEqual(set(shapes), set(self.tiles.SHAPES))
        self.assertEqual(shapes["straight_h"].size,
                         (self.tiles.MODULE * 3, self.tiles.MODULE))
        self.assertEqual(shapes["straight_v"].size,
                         (self.tiles.MODULE, self.tiles.MODULE * 3))
        self.assertEqual(shapes["inner_corner_l"].size,
                         (self.tiles.MODULE * 3, self.tiles.MODULE * 3))
        # The L leaves its top-right quadrant empty and must be genuinely transparent there.
        corner = shapes["inner_corner_l"]
        alpha = corner.getchannel("A")
        self.assertEqual(alpha.getpixel((corner.width - 4, 4)), 0)
        self.assertEqual(alpha.getpixel((4, corner.height - 4)), 255)
        # The end pillar is one module wider than the plain straight wall.
        self.assertEqual(shapes["end_pillar"].width, self.tiles.MODULE * 4)

    def test_constructed_tiles_report_zero_seam_delta(self):
        module = self.tiles.build_module(self.material)
        pillar = self.tiles.build_pillar_module(module)
        shapes = self.tiles.build_shapes(module, pillar)
        horizontal = self.tiles.seam_delta(shapes["straight_h"], "x")
        vertical = self.tiles.seam_delta(shapes["straight_v"], "y")
        self.assertEqual(horizontal["edge_delta"], 0.0)
        self.assertEqual(vertical["edge_delta"], 0.0)
        self.assertEqual(horizontal["verdict"], "seamless")
        self.assertEqual(vertical["verdict"], "seamless")

    def test_rotated_cell_keeps_the_same_edge_ring(self):
        module = self.tiles.build_module(self.material)
        rotated = self.tiles.rotate_cell(module, 1)
        self.assertEqual(rotated.size, (self.tiles.MODULE, self.tiles.MODULE))
        self.assertEqual(rotated.crop((0, 0, 1, rotated.height)).tobytes(),
                         module.crop((0, 0, 1, module.height)).tobytes())

    def test_derive_materials_reads_bounds_from_the_alpha_sibling(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "raw").mkdir()
            (root / "alpha").mkdir()
            raw = root / "raw" / "wall_grand_straight_h_00001_.png"
            alpha = root / "alpha" / raw.name
            Image.new("RGB", (256, 256), (255, 255, 255)).save(raw)
            canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
            draw = ImageDraw.Draw(canvas)
            draw.rectangle((32, 28, 224, 228), fill=(74, 49, 40, 255))
            draw.rectangle((96, 100, 176, 200), fill=(83, 40, 37, 255))
            canvas.save(alpha)
            derived = self.tiles.derive_materials(raw)
            for key in ("wood", "trim", "damask"):
                self.assertGreater(derived[key].width, 7)
                self.assertGreater(derived[key].height, 7)

            # Without a usable matte the tool must refuse rather than fabricate materials.
            opaque = root / "raw" / "wall_grand_straight_v_00001_.png"
            Image.new("RGB", (256, 256), (74, 49, 40)).save(opaque)
            with self.assertRaises(ValueError):
                self.tiles.derive_materials(opaque)

    def test_committed_report_describes_a_seamless_tileset(self):
        report_path = ROOT / "docs/evidence/wall_tileset/report.json"
        self.assertTrue(report_path.is_file(), "tileset report is missing from docs/evidence")
        report = json.loads(report_path.read_text(encoding="utf-8"))
        self.assertEqual(report["style"], "grand")
        self.assertEqual(report["module_px"], [self.tiles.MODULE, self.tiles.MODULE])
        self.assertEqual(report["game_px"], [self.tiles.MODULE // 2, self.tiles.MODULE // 2])
        self.assertEqual(set(report["shapes"]), set(self.tiles.SHAPES))
        for name in ("straight_h", "straight_v"):
            self.assertEqual(report["seams"][name]["edge_delta"], 0.0)
            self.assertEqual(report["seams"][name]["verdict"], "seamless")


if __name__ == "__main__":
    unittest.main()
