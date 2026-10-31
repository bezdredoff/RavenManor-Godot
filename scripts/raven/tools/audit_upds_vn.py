#!/usr/bin/env python3
"""Read-only pinned UPDS-godot VN corpus audit. No private story text is exported.

Usage: python3 scripts/raven/tools/audit_upds_vn.py --upds-root /checkout/UPDS-godot
Do not copy donor files or private licensed assets into the public Raven repo.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_MANIFEST = ROOT / "data/raven/production/upds_vn_corpus_manifest.json"
LOCALES = frozenset(("ru", "en", "be"))


def blob_sha(raw: bytes) -> str:
    header = f"blob {len(raw)}\0".encode("ascii")
    return hashlib.sha1(header + raw).hexdigest()


def safe_file(root: Path, relative: str) -> Path:
    if not relative.startswith("data/") and not relative.startswith("scripts/"):
        raise ValueError(f"disallowed donor path: {relative!r}")
    p = (root / relative).resolve()
    if not p.is_relative_to(root.resolve()) or not p.is_file():
        raise ValueError(f"missing/unsafe donor file: {relative}")
    return p


def load_json(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"expected JSON object: {path.name}")
    return data


def read_scenes(scene: dict) -> list[tuple[str, list]]:
    groups = []
    if isinstance(scene.get("lines"), list):
        groups.append(("base", scene["lines"]))
    variants = scene.get("variants", {})
    if not isinstance(variants, dict):
        raise ValueError("invalid variants container")
    for key, values in sorted(variants.items()):
        if not isinstance(values, list):
            raise ValueError(f"invalid variant {key}")
        groups.append((f"variant:{key}", values))
    if not groups:
        raise ValueError("scene has no lines or variants")
    return groups


def scan(donor: Path, manifest: dict) -> tuple[dict, list[str]]:
    errors: list[str] = []
    files = manifest["scenes"]
    extra = manifest["references"]
    expected_paths = {entry["path"] for entry in files}
    actual_paths = {
        "data/" + p.name for p in (donor / "data").glob("*.json")
        if p.name.endswith("_scene.json") or p.name in {"prologue.json", "locker_scene.json"}
    }
    for p in sorted(expected_paths - actual_paths):
        errors.append(f"missing scene: {p}")
    for p in sorted(actual_paths - expected_paths):
        errors.append(f"new unpinned scene: {p}")

    sources = []
    for entry in files + extra:
        path = entry["path"]
        try:
            f = safe_file(donor, path)
        except ValueError as exc:
            errors.append(str(exc))
            continue
        raw = f.read_bytes()
        sha = blob_sha(raw)
        if sha != entry["blobSha"]:
            errors.append(f"SHA drift {path}: expected {entry['blobSha']}, got {sha}")
        if "bytes" in entry and len(raw) != entry["bytes"]:
            errors.append(f"size drift {path}: {len(raw)} != {entry['bytes']}")
        sources.append(path)

    try:
        contract = load_json(safe_file(donor, "data/save_contract.json"))
        layout = load_json(safe_file(donor, "data/actor_layouts.json"))
        catalog = load_json(safe_file(donor, "data/asset_catalog.json"))
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        errors.append(f"reference read: {exc}")
        return {"sourceFiles": len(sources)}, errors
    indexed = contract.get("storySceneIds", [])
    level_ids = set(contract.get("levelIds", []))
    gate_ids = set(contract.get("storyChoiceGateIds", []))
    backgrounds = catalog.get("assets", {}).get("backgrounds", {})
    frames = layout.get("frames", {})
    placements = layout.get("placements", {})
    if len(indexed) != len(files) or len(set(indexed)) != len(indexed):
        errors.append("save contract scene list is missing/duplicated")
    stats = {"scenes": 0, "lineOccurrences": 0, "hiddenOccurrences": 0,
             "localeOccurrences": {lang: 0 for lang in sorted(LOCALES)},
             "variantScenes": 0, "choiceGateScenes": 0, "match3GateScenes": 0,
             "endingScenes": 0, "actorPlacements": 0, "distinctCharacters": [],
             "distinctBackgrounds": [], "branchRoutes": 0, "warnings": []}
    chars, backgrounds_used = set(), set()
    scene_ids = set()
    for entry in files:
        path = entry["path"]
        try:
            scene = load_json(safe_file(donor, path))
            groups = read_scenes(scene)
        except (ValueError, OSError, json.JSONDecodeError) as exc:
            errors.append(f"{path}: {exc}")
            continue
        sid = scene.get("sceneId")
        if sid in scene_ids or sid not in indexed:
            errors.append(f"{path}: unknown/duplicate sceneId {sid}")
        scene_ids.add(sid)
        scene_index = indexed.index(sid) if sid in indexed else -1
        if scene.get("sceneIndex", scene_index) != scene_index:
            errors.append(f"{path}: sceneIndex doesn't match save_contract: {scene_index}")
        stats["scenes"] += 1
        if "variants" in scene:
            stats["variantScenes"] += 1
            if set(scene.get("choices", {})) != set(scene["variants"]):
                errors.append(f"{path}: choices and variants differ")
        if "choiceGate" in scene:
            stats["choiceGateScenes"] += 1
            if scene["choiceGate"].get("id") not in gate_ids:
                errors.append(f"{path}: gate not in save contract")
        if scene.get("nextLevelId"):
            stats["match3GateScenes"] += 1
            if scene["nextLevelId"] not in level_ids:
                errors.append(f"{path}: invalid match3 level")
        if scene.get("ending"):
            stats["endingScenes"] += 1
        for k in ("nextSceneIndex", "onWinSceneIndex"):
            if k in scene and scene[k] not in (-1, None) and (
                not isinstance(scene[k], int) or scene[k] not in range(len(indexed))
            ):
                errors.append(f"{path}: bad target {k}={scene[k]}")
        for branch, dest in scene.get("nextSceneIndices", {}).items():
            stats["branchRoutes"] += 1
            if branch not in "ABC" or not isinstance(dest, int) or dest not in range(len(indexed)):
                errors.append(f"{path}: bad routed branch {branch}={dest}")
        if scene.get("background"):
            backgrounds_used.add(scene["background"])
        local_ids = set()
        observed = 0
        hidden = 0
        for group_name, lines in groups:
            for line in lines:
                observed += 1
                line_id = line.get("id") if isinstance(line, dict) else None
                if not isinstance(line_id, str) or not line_id.startswith("VN"):
                    errors.append(f"{path} {group_name}: missing/bad line id")
                # Same line ID is allowed across mutually exclusive A/B/C variants.
                if line_id in local_ids and group_name == "base":
                    errors.append(f"{path}: repeated base line id {line_id}")
                local_ids.add(line_id)
                if line.get("hidden") is True:
                    hidden += 1
                localized = line.get("localized", {})
                if set(localized) != LOCALES:
                    errors.append(f"{path}:{line_id}: missing/extra locale")
                for loc in LOCALES:
                    cell = localized.get(loc, {})
                    if not isinstance(cell, dict) or any(
                        not isinstance(cell.get(field), str)
                        for field in ("speaker", "emotion", "text")
                    ):
                        errors.append(f"{path}:{line_id}: malformed {loc} locale")
                    else:
                        stats["localeOccurrences"][loc] += 1
                background = line.get("background")
                if background:
                    backgrounds_used.add(background)
                actors = line.get("actors", [])
                if not isinstance(actors, list):
                    errors.append(f"{path}:{line_id}: invalid actors")
                    continue
                stats["actorPlacements"] += len(actors)
                for actor in actors:
                    if not isinstance(actor, dict):
                        errors.append(f"{path}:{line_id}: invalid actor")
                        continue
                    character = actor.get("character")
                    chars.add(character)
                    if character not in frames:
                        errors.append(f"{path}:{line_id}: missing frame for actor {character}")
                    if actor.get("layout") not in placements:
                        errors.append(f"{path}:{line_id}: unknown layout {actor.get('layout')}")
        stats["lineOccurrences"] += observed
        stats["hiddenOccurrences"] += hidden
        if observed != entry["lineOccurrences"] or hidden != entry["hiddenOccurrences"]:
            errors.append(f"{path}: line/hidden stats drift: {observed}/{hidden}")
        if scene.get("choiceGate"):
            checkpoint = scene["choiceGate"].get("checkpointLineId")
            if checkpoint not in local_ids:
                errors.append(f"{path}: choice checkpoint {checkpoint} not found")
    for bg in backgrounds_used:
        if bg not in backgrounds:
            stats["warnings"].append(f"background not in catalog: {bg}")
    stats["distinctCharacters"] = sorted(chars)
    stats["distinctBackgrounds"] = sorted(backgrounds_used)
    for k, expected in manifest["expected"].items():
        if stats.get(k) != expected:
            errors.append(f"total drift {k}: got {stats.get(k)}, expected {expected}")
    return {"sourceFiles": len(sources), **stats}, errors


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--upds-root", type=Path, required=True, help="PRIVATE UPDS-godot checkout; never modified")
    p.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    p.add_argument("--output", type=Path, default=None, help="Audit summary outside donor")
    args = p.parse_args(argv)
    manifest = load_json(args.manifest)
    report, errors = scan(args.upds_root, manifest)
    result = {"source": manifest.get("donor", {}), "stats": report, "errors": errors,
              "valid": len(errors) == 0}
    output_text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        output = args.output.resolve()
        if output.is_relative_to(args.upds_root.resolve()):
            p.error("output must not be written to private donor checkout")
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(output_text, encoding="utf-8")
    else:
        print(output_text, end="")
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
