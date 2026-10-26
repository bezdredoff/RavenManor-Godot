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


if __name__ == "__main__":
    unittest.main()
