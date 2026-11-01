"""Read-only Raven VN Studio v5 source adapter audit.

This produces an in-memory v2 proposal; it never creates or modifies a draft.
"""

import argparse
import hashlib
import json
from pathlib import Path

SOURCES = {
    "dialogue": "season1_dialogue_catalog.json",
    "staging": "vn_staging.json",
    "backgrounds": "vn_background_catalog.json",
    "cast": "character_performance.json",
    "cues": "line_performance_cues.json",
    "routes": "map_narrative_routes.json",
}


def audit(root: Path) -> dict:
    base = root / "data/raven/production"
    data = {}
    hashes = {}
    for key, name in SOURCES.items():
        raw = (base / name).read_bytes()
        data[key] = json.loads(raw)
        hashes[name] = hashlib.sha256(raw).hexdigest()

    scenes = data["dialogue"]["scenes"]
    lines = data["dialogue"]["entries"]
    shots = data["staging"]["sceneShots"]
    cues = data["cues"]["cues"]
    routes = data["routes"]["sceneTriggers"]
    backgrounds = data["backgrounds"]["entries"]
    scene_ids = [s["sceneId"] for s in scenes]
    line_ids = [line["id"] for line in lines]
    def unique(values, label):
        if len(values) != len(set(values)) or not all(values):
            raise ValueError(f"Duplicate or empty {label}")
    unique(scene_ids, "sceneId")
    unique(line_ids, "lineId")
    unique([b["id"] for b in backgrounds], "background variantId")
    unique([s["sceneId"] for s in shots], "shot sceneId")
    unique([r["sceneId"] for r in routes], "route sceneId")
    unique([c["lineId"] for c in cues], "cue lineId")
    if set(scene_ids) != {s["sceneId"] for s in shots} or set(scene_ids) != {r["sceneId"] for r in routes}:
        raise ValueError("Scene, shot and route ID sets differ")
    if set(line_ids) != {c["lineId"] for c in cues}:
        raise ValueError("Line and cue ID sets differ")
    if any(line["sceneId"] not in scene_ids for line in lines):
        raise ValueError("Line refers to unknown scene")
    if any(not line.get("localized", {}).get("ru", {}).get("text") for line in lines):
        raise ValueError("Line has no RU source text")
    if any(b["backgroundId"] not in {m["id"] for m in data["staging"]["masters"]} for b in backgrounds):
        raise ValueError("Background variant refers to unknown master")

    # The adapter is deliberately structural: no topology, stage coordinates or
    # animation semantics are inferred from order or performance cues.
    proposed = [{"sceneId": sid,
                 "lineIds": [line["id"] for line in lines if line["sceneId"] == sid],
                 "shotId": sid,
                 "transitions": []} for sid in scene_ids]
    return {
        "format": "vns5-read-only-contract-audit-v1",
        "sourceSha256": hashes,
        "counts": {"scenes": len(scenes), "lines": len(lines),
                   "masters": len(data["staging"]["masters"]), "shots": len(shots),
                   "backgroundCandidates": len(backgrounds),
                   "characters": len(data["cast"]["characters"]),
                   "cues": len(cues), "routes": len(routes)},
        "sceneIds": scene_ids,
        "lineIds": line_ids,
        "backgroundVariantIds": [b["id"] for b in backgrounds],
        "proposedSceneAdapters": proposed,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[3])
    args = parser.parse_args()
    print(json.dumps(audit(args.root), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
