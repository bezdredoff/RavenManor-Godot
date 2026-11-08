"""Run: python3 -m unittest discover -s assets/raven/map/tools -p 'test_*.py' -v."""
import copy
import hashlib
from pathlib import Path
import struct
import tempfile
import unittest
import zlib

from validate_first_floor_manifest import (
    ContractError, png_dimensions, project_plan, unproject_plan, verify
)


def chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xffffffff)


def valid_png(w: int, h: int) -> bytes:
    header = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    scanlines = b"".join(b"\x00" + b"\x00\x00\x00\xff" * w for _ in range(h))
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(scanlines)) + chunk(b"IEND", b"")


class MapManifestTests(unittest.TestCase):
    def test_dimensions_and_crc(self):
        raw = valid_png(7, 9)
        self.assertEqual(png_dimensions(raw), (7, 9))
        broken = bytearray(raw)
        broken[29] ^= 1
        with self.assertRaises(ContractError):
            png_dimensions(bytes(broken))

    def test_round_trip_has_no_raster_claim(self):
        for zoom in (.35, .74, 1.0, 2.2):
            point = [-5.3, 610.2]
            result = unproject_plan(project_plan(point, zoom, [800.25, -57.8]), zoom, [800.25, -57.8])
            for actual, expected in zip(result, point):
                self.assertAlmostEqual(actual, expected)

    def test_integrity_and_unique_ids(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            raw = valid_png(4, 6)
            (root / "approved.png").write_bytes(raw)
            rooms = [{"id": f"RM-ROOM-{name}"} for name in (
                "HALL", "ENTRY", "ARCHIVE", "CORRIDOR", "BEDROOM",
                "BATHROOM", "KITCHEN", "CONSERVATORY"
            )]
            data = {
                "schemaVersion": 1, "contractId": "raven.first-floor-art",
                "source": {"path": "approved.png", "byteSize": len(raw),
                           "sha256": hashlib.sha256(raw).hexdigest(), "dimensionsPx": [4, 6],
                           "gitBlobSha": hashlib.sha1(f"blob {len(raw)}\0".encode("ascii") + raw).hexdigest()},
                "rooms": rooms,
                "doors": [{"id": "RM-DOOR-ENTRY-HALL", "roomIds": [rooms[0]["id"], rooms[1]["id"]], "sourcePixelPoint": None}],
                "objects": [{"id": "RM-ASSET-HALL-CLOCK", "roomId": rooms[0]["id"], "sourcePixelPivot": None}],
                "navigationReferenceAnchors": [{"id": "RM-NAV-HALL-SPAWN", "roomId": rooms[0]["id"]}],
                "layers": [{"id": "base", "path": "approved.png", "state": "available"}],
                "unresolvedQuestions": [{"id": "ART-Q-1"}],
                "coordinateSystems": {"worldPlanToSourcePixel": {"status": "unresolved", "matrix": None}},
                "productionReady": False, "integrationAllowed": False,
            }
            self.assertTrue(verify(root, data, require_hash=True))
            bad = copy.deepcopy(data)
            bad["doors"].append(copy.deepcopy(bad["doors"][0]))
            with self.assertRaisesRegex(ContractError, "duplicate"):
                verify(root, bad)
            bad = copy.deepcopy(data)
            bad["source"]["sha256"] = "0" * 64
            with self.assertRaisesRegex(ContractError, "SHA256"):
                verify(root, bad)
            bad = copy.deepcopy(data)
            bad["layers"].append({"id": "invalid-path", "path": "../private.png", "state": "available"})
            with self.assertRaisesRegex(ContractError, "Unsafe"):
                verify(root, bad)
            bad = copy.deepcopy(data)
            bad["productionReady"] = True
            with self.assertRaisesRegex(ContractError, "cannot enable"):
                verify(root, bad)


if __name__ == "__main__":
    unittest.main()
