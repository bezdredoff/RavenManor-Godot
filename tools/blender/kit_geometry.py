"""Pure-python geometry for the Blender wall kit.

Kept free of `bpy` so the joint maths can be unit-tested without Blender. Every piece is a
set of axis-aligned boxes; the kit convention is that two pieces butt-join when their
cross-section profile at the shared plane is identical, and that a corner owns the exterior
corner post so no quadrant stays empty.

Coordinates: Z is up, the room is at positive X/Y, walls grow outwards (negative X/Y).
"""
from __future__ import annotations

THICKNESS = 22.0
HEIGHT = 200.0
LENGTH = 200.0

# (z0, z1, protrusion towards the room) — plinth, wainscot, chair rail, upper wall, crown.
PROFILE = (
    (0.0, 8.0, 0.0),
    (8.0, 70.0, 1.5),
    (70.0, 75.0, 3.0),
    (75.0, 194.0, 0.0),
    (194.0, 200.0, 2.0),
)

Box = tuple[float, float, float, float, float, float]   # x0, y0, z0, x1, y1, z1


def north_arm(x0: float, x1: float, z0: float, z1: float, protrusion: float) -> Box:
    """Wall running along +X with its inner face on y = 0."""
    return (x0, -THICKNESS, z0, x1, protrusion, z1)


def west_arm(y0: float, y1: float, z0: float, z1: float, protrusion: float) -> Box:
    """Wall running along +Y with its inner face on x = 0."""
    return (-THICKNESS, y0, z0, protrusion, y1, z1)


def straight(length: float = LENGTH) -> list[Box]:
    return [north_arm(0.0, length, z0, z1, p) for z0, z1, p in PROFILE]


def corner(length: float = LENGTH) -> list[Box]:
    """Inside corner: the north arm wraps the exterior corner post, the west arm butts into it.

    The post is what makes the joint solid. A corner pilaster then covers the two wainscot
    ends, so the junction reads as a designed detail instead of a seam.
    """
    boxes: list[Box] = []
    for z0, z1, protrusion in PROFILE:
        boxes.append(north_arm(-THICKNESS, length, z0, z1, protrusion))
        boxes.append(west_arm(0.0, length, z0, z1, protrusion))
    # Pilaster: fills the inner corner through the wainscot and the chair rail.
    boxes.append((-THICKNESS - 3.0, -THICKNESS - 3.0, 6.0, 26.0, 26.0, 75.0))
    boxes.append((-THICKNESS - 5.0, -THICKNESS - 5.0, 75.0, 28.0, 28.0, 82.0))
    return boxes


def end_pillar(length: float = LENGTH, column: float = 34.0) -> list[Box]:
    """Straight run finished with a slightly wider, taller pillar at its far end."""
    boxes = straight(length)
    over = 4.0
    for index, (z0, z1, _protrusion) in enumerate(PROFILE):
        top = HEIGHT + 6.0 if index == len(PROFILE) - 1 else z1
        boxes.append((length - column, -THICKNESS - over, z0, length, over, top))
    boxes.append((length - column - 2, -THICKNESS - over - 2, HEIGHT + 6.0,
                  length + 2, over + 2, HEIGHT + 14.0))
    return boxes


def legacy_corner(length: float = LENGTH) -> list[Box]:
    """Previous corner: both arms start at zero, leaving the exterior post empty.

    Kept only so the regression test can prove the leak metric still catches it.
    """
    boxes: list[Box] = []
    for z0, z1, protrusion in PROFILE:
        boxes.append(north_arm(0.0, length, z0, z1, protrusion))
        boxes.append(west_arm(0.0, length, z0, z1, protrusion))
    return boxes


def mirror_x(boxes: list[Box]) -> list[Box]:
    """Mirror a piece across the Y axis, keeping box winding valid."""
    return [(-x1, y0, z0, -x0, y1, z1) for x0, y0, z0, x1, y1, z1 in boxes]


def translate(boxes: list[Box], dx: float, dy: float, dz: float = 0.0) -> list[Box]:
    return [(x0 + dx, y0 + dy, z0 + dz, x1 + dx, y1 + dy, z1 + dz)
            for x0, y0, z0, x1, y1, z1 in boxes]


def _inside(boxes: list[Box], x: float, y: float, z: float, eps: float = 1e-6) -> bool:
    for x0, y0, z0, x1, y1, z1 in boxes:
        if x0 - eps <= x <= x1 + eps and y0 - eps <= y <= y1 + eps and z0 - eps <= z <= z1 + eps:
            return True
    return False


def plane_coverage(pieces: list[list[Box]], axis: str, value: float,
                   u_range: tuple[float, float], steps: int = 61) -> float:
    """Coverage of a cut plane over an explicit cross-section envelope.

    Used to prove that two pieces present the same profile where they meet: both sides must
    return 1.0 for the same envelope, otherwise there is a step or a gap at the joint.
    """
    boxes = [box for piece in pieces for box in piece]
    covered = 0
    total = 0
    u0, u1 = u_range
    for i in range(steps):
        u = u0 + (u1 - u0) * i / (steps - 1)
        for j in range(steps):
            z = HEIGHT * j / (steps - 1)
            point = {"x": (value, u, z), "y": (u, value, z)}[axis]
            total += 1
            if _inside(boxes, *point):
                covered += 1
    return covered / total


def corner_leak(pieces: list[list[Box]], steps: int = 41) -> float:
    """Fraction of the exterior corner post that is empty (0.0 means the corner is filled)."""
    empty = 0
    total = 0
    for i in range(steps):
        for j in range(steps):
            for k in range(steps):
                x = -THICKNESS + THICKNESS * 0.02 + (THICKNESS * 0.96) * i / (steps - 1)
                y = -THICKNESS + THICKNESS * 0.02 + (THICKNESS * 0.96) * j / (steps - 1)
                z = HEIGHT * 0.02 + HEIGHT * 0.96 * k / (steps - 1)
                total += 1
                if not _inside([box for piece in pieces for box in piece], x, y, z):
                    empty += 1
    return empty / total


def piece_report(name: str, boxes: list[Box]) -> dict:
    xs = [b[0] for b in boxes] + [b[3] for b in boxes]
    ys = [b[1] for b in boxes] + [b[4] for b in boxes]
    zs = [b[2] for b in boxes] + [b[5] for b in boxes]
    return {"name": name, "boxes": len(boxes), "size": [round(max(xs) - min(xs), 2),
                                                        round(max(ys) - min(ys), 2),
                                                        round(max(zs) - min(zs), 2)],
            "bounds": [round(min(xs), 2), round(min(ys), 2), round(min(zs), 2),
                       round(max(xs), 2), round(max(ys), 2), round(max(zs), 2)],
            # Pivot sits on the floor at the inner corner, matching the room's wall line.
            "pivot": [0.0, 0.0, 0.0]}
