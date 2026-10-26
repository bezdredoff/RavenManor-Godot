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


    def test_door_is_a_through_hole_and_the_header_stays_solid(self):
        door = (150.0, 250.0, 0.0, 130.0)
        wall = self.kit.wall_with_openings(600.0, [door])
        self.assertFalse(self.kit.covers(wall, 200, -21.0, 60))   # through the doorway
        self.assertFalse(self.kit.covers(wall, 200, -5.0, 60))    # nothing in the reveal
        self.assertTrue(self.kit.covers(wall, 200, -11.0, 150))   # header above the door
        self.assertTrue(self.kit.covers(wall, 320, -11.0, 60))    # pier beside it

    def test_window_keeps_the_wall_solid(self):
        # Windows are not traversable: they stay part of the wall sprite, with no hole.
        door = (150.0, 250.0, 0.0, 130.0)
        wall = self.kit.wall_with_openings(600.0, [door])
        window = (400.0, 540.0, 70.0, 175.0)
        for y in (-21.0, -11.0, -1.0):
            with self.subTest(y=y):
                self.assertTrue(self.kit.covers(wall, 470, y, 120))
        frame, glass = self.kit.window_parts(*window)
        self.assertTrue(frame)
        self.assertGreaterEqual(glass[0], window[0])
        self.assertLessEqual(glass[2], window[1])

    def test_window_frame_sits_proud_of_the_wall_face(self):
        frame, glass = self.kit.window_parts(400.0, 540.0, 70.0, 175.0)
        for box in frame:
            self.assertGreaterEqual(box[1], 0.0)          # starts at the inner face
            self.assertGreater(box[4], 0.0)               # and stands proud of it
        self.assertGreater(glass[4], 0.0)

    def test_door_leaf_sits_inside_the_hole(self):
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

    def test_arch_is_open_below_the_apex_and_solid_above_it(self):
        arch = dict(open_x0=220.0, open_x1=380.0, z0=0.0, z_spring=85.0, z_apex=185.0)
        wall = self.kit.wall_with_arch(600.0, **arch)
        centre = (arch["open_x0"] + arch["open_x1"]) / 2
        y = -11.0
        self.assertFalse(self.kit.covers(wall, centre, y, 40))    # doorway below the spring
        self.assertFalse(self.kit.covers(wall, centre, y, 150))   # inside the vault
        self.assertTrue(self.kit.covers(wall, centre, y, 190))    # header above the apex
        self.assertTrue(self.kit.covers(wall, arch["open_x0"] - 4, y, 50))   # jamb
        self.assertFalse(self.kit.covers(wall, arch["open_x0"] + 4, y, 50))  # clear opening

    def test_arch_curve_narrows_monotonically(self):
        widths = [self.kit.arch_half_width(60.0, dz, 100.0) for dz in (0, 20, 40, 60, 80, 99)]
        self.assertAlmostEqual(widths[0], 60.0, places=6)
        self.assertGreater(widths[-1], 0.0)
        self.assertLess(widths[-1], 5.0)
        for a, b in zip(widths, widths[1:]):
            self.assertGreater(a, b)

    def test_arch_surround_stays_outside_the_opening_and_proud(self):
        arch = dict(open_x0=220.0, open_x1=380.0, z0=0.0, z_spring=85.0, z_apex=185.0)
        parts = self.kit.arch_surround(**arch)
        self.assertTrue(parts)
        centre = (arch["open_x0"] + arch["open_x1"]) / 2
        for box in parts:
            self.assertGreater(box[4], 0.0)          # proud of the wall face
            self.assertLess(box[2], arch["z_apex"] + 1.0)
            # Each band segment must sit outside the clear opening at its own height.
            if box[3] <= centre:
                self.assertLessEqual(box[3], centre)
            else:
                self.assertGreaterEqual(box[0], centre)

    def test_arch_rejects_degenerate_shape(self):
        with self.assertRaises(ValueError):
            self.kit.wall_with_arch(600.0, 220.0, 380.0, 0.0, 120.0, 120.0)
        with self.assertRaises(ValueError):
            self.kit.wall_with_arch(600.0, 380.0, 220.0, 0.0, 80.0, 160.0)
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



    def test_stairs_are_contiguous_and_rising(self):
        flight = self.kit.stairs(width=180.0, steps=8, rise=15.0, run=24.0)
        self.assertEqual(len(flight), 8)
        for index, (x0, y0, z0, x1, y1, z1) in enumerate(flight):
            self.assertEqual(x0, -90.0)
            self.assertEqual(x1, 90.0)
            self.assertEqual(z0, 0.0)
            self.assertAlmostEqual(z1, (index + 1) * 15.0, places=6)
            if index:
                self.assertAlmostEqual(y1, flight[index - 1][1], places=6)  # shared riser line
        self.assertAlmostEqual(flight[-1][5], 120.0, places=6)

    def test_balustrade_posts_stay_inside_the_span_and_carry_a_rail(self):
        x0, x1 = 250.0, 330.0
        parts = self.kit.balustrade(x0, x1, 4.0, 7.0, height=64.0, max_gap=34.0)
        posts = parts[:-1]
        rail = parts[-1]
        self.assertGreaterEqual(len(posts), 3)
        for x_a, y0, z0, x_b, _y1, z1 in posts:
            self.assertGreaterEqual(x_a, x0)
            self.assertLessEqual(x_b, x1)
            self.assertAlmostEqual(z1, 64.0, places=6)
        self.assertEqual(rail[0], x0)
        self.assertEqual(rail[3], x1)
        self.assertAlmostEqual(rail[2], 64.0, places=6)

    def test_stair_opening_is_clear_and_headed(self):
        wall = self.kit.stair_opening(700.0, 250.0, 450.0, 190.0)
        self.assertFalse(self.kit.covers(wall, 350, -11.0, 80))    # clear below the head
        self.assertTrue(self.kit.covers(wall, 350, -11.0, 195))    # header above
        self.assertTrue(self.kit.covers(wall, 240, -11.0, 80))     # pier beside
        self.assertTrue(self.kit.covers(wall, 460, -11.0, 80))

    def test_stairs_reject_degenerate_input(self):
        with self.assertRaises(ValueError):
            self.kit.stairs(180.0, steps=0)
        with self.assertRaises(ValueError):
            self.kit.stairs(180.0, rise=0)
        with self.assertRaises(ValueError):
            self.kit.balustrade(300.0, 200.0, 0.0, 6.0)


    def test_stair_rail_posts_rise_with_the_flight(self):
        rail = self.kit.stair_rail(180.0, steps=8, rise=15.0, run=24.0, side=1)
        posts = rail[:8]
        self.assertEqual(len(posts), 8)
        for index, (x0, _y0, z0, x1, _y1, z1) in enumerate(posts):
            self.assertGreaterEqual(x0, 84.0)      # on the +X edge of a 180-wide flight
            self.assertLessEqual(x1, 90.0)
            self.assertAlmostEqual(z0, (index + 1) * 15.0, places=6)
            self.assertAlmostEqual(z1, (index + 1) * 15.0 + 58.0, places=6)

    def test_stair_rail_handrail_climbs_continuously(self):
        rail = self.kit.stair_rail(180.0, steps=8, rise=15.0, run=24.0, side=1,
                                   slices_per_step=8)
        slices = rail[8:]
        self.assertGreaterEqual(len(slices), 8 * 4)
        tops = [box[5] for box in slices]
        for a, b in zip(tops, tops[1:]):
            self.assertGreaterEqual(b, a - 1e-9)
        self.assertAlmostEqual(tops[-1], 8 * 15.0 + 58.0, places=6)

    def test_stair_rail_mirrors_to_the_other_side(self):
        left = self.kit.stair_rail(180.0, steps=4, rise=15.0, run=24.0, side=-1)
        for x0, _y0, _z0, x1, _y1, _z1 in left[:4]:
            self.assertGreaterEqual(x0, -90.0)
            self.assertLessEqual(x1, -84.0 + 1e-9)

    def test_stair_rail_rejects_bad_side(self):
        with self.assertRaises(ValueError):
            self.kit.stair_rail(180.0, steps=4, rise=15.0, run=24.0, side=0)

if __name__ == "__main__":
    unittest.main()
