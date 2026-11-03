#!/usr/bin/env python3
"""Embed source-derived P0 links in the *built* Pages HTML as a no-JS fallback.

The browser app replaces this exact list after loading status.json. Generating
from status.json prevents a hardcoded stale public roadmap and ensures tasks
are visible even if a device blocks ES modules or runtime fetching.
"""
from __future__ import annotations
import argparse
import html
import json
from pathlib import Path

TERMINAL = {"merged", "integrated", "device_verified", "accepted", "superseded", "not_planned"}
ANCHOR = '<div class="quick-tasks" id="quick-tasks"></div>'
SOURCE_URL = "https://github.com/bezdredoff/RavenManor-Godot/blob/main/data/raven/production/gap_work_packages.json"


def render(index: str, data: dict) -> str:
    if index.count(ANCHOR) != 1:
        raise ValueError("Expected exactly one dashboard P0 placeholder")
    tasks = sorted((t for t in data.get("tasks", [])
        if t.get("priority") == "P0" and t.get("status") not in TERMINAL),
        key=lambda t: str(t.get("id", "")))
    if not tasks:
        raise ValueError("No active P0 tasks: dashboard snapshot would be empty")
    links = "".join(
        '<a class="quick-task" href="' + SOURCE_URL + '">'
        + '<strong>' + html.escape(str(t.get("id", ""))) + '</strong>'
        + '<span>' + html.escape(str(t.get("title", ""))) + '</span>'
        + '<small>' + html.escape(str(t.get("status", ""))) + ' · static fallback</small></a>'
        for t in tasks[:6]
    )
    result = index.replace(ANCHOR,
        '<div class="quick-tasks" id="quick-tasks" data-static-snapshot="true">' + links + '</div>')
    result = result.replace(
        "Загружаю актуальные задачи из реестра…",
        f"Открытых P0-задач: {len(tasks)} · показаны первые {min(6, len(tasks))}. При загрузке JavaScript список становится интерактивным."
    )
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()
    source = args.root / "status.json"
    page = args.root / "index.html"
    data = json.loads(source.read_text(encoding="utf-8"))
    output = render(page.read_text(encoding="utf-8"), data)
    page.write_text(output, encoding="utf-8")
    print("Dashboard HTML fallback PASS: source-derived P0 tasks embedded")


if __name__ == "__main__":
    main()
