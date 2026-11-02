#!/usr/bin/env python3
"""Offline integrity check + immutable extraction for Godot VNS5-06D1 bundles.

Input is the *exact* raven-vn-production-4registry-review-v1 JSON exported
by Raven VN Studio (PR #117). This is not an alternate approval manifest and
never changes res://, runtime flags, player saves or canonical registries.

  python3 scripts/raven/tools/prepare_vn_promotion.py --package review.json --check-only
  python3 scripts/raven/tools/prepare_vn_promotion.py --package review.json --output /tmp/review-folder
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "data/raven/production"
FILES = {
    "catalog": "season1_dialogue_catalog.json",
    "staging": "vn_staging.json",
    "routes": "map_narrative_routes.json",
    "cues": "line_performance_cues.json",
    "cast": "character_performance.json",
}
CANDIDATE_NAMES = tuple(FILES[key] for key in ("catalog", "staging", "routes", "cues"))
SOURCE_HASH_KEYS = {
    "catalog": "sourceSha256", "staging": "stageSourceSha256",
    "routes": "routeSourceSha256", "cues": "cueSourceSha256",
    "cast": "castSourceSha256",
}
PACKAGE_FORMAT = "raven-vn-production-4registry-review-v1"
SCENE_ID = re.compile(r"RM-BEAT-[0-9]{2}-[0-9]{2}$")
LINE_ID = re.compile(r"RM-BEAT-[0-9]{2}-(?:[0-9]{2}|POST)-L[0-9]{3}$")


class BundleError(ValueError):
    pass


def demand(ok: bool, reason: str) -> None:
    if not ok:
        raise BundleError(reason)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    demand(isinstance(value, dict), f"{path}: expected object")
    return value


def index(rows: object, key: str, where: str) -> dict:
    demand(isinstance(rows, list), f"{where} must be a list")
    found = {}
    for row in rows:
        demand(isinstance(row, dict) and isinstance(row.get(key), str) and
               bool(row[key]) and row[key] not in found,
               f"{where}: duplicate/missing {key}")
        found[row[key]] = row
    return found


def same_metadata(original: dict, candidate: dict, where: str) -> None:
    demand({k: v for k, v in original.items() if k != "status"} ==
           {k: v for k, v in candidate.items() if k != "status"},
           f"{where}: canonical metadata unexpectedly changed")


def verify(package: dict, base: Path = BASE, package_sha: str | None = None) -> dict[str, bytes]:
    """Verify exact merged-main parity; return fixed-name candidate files + audit manifest."""
    demand(package.get("format") == PACKAGE_FORMAT and
           package.get("schemaVersion") == 1,
           "Expected native Godot VNS5-06D1 four-registry review bundle")
    demand(package.get("runtimeApplied") is False and
           package.get("readyForRuntime") is False and
           package.get("requiresHumanReview") is True and
           package.get("requiresFollowUpPromotion") is True,
           "Unapproved, non-runtime review markers are mandatory")
    demand(isinstance(package.get("reviewRef"), str) and
           4 <= len(package["reviewRef"].strip()) <= 160,
           "Review reference is missing (not proof of approval)")
    demand(isinstance(package.get("releaseBlockers"), list) and
           len(package["releaseBlockers"]) >= 3,
           "Release blockers missing: cannot treat review as playable content")
    original = {kind: load(base / name) for kind, name in FILES.items()}
    hashes = {kind: digest((base / name).read_bytes()) for kind, name in FILES.items()}
    for kind, key in SOURCE_HASH_KEYS.items():
        demand(package.get(key) == hashes[kind],
               f"{kind} source SHA drift; re-export from updated main")
    files = package.get("files")
    demand(isinstance(files, dict) and set(files) == set(CANDIDATE_NAMES),
           "Expected exactly four candidate registry files")
    mapped = package.get("sceneIdMap")
    line_map = package.get("lineIdMap")
    raw = package.get("retainedDraft")
    demand(isinstance(mapped, dict) and isinstance(line_map, dict) and
           isinstance(raw, dict), "Missing source-preserving draft ID maps")
    authored = index(raw.get("authoredScenes"), "sceneId", "authoredScenes")
    authored_lines = index(raw.get("authoredLines"), "id", "authoredLines")
    demand(set(mapped) == set(authored) and
           all(id.startswith("RM-DRAFT-BEAT-") for id in mapped),
           "Every reserved draft scene needs one mapping")
    new_scene_ids = list(mapped.values())
    demand(all(isinstance(s, str) and SCENE_ID.fullmatch(s) for s in new_scene_ids) and
           len(set(new_scene_ids)) == len(new_scene_ids),
           "Invalid/duplicate mapped scene IDs")
    demand(set(line_map) == set(authored_lines),
           "Line mapping must cover all and only authored lines")
    old_scenes = index(original["catalog"]["scenes"], "sceneId", "canonical scenes")
    old_lines = index(original["catalog"]["entries"], "id", "canonical lines")
    old_shots = index(original["staging"]["sceneShots"], "sceneId", "canonical shots")
    old_routes = index(original["routes"]["sceneTriggers"], "sceneId", "canonical routes")
    old_cues = index(original["cues"]["cues"], "lineId", "canonical cues")
    demand(set(old_scenes) == set(old_shots) == set(old_routes),
           "Canonical scenes/shots/routes are already out of sync")
    demand(set(old_lines) == set(old_cues),
           "Canonical line/cue registry parity broken")
    demand(not set(new_scene_ids) & set(old_scenes), "New scene ID collides with production")
    demand(all(isinstance(v, str) and LINE_ID.fullmatch(v) for v in line_map.values()) and
           len(set(line_map.values())) == len(line_map) and
           not set(line_map.values()) & set(old_lines),
           "New line ID malformed, duplicated or colliding")
    for kind, name in FILES.items():
        if kind == "cast":
            continue
        candidate = files[name]
        demand(isinstance(candidate, dict) and
               candidate.get("status") == "DRAFT_REVIEW_NOT_RUNTIME",
               f"{name}: status must remain review-only")
        for field in original[kind]:
            if field in ("status", "scenes", "entries", "sceneShots", "sceneTriggers", "cues"):
                continue
            demand(candidate.get(field) == original[kind][field],
                   f"{name}: canonical metadata changed at {field}")
    proposed_scenes = index(files[FILES["catalog"]].get("scenes"), "sceneId", "candidate scenes")
    proposed_lines = index(files[FILES["catalog"]].get("entries"), "id", "candidate lines")
    proposed_shots = index(files[FILES["staging"]].get("sceneShots"), "sceneId", "candidate shots")
    proposed_routes = index(files[FILES["routes"]].get("sceneTriggers"), "sceneId", "candidate routes")
    proposed_cues = index(files[FILES["cues"]].get("cues"), "lineId", "candidate cues")
    demand(set(proposed_scenes) == set(old_scenes) | set(new_scene_ids) ==
           set(proposed_shots) == set(proposed_routes),
           "Scene, shot and route 1:1 coverage failed")
    demand(set(proposed_lines) == set(old_lines) | set(line_map.values()) ==
           set(proposed_cues), "Line and cue 1:1 coverage failed")
    for id, record in old_scenes.items():
        demand(proposed_scenes[id] == record, f"Canonical scene changed: {id}")
    for kind, old_index, next_index in (
            ("shot", old_shots, proposed_shots),
            ("route", old_routes, proposed_routes),
            ("cue", old_cues, proposed_cues)):
        for id, record in old_index.items():
            demand(next_index[id] == record, f"Canonical {kind} changed: {id}")
    patches = raw.get("textPatches")
    demand(isinstance(patches, dict), "Missing source text patch history")
    demand(set(patches).issubset(set(old_lines) | set(authored_lines)),
           "Unknown line has text patches")
    for id, record in old_lines.items():
        expected = copy.deepcopy(record)
        change = patches.get(id, {})
        demand(isinstance(change, dict) and set(change).issubset({"ru", "be", "en"}),
               "Invalid old-line text patch")
        for lang, value in change.items():
            demand(isinstance(value, str), "Text patch must be a string")
            expected["localized"][lang] = {"text": value}
        demand(proposed_lines[id] == expected,
               f"Unreviewed canonical line mutation: {id}")
    cast = index(original["cast"]["characters"], "id", "canonical actors")
    masters = index(original["staging"]["masters"], "id", "background masters")
    for source_id, target_id in mapped.items():
        raw_scene = authored[source_id]
        scene = proposed_scenes[target_id]
        demand(scene.get("title") == raw_scene.get("title") and
               scene.get("status") == "review_only_not_runtime" and
               scene.get("source") == "vn_studio_promotion_review_only",
               f"New scene provenance/status wrong: {target_id}")
        shot = proposed_shots[target_id]
        bg = masters.get(shot.get("backgroundId"))
        demand(bg is not None and
               shot.get("lighting") in bg.get("lightingVariants", []) and
               shot.get("roomState") in bg.get("stateLayers", []),
               f"Invalid master/lighting/room-state: {target_id}")
        members = shot.get("cast")
        demand(isinstance(members, list) and 1 <= len(members) <= 3 and
               shot.get("visibleCount") == len(members), f"Invalid cast size: {target_id}")
        slots = set()
        actors = set()
        for member in members:
            demand(isinstance(member, dict) and member.get("characterId") in cast,
                   f"Unregistered staged character: {target_id}")
            actor_id = member["characterId"]
            spec = cast[actor_id]
            demand(actor_id not in actors and member.get("slot") in ("left", "center", "right") and
                   member["slot"] not in slots, f"Repeated actor/slot: {target_id}")
            demand(member.get("pose") in spec.get("poses", []) and
                   member.get("emotion") in spec.get("emotions", []),
                   f"Unknown pose/emotion: {target_id}")
            micro = {m["id"] for m in spec.get("signatureMicros", [])}
            demand(member.get("micro") in set(original["cast"]["commonMicro"]) | micro,
                   f"Unknown animation: {target_id}")
            slots.add(member["slot"])
            actors.add(actor_id)
        gate = proposed_routes[target_id].get("gate", {})
        demand(gate == {"kind": "draft_unapproved", "ref": "none",
                        "approvedRuntime": False, "proposedRuntime": True} and
               proposed_routes[target_id].get("interactionTarget") == "review_only_not_playable",
               f"Runtime route is forbidden for new scene: {target_id}")
    for source_id, proposed_id in line_map.items():
        raw_line = authored_lines[source_id]
        source_scene = raw_line.get("sceneId")
        target_scene = mapped.get(source_scene, source_scene)
        demand(proposed_id == target_scene + source_id[len(source_scene):] and
               LINE_ID.fullmatch(proposed_id) is not None,
               f"Line remap not deterministic: {source_id}")
        line = proposed_lines[proposed_id]
        expected = copy.deepcopy(raw_line)
        expected["id"] = proposed_id
        expected["sceneId"] = target_scene
        expected["source"] = "vn_studio_promotion_review_only"
        for lang, value in patches.get(source_id, {}).items():
            expected["localized"][lang] = {"text": value}
        demand(line == expected, f"New line differs from authored draft: {source_id}")
        speaker = cast.get(line.get("speakerId"))
        demand(speaker is not None and
               isinstance(line.get("localized", {}).get("ru"), dict) and
               bool(str(line["localized"]["ru"].get("text", "")).strip()),
               f"New line has no registered speaker or RU text: {proposed_id}")
        cue = proposed_cues[proposed_id]
        demand(cue.get("manualReview") is True and
               cue.get("lineId") == proposed_id and
               cue.get("sceneId") == line["sceneId"] and
               cue.get("speakerId") == line["speakerId"],
               f"Cue status/ownership incorrect: {proposed_id}")
        demand(cue.get("poseId") in speaker.get("poses", []) and
               cue.get("emotionId") in speaker.get("emotions", []),
               f"Cue pose/emotion unknown: {proposed_id}")
        micro = {x["id"] for x in speaker.get("signatureMicros", [])}
        demand(cue.get("microOnEnter") is None or
               cue.get("microOnEnter") in micro,
               f"Cue animation unknown: {proposed_id}")
    graph = raw.get("storyGraphPatches")
    demand(isinstance(graph, dict) and
           all(isinstance(v, dict) and not v.get("edges") for v in graph.values()),
           "Playable Story Map branch requires separate reducer/save contract")
    demand(isinstance(package.get("routeProposals"), dict) and
           set(package["routeProposals"]) == set(new_scene_ids),
           "Route proposal history missing or mismatched")
    demand(isinstance(package_sha, str) and re.fullmatch(r"[a-f0-9]{64}", package_sha),
           "Exact input byte SHA is required for audited staging")
    payloads = {name: (json.dumps(files[name], ensure_ascii=False, indent=2) + "\n").encode("utf-8")
                for name in CANDIDATE_NAMES}
    audit = {
        "format": "raven-vn-offline-check-v1", "schemaVersion": 1,
        "sourcePackageSha256": package_sha, "reviewRef": package["reviewRef"],
        "sourceSha256": {kind: hashes[kind] for kind in FILES},
        "candidateSha256": {name: digest(content) for name, content in payloads.items()},
        "sceneCount": len(proposed_scenes), "lineCount": len(proposed_lines),
        "newSceneIds": new_scene_ids, "newLineIds": list(line_map.values()),
        "runtimeApplied": False, "readyForRuntime": False,
        "humanReviewRequired": True, "cannotAutoApply": True,
        "notes": "Offline check of Godot VNS5-06D1; not a second approval/manifest schema.",
    }
    payloads["offline_integrity_manifest.json"] = (json.dumps(audit, ensure_ascii=False, indent=2) + "\n").encode()
    return payloads


def write_once(path: Path, payloads: dict[str, bytes]) -> None:
    demand(not path.exists(), "Output directory already exists; no overwrite")
    demand(path.parent.is_dir(), "Output directory parent must exist")
    path.mkdir(exist_ok=False)
    try:
        for name, content in payloads.items():
            demand(name in (*CANDIDATE_NAMES, "offline_integrity_manifest.json"),
                   "Unexpected output file")
            with (path / name).open("xb") as stream:
                stream.write(content)
        demand(all((path / n).read_bytes() == content for n, content in payloads.items()),
               "Written candidate content mismatch")
    except Exception:
        for child in path.iterdir():
            if child.is_file():
                child.unlink()
        path.rmdir()
        raise


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True, help="Godot VNS5-06D1 review bundle")
    parser.add_argument("--output", type=Path, help="New external output directory")
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args(argv)
    if not args.check_only and args.output is None:
        parser.error("--output required without --check-only")
    try:
        raw = args.package.read_bytes()
        package = json.loads(raw.decode("utf-8"))
        demand(isinstance(package, dict), "Package JSON must be an object")
        files = verify(package, package_sha=digest(raw))
        if not args.check_only:
            write_once(args.output, files)
            print("Staged review-only candidate:", args.output)
        print("PASS: Godot VNS5-06D1 review bundle verified; no production or runtime changes")
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print("BLOCKED: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
