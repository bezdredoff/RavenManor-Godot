import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class FirstActWallKitTests(unittest.TestCase):
    def test_budget_and_every_map_boundary_are_accounted_for(self):
        kit = json.loads((ROOT / "data/raven/season1_wall_kit.json").read_text(encoding="utf-8"))
        world = json.loads((ROOT / "data/raven/season1_world_map.json").read_text(encoding="utf-8"))
        self.assertEqual(kit["wallStyles"], ["grand", "residential", "service", "glass"])
        self.assertEqual(kit["totals"], {"roomSides": 32, "wallGridUnits": 609,
            "physicalDoorOrArchOpenings": 10, "stairOpenings": 1,
            "ordinaryWindows": 7, "glassWallSections": 8})
        rooms = {room["roomId"]: room for room in kit["rooms"]}
        self.assertEqual(set(rooms), {room["id"] for room in world["rooms"]})
        described = {opening["doorId"] for room in kit["rooms"] for opening in room.get("openings", [])}
        self.assertEqual(described, {door["id"] for door in world["doors"] if door["a"] == 1 or door["b"] == 1}
                         | {"RM-DOOR-CORRIDOR-BEDROOM", "RM-DOOR-CORRIDOR-BATHROOM",
                            "RM-DOOR-CORRIDOR-KITCHEN", "RM-DOOR-KITCHEN-CONSERVATORY",
                            "RM-DOOR-KITCHEN-SERVICE", "RM-DOOR-CONSERVATORY-GARDEN"})
        self.assertEqual(sum(len(r.get("windows", [])) for r in kit["rooms"]), 7)
        self.assertEqual(sum(len(r.get("glassSections", [])) for r in kit["rooms"]), 8)

    def test_all_door_faces_match_exact_world_local_coordinates(self):
        kit = json.loads((ROOT / "data/raven/season1_wall_kit.json").read_text(encoding="utf-8"))
        world = json.loads((ROOT / "data/raven/season1_world_map.json").read_text(encoding="utf-8"))
        room_index = {room["id"]: index for index, room in enumerate(world["rooms"])}
        door_by_id = {door["id"]: door for door in world["doors"]}
        for room_schedule in kit["rooms"]:
            room = world["rooms"][room_index[room_schedule["roomId"]]]
            origin = room["rect"][:2]
            index = room_index[room_schedule["roomId"]]
            for opening in room_schedule.get("openings", []):
                door = door_by_id[opening["doorId"]]
                self.assertIn(index, [door["a"], door["b"]])
                self.assertEqual(opening["point"], [door["point"][0]-origin[0], door["point"][1]-origin[1]])

    def test_hall_wall_plan_has_five_distinct_portals_and_two_exact_stairs(self):
        plan = json.loads((ROOT / "data/raven/hall_wall_plan.json").read_text(encoding="utf-8"))
        world = json.loads((ROOT / "data/raven/season1_world_map.json").read_text(encoding="utf-8"))
        hall_index = next(i for i, room in enumerate(world["rooms"]) if room["id"] == "RM-ROOM-HALL")
        hall = world["rooms"][hall_index]
        walls = {wall["id"]: wall for wall in plan["walls"]}
        self.assertEqual(len(plan["openings"]), 5)
        self.assertEqual(len({opening["doorId"] for opening in plan["openings"]}), 5)
        expected = {door["id"]: [door["point"][0]-hall["rect"][0], door["point"][1]-hall["rect"][1]]
                    for door in world["doors"] if hall_index in [door["a"], door["b"]]}
        for opening in plan["openings"]:
            wall = walls[opening["wallId"]]
            actual = [wall["ax"]+(wall["bx"]-wall["ax"])*opening["offset"],
                      wall["ay"]+(wall["by"]-wall["ay"])*opening["offset"]]
            self.assertAlmostEqual(actual[0], expected[opening["doorId"]][0], places=5)
            self.assertAlmostEqual(actual[1], expected[opening["doorId"]][1], places=5)
        stair_props = {prop["id"]: [prop["rect"][0]-hall["rect"][0], prop["rect"][1]-hall["rect"][1],
                                         prop["rect"][2], prop["rect"][3]]
                       for prop in world["props"] if prop["id"].startswith("RM-ASSET-HALL-STAIRS-")}
        self.assertEqual({stair["id"]: stair["rect"] for stair in plan["staircases"]}, stair_props)
        self.assertEqual(sum(wall.get("role") == "balustrade-review" for wall in plan["walls"]), 4)
        self.assertEqual(plan["collisionPolicy"]["default"], "existing-combined-seat-obstacle")


if __name__ == "__main__":
    unittest.main()
