"""Raven production dashboard and phone ZIP preflight regression tests."""
import importlib.util
import io
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

TOOLS = Path(__file__).resolve().parent


def mod(filename, name):
    spec = importlib.util.spec_from_file_location(name, TOOLS / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


dashboard = mod("build_production_dashboard.py", "dashboard")
patch = mod("validate_mobile_patch.py", "mobile_patch")
SHA = "a" * 40


class DashboardTests(unittest.TestCase):
    def test_all_plan_sources_and_current_merge(self):
        data = dashboard.build()
        ids = [t["id"] for t in data["tasks"]]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertGreaterEqual(len(ids), 120)
        self.assertIn("RM-GAP-002", ids)
        self.assertIn("GFX-11-T01", ids)
        self.assertIn("CODE-01-01", ids)
        merged = next(t for t in data["tasks"] if t["id"] == "CODE-01-01")
        self.assertEqual(merged["status"], "merged")
        self.assertIn("pull/46", merged["evidence"])
        # IMPORTANT: a green or merged PR must never automatically mean accepted.
        self.assertNotEqual(merged["status"], "accepted")

    def test_art_source_is_not_mutated(self):
        source = dashboard.GFX.read_text(encoding="utf-8")
        stages, tasks = dashboard.graphics_items(source)
        self.assertEqual(len(stages), 14)
        self.assertTrue(all(t["status"] == "proposed" for t in tasks))
        self.assertIn("GFX-00-01", {t["id"] for t in tasks})


class MobileZipTests(unittest.TestCase):
    def archive(self, folder, manifest, members, extras=None):
        target = Path(folder) / "candidate.zip"
        with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("patch-manifest.json", json.dumps(manifest))
            for path, data in members.items():
                z.writestr(path, data)
            for path, data in (extras or {}).items():
                z.writestr(path, data)
        return target

    def manifest(self, files=None, base=SHA):
        return {"format": "raven-delta-v1", "baseSha": base,
                "feature": "CODE-02-R1", "taskIds": ["CODE-02-01"],
                "files": files or ["docs/foo.md"], "delete": []}

    def test_valid_archive_and_safe_extract(self):
        with tempfile.TemporaryDirectory() as tmp:
            zip_path = self.archive(tmp, self.manifest(), {"files/docs/foo.md": "hello"})
            out = Path(tmp) / "out"
            out.mkdir()
            result = patch.preflight(zip_path, SHA, out)
            self.assertEqual(result["files"], 1)
            self.assertEqual((out/"docs/foo.md").read_text(), "hello")

    def test_stale_sha_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            z = self.archive(tmp, self.manifest(base="b"*40), {"files/docs/foo.md":"x"})
            with self.assertRaises(patch.PatchError):
                patch.preflight(z,SHA)

    def test_undeclared_or_protected_paths_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            a = self.archive(tmp, self.manifest(), {"files/docs/foo.md":"x"}, {"extra.txt":"y"})
            with self.assertRaises(patch.PatchError):
                patch.preflight(a,SHA)
            b = self.archive(tmp, self.manifest(files=[".github/workflows/evil.yml"]),
                             {"files/.github/workflows/evil.yml":"oops"})
            with self.assertRaises(patch.PatchError):
                patch.preflight(b,SHA)

    def test_traversal_and_case_collisions_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            a = self.archive(tmp, self.manifest(files=["../outside"]),
                             {"files/../outside":"bad"})
            with self.assertRaises(patch.PatchError):
                patch.preflight(a,SHA)
            b = self.archive(tmp, self.manifest(), {"files/docs/foo.md":"x"}, {"files/DOCS/FOO.md":"x"})
            with self.assertRaises(patch.PatchError):
                patch.preflight(b,SHA)

    def test_symlinks_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            output=Path(tmp)/"test.zip"
            with zipfile.ZipFile(output,"w") as zf:
                zf.writestr("patch-manifest.json", json.dumps(self.manifest()))
                item=zipfile.ZipInfo("files/docs/foo.md")
                item.create_system=3
                item.external_attr=(0o120777 << 16)
                zf.writestr(item,"/etc/passwd")
            with self.assertRaises(patch.PatchError):
                patch.preflight(output,SHA)


if __name__ == "__main__":
    unittest.main()
