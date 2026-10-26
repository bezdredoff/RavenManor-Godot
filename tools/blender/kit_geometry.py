"""Pure-python geometry for the Blender wall kit.

Kept free of `bpy` so the joint maths can be unit-tested without Blender. Every piece is a
set of axis-aligned boxes; the kit convention is that two pieces butt-join when their
cross-section profile at the shared plane is identical, and that a corner owns the exterior
corner post so no quadrant stays empty.

Coordinates: Z is up, the room is at positive X/Y, walls grow outwards (negative X/Y).
"""
from __future__ import annotations

import math

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


def wall_with_openings(length: float,
                       openings: list[tuple[float, float, float, float]]) -> list[Box]:
    """Straight wall with rectangular holes, built from boxes instead of booleans.

    The wall is cut into horizontal slices at every profile and opening boundary; inside each
    slice the openings remove their x-interval. That keeps the wall solid under a window and
    above a door, and the hole's inner faces are the sides of the remaining boxes, so the
    reveal depth equals the wall thickness for free.
    """
    if not openings:
        return straight(length)

    cuts = {z for z0, z1, _p in PROFILE for z in (z0, z1)}
    for _x0, _x1, z0, z1 in openings:
        cuts.update((z0, z1))
    slices = sorted(cuts)

    boxes: list[Box] = []
    for z0, z1 in zip(slices, slices[1:]):
        if z1 <= z0:
            continue
        band = next((b for b in PROFILE if b[0] <= z0 < b[1]), None)
        if band is None:
            continue
        protrusion = band[2]
        holes = sorted((x0, x1) for x0, x1, oz0, oz1 in openings if oz0 <= z0 and z1 <= oz1)
        cursor = 0.0
        solids: list[tuple[float, float]] = []
        for x0, x1 in holes:
            if x0 > cursor:
                solids.append((cursor, x0))
            cursor = max(cursor, x1)
        if cursor < length:
            solids.append((cursor, length))
        for a, b in solids:
            boxes.append(north_arm(a, b, z0, z1, protrusion))
    return boxes

def door_leaf(open_x0: float, open_x1: float, open_z0: float, open_z1: float,
              gap: float = 1.5) -> list[Box]:
    """Closed leaf plus casing, sitting inside the reveal so states are separate sprites."""
    y0, y1 = -THICKNESS + 8.0, -8.0
    return [
        (open_x0 + gap, y0, open_z0 + gap, open_x1 - gap, y1, open_z1 - gap),
        (open_x0 + gap + 6, y1 - 1.0, open_z0 + gap + 6, open_x1 - gap - 6, y1 + 2.0,
         open_z1 - gap - 6),
    ]


def window_parts(open_x0: float, open_x1: float, open_z0: float, open_z1: float,
                 casing: float = 7.0, proud: float = 2.0
                 ) -> tuple[list[Box], tuple[float, float, float, float]]:
    """Window for a SOLID wall: proud casing, mullions and a glass pane.

    Windows are not traversable, so they stay part of the wall sprite instead of cutting a
    hole: no see-through opening, no occlusion work and no invented exterior behind the glass.
    Doorways and arches use `wall_with_openings()` instead.
    """
    mid_x = (open_x0 + open_x1) / 2
    mid_z = (open_z0 + open_z1) / 2
    frame = [
        (open_x0 - casing, 0.0, open_z0 - casing, open_x1 + casing, proud, open_z0),
        (open_x0 - casing, 0.0, open_z1, open_x1 + casing, proud, open_z1 + casing),
        (open_x0 - casing, 0.0, open_z0, open_x0, proud, open_z1),
        (open_x1, 0.0, open_z0, open_x1 + casing, proud, open_z1),
        (mid_x - 2.5, 0.0, open_z0, mid_x + 2.5, proud * 0.8, open_z1),
        (open_x0, 0.0, mid_z - 2.5, open_x1, proud * 0.8, mid_z + 2.5),
    ]
    glass = (open_x0, 0.0, open_z0, open_x1, proud * 0.4, open_z1)
    return frame, glass

def covers(boxes: list[Box], x: float, y: float, z: float) -> bool:
    """Public point-in-kit query used by the opening tests."""
    return _inside(boxes, x, y, z)

def arch_half_width(w: float, dz: float, rise: float) -> float:
    """Half-width of a two-centred (equilateral) pointed arch.

    The real construction uses two arcs centred on the opposite spring points: at height dz
    above the springline the clear half-width is `sqrt(W^2 - dz^2) - W/2`, which is zero at
    `0.866 * W`. The caller's apex may be lower or higher, so the height is rescaled first.
    """
    if rise <= 0 or dz >= rise or w <= 0:
        return 0.0
    if dz <= 0:
        return w
    equilateral_rise = math.sqrt(3.0) * w
    scaled = dz * equilateral_rise / rise
    width = 2.0 * w
    return max(0.0, math.sqrt(max(0.0, width * width - scaled * scaled)) - w)

