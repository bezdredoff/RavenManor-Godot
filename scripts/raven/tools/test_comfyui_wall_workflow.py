import importlib.util
import json
import tempfile
import unittest
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
COMFY = ROOT / "scripts/raven/comfyui"

try:  # The review checks and guide renderer only run when Pillow is present.
    from PIL import Image

    HAS_PIL = True
except ImportError:  # pragma: no cover - exercised only on machines without Pillow
    HAS_PIL = False


def load_module(name, filename):
    spec = importlib.util.spec_from_file_location(name, COMFY / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def registry(manifest):
    """Minimal stand-in for live /object_info, limited to the nodes this batch uses."""
    combo = lambda *options: [list(options)]
    v3_combo = lambda *options: ["COMBO", {"options": list(options)}]
    return {
        "LoadImage": {"input": {"required": {"image": combo("guide.png")}},
                      "output": ["IMAGE", "MASK"]},
        "ImageScaleToTotalPixels": {"input": {"required": {
            "image": ["IMAGE"], "upscale_method": combo("lanczos", "bicubic", "area"),
            "megapixels": ["FLOAT", {"default": 1.0}],
            "resolution_steps": ["INT", {"default": 1}]}}, "output": ["IMAGE"]},
        "UNETLoader": {"input": {"required": {
            "unet_name": combo(manifest["model"]["unet"]),
            "weight_dtype": combo("default", "fp8_e4m3fn")}}, "output": ["MODEL"]},
        "CLIPLoader": {"input": {"required": {
            "clip_name": combo(manifest["model"]["clip"]),
            "type": combo("flux2", "qwen_image"),
            "device": combo("default", "cpu")}}, "output": ["CLIP"]},
        "VAELoader": {"input": {"required": {"vae_name": combo(manifest["model"]["vae"])}},
                      "output": ["VAE"]},
        "KSamplerSelect": {"input": {"required": {"sampler_name": v3_combo("euler", "heun")}},
                           "output": ["SAMPLER"]},
        "VNCCS_Flux_Klein_Encoder": {"input": {
            "required": {"clip": ["CLIP"], "prompt": ["STRING"], "vae": ["VAE"]},
            "optional": {"image1": ["IMAGE"], "image2": ["IMAGE"], "image3": ["IMAGE"],
                         "upscale_method": combo("lanczos"), "megapixels": ["FLOAT"],
                         "resolution_steps": ["INT"], "empty_width": ["INT"],
                         "empty_height": ["INT"], "batch_size": ["INT"]}},
            "output": ["CONDITIONING", "CONDITIONING", "LATENT"]},
        "Flux2Scheduler": {"input": {"required": {"steps": ["INT"], "width": ["INT"],
                                                  "height": ["INT"]}}, "output": ["SIGMAS"]},
        "BasicGuider": {"input": {"required": {"model": ["MODEL"],
                                               "conditioning": ["CONDITIONING"]}},
                        "output": ["GUIDER"]},
        "RandomNoise": {"input": {"required": {"noise_seed": ["INT"]}}, "output": ["NOISE"]},
        "SamplerCustomAdvanced": {"input": {"required": {
            "noise": ["NOISE"], "guider": ["GUIDER"], "sampler": ["SAMPLER"],
            "sigmas": ["SIGMAS"], "latent_image": ["LATENT"]}},
            "output": ["LATENT", "LATENT"]},
        "VAEDecode": {"input": {"required": {"samples": ["LATENT"], "vae": ["VAE"]}},
                      "output": ["IMAGE"]},
        "BiRefNetRMBG": {"input": {
            "required": {"image": ["IMAGE"], "model": combo(manifest["model"]["rembg"])},
            "optional": {"sensitivity": ["FLOAT"], "mask_blur": ["INT"],
                         "mask_offset": ["INT"], "invert_output": ["BOOLEAN"],
                         "refine_foreground": ["BOOLEAN"], "background": combo("Alpha", "Color"),
                         "background_color": ["COLORCODE"]}},
            "output": ["IMAGE", "MASK", "IMAGE"]},
        "SaveImage": {"input": {"required": {"images": ["IMAGE"],
                                             "filename_prefix": ["STRING"]}},
                      "output": ["IMAGE"]},
    }


class ComfyUIWallWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.manifest = read_json(ROOT / "data/raven/comfyui_wall_asset_manifest.json")
        self.workflow = read_json(COMFY / "raven_wall_asset_api.json")
        self.runner = load_module("run_wall_asset_batch", "run_wall_asset_batch.py")

    def test_exact_first_act_prompt_matrix(self):
        jobs = self.manifest["jobs"]
        self.assertEqual(self.manifest["status"], "GENERATION_CANDIDATES_NOT_ART_APPROVED")
        self.assertEqual(self.manifest["count"], 52)
        self.assertEqual(len(jobs), 52)
        self.assertEqual(len({job["id"] for job in jobs}), 52)
        self.assertEqual(len({job["seed"] for job in jobs}), 52)
        self.assertEqual(Counter(job["category"] for job in jobs),
                         {"structure": 28, "door": 12, "window": 5, "arch": 3, "foreground": 4})
        for style in ("grand", "residential", "service", "glass"):
            self.assertEqual(sum(job["category"] == "structure" and job["style"] == style
                                 for job in jobs), 7)
        for job in jobs:
            self.assertEqual((job["width"], job["height"]), (1024, 1024))
            self.assertIn("orthographic 65-degree top-down game view", job["prompt"])
            self.assertIn("blank pure-white studio backdrop", job["prompt"])
            self.assertIn("fully inside the frame with a wide empty white margin", job["prompt"])
            self.assertIn(job["guide"], self.runner.GUIDE_KINDS)
            # The sampler has no CFG step, so negated nouns in the prompt are rendered as
            # content: an early pass with "no characters" produced a woman silhouette.
            for forbidden in ("no characters", "no furniture", "no floor plane", "no room scene",
                              "no text", "no watermark", "no crop", "no fisheye"):
                self.assertNotIn(forbidden, job["prompt"])

    def test_api_graph_is_connected_and_uses_manifest_models(self):
        self.assertEqual(self.workflow["10"]["inputs"]["unet_name"],
                         self.manifest["model"]["unet"])
        self.assertEqual(self.workflow["11"]["inputs"]["clip_name"],
                         self.manifest["model"]["clip"])
        self.assertEqual(self.workflow["12"]["inputs"]["vae_name"],
                         self.manifest["model"]["vae"])
        self.assertEqual(self.workflow["27"]["inputs"]["model"],
                         self.manifest["model"]["rembg"])
        self.assertEqual(self.workflow["27"]["inputs"]["background"], "Alpha")
        self.assertEqual(self.workflow["81"]["inputs"]["images"], ["27", 0])
        for node in self.workflow.values():
            for value in node["inputs"].values():
                if isinstance(value, list) and len(value) == 2 and isinstance(value[0], str):
                    self.assertIn(value[0], self.workflow)

    def test_alpha_cutout_uses_the_installed_birefnet_node(self):
        # VNCCS_RMBG2 was never installed locally; the batch must use the real node.
        node = self.workflow["27"]
        self.assertEqual(node["class_type"], "BiRefNetRMBG")
        self.assertEqual(node["inputs"]["model"], "BiRefNet_toonout")
        self.assertIs(node["inputs"]["refine_foreground"], True)
        self.assertIs(node["inputs"]["invert_output"], False)
        self.assertEqual(node["inputs"]["background"], "Alpha")
        self.assertEqual(node["inputs"]["sensitivity"], 1.0)

    def test_workflow_matches_the_declared_live_node_contract(self):
        self.assertEqual(self.runner.validate_graph(self.workflow,
                                                     registry(self.manifest)), [])

    def test_preflight_reports_stale_or_unsupported_graph_edits(self):
        cases = []
        stale = json.loads(json.dumps(self.workflow))
        stale["27"]["class_type"] = "VNCCS_RMBG2"
        cases.append((stale, "no node class 'VNCCS_RMBG2'"))

        stray = json.loads(json.dumps(self.workflow))
        stray["80"]["inputs"]["quality"] = 90
        cases.append((stray, "unsupported input 'quality'"))

        wrong_model = json.loads(json.dumps(self.workflow))
        wrong_model["27"]["inputs"]["model"] = "BiRefNet_toonout.safetensors"
        cases.append((wrong_model, "is not installed in ComfyUI"))

        wrong_link = json.loads(json.dumps(self.workflow))
        wrong_link["80"]["inputs"]["images"] = ["26", 4]
        cases.append((wrong_link, "which has 1"))

        missing_link = json.loads(json.dumps(self.workflow))
        missing_link["80"]["inputs"]["images"] = ["99", 0]
        cases.append((missing_link, "links to missing node '99'"))

        missing_input = json.loads(json.dumps(self.workflow))
        del missing_input["24"]["inputs"]["noise_seed"]
        cases.append((missing_input, "missing required input 'noise_seed'"))

        for workflow, expected in cases:
            with self.subTest(expected=expected):
                problems = self.runner.validate_graph(workflow, registry(self.manifest))
                self.assertTrue(any(expected in problem for problem in problems),
                                f"{expected!r} not reported in {problems}")

    def test_manifest_model_names_are_bound_to_graph_nodes(self):
        self.assertEqual(self.runner.bind_model_names(self.manifest, self.workflow), [])
        drifted = json.loads(json.dumps(self.workflow))
        drifted["12"]["inputs"]["vae_name"] = "other-vae.safetensors"
        problems = self.runner.bind_model_names(self.manifest, drifted)
        self.assertTrue(any("vae" in problem for problem in problems), problems)

    def test_server_candidates_cover_the_default_and_desktop_ports(self):
        self.assertIn("http://127.0.0.1:8188", self.runner.SERVER_CANDIDATES)
        self.assertIn("http://127.0.0.1:8000", self.runner.SERVER_CANDIDATES)

    @unittest.skipUnless(HAS_PIL, "Pillow is required to render guides")
    def test_guides_are_black_silhouettes_on_white(self):
        for kind in self.runner.GUIDE_KINDS:
            with self.subTest(kind=kind):
                image = self.runner.render_guide(kind).convert("L")
                self.assertEqual(image.getpixel((0, 0)), 255)
                self.assertLess(image.getextrema()[0], 32)  # a visible black silhouette


class WallReviewTests(unittest.TestCase):
    def setUp(self):
        self.review = load_module("review_wall_asset_batch", "review_wall_asset_batch.py")
        self.runner = load_module("run_wall_asset_batch", "run_wall_asset_batch.py")
        self.manifest = read_json(ROOT / "data/raven/comfyui_wall_asset_manifest.json")

    @unittest.skipUnless(HAS_PIL, "Pillow is required for the alpha checks")
    def test_alpha_checks_flag_empty_opaque_and_clipped_cutouts(self):
        with tempfile.TemporaryDirectory() as temp:
            empty = Path(temp) / "empty.png"
            Image.new("RGBA", (64, 64), (0, 0, 0, 0)).save(empty)
            self.assertIn("alpha_empty", self.review.analyze_alpha(empty)["flags"])

            opaque = Path(temp) / "opaque.png"
            Image.new("RGBA", (64, 64), (10, 20, 30, 255)).save(opaque)
            flags = self.review.analyze_alpha(opaque)["flags"]
            self.assertIn("alpha_opaque", flags)
            self.assertIn("alpha_touches_border", flags)

            clean = Path(temp) / "clean.png"
            canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
            canvas.paste((120, 30, 40, 255), (16, 16, 48, 48))
            canvas.save(clean)
            self.assertEqual(self.review.analyze_alpha(clean)["flags"], [])

    @unittest.skipUnless(HAS_PIL, "Pillow is required for the raw check")
    def test_raw_background_check_rejects_dark_canvases(self):
        with tempfile.TemporaryDirectory() as temp:
            white = Path(temp) / "white.png"
            Image.new("RGB", (64, 64), (255, 255, 255)).save(white)
            self.assertEqual(self.review.analyze_raw(white)["flags"], [])
            dark = Path(temp) / "dark.png"
            Image.new("RGB", (64, 64), (12, 12, 12)).save(dark)
            self.assertIn("raw_background_not_white",
                          self.review.analyze_raw(dark)["flags"])

    def test_committed_review_manifest_matches_the_prompt_matrix(self):
        path = ROOT / "data/raven/comfyui_wall_asset_review.json"
        if not path.is_file():
            self.skipTest("no committed review manifest yet")
        review = read_json(path)
        self.assertEqual([job["id"] for job in review["jobs"]],
                         [job["id"] for job in self.manifest["jobs"]])
        self.assertEqual(review["model"], self.manifest["model"])
        for job in review["jobs"]:
            self.assertIn(job["decision"], ("pending", "approved", "rejected"))
            if job["decision"] != "pending":
                self.assertTrue(job["reviewer"], f"{job['id']} decided without a reviewer")
            for key in ("raw", "alpha"):
                if job[key]:
                    self.assertRegex(job[key]["sha256"], r"^[0-9a-f]{64}$")
                    self.assertEqual(job[key]["size"], [1024, 1024])

    @unittest.skipUnless(HAS_PIL, "Pillow is required to read candidates")
    def test_review_records_the_guide_silhouette_for_overlay_review(self):
        self.assertEqual(self.review.guide_bbox("straight_h"), [90, 390, 935, 636])
        self.assertEqual(self.review.guide_bbox("straight_v"), [390, 90, 636, 935])
        for kind in self.runner.GUIDE_KINDS:
            with self.subTest(kind=kind):
                box = self.review.guide_bbox(kind)
                self.assertEqual(len(box), 4)
                self.assertLess(box[0], box[2])
                self.assertLess(box[1], box[3])

    @unittest.skipUnless(HAS_PIL, "Pillow is required to read candidates")
    def test_review_manifest_preserves_human_decisions(self):
        manifest = {"model": self.manifest["model"],
                    "jobs": [self.manifest["jobs"][0]]}
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / self.review.RAW_SUBDIR).mkdir(parents=True)
            (root / self.review.ALPHA_SUBDIR).mkdir(parents=True)
            job_id = manifest["jobs"][0]["id"]
            raw = root / self.review.RAW_SUBDIR / f"{job_id}_00001_.png"
            alpha = root / self.review.ALPHA_SUBDIR / f"{job_id}_00001_.png"
            Image.new("RGB", (64, 64), (255, 255, 255)).save(raw)
            canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
            canvas.paste((90, 40, 20, 255), (16, 16, 48, 48))
            canvas.save(alpha)
            out = root / "review.json"

            first = self.review.build_review(manifest, root, out)
            self.assertEqual(first["jobs"][0]["decision"], "pending")
            self.assertEqual(first["summary"]["missing"], 0)
            self.assertIsNotNone(first["jobs"][0]["alpha"]["sha256"])

            first["jobs"][0]["decision"] = "approved"
            first["jobs"][0]["reviewer"] = "art-director"
            first["jobs"][0]["notes"] = "trim height matches"
            out.write_text(json.dumps(first), encoding="utf-8")

            second = self.review.build_review(manifest, root, out)
            self.assertEqual(second["jobs"][0]["decision"], "approved")
            self.assertEqual(second["jobs"][0]["reviewer"], "art-director")

            # A regenerated file invalidates the old approval instead of silently keeping it.
            canvas.paste((10, 200, 30, 255), (16, 16, 48, 48))
            canvas.save(alpha)
            third = self.review.build_review(manifest, root, out)
            self.assertEqual(third["jobs"][0]["decision"], "pending")
            self.assertIsNone(third["jobs"][0]["reviewer"])


if __name__ == "__main__":
    unittest.main()
