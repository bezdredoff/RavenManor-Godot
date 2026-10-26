#!/usr/bin/env python3
"""Export Raven Manor RU/BE/EN translation worklist without mutating canonical JSON."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "data/raven/production"


def read(name):
    return json.loads((BASE / name).read_text(encoding="utf-8"))


def translate_cell(localized, locale):
    value = localized.get(locale)
    return value.get("text", "") if isinstance(value, dict) else ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, default=ROOT / "data/raven/production/season1_translation_worklist.csv")
    args = ap.parse_args()
    dialogues = read("season1_dialogue_catalog.json")
    popups = read("hotspot_popup_copy.json")
    rows = []
    for scene in dialogues["scenes"]:
        title = scene.get("title", {})
        rows.append(("scene_title", scene["sceneId"] + "-TITLE", scene["sceneId"], "", title.get("ru") or "", title.get("be") or "", title.get("en") or "", scene["source"]))
    for line in dialogues["entries"]:
        localized = line["localized"]
        rows.append(("dialogue", line["id"], line["sceneId"], line["speakerId"], translate_cell(localized, "ru"), translate_cell(localized, "be"), translate_cell(localized, "en"), line["source"]))
    for popup in popups["items"]:
        localized = popup["localized"]
        rows.append(("map_popup", popup["id"], "", "", translate_cell(localized, "ru"), translate_cell(localized, "be"), translate_cell(localized, "en"), str(popup.get("roomId", ""))))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # BOM makes Cyrillic source easy to open in spreadsheet applications.
    with args.output.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(["kind", "stable_id", "scene_id", "speaker_id", "ru", "be", "en", "context"])
        writer.writerows(rows)
    print(f"Raven Manor translation worklist: {len(rows)} rows -> {args.output}")


if __name__ == "__main__":
    main()
