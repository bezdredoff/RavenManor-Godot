#!/usr/bin/env python3
"""Check Raven Manor narrative production registries; release gate is opt-in.

Usage:
  python3 scripts/raven/tools/validate_production_narrative.py
  python3 scripts/raven/tools/validate_production_narrative.py --release

English/Belarusian dialogue is intentionally not yet translated. The regular
contract check accepts TODO fields; --release rejects any incomplete locale.
"""
import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "data/raven/production"


def load(name):
    return json.loads((BASE / name).read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", action="store_true", help="require all translations")
    args = parser.parse_args()
    errors = []
    story = load("season1_dialogue_catalog.json")
    shots = load("vn_staging.json")
    chars = load("character_performance.json")
    routes = load("map_narrative_routes.json")
    props = load("story_props.json")
    popups = load("hotspot_popup_copy.json")
    speakers = {c["id"]: c for c in chars["characters"]}
    speakers["RM-CHAR-UNKNOWN-VOICE"] = None
    scene_ids = [s["sceneId"] for s in story["scenes"]]
    dialogue_ids = [ln["id"] for ln in story["entries"]]
    line_scenes = Counter(ln["sceneId"] for ln in story["entries"])
    if len(scene_ids) != len(set(scene_ids)):
        errors.append("duplicate scene ID")
    if len(dialogue_ids) != len(set(dialogue_ids)):
        errors.append("duplicate line ID")
    if set(scene_ids) != {s["sceneId"] for s in shots["sceneShots"]}:
        errors.append("scene/shot mismatch")
    if set(scene_ids) != {s["sceneId"] for s in routes["sceneTriggers"]}:
        errors.append("scene/route mismatch")
    if len(shots["sceneShots"]) != len(scene_ids) or len(routes["sceneTriggers"]) != len(scene_ids):
        errors.append("duplicate shot or route")
    if len(shots["masters"]) > 11:
        errors.append("background budget exceeded")
    ids = set(scene_ids)
    missing = Counter()
    for ln in story["entries"]:
        if ln["sceneId"] not in ids or not re.match(r"^RM-BEAT-\d\d-(?:\d\d|POST)-L\d{3}$", ln["id"]):
            errors.append("invalid line ID: " + ln["id"])
        if ln["speakerId"] not in speakers:
            errors.append("unknown speaker: " + ln["speakerId"])
        for lang in ("ru", "be", "en"):
            cell = ln["localized"].get(lang)
            if not isinstance(cell, dict) or not str(cell.get("text", "")).strip():
                missing[lang] += 1
        if not isinstance(ln["localized"].get("ru"), dict):
            errors.append("missing RU source: " + ln["id"])
    for sid in ids:
        if line_scenes[sid] <= 0:
            errors.append("empty beat: " + sid)
    masters = {b["id"] for b in shots["masters"]}
    common = set(chars["commonMicro"])
    for shot in shots["sceneShots"]:
        if shot["backgroundId"] not in masters:
            errors.append("undefined BG: " + shot["backgroundId"])
        if len(shot["cast"]) != shot["visibleCount"] or not 1 <= shot["visibleCount"] <= 3:
            errors.append("bad cast size: " + shot["sceneId"])
        slots = set()
        for actor in shot["cast"]:
            cid = actor["characterId"]
            if cid not in speakers or speakers[cid] is None:
                errors.append("invalid visible character in " + shot["sceneId"])
                continue
            if actor["slot"] in slots:
                errors.append("duplicate slot in " + shot["sceneId"])
            slots.add(actor["slot"])
            spec = speakers[cid]
            if actor["pose"] not in spec["poses"] or actor["emotion"] not in spec["emotions"]:
                errors.append("undefined pose/emotion in " + shot["sceneId"])
            micro = {m["id"] for m in spec["signatureMicros"]}
            if actor["micro"] not in micro | common:
                errors.append("undefined micro in " + shot["sceneId"])
    existing_assets = (ROOT / "docs/assets/ROOM_OBJECT_REGISTER.csv").read_text(encoding="utf-8")
    prop_ids = {p["id"] for p in props["objects"]}
    for obj in props["objects"]:
        aid = obj.get("assetRefId")
        if aid and ('"' + aid + '"') not in existing_assets:
            errors.append("unknown asset reference " + aid)
        if not set(obj["sceneIds"]).issubset(ids):
            errors.append("prop references missing scene: " + obj["id"])
    for pop in popups["items"]:
        if pop.get("objectId") and pop["objectId"] not in prop_ids:
            errors.append("missing popup object: " + pop["objectId"])
        for lang in ("ru", "be", "en"):
            if not str((pop.get("localized", {}).get(lang) or {}).get("text", "")).strip():
                errors.append("popup incomplete: " + pop["id"] + "/" + lang)
    if args.release:
        for lang, count in missing.items():
            if count:
                errors.append(f"missing dialogue translations for {lang}: {count}")
        for s in story["scenes"]:
            for lang in ("ru", "be", "en"):
                if not str(s["title"].get(lang) or "").strip():
                    errors.append("missing scene title: " + s["sceneId"] + "/" + lang)
    else:
        if missing["ru"]:
            errors.append("missing original Russian dialogue: " + str(missing["ru"]))
    print(f"Production contract: {len(scene_ids)} scenes, {len(dialogue_ids)} lines, "
          f"{len(shots['masters'])} backgrounds, {len(props['objects'])} props, "
          f"{len(popups['items'])} popups")
    print("Missing dialogue translations:", dict(missing))
    for error in errors[:30]:
        print("ERROR:", error, file=sys.stderr)
    if len(errors) > 30:
        print(f"... and {len(errors) - 30} more", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
