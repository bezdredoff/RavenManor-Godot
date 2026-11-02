#!/usr/bin/env python3
"""VNS5-06D2A: fail-closed release readiness, save-ID and rollback rehearsal.

Consumes one native Godot D1 bundle AND its verified D1-CLI extracted directory.
Never activates runtime, changes save data, or overwrites tracked production files.

  python3 scripts/raven/tools/plan_vn_release.py --package /tmp/review.json --staging /tmp/extracted --check-only
  python3 scripts/raven/tools/plan_vn_release.py --package /tmp/review.json --staging /tmp/extracted --output /tmp/new-audit

The --require-ready option returns nonzero whenever unresolved release gates
remain, including the intentional lack of runtime integration at this phase.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

from scripts.raven.tools import prepare_vn_promotion as d1

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "data/raven/production"
FOUNDATION = ROOT / "data/raven/foundation_catalog.json"
SAVE_CONTRACT = ROOT / "data/save_contract.json"
AUDIT_FORMAT = "raven-vn-release-rehearsal-v1"
ROLLBACK_SOURCES = {
    **{name: BASE / name for name in d1.FILES.values()},
    "foundation_catalog.json": FOUNDATION,
    "save_contract.json": SAVE_CONTRACT,
}


def require(ok: bool, reason: str) -> None:
    if not ok:
        raise d1.BundleError(reason)


def _safe_read(path: Path) -> bytes:
    require(path.is_file() and not path.is_symlink(),
            "Expected an ordinary file, no symlinks: " + str(path))
    return path.read_bytes()


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _load_bytes(raw: bytes, name: str) -> dict:
    value = json.loads(raw.decode("utf-8"))
    require(isinstance(value, dict), name + " must be a JSON object")
    return value


def _one_line(items: list[str]) -> list[str]:
    return sorted(set(items))


def _dependency_report(proposals: dict, old_scenes: set[str], additions: set[str],
                       levels: set[str]) -> tuple[list[str], list[str]]:
    blockers: list[str] = []
    paths: list[str] = []
    graph: dict[str, str] = {}
    require(set(proposals) == additions, "Missing or unexpected route proposal")
    for scene_id, data in proposals.items():
        require(isinstance(data, dict), "Route proposal object required")
        kind, ref = data.get("kind"), data.get("ref")
        if kind == "scene_complete":
            if ref not in old_scenes | additions or ref == scene_id:
                blockers.append(scene_id + ": scene_complete must reference a distinct registered scene")
            elif ref in additions:
                graph[scene_id] = ref
            paths.append(f"{scene_id}: scene_complete({ref})")
        elif kind == "first_clear":
            if ref not in levels:
                blockers.append(scene_id + ": unknown Match-3 first_clear level " + str(ref))
            paths.append(f"{scene_id}: first_clear({ref})")
        else:
            blockers.append(scene_id + ": runtime route kind not supported " + str(kind))
    for root in graph:
        seen: set[str] = set()
        at = root
        while at in graph:
            if at in seen:
                blockers.append(root + ": cycle of proposed scene dependencies")
                break
            seen.add(at)
            at = graph[at]
    return _one_line(blockers), sorted(paths)


def audit(package: dict, raw: bytes, staging_dir: Path,
          base: Path = BASE, foundation: Path = FOUNDATION,
          save_path: Path = SAVE_CONTRACT) -> dict:
    """Verify two upstream artifacts, then report release blockers + rollback SHA.

    This function is pure w.r.t. the repo and user files (read only).
    """
    require(staging_dir.is_dir() and not staging_dir.is_symlink(),
            "Staging directory must be a real directory")
    incoming_sha = _sha(raw)
    verified = d1.verify(package, base=base, package_sha=incoming_sha)
    manifest_bytes = _safe_read(staging_dir / "offline_integrity_manifest.json")
    manifest = _load_bytes(manifest_bytes, "offline_integrity_manifest")
    require(manifest.get("format") == "raven-vn-offline-check-v1" and
            manifest.get("schemaVersion") == 1 and
            manifest.get("sourcePackageSha256") == incoming_sha,
            "Offline manifest does not match the exact Godot bundle")
    require(manifest.get("readyForRuntime") is False and
            manifest.get("runtimeApplied") is False and
            manifest.get("cannotAutoApply") is True,
            "Cannot accept already-authorized/unlocked offline manifest")
    require(manifest.get("candidateSha256") ==
            {name: _sha(data) for name, data in verified.items()
             if name in d1.CANDIDATE_NAMES},
            "Offline manifest candidate SHA list does not match the Godot bundle")
    expected_sources = {k: _sha(_safe_read(base / name)) for k, name in d1.FILES.items()}
    require(manifest.get("sourceSha256") == expected_sources,
            "Offline manifest source hashes differ from the five current files")
    require(set(p.name for p in staging_dir.iterdir()) ==
            set(d1.CANDIDATE_NAMES) | {"offline_integrity_manifest.json"},
            "Offline directory has unexpected/missing files")
    for name, bytes_value in verified.items():
        if name == "offline_integrity_manifest.json":
            # Audit equality of semantic fields to allow nonessential JSON formatting.
            continue
        actual = _safe_read(staging_dir / name)
        require(actual == bytes_value,
                "Offline staged file changed after integrity check: " + name)

    canon = _load_bytes(_safe_read(base / d1.FILES["catalog"]), "canonical catalog")
    candidate = _load_bytes(verified[d1.FILES["catalog"]], "candidate catalog")
    routes = _load_bytes(verified[d1.FILES["routes"]], "candidate routes")
    cues = _load_bytes(verified[d1.FILES["cues"]], "candidate cues")
    foundation_data = _load_bytes(_safe_read(foundation), "foundation catalog")
    save_data = _load_bytes(_safe_read(save_path), "save contract")
    require(save_data.get("ravenSchema") == 1 and
            save_data.get("ravenKey") == "raven-manor-campaign-v1",
            "Unknown save contract; review migration before any scene publication")
    require(foundation_data.get("schemaVersion") == 1 and
            isinstance(foundation_data.get("storyBeats"), list),
            "Unsupported foundation storyBeat registry contract")

    original_lines = d1.index(canon["entries"], "id", "canonical lines")
    new_lines = d1.index(candidate["entries"], "id", "candidate lines")
    new_scenes = list(package["sceneIdMap"].values())
    new_line_ids = list(package["lineIdMap"].values())
    foundation_beats = set(foundation_data["storyBeats"])
    level_ids = set(foundation_data["levels"])
    old_scenes = {item["sceneId"] for item in canon["scenes"]}
    blockers: list[str] = []
    warnings: list[str] = []

    require(bool(new_scenes) or bool(new_line_ids),
            "No authored scene or line was proposed for this release rehearsal")
    # Existing saves are normalized by RavenSnapshot against foundation_catalog.
    # A new story beat absent there would be discarded, even if in dialogue data.
    for scene_id in new_scenes:
        if scene_id not in foundation_beats:
            blockers.append(scene_id + ": not in foundation_catalog.storyBeats; Snapshot.normalize would drop this ID")
        blockers.append(scene_id + ": runtime scene presenter/interaction path not registered in RavenSliceDirector")
        blockers.append(scene_id + ": route is review-only draft_unapproved, not playable")
        blockers.append(scene_id + ": art asset provenance and owner approval not recorded")
        scene = next(x for x in candidate["scenes"] if x["sceneId"] == scene_id)
        for lang in ("be", "en"):
            if not isinstance(scene.get("title", {}).get(lang), str) or not scene["title"][lang].strip():
                blockers.append(scene_id + ": missing approved scene title " + lang.upper())

    # Only new text requires complete release translations in this incremental
    # preflight. Existing season1 BE/EN translation debt is reported separately.
    for line_id in new_line_ids:
        line = new_lines[line_id]
        for lang in ("be", "en"):
            cell = line.get("localized", {}).get(lang)
            if not isinstance(cell, dict) or not str(cell.get("text", "")).strip():
                blockers.append(line_id + ": missing " + lang.upper() + " release translation")
        blockers.append(line_id + ": performance cue still manualReview=true")
    if new_line_ids:
        blockers.append("Save/replay and VN line-paging parity for newly inserted lines not approved")

    original_missing = 0
    for entry in original_lines.values():
        for lang in ("be", "en"):
            cell = entry.get("localized", {}).get(lang)
            if not isinstance(cell, dict) or not str(cell.get("text", "")).strip():
                original_missing += 1
    if original_missing:
        warnings.append(f"Existing canon still has {original_missing} BE/EN missing cells (outside new-content gate)")
    blockers.append("No signed/owner-reviewed release transition, revert PR and accepted save compatibility evidence")
    blockers.append("Runtime routing/reducer, Match-3 branching and old-save replay tests must be reviewed before enabling routes")

    route_warnings, route_list = _dependency_report(
        package.get("routeProposals", {}), old_scenes, set(new_scenes), level_ids)
    blockers.extend(route_warnings)

    ids = {x["sceneId"] for x in routes["sceneTriggers"]}
    require(ids == old_scenes | set(new_scenes), "Candidate route scene IDs changed")
    cue_index = d1.index(cues["cues"], "lineId", "candidate cues")
    require(set(cue_index) == set(new_lines), "New candidate cues do not match lines")
    changed_original_lines = sorted([
        id for id in original_lines if original_lines[id] != new_lines[id]])
    diff_summary = {
        "scenesBefore": len(canon["scenes"]),
        "scenesProposed": len(candidate["scenes"]),
        "linesBefore": len(canon["entries"]),
        "linesProposed": len(candidate["entries"]),
        "newScenes": sorted(new_scenes),
        "newLines": sorted(new_line_ids),
        "editedCanonicalLines": changed_original_lines,
        "routeProposals": route_list,
    }
    original_files = {
        name: _sha(_safe_read(base / name))
        for name in d1.FILES.values()}
    original_files["foundation_catalog.json"] = _sha(_safe_read(foundation))
    original_files["save_contract.json"] = _sha(_safe_read(save_path))
    return {
        "format": AUDIT_FORMAT,
        "schemaVersion": 1,
        "status": "NOT_RELEASE_READY",
        "sourceGodotPackageSha256": incoming_sha,
        "offlineManifestSha256": _sha(manifest_bytes),
        "candidateSha256": {name: _sha(verified[name]) for name in d1.CANDIDATE_NAMES},
        "rollbackOriginalSha256": original_files,
        "saveCompatibility": {
            "ravenSaveKey": save_data["ravenKey"],
            "ravenSaveSchema": save_data["ravenSchema"],
            "foundationStoryBeatCount": len(foundation_beats),
            "newStoryBeatsRegistered": sorted(set(new_scenes) & foundation_beats),
            "newStoryBeatsMissing": sorted(set(new_scenes) - foundation_beats),
            "existingSavesRemainUnmodified": True,
            "oldSaveMigrationVerifiedForRuntime": False,
        },
        "diffSummary": diff_summary,
        "warnings": _one_line(warnings),
        "blockers": _one_line(blockers),
        "readyForRuntime": False,
        "runtimeApplied": False,
        "rollbackPlan": {
            "mode": "EXTERNAL_AUDIT_BACKUP_ONLY",
            "order": ["Review exact four-registry/scene/reducer diff",
                      "Take backup of existing saves before any release",
                      "Rehearse rollback with game-save snapshots",
                      "Only then create an owner-approved atomic source PR"],
            "neverRestoreUserSavesAutomatically": True,
            "sourceBackupsIncluded": True,
        },
    }


def write_audit_once(output: Path, report: dict, *,
                     base: Path = BASE, foundation: Path = FOUNDATION,
                     save_path: Path = SAVE_CONTRACT) -> None:
    require(not output.exists(), "Audit output already exists; no overwrite")
    require(output.parent.is_dir(), "Audit parent directory does not exist")
    require(not output.resolve().is_relative_to(ROOT.resolve()),
            "Audit must be outside the repository checkout")
    originals = {**{name: base / name for name in d1.FILES.values()},
                 "foundation_catalog.json": foundation,
                 "save_contract.json": save_path}
    # Audit is intentionally an EXTERNAL backup, not a production overwrite.
    output.mkdir(exist_ok=False)
    try:
        rollback = output / "rollback"
        rollback.mkdir(exist_ok=False)
        for name, path in originals.items():
            raw = _safe_read(path)
            require(_sha(raw) == report["rollbackOriginalSha256"][name],
                    "Source changed since audit; block backup: " + name)
            with (rollback / name).open("xb") as out:
                out.write(raw)
        raw = (json.dumps(report, ensure_ascii=False, indent=2) + "\n").encode()
        with (output / "release_readiness_report.json").open("xb") as stream:
            stream.write(raw)
    except Exception:
        for file in (output / "rollback").glob("*") if (output / "rollback").exists() else []:
            file.unlink()
        if (output / "rollback").exists():
            (output / "rollback").rmdir()
        if (output / "release_readiness_report.json").exists():
            (output / "release_readiness_report.json").unlink()
        output.rmdir()
        raise


def main(args: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--staging", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--require-ready", action="store_true")
    options = parser.parse_args(args)
    if not options.check_only and options.output is None:
        parser.error("--output is required without --check-only")
    try:
        raw = _safe_read(options.package)
        report = audit(_load_bytes(raw, "Godot review package"), raw, options.staging)
        if options.require_ready:
            require(not report["blockers"] and report["readyForRuntime"],
                    f"NOT RELEASE READY: {len(report['blockers'])} unresolved requirements")
        if options.output and not options.check_only:
            write_audit_once(options.output, report)
            print("External audit and rollback sources:", options.output)
        print("NOT RELEASE READY: %d blockers, %d warnings" %
              (len(report["blockers"]), len(report["warnings"])))
        return 0
    except (OSError, ValueError, TypeError, KeyError) as exc:
        print("BLOCKED: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
