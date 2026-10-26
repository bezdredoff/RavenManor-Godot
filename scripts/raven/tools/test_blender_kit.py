import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def load_kit():
    path = ROOT / "tools/blender/kit_geometry.py"
    spec = importlib.util.spec_from_file_location("kit_geometry", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class WallKitGeometryTests(unittest.TestCase):
    def setUp(self):
        self.kit = load_kit()
        self.cross_section = (-self.kit.THICKNESS, 3.0)

    def test_corner_post_is_filled(self):
        # The previous geometry left the exterior post empty: light leaked through the joint.
        self.assertEqual(self.kit.corner_leak([self.kit.legacy_corner()]), 1.0)
        self.assertEqual(self.kit.corner_leak([self.kit.corner()]), 0.0)

    def test_corner_and_straight_present_the_same_joint_profile(self):
        straight = self.kit.plane_coverage([self.kit.straight()], "x", self.kit.LENGTH,
                                           self.cross_section)
        corner = self.kit.plane_coverage([self.kit.corner()], "x", self.kit.LENGTH,
                                         self.cross_section)
        self.assertAlmostEqual(straight, corner, places=6)
        self.assertGreater(straight, 0.5)

    def test_butt_joint_adds_no_gap(self):
        single = self.kit.plane_coverage([self.kit.straight()], "x", self.kit.LENGTH,
                                         self.cross_section)
        pair = [self.kit.straight(), self.kit.translate(self.kit.straight(), self.kit.LENGTH, 0)]
        joined = self.kit.plane_coverage(pair, "x", self.kit.LENGTH, self.cross_section)
        self.assertAlmostEqual(single, joined, places=6)

    def test_corner_arm_butts_into_straight_without_gap(self):
        corner_only = self.kit.plane_coverage([self.kit.corner()], "x", self.kit.LENGTH,
                                              self.cross_section)
        assembled = [self.kit.corner(),
                     self.kit.translate(self.kit.straight(), self.kit.LENGTH, 0)]
        joined = self.kit.plane_coverage(assembled, "x", self.kit.LENGTH, self.cross_section)
        self.assertAlmostEqual(corner_only, joined, places=6)

    def test_profile_covers_the_full_wall_height(self):
        total = sum(z1 - z0 for z0, z1, _p in self.kit.PROFILE)
        self.assertAlmostEqual(total, self.kit.HEIGHT, places=6)
        self.assertEqual(self.kit.PROFILE[0][0], 0.0)
        self.assertEqual(self.kit.PROFILE[-1][1], self.kit.HEIGHT)

    def test_piece_bounds_and_pivot(self):
        for name, boxes in (("straight", self.kit.straight()),
                            ("corner", self.kit.corner()),
                            ("end_pillar", self.kit.end_pillar())):
            with self.subTest(piece=name):
                report = self.kit.piece_report(name, boxes)
                self.assertEqual(report["pivot"], [0.0, 0.0, 0.0])
                self.assertEqual(report["bounds"][2], 0.0)      # sits on the floor
                self.assertGreaterEqual(report["size"][0], self.kit.LENGTH)


    def test_openings_keep_wall_above_a_door_and_below_a_window(self):
        wall = self.kit.wall_with_openings(
            600.0, [(150.0, 250.0, 0.0, 130.0), (400.0, 540.0, 70.0, 175.0)])
        y = -11.0
        self.assertFalse(self.kit.covers(wall, 200, y, 60))     # inside the doorway
        self.assertTrue(self.kit.covers(wall, 200, y, 150))     # header above the door
        self.assertFalse(self.kit.covers(wall, 470, y, 100))    # inside the window
        self.assertTrue(self.kit.covers(wall, 470, y, 30))      # wall under the window
        self.assertTrue(self.kit.covers(wall, 470, y, 185))     # wall above the window
        self.assertTrue(self.kit.covers(wall, 320, y, 60))      # pier between openings

    def test_door_leaf_and_window_frame_sit_inside_the_hole(self):
        door = (150.0, 250.0, 0.0, 130.0)
        leaf = self.kit.door_leaf(*door)
        xs = [b[0] for b in leaf] + [b[3] for b in leaf]
        zs = [b[2] for b in leaf] + [b[5] for b in leaf]
        ys = [b[1] for b in leaf] + [b[4] for b in leaf]
        self.assertGreaterEqual(min(xs), door[0])
        self.assertLessEqual(max(xs), door[1])
        self.assertGreaterEqual(min(zs), door[2])
        self.assertLessEqual(max(zs), door[3])
        self.assertGreaterEqual(min(ys), -self.kit.THICKNESS)
        self.assertLessEqual(max(ys), 0.0)

        window = (400.0, 540.0, 70.0, 175.0)
        parts, glass = self.kit.window_parts(*window)
        for box in parts:
            self.assertGreaterEqual(box[0], window[0])
            self.assertLessEqual(box[3], window[1])
        self.assertGreaterEqual(glass[0], window[0])
        self.assertLessEqual(glass[2], window[1])

    def test_wall_without_openings_matches_a_straight_run(self):
        self.assertEqual(self.kit.wall_with_openings(200.0, []), self.kit.straight())
    def test_mirror_keeps_geometry_valid(self):
        original = self.kit.corner()
        mirrored = self.kit.mirror_x(original)
        self.assertEqual(len(mirrored), len(original))
        ox0 = min(box[0] for box in original)
        ox1 = max(box[3] for box in original)
        mx0 = min(box[0] for box in mirrored)
        mx1 = max(box[3] for box in mirrored)
        self.assertAlmostEqual(mx0, -ox1, places=6)
        self.assertAlmostEqual(mx1, -ox0, places=6)


if __name__ == "__main__":
    unittest.main()
