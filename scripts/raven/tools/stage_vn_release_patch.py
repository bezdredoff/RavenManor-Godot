#!/usr/bin/env python3
"""VNS5-06D2B: stage a traceable, reversible narrative source diff for review.

NO production writes, git operations, save writes, executable route activation,
or automatic restore. Consumes the *one* VNS5-06D1 Godot review format,
D1-CLI extracted files, D2A audit/rollback backup and an explicit review
acknowledgment tied to exact file hashes.

  python3 scripts/raven/tools/stage_vn_release_patch.py --package godot.json \
    --staging extracted --audit audited --decision release-decision.json --check-only
  python3 scripts/raven/tools/stage_vn_release_patch.py --package godot.json \
    --staging extracted --audit audited --decision release-decision.json \
    --output /tmp/new-vn-review-patch
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

from scripts.raven.tools import prepare_vn_promotion as d1
from scripts.raven.tools import plan_vn_release as d2a

ROOT = d2a.ROOT
FORMAT = "raven-vn-release-stage-decision-v1"
OUTPUT_FORMAT = "raven-vn-locked-patch-review-v1"
KEYS = {
    "format", "schemaVersion", "releaseMode", "packageSha256",
    "auditReportSha256", "reviewRef", "storyReviewRef", "artReviewRef",
    "localizationReviewRef", "saveReviewRef", "acceptedSceneIds",
    "acceptedLineIds", "acceptedRouteProposals", "unresolvedBlockers",
    "enableRuntime", "applyToRepo"
}
LOCKED = "REVIEW_ONLY_NO_RUNTIME"
STAGED_NAMES = [*d1.CANDIDATE_NAMES, "foundation_catalog.json"]
BACKUP_NAMES = [*d1.FILES.values(), "foundation_catalog.json", "save_contract.json"]


def require(ok: bool, message: str) -> None:
    if not ok:
        raise d1.BundleError(message)


def _read(path: Path) -> bytes:
    return d2a._safe_read(path)


def _digest(contents: bytes) -> str:
    return hashlib.sha256(contents).hexdigest()


def _parse(contents: bytes, where: str) -> dict:
    value = json.loads(contents.decode("utf-8"))
    require(isinstance(value, dict), where + " must be a JSON object")
    return value


def _normal_path(path: Path) -> Path:
    # resolve() ensures symlink ancestors and traversal don't bypass the
    # repository / input-folder exclusion check.
    return path.resolve()


def _external_destination(output: Path, inputs: list[Path]) -> None:
    target = _normal_path(output)
    require(not output.exists() and not output.is_symlink(), "Output already exists; no overwrite")
    require(output.parent.is_dir(), "Output parent directory missing")
    for protected in [ROOT, *inputs]:
        root = _normal_path(protected)
        require(not (target == root or target.is_relative_to(root) or
                     root.is_relative_to(target)),
                "Output overlaps repository or source review/backup directory")
    require(not target.is_relative_to(ROOT.resolve()), "Output must be outside the repository")


def stage(package_path: Path, staging_dir: Path, audit_dir: Path,
          decision_path: Path, *,
          base: Path = d1.BASE, foundation: Path = d2a.FOUNDATION,
          save_path: Path = d2a.SAVE_CONTRACT) -> dict:
    """Recheck D1/D2A source hash chain; return immutable review-only sources."""
    package_raw = _read(package_path)
    review = _parse(package_raw, "Godot review package")
    report = d2a.audit(review, package_raw, staging_dir,
                       base=base, foundation=foundation, save_path=save_path)
    require(report.get("status") == "NOT_RELEASE_READY" and
            report.get("runtimeApplied") is False and
            report.get("readyForRuntime") is False,
            "Cannot stage a released or runtime-enabled package")
    require(audit_dir.is_dir() and not audit_dir.is_symlink(), "D2A audit folder missing")
    audit_raw = _read(audit_dir / "release_readiness_report.json")
    previously = _parse(audit_raw, "D2A report")
    require(previously == report,
            "D2A audit is stale, modified or not for the exact review inputs")
    require(set(p.name for p in audit_dir.iterdir()) ==
            {"release_readiness_report.json", "rollback"},
            "Unexpected or missing D2A audit files")
    old_dir = audit_dir / "rollback"
    require(old_dir.is_dir() and not old_dir.is_symlink(), "D2A rollback directory missing")
    require(set(p.name for p in old_dir.iterdir()) == set(BACKUP_NAMES),
            "D2A rollback must contain all exact original source files")
    originals: dict[str, bytes] = {}
    for name in BACKUP_NAMES:
        raw = _read(old_dir / name)
        require(_digest(raw) == report["rollbackOriginalSha256"][name],
                "D2A rollback source checksum mismatch: " + name)
        if name == "foundation_catalog.json":
            source_path = foundation
        elif name == "save_contract.json":
            source_path = save_path
        else:
            source_path = base / name
        require(raw == _read(source_path),
                "Source changed since D2A audit: " + name)
        originals[name] = raw

    decision = _parse(_read(decision_path), "Release review acknowledgment")
    require(set(decision) == KEYS, "Release review decision has missing/foreign fields")
    require(decision.get("format") == FORMAT and decision.get("schemaVersion") == 1,
            "Unsupported release review decision version")
    require(decision.get("releaseMode") == LOCKED and
            decision.get("enableRuntime") is False and
            decision.get("applyToRepo") is False,
            "Runtime activation and applying canonical source files forbidden in this phase")
    require(decision.get("packageSha256") == _digest(package_raw) and
            decision.get("auditReportSha256") == _digest(audit_raw),
            "Release decision must bind exact bytes of Godot and D2A report")
    require(decision.get("reviewRef") == review["reviewRef"],
            "Review reference must match the native Godot package")
    for key in ("storyReviewRef", "artReviewRef", "localizationReviewRef", "saveReviewRef"):
        require(isinstance(decision.get(key), str) and
                4 <= len(decision[key].strip()) <= 160,
                key + " must provide a meaningful external review reference")
    scenes = sorted(review["sceneIdMap"].values())
    lines = sorted(review["lineIdMap"].values())
    require(decision.get("acceptedSceneIds") == scenes and
            decision.get("acceptedLineIds") == lines,
            "Decision must name all and only proposed scene/line IDs")
    require(decision.get("acceptedRouteProposals") == review["routeProposals"],
            "Route decisions must match the exact Godot proposal; no unreviewed changes")
    require(decision.get("unresolvedBlockers") == report["blockers"],
            "Every D2A release blocker must remain acknowledged and unresolved")

    # The only allowed staged foundation change is appending the mapped new
    # story beats; existing IDs/values and save schema must be preserved.
    foundation_data = _parse(originals["foundation_catalog.json"], "foundation")
    require(foundation_data.get("schemaVersion") == 1 and
            isinstance(foundation_data.get("storyBeats"), list),
            "Unknown foundation registry")
    old_beats = foundation_data["storyBeats"]
    new_beats = [id for id in scenes if id not in old_beats]
    require(not set(scenes).intersection(old_beats),
            "New scene IDs already exist in the foundation registry")
    candidate_foundation = json.loads(json.dumps(foundation_data))
    candidate_foundation["storyBeats"].extend(new_beats)
    require(len(set(candidate_foundation["storyBeats"])) ==
            len(candidate_foundation["storyBeats"]),
            "Duplicate story beat IDs would break save normalization")
    # Save schema/keys deliberately never change; old saves retain all known
    # story beat ids after a future approved registry addition.
    save_contract = _parse(originals["save_contract.json"], "save contract")
    require(save_contract.get("ravenSchema") == 1 and
            save_contract.get("ravenKey") == "raven-manor-campaign-v1",
            "Incompatible save contract")
    candidate_files = {name: _read(staging_dir / name) for name in d1.CANDIDATE_NAMES}
    candidate_files["foundation_catalog.json"] = (
        json.dumps(candidate_foundation, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    # No route may be made playable. D1-CLI and D2A enforce this on each call.
    for route in _parse(candidate_files[d1.FILES["routes"]], "routes")["sceneTriggers"]:
        if route["sceneId"] in scenes:
            gate = route["gate"]
            require(gate.get("kind") == "draft_unapproved" and
                    gate.get("approvedRuntime") is False,
                    "No route activation permitted in review staging")
    plan = {
        "format": OUTPUT_FORMAT,
        "schemaVersion": 1,
        "status": "NOT_RELEASE_READY",
        "reviewRef": decision["reviewRef"],
        "reviewRefs": {key: decision[key] for key in
                       ("storyReviewRef", "artReviewRef",
                        "localizationReviewRef", "saveReviewRef")},
        "sourceGodotPackageSha256": _digest(package_raw),
        "sourceAuditReportSha256": _digest(audit_raw),
        "sourceDecisionSha256": _digest(_read(decision_path)),
        "baselineSourceSha256": {name: _digest(originals[name]) for name in BACKUP_NAMES},
        "stagedCandidateSha256": {name: _digest(candidate_files[name]) for name in STAGED_NAMES},
        "newSceneIds": scenes,
        "newLineIds": lines,
        "sceneIdsAddedToFoundationCandidate": new_beats,
        "routeProposals": review["routeProposals"],
        "unresolvedBlockers": report["blockers"],
        "changesNeededOutsideRegistry": [
            "Implement and test approved RavenSliceDirector/playable VN scene dispatch",
            "Add approved route gate and interaction mapping with story completion",
            "Run old-save/new-save replay, snapshot persistence and rollback tests",
            "Complete localization, art provenance and owner-approved cues",
            "Obtain owner-reviewed production PR with exact source diff"
        ],
        "rollbackOrder": [
            "Do not touch player saves automatically",
            "Restore tracked registry/scene changes from reviewed baseline commit",
            "Reapply any released migrations only after independent save check"
        ],
        "runtimeApplied": False, "readyForRuntime": False,
        "canMergeToProduction": False, "mayRestoreSavesAutomatically": False,
    }
    return {"manifest": plan, "staged": candidate_files, "rollback": originals}


def write_once(output: Path, contents: dict, inputs: list[Path]) -> None:
    _external_destination(output, inputs)
    # All files are bytes checked above. A new external directory is the only
    # write surface. No shutil / execution / git / automatic restore.
    output.mkdir(exist_ok=False)
    try:
        for folder in ("candidate", "rollback"):
            (output / folder).mkdir(exist_ok=False)
        for group, keys in (("candidate", STAGED_NAMES), ("rollback", BACKUP_NAMES)):
            for name in keys:
                with (output / group / name).open("xb") as f:
                    f.write(contents["staged" if group == "candidate" else group][name])
        manifest = (json.dumps(contents["manifest"], ensure_ascii=False, indent=2) + "\n").encode("utf-8")
        with (output / "locked_release_patch_manifest.json").open("xb") as f:
            f.write(manifest)
        for folder, group, keys, field in (
            ("candidate", "staged", STAGED_NAMES, "stagedCandidateSha256"),
            ("rollback", "rollback", BACKUP_NAMES, "baselineSourceSha256")):
            for name in keys:
                require(_digest(_read(output / folder / name)) == contents["manifest"][field][name],
                        "Output verification failed: " + name)
    except Exception:
        for folder in ("candidate", "rollback"):
            directory = output / folder
            if directory.is_dir():
                for file in directory.iterdir():
                    file.unlink()
                directory.rmdir()
        m = output / "locked_release_patch_manifest.json"
        if m.exists():
            m.unlink()
        output.rmdir()
        raise


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--staging", required=True, type=Path)
    parser.add_argument("--audit", required=True, type=Path)
    parser.add_argument("--decision", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args(argv)
    if not args.check_only and args.output is None:
        parser.error("--output is required without --check-only")
    try:
        data = stage(args.package, args.staging, args.audit, args.decision)
        if not args.check_only:
            write_once(args.output, data, [args.staging, args.audit,
                                          args.package.parent, args.decision.parent])
            print("Created LOCKED review staging package:", args.output)
        print("PASS: reversible candidate staged for review, runtime still BLOCKED")
        return 0
    except (OSError, ValueError, TypeError, KeyError) as exc:
        print("BLOCKED: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
