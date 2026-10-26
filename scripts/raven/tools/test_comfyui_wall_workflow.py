import json
import unittest
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class ComfyUIWallWorkflowTests(unittest.TestCase):
    def test_exact_first_act_prompt_matrix(self):
        manifest = json.loads((ROOT / "data/raven/comfyui_wall_asset_manifest.json").read_text(encoding="utf-8"))
        jobs = manifest["jobs"]
        self.assertEqual(manifest["status"], "GENERATION_CANDIDATES_NOT_ART_APPROVED")
        self.assertEqual(manifest["count"], 52)
        self.assertEqual(len(jobs), 52)
        self.assertEqual(len({job["id"] for job in jobs}), 52)
        self.assertEqual(len({job["seed"] for job in jobs}), 52)
        self.assertEqual(Counter(job["category"] for job in jobs),
                         {"structure": 28, "door": 12, "window": 5, "arch": 3, "foreground": 4})
        for style in ("grand", "residential", "service", "glass"):
            self.assertEqual(sum(job["category"] == "structure" and job["style"] == style for job in jobs), 7)
        for job in jobs:
            self.assertEqual((job["width"], job["height"]), (1024, 1024))
            self.assertIn("orthographic 65-degree top-down camera", job["prompt"])
            self.assertIn("plain white background", job["prompt"])
            self.assertIn("no characters", job["prompt"])

    def test_api_graph_is_connected_and_uses_manifest_models(self):
        workflow = json.loads((ROOT / "scripts/raven/comfyui/raven_wall_asset_api.json").read_text(encoding="utf-8"))
        manifest = json.loads((ROOT / "data/raven/comfyui_wall_asset_manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(workflow["10"]["inputs"]["unet_name"], manifest["model"]["unet"])
        self.assertEqual(workflow["11"]["inputs"]["clip_name"], manifest["model"]["clip"])
        self.assertEqual(workflow["12"]["inputs"]["vae_name"], manifest["model"]["vae"])
        self.assertEqual(workflow["27"]["inputs"]["model"], manifest["model"]["rembg"])
        self.assertEqual(workflow["27"]["inputs"]["background"], "Alpha")
        self.assertEqual(workflow["81"]["inputs"]["images"], ["27", 0])
        for node in workflow.values():
            for value in node["inputs"].values():
                if isinstance(value, list) and len(value) == 2 and isinstance(value[0], str):
                    self.assertIn(value[0], workflow)


if __name__ == "__main__":
    unittest.main()