def wall_with_arch(length: float, open_x0: float, open_x1: float, z0: float,
                   z_spring: float, z_apex: float, steps: int = 40) -> list[Box]:
    """Straight wall with a pointed-arch hole, cut into z slices.

    Below the springline the hole is a plain rectangle; above it each slice cuts the width of
    the curve. The slice height sets how smooth the head reads: 40 steps over the rise keeps
    the stair-stepping under one pixel at sprite scale.
    """
    if open_x1 <= open_x0 or z_apex <= z_spring:
        raise ValueError("arch needs a positive span and rise")
    half = (open_x1 - open_x0) / 2
    centre = (open_x0 + open_x1) / 2
    rise = z_apex - z_spring

    cuts = {z for band in PROFILE for z in (band[0], band[1])}
    cuts.update((z0, z_spring, z_apex))
    for index in range(1, steps):
        cuts.add(z_spring + rise * index / steps)
    slices = sorted(cuts)

    boxes: list[Box] = []
    for za, zb in zip(slices, slices[1:]):
        if zb <= za:
            continue
        band = next((b for b in PROFILE if b[0] <= za < b[1]), None)
        if band is None:
            continue
        protrusion = band[2]
        middle = (za + zb) / 2
        hole: tuple[float, float] | None = None
        if middle < z0:
            hole = None
        elif middle <= z_spring:
            hole = (open_x0, open_x1)
        else:
            width = arch_half_width(half, middle - z_spring, rise)
            hole = (centre - width, centre + width) if width > 0.4 else None
        solids: list[tuple[float, float]] = []
        if hole is None:
            solids.append((0.0, length))
        else:
            if hole[0] > 0:
                solids.append((0.0, hole[0]))
            if hole[1] < length:
                solids.append((hole[1], length))
        for a, b in solids:
            boxes.append(north_arm(a, b, za, zb, protrusion))
    return boxes


def arch_surround(open_x0: float, open_x1: float, z0: float, z_spring: float,
                  z_apex: float, steps: int = 18, band: float = 7.0,
                  proud: float = 2.5) -> list[Box]:
    """Archivolt: a moulded band that follows the curve and stands proud of the wall."""
    half = (open_x1 - open_x0) / 2
    centre = (open_x0 + open_x1) / 2
    rise = z_apex - z_spring
    boxes: list[Box] = [
        (open_x0 - band, 0.0, z0, open_x0, proud, z_spring),
        (open_x1, 0.0, z0, open_x1 + band, proud, z_spring),
    ]
    for index in range(steps):
        za = z_spring + rise * index / steps
        zb = z_spring + rise * (index + 1) / steps
        width_a = arch_half_width(half, za - z_spring, rise)
        width_b = arch_half_width(half, zb - z_spring, rise)
        if width_a <= 0.4 and width_b <= 0.4:
            continue
        outer = max(width_a, width_b) + band
        inner = min(width_a, width_b)
        boxes.append((centre - outer, 0.0, za, centre - inner, proud, zb))
        boxes.append((centre + inner, 0.0, za, centre + outer, proud, zb))
    return boxes

def stairs(width: float, steps: int = 8, rise: float = 14.0, run: float = 22.0,
           depth: float = 0.0) -> list[Box]:
    """Solid ascending flight: each step is a full-height block from the floor.

    `width` is measured along X, the flight climbs towards -Y (away from the camera) so the
    treads stay visible at a raised camera. `depth` shifts the whole flight away from the wall.
    """
    if steps < 1 or width <= 0 or rise <= 0 or run <= 0:
        raise ValueError("stairs need a positive width, rise, run and at least one step")
    half = width / 2
    boxes: list[Box] = []
    for index in range(steps):
        y0 = -depth - (index + 1) * run
        y1 = -depth - index * run
        boxes.append((-half, y0, 0.0, half, y1, (index + 1) * rise))
    return boxes


def balustrade(x0: float, x1: float, y: float, depth: float, base_z: float = 0.0,
               height: float = 64.0, post: float = 6.0, max_gap: float = 34.0) -> list[Box]:
    """Straight balustrade run: evenly spaced posts plus a handrail on top."""
    if x1 <= x0 or depth <= 0 or height <= 0:
        raise ValueError("balustrade needs a positive span, depth and height")
    span = x1 - x0
    count = max(2, int(span // max_gap) + 1)
    stride = (span - post) / (count - 1)
    boxes: list[Box] = []
    for index in range(count):
        px = x0 + post / 2 + index * stride
        boxes.append((px - post / 2, y, base_z, px + post / 2, y + depth, base_z + height))
    boxes.append((x0, y, base_z + height, x1, y + depth, base_z + height + 9.0))
    return boxes


def stair_opening(length: float, open_x0: float, open_x1: float, z_top: float) -> list[Box]:
    """Tall opening for a staircase: a portal that reaches from the floor to `z_top`."""
    return wall_with_openings(length, [(open_x0, open_x1, 0.0, z_top)])

def stair_rail(width: float, steps: int, rise: float, run: float, height: float = 58.0,
               post: float = 6.0, side: int = 1, depth: float = 0.0,
               slices_per_step: int = 4) -> list[Box]:
    """Balustrade that follows the flight: posts on the steps plus a sloped handrail.

    The handrail is built from thin slices instead of one rotated box, so it reads as a smooth
    slope after beveling while the kit stays axis-aligned and testable.
    """
    if steps < 1 or width <= 0 or rise <= 0 or run <= 0 or side not in (-1, 1):
        raise ValueError("stair rail needs a positive flight and side +1 or -1")
    outer = side * width / 2
    inner = outer - side * post
    x0, x1 = sorted((inner, outer))

    boxes: list[Box] = []
    for index in range(steps):
        y1 = -depth - index * run
        y0 = y1 - run
        z = (index + 1) * rise
        boxes.append((x0, y0, z, x1, y1, z + height))

    slices = max(1, steps * slices_per_step)
    for k in range(slices):
        t0 = k / slices
        t1 = (k + 1) / slices
        y0 = -depth - run * steps * t0
        y1 = -depth - run * steps * t1
        z0 = rise * steps * t0 + height
        z1 = rise * steps * t1 + height
        boxes.append((x0, min(y0, y1), z0, x1, max(y0, y1), z1))
    return boxes