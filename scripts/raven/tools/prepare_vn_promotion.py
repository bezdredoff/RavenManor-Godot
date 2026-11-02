#!/usr/bin/env python3
"""VNS5-06D: validate a human-reviewed VN candidate and stage a multi-file PR
package without touching canonical production or enabling game runtime.

Examples:
  python3 scripts/raven/tools/prepare_vn_promotion.py --review review.json --approval approval.json --check-only
  python3 scripts/raven/tools/prepare_vn_promotion.py --review review.json --approval approval.json --output /tmp/raven-vn-promotion

Both inputs are untrusted. ApprovalRef is traceability, NOT authentication.
The resulting folder is not a deployable/runtime-approved payload.
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
DATA = ROOT / "data/raven/production"
FILES = {
    "catalog": "season1_dialogue_catalog.json",
    "staging": "vn_staging.json",
    "routes": "map_narrative_routes.json",
    "cast": "character_performance.json",
    "cues": "line_performance_cues.json",
}
SHA_KEYS = {"catalog": "sourceSha256", "staging": "stageSourceSha256",
            "routes": "routeSourceSha256", "cast": "castSourceSha256"}
FORMAT = "raven-vn-promotion-review-v1"
APPROVAL_FORMAT = "raven-vn-release-preflight-v1"
SCENE_ID = re.compile(r"RM-BEAT-[0-9]{2}-[0-9]{2}$")
LINE_ID = re.compile(r"RM-BEAT-[0-9]{2}-(?:[0-9]{2}|POST)-L[0-9]{3}$")
OUTPUT_FILES = {"catalog": FILES["catalog"], "staging": FILES["staging"],
                "routes": FILES["routes"], "cues": FILES["cues"]}


class PromotionError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PromotionError(message)


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def json_file(path: Path) -> dict:
    obj = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(obj, dict), f"{path.name}: expected JSON object")
    return obj


def unique(records: list, field: str, name: str) -> dict:
    require(isinstance(records, list), f"{name} must be an array")
    index = {}
    for record in records:
        require(isinstance(record, dict), f"{name} entries must be objects")
        key = record.get(field)
        require(isinstance(key, str) and key and key not in index,
                f"{name} invalid/duplicate {field}: {key}")
        index[key] = record
    return index


def _nonempty(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def build(review: dict, approval: dict, base: Path = DATA,
          review_sha: str | None = None) -> dict:
    """Return deterministic proposed file bytes + manifest; no IO writes."""
    require(review.get("format") == FORMAT and review.get("schemaVersion") == 1,
            "Only VNS5-06C promotion review v1 is accepted")
    require(review.get("runtimeApplied") is False and review.get("readyForRuntime") is False,
            "Review candidate must not claim runtime approval")
    require(review.get("requiresHumanReview") is True and review.get("requiresFollowUpPromotion") is True,
            "Cannot promote an unmarked or already-applied review candidate")
    require(approval.get("format") == APPROVAL_FORMAT and approval.get("schemaVersion") == 1,
            "Approval manifest has an unsupported format")
    require(_nonempty(approval.get("approvalRef")) and
            approval.get("reviewSha256") == review_sha and review_sha is not None,
            "Missing review reference or wrong exact input-file SHA")
    sources = {key: json_file(base / filename) for key, filename in FILES.items()}
    for key, attr in SHA_KEYS.items():
        require(review.get(attr) == digest((base / FILES[key]).read_bytes()),
                f"Canonical {key} file SHA mismatch: re-export the candidate")
    require(approval.get("cueSourceSha256") == digest((base / FILES["cues"]).read_bytes()),
            "Line cue file changed since explicit approval review")
    source_scenes = unique(sources["catalog"]["scenes"], "sceneId", "canonical scenes")
    source_lines = unique(sources["catalog"]["entries"], "id", "canonical lines")
    source_shots = unique(sources["staging"]["sceneShots"], "sceneId", "canonical shots")
    source_routes = unique(sources["routes"]["sceneTriggers"], "sceneId", "canonical routes")
    source_cues = unique(sources["cues"]["cues"], "lineId", "canonical cues")
    require(set(source_scenes) == set(source_shots) == set(source_routes),
            "Base scene/shot/route registries are not aligned")
    require(set(source_lines) == set(source_cues),
            "Base dialogue/line-cue registries are not aligned")
    require(isinstance(review.get("reviewCatalog"), dict) and
            review["reviewCatalog"].get("status") == "DRAFT_PROMOTION_REVIEW_NOT_RUNTIME",
            "Missing review-only dialogue catalog")
    catalog = copy.deepcopy(review["reviewCatalog"])
    new_scenes = unique(catalog.get("scenes"), "sceneId", "review scenes")
    new_lines = unique(catalog.get("entries"), "id", "review lines")
    raw = review.get("retainedDraft", {})
    require(isinstance(raw, dict), "Raw authored draft is required for reversible review")
    authored = unique(raw.get("authoredScenes"), "sceneId", "authored scenes")
    authored_lines = unique(raw.get("authoredLines"), "id", "authored lines")
    mapping = review.get("idMap")
    line_mapping = review.get("lineIdMap")
    require(isinstance(mapping, dict) and isinstance(line_mapping, dict) and
            raw.get("promotionSceneIdMap") == mapping, "ID mapping and retained source disagree")
    require(set(mapping) == set(authored), "Every draft scene must have one mapped target")
    require(all(isinstance(x, str) and x.startswith("RM-DRAFT-BEAT-") for x in authored),
            "Only reserved draft scene IDs may be migrated")
    mapped = list(mapping.values())
    require(all(isinstance(x, str) and SCENE_ID.fullmatch(x) for x in mapped) and
            len(set(mapped)) == len(mapped) and not set(mapped) & set(source_scenes),
            "Promotion scene IDs are invalid, duplicated or collide with canon")
    require(set(new_scenes) == set(source_scenes) | set(mapped),
            "Review scene set differs from canonical + mapped authored scenes")
    require(len(catalog["scenes"]) == len(source_scenes) + len(mapped),
            "Promotion review has unexpected scene count")
    for scene_id, original in source_scenes.items():
        require(new_scenes[scene_id] == original,
                f"Canonical scene metadata modified without migration: {scene_id}")
    for raw_id, target in mapping.items():
        candidate = new_scenes[target]
        require(candidate.get("status") == "proposed_future_runtime" and
                candidate.get("source") == "vn_studio_promotion_review_only" and
                candidate.get("title") == authored[raw_id].get("title"),
                f"Mapped scene was altered outside the review contract: {target}")
    for raw_id, line in authored_lines.items():
        original_scene = line.get("sceneId", "")
        target_scene = mapping.get(original_scene, original_scene)
        expected_id = target_scene + raw_id[len(original_scene):]
        require(LINE_ID.fullmatch(expected_id) is not None and
                line_mapping.get(raw_id) == expected_id,
                f"New line remap is inconsistent: {raw_id}")
    require(set(line_mapping) == set(authored_lines),
            "Line mapping must cover precisely all authored lines")
    require(set(new_lines) == set(source_lines) | set(line_mapping.values()) and
            len(catalog["entries"]) == len(source_lines) + len(authored_lines),
            "Review line set differs from canonical + mapped authored lines")
    allowed_text = approval.get("approvedTextLineIds", [])
    require(isinstance(allowed_text, list) and len(allowed_text) == len(set(allowed_text)),
            "Approved text IDs must be a unique list")
    require(set(allowed_text).issubset(set(source_lines)),
            "Approved text IDs include an unknown canonical line")
    for line_id, original in source_lines.items():
        candidate = new_lines[line_id]
        for field in original:
            if field != "localized":
                require(candidate.get(field) == original[field],
                        f"Existing line metadata was changed: {line_id}/{field}")
        if candidate.get("localized") != original.get("localized"):
            require(line_id in allowed_text, f"Unapproved modification to canonical text: {line_id}")
    speakers = unique(sources["cast"]["characters"], "id", "character registry")
    for line_id, line in new_lines.items():
        require(LINE_ID.fullmatch(line_id) is not None and line.get("sceneId") in new_scenes,
                f"Invalid line ID or missing scene: {line_id}")
        require(line.get("speakerId") in speakers,
                f"Unknown speaker: {line_id}")
        localized = line.get("localized", {})
        ru = localized.get("ru") if isinstance(localized, dict) else None
        require(isinstance(ru, dict) and _nonempty(ru.get("text")),
                f"Missing original RU text: {line_id}")
    for raw_id, original in authored_lines.items():
        line_id = line_mapping[raw_id]
        mapped_entry = new_lines[line_id]
        require(mapped_entry.get("sceneId") == mapping.get(original["sceneId"], original["sceneId"]) and
                mapped_entry.get("speakerId") == original.get("speakerId") and
                mapped_entry.get("source") == "vn_studio_promotion_review_only",
                f"New line provenance or owner altered: {raw_id}")
    # All graph edges are review-only: there is no approved runtime choice sink.
    graph = review.get("reviewGraphPatches", {})
    require(isinstance(graph, dict), "Review graph must be an object")
    require(all(isinstance(g, dict) and not g.get("edges") for g in graph.values()),
            "Playable Story Map branches are not implemented; export blocked")
    retain = raw.get("storyGraphPatches", {})
    require(isinstance(retain, dict) and all(isinstance(g, dict) and not g.get("edges")
            for g in retain.values()), "Raw Story Map has unresolved runtime edges")
    save = approval.get("saveReview", {})
    require(isinstance(save, dict) and save.get("existingSaves") == "preserve" and
            save.get("newScenesDefault") == "locked" and _nonempty(save.get("reviewRef")),
            "Explicit reviewed save compatibility policy required")
    # Even an approved manifest may not turn on runtime here.
    staged_shots = approval.get("sceneShots", [])
    staged_routes = approval.get("sceneTriggers", [])
    staged_cues = approval.get("lineCues", [])
    new_shot_map = unique(staged_shots, "sceneId", "approved scene shots")
    new_route_map = unique(staged_routes, "sceneId", "approved scene triggers")
    new_cue_map = unique(staged_cues, "lineId", "approved line cues")
    require(set(new_shot_map) == set(mapped) == set(new_route_map),
            "Every new scene requires exactly one reviewed shot and route")
    require(set(new_cue_map) == set(line_mapping.values()),
            "Every new line, even in existing scenes, requires one reviewed cue")
    require(_nonempty(approval.get("artApprovalRef")) and
            _nonempty(approval.get("storyApprovalRef")) and
            _nonempty(approval.get("cueApprovalRef")),
            "Missing independent art/story/cue approval references")
    masters = unique(sources["staging"]["masters"], "id", "background masters")
    for scene_id, shot in new_shot_map.items():
        require(shot.get("backgroundId") in masters, f"Unknown background: {scene_id}")
        master = masters[shot["backgroundId"]]
        require(shot.get("lighting") in master.get("lightingVariants", []) and
                shot.get("roomState") in master.get("stateLayers", []),
                f"Invalid approved background state: {scene_id}")
        cast = shot.get("cast", [])
        require(isinstance(cast, list) and 1 <= len(cast) <= 3 and
                shot.get("visibleCount") == len(cast), f"Invalid staged cast count: {scene_id}")
        slots = set()
        for actor in cast:
            require(isinstance(actor, dict) and actor.get("characterId") in speakers,
                    f"Unregistered staged character: {scene_id}")
            spec = speakers[actor["characterId"]]
            require(actor.get("pose") in spec.get("poses", []) and
                    actor.get("emotion") in spec.get("emotions", []),
                    f"Unapproved actor pose/emotion: {scene_id}")
            require(actor.get("slot") in ("left", "center", "right") and
                    actor["slot"] not in slots, f"Invalid duplicate character slot: {scene_id}")
            slots.add(actor["slot"])
    used_ordinals = {route["ordinal"] for route in source_routes.values()}
    for scene_id, route in new_route_map.items():
        gate = route.get("gate", {})
        require(isinstance(gate, dict) and gate.get("kind") == "scene_complete" and
                gate.get("ref") in source_scenes and gate.get("approvedRuntime") is False and
                gate.get("proposedRuntime") is True,
                f"Only non-runtime scene_complete gates referencing existing scenes are supported: {scene_id}")
        require(isinstance(route.get("ordinal"), int) and route["ordinal"] not in used_ordinals,
                f"Scene trigger ordinal conflict: {scene_id}")
        used_ordinals.add(route["ordinal"])
        require(_nonempty(route.get("interactionTarget")) and
                route.get("postSceneAction") == "record_story_beat_only_after_player_finishes_VN" and
                route.get("whenReached") == "play_once_then_unlock_next_state",
                f"Unsupported scene trigger semantics: {scene_id}")
    common = set(sources["cast"].get("commonMicro", []))
    for line_id, cue in new_cue_map.items():
        line = new_lines[line_id]
        require(cue.get("sceneId") == line["sceneId"] and
                cue.get("speakerId") == line["speakerId"], f"Invalid cue owner: {line_id}")
        spec = speakers[cue["speakerId"]]
        require(cue.get("poseId") in spec.get("poses", []) and
                cue.get("emotionId") in spec.get("emotions", []),
                f"Invalid cue pose/emotion: {line_id}")
        micros = {x["id"] for x in spec.get("signatureMicros", [])}
        require(cue.get("microOnEnter") in (None, *common, *micros),
                f"Unknown micro animation cue: {line_id}")
    proposed = {
        "catalog": copy.deepcopy(catalog),
        "staging": copy.deepcopy(sources["staging"]),
        "routes": copy.deepcopy(sources["routes"]),
        "cues": copy.deepcopy(sources["cues"]),
    }
    for key in proposed:
        proposed[key]["status"] = "CANDIDATE_UNPUBLISHED_NOT_RUNTIME"
    proposed["staging"]["sceneShots"].extend(copy.deepcopy(staged_shots))
    proposed["routes"]["sceneTriggers"].extend(copy.deepcopy(staged_routes))
    proposed["cues"]["cues"].extend(copy.deepcopy(staged_cues))
    # Global cardinality / referential integrity of the complete staged registries.
    require(set(unique(proposed["staging"]["sceneShots"], "sceneId", "result shots")) ==
            set(unique(proposed["catalog"]["scenes"], "sceneId", "result scenes")) ==
            set(unique(proposed["routes"]["sceneTriggers"], "sceneId", "result routes")),
            "Resulting scene/shot/route sets differ")
    require(set(unique(proposed["cues"]["cues"], "lineId", "result cues")) ==
            set(unique(proposed["catalog"]["entries"], "id", "result lines")),
            "Resulting line/cue sets differ")
    payloads = {OUTPUT_FILES[key]: (json.dumps(proposed[key], ensure_ascii=False, indent=2) + "\n").encode("utf-8")
                for key in OUTPUT_FILES}
    evidence = {
        "format": "raven-vn-production-staging-package-v1", "schemaVersion": 1,
        "reviewSha256": review_sha, "approvalRef": approval["approvalRef"],
        "artApprovalRef": approval["artApprovalRef"],
        "storyApprovalRef": approval["storyApprovalRef"],
        "cueApprovalRef": approval["cueApprovalRef"],
        "saveReview": save,
        "sourceSha256": {key: digest((base / file).read_bytes()) for key, file in FILES.items()},
        "candidateSha256": {name: digest(contents) for name, contents in payloads.items()},
        "sceneCount": len(new_scenes), "lineCount": len(new_lines),
        "newSceneIds": mapped, "newLineIds": list(line_mapping.values()),
        "hasPlayableStoryMapEdges": False, "runtimeApplied": False,
        "readyForRuntime": False, "humanReviewRequired": True,
        "cannotAutoApply": True,
        "notes": "PR staging only. Follow up with explicit runtime/save/branch QA and review.",
    }
    payloads["promotion_manifest.json"] = (json.dumps(evidence, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    return payloads


def write_once(output: Path, payloads: dict[str, bytes]) -> None:
    require(not output.exists(), "Target already exists; no overwrite/merge permitted")
    require(output.parent.is_dir(), "Output parent must exist")
    # Exclusive directory creation guarantees no overwrite. Remove partial work on failure.
    output.mkdir(exist_ok=False)
    try:
        for filename, data in payloads.items():
            require(filename in {*OUTPUT_FILES.values(), "promotion_manifest.json"}, "Bad output name")
            path = output / filename
            with path.open("xb") as stream:
                stream.write(data)
        require(all((output / filename).read_bytes() == data for filename, data in payloads.items()),
                "Staged payload verification failed")
    except Exception:
        for child in output.iterdir():
            if child.is_file():
                child.unlink()
        output.rmdir()
        raise


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review", type=Path, required=True)
    parser.add_argument("--approval", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args(argv)
    if not args.check_only and args.output is None:
        parser.error("--output is required unless --check-only")
    try:
        raw = args.review.read_bytes()
        review = json.loads(raw.decode("utf-8"))
        approval = json_file(args.approval)
        require(isinstance(review, dict), "Review must be an object")
        payloads = build(review, approval, review_sha=digest(raw))
        if not args.check_only:
            write_once(args.output, payloads)
            print("Staged for human PR review:", args.output)
        print("PASS: checked scene/shot/route/line/cue contracts; no runtime changes")
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print("BLOCKED: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
